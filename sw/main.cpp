#ifdef IS_QT
    #include <QCoreApplication>
#endif

#include <iostream>
#include <cstdlib>
#include <cassert>
#include <cstring>
#include <cstdio>
#include <unistd.h>
#include <math.h>
#include <float.h>

#ifndef IS_QT
    #include "Board.h"
#endif
#include "Timer.h"

using namespace std;

// CONSTANTS
#define ADDR_WIDTH      12
#define MAX_SIZE        (1 << ADDR_WIDTH)

#define CORDIC_ROUNDS   16

#define X_MEM_ADDR      0x0000
#define Y_MEM_ADDR      0x1000
#define Z_MEM_ADDR      0x2000

#ifndef IS_QT
    #define MODE_ADDR   ((1 << MMAP_ADDR_WIDTH)-4)
    #define GO_ADDR     ((1 << MMAP_ADDR_WIDTH)-3)
    #define SIZE_ADDR   ((1 << MMAP_ADDR_WIDTH)-2)
    #define DONE_ADDR   ((1 << MMAP_ADDR_WIDTH)-1)
#endif

// Software atan
void sw_atan(unsigned *x_input, unsigned *y_input, double *outputs, unsigned size)
{
    double rad_to_deg = 180.0/M_PI;

    for(unsigned i = 0; i < size; ++i)
    {
        outputs[i] = atan(double(y_input[i])/double(x_input[i])) * rad_to_deg;
    }
}

// software implementation of the code implemented on the FPGA
void sw_cordic(unsigned *x_input, unsigned *y_input, unsigned *z_input,
                unsigned *x_output, unsigned *y_output, unsigned *z_output,
                unsigned size, unsigned mode) {

    for (unsigned i = 0; i < size; ++i) {

    signed x = x_input[i];
    signed y = y_input[i];
    signed z = z_input[i];

    double rad_to_deg = 180.0/M_PI;

    bool dir;

    for(unsigned j = 0; j < CORDIC_ROUNDS; ++j)
    {
        double shift_value  = 1/pow(2,j);
        double shifted_x    = signed(floor(double(x) * shift_value));
        double shifted_y    = signed(floor(double(y) * shift_value));

        signed theta        = signed(round(atan((1/pow(2, j))) * 256 * rad_to_deg));

        if(mode)
        {
            dir = z < 0;
        } else
        {
            dir = y >= 0;
        }

        if (dir)
        {
            x = x + shifted_y;
            y = y - shifted_x;
            z = z + theta;
        }else
        {
            x = x - shifted_y;
            y = y + shifted_x;
            z = z - theta;
        }
    }

    x_output[i] = x;
    y_output[i] = y;
    z_output[i] = z;
  }
}

int main(int argc, char *argv[])
{
    #ifdef IS_QT
        QCoreApplication a(argc, argv);
    #endif


    #ifndef IS_QT
        if (argc != 2) {
            cerr << "Usage: " << argv[0] << " bitfile" << endl;
            return -1;
        }
    #endif

    #ifndef IS_QT
        // setup clock frequencies
        vector<float> clocks(Board::NUM_FPGA_CLOCKS);
        clocks[0] = 100.0;
        clocks[1] = 100.0;
        clocks[2] = 0.0;
        clocks[3] = 0.0;

        // initialize board
        Board *board;
        try {
          board = new Board(argv[1], clocks);
        }
        catch(...) {
          exit(-1);
        }
    #endif

    unsigned size = 100;
    unsigned mode = 0;

    unsigned go, done;
    unsigned *x_input, *y_input, *z_input,
                *x_swOutput, *y_swOutput, *z_swOutput,
                *x_hwOutput, *y_hwOutput, *z_hwOutput;

    double *atan_outputs;

    Timer swCordicTime, swAtanTime, hwTime, readTime, writeTime, waitTime;

    x_input     = new unsigned[size];
    y_input     = new unsigned[size];
    z_input     = new unsigned[size];

    x_hwOutput    = new unsigned[size];
    y_hwOutput    = new unsigned[size];
    z_hwOutput    = new unsigned[size];

    x_swOutput    = new unsigned[size];
    y_swOutput    = new unsigned[size];
    z_swOutput    = new unsigned[size];

    atan_outputs  = new double[size];

    assert(x_input  != NULL);
    assert(y_input  != NULL);
    assert(z_input  != NULL);
    assert(x_swOutput != NULL);
    assert(y_swOutput != NULL);
    assert(z_swOutput != NULL);
    assert(x_hwOutput != NULL);
    assert(y_hwOutput != NULL);
    assert(z_hwOutput != NULL);
    assert(atan_outputs != NULL);

    // Initialize input array
    for (unsigned i=0; i < size; i++) {
        x_input[i] = (unsigned)rand() % 1024;
        y_input[i] = (unsigned)rand() % 1024;
        z_input[i] = 0;

        x_hwOutput[i] = 0;
        y_hwOutput[i] = 0;
        z_hwOutput[i] = 0;

        x_swOutput[i] = 0;
        y_swOutput[i] = 0;
        z_swOutput[i] = 0;

        atan_outputs[i] = 0;
    }

    // Test Print
    //  As it turns out, memset does not work... who knew?
    /*printf("size = %d\n", size);
    printf("mode = %d\n", mode);

    for (unsigned i=0; i < size; i++) {
      printf("%d: x_input = %d\n", i, x_input[i]);
      printf("%d: y_input = %d\n", i, y_input[i]);
      printf("%d: z_input = %d\n", i, z_input[i]);

      printf("%d: swOutput = %d\n", i, swOutput[i]);
      printf("%d: hwOutput = %d\n", i, hwOutput[i]);
    } */

    // transfer input array, size, and mode to FPGA
    hwTime.start();
    writeTime.start();
    #ifndef IS_QT
        board->write(x_input, X_MEM_ADDR, size);
        board->write(y_input, Y_MEM_ADDR, size);
        board->write(z_input, Z_MEM_ADDR, size);
        board->write(&size, SIZE_ADDR, 1);
        board->write(&mode, MODE_ADDR, 1);
    #endif
    writeTime.stop();

    // assert go. Note that the memory map automatically sets go back to 1 to
    // avoid an additional transfer.
    go = 1;
    #ifndef IS_QT
        board->write(&go, GO_ADDR, 1);
    #endif

    // wait for the board to assert done
    waitTime.start();
    done = 0;

    #ifndef IS_QT
        while (!done) {
            board->read(&done, DONE_ADDR, 1);
        }
    #endif
    waitTime.stop();

    // read the outputs back from the FPGA
    readTime.start();
    #ifndef IS_QT
        board->read(x_hwOutput, X_MEM_ADDR, size);
        board->read(y_hwOutput, Y_MEM_ADDR, size);
        board->read(z_hwOutput, Z_MEM_ADDR, size);
    #endif
    readTime.stop();
    hwTime.stop();

    // execute the same code in software
    swCordicTime.start();
    sw_cordic(x_input, y_input, z_input, x_swOutput, y_swOutput, z_swOutput, size, mode);
    swCordicTime.stop();

    swAtanTime.start();
    sw_atan(x_input, y_input, atan_outputs, size);
    swAtanTime.stop();

    printf("\n");
    printf("Results:\n");

    // Report CORDIC errors
    unsigned errors = 0;
    #ifndef IS_QT
        for (unsigned i=0; i < size; i++) {
            if(x_hwOutput[i] != x_swOutput[i])
            {
                printf("ERROR: X values do not match at iteration %d\n", i);
                printf("\tHW_X = %d\tSW_X = %d\n", x_hwOutput[i], x_swOutput[i]);
                ++errors;
            }
            if(y_hwOutput[i] != y_swOutput[i])
            {
                printf("ERROR: Y values do not match at iteration %d\n", i);
                printf("\tHW_Y = %d\tSW_Y = %d\n", y_hwOutput[i], y_swOutput[i]);
                ++errors;
            }
            if(z_hwOutput[i] != z_swOutput[i])
            {
                printf("ERROR: Z values do not match at iteration %d\n", i);
                printf("\tHW_Z = %d\tSW_Z = %d\n", z_hwOutput[i], z_swOutput[i]);
                ++errors;
            }
        }
    #endif

    printf("There were %d erros\n", errors);

    // Report percent error
    double *percentError;
    percentError = new double[size];

    double avg_percent_error = 0;
    double min_percent_error = DBL_MAX;
    double max_percent_error = 0;

    printf("\n");

    for(unsigned i = 0; i < size; ++i)
    {
        percentError[i] = fabs((double(z_hwOutput[i])/256.0) - atan_outputs[i])/atan_outputs[i];
        avg_percent_error += percentError[i];

        if(percentError[i] < min_percent_error)
        {
            min_percent_error = percentError[i];
        }else if (percentError[i] > max_percent_error)
        {
            max_percent_error = percentError[i];
        }
    }

    avg_percent_error = avg_percent_error/size;

    printf("Average percent error: \t\t\t\t%f%%\n", avg_percent_error * 100);
    printf("Minimum percent error: \t\t\t\t%f%%\n", min_percent_error * 100);
    printf("Maximum percent error: \t\t\t\t%f%%\n", max_percent_error * 100);

    printf("\n");

    // calculate speedup
    double transferTime = writeTime.elapsedTime() + readTime.elapsedTime();
    double hwTimeNoTransfer = hwTime.elapsedTime() - transferTime;
    printf("Speedup VS Software CORDIC: \t\t\t%f\n", swCordicTime.elapsedTime()/hwTime.elapsedTime());
    printf("Speedup VS Software CORDIC (no transfers): \t%f\n", swCordicTime.elapsedTime()/hwTimeNoTransfer);
    printf("Speedup VS Software ATAN: \t\t\t%f\n", swAtanTime.elapsedTime()/hwTime.elapsedTime());
    printf("Speedup VS Software ATAN (no transfers): \t%f\n", swAtanTime.elapsedTime()/hwTimeNoTransfer);
    printf("\n");

    // clean-up
    delete x_input;
    delete y_input;
    delete z_input;

    delete x_hwOutput;
    delete y_hwOutput;
    delete z_hwOutput;

    delete x_swOutput;
    delete y_swOutput;
    delete z_swOutput;

    delete atan_outputs;

    delete percentError;

    return 0;
}
