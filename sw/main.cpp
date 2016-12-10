#ifdef IS_QT
    #include <QCoreApplication>
#endif

#include <iostream>
#include <cstdlib>
#include <cassert>
#include <cstring>
#include <cstdio>
#include <unistd.h>

#ifndef IS_QT
    #include <Board.h>
#endif
#include <Timer.h>

using namespace std;

// CONSTANTS
#define ADDR_WIDTH      12
#define MAX_SIZE        (1 << ADDR_WIDTH)

#define X_MEM__ADDR     0x0000
#define Y_MEM__ADDR     0x1000
#define Z_MEM__ADDR     0x2000

#ifndef IS_QT
    #define MODE_ADDR   ((1 << MMAP_ADDR_WIDTH)-4)
    #define GO_ADDR     ((1 << MMAP_ADDR_WIDTH)-3)
    #define SIZE_ADDR   ((1 << MMAP_ADDR_WIDTH)-2)
    #define DONE_ADDR   ((1 << MMAP_ADDR_WIDTH)-1)
#endif

int main(int argc, char *argv[])
{
    #ifdef IS_QT
        QCoreApplication a(argc, argv);
    #endif

    if (argc != 2) {
      cerr << "Usage: " << argv[0] << " bitfile" << endl;
      return -1;
    }

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

    unsigned size = 10;
    unsigned mode = 0;

    unsigned go, done;
    unsigned *x_input, *y_input, *z_input,
                *swOutput, *hwOutput;
    Timer swTime, hwTime, readTime, writeTime, waitTime;

    x_input     = new unsigned[size];
    y_input     = new unsigned[size];
    z_input     = new unsigned[size];

    hwOutput    = new unsigned[size];
    swOutput    = new unsigned[size];

    assert(x_input  != NULL);
    assert(y_input  != NULL);
    assert(z_input  != NULL);
    assert(swOutput != NULL);
    assert(hwOutput != NULL);

    // Initialize input array
    memset(x_input, 200, size);
    memset(y_input, 100, size);
    memset(z_input, 0, size);

    // Initialize output arrays
    memset(hwOutput, 0, size);
    memset(swOutput, 0, size);

    // transfer input array, size, and mode to FPGA
    hwTime.start();
    writeTime.start();
    #ifndef IS_QT
        board->write(x_input, X_MEM_IN_ADDR, size);
        board->write(y_input, Y_MEM_IN_ADDR, size);
        board->write(z_input, Z_MEM_IN_ADDR, size);
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
    while (!done) {
        #ifndef IS_QT
            board->read(&done, DONE_ADDR, 1);
        #endif
    }
    waitTime.stop();

    // read the outputs back from the FPGA
    readTime.start();
    #ifndef IS_QT
        board->read(hwOutput, Z_MEM_OUT_ADDR, size);
    #endif
    readTime.stop();
    hwTime.stop();

    printf("Results:\n");
    for (unsigned i=0; i < size; i++) {
      printf("%d: HW = %d\n", i, hwOutput[i]);
    }

    return 0;
}
