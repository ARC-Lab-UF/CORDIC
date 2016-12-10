-- Greg Stitt
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_pkg.all;

package user_pkg is

    constant C_MEM_ADDR_WIDTH       : positive := 12;
    constant C_MEM_IN_WIDTH         : positive := 32;
    constant C_MEM_OUT_WIDTH        : positive := 32;

    constant C_FIFO_WIDTH           : positive := 96;

    constant C_CORDIC_WIDTH         : positive := 32;
    constant C_CORDIC_ROUNDS        : positive := 16;
    constant C_CORDIC_MODE_WIDTH    : positive := 3;

    constant C_X_MEM_START_ADDR     : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned((2**C_MEM_ADDR_WIDTH) * 0, C_MMAP_ADDR_WIDTH));
    constant C_X_MEM_END_ADDR       : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(unsigned(C_X_MEM_START_ADDR)+(2**C_MEM_ADDR_WIDTH-1));
    subtype  X_SLICE is natural range C_FIFO_WIDTH-1 downto 2*(C_FIFO_WIDTH/3);

    constant C_Y_MEM_START_ADDR     : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned((2**C_MEM_ADDR_WIDTH) * 1, C_MMAP_ADDR_WIDTH));
    constant C_Y_MEM_END_ADDR       : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(unsigned(C_Y_MEM_START_ADDR)+(2**C_MEM_ADDR_WIDTH-1));
    subtype  Y_SLICE is natural range 2*(C_FIFO_WIDTH/3)-1 downto C_FIFO_WIDTH/3;

    constant C_Z_MEM_START_ADDR     : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned((2**C_MEM_ADDR_WIDTH) * 2, C_MMAP_ADDR_WIDTH));
    constant C_Z_MEM_END_ADDR       : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(unsigned(C_Z_MEM_START_ADDR)+(2**C_MEM_ADDR_WIDTH-1));
    subtype  Z_SLICE is natural range C_FIFO_WIDTH/3-1 downto 0;

    constant C_GO_ADDR              : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-3, C_MMAP_ADDR_WIDTH));
    constant C_SIZE_ADDR            : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-2, C_MMAP_ADDR_WIDTH));
    constant C_DONE_ADDR            : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-1, C_MMAP_ADDR_WIDTH));

    constant C_MODE_ADDR            : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-4, C_MMAP_ADDR_WIDTH));

    constant C_1                    : std_logic := '1';
    constant C_0                    : std_logic := '0';

end user_pkg;
