-- Greg Stitt
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package config_pkg is

    constant C_MMAP_ADDR_WIDTH  : positive := 18;
    constant C_MMAP_DATA_WIDTH  : positive := 32;
    constant C_NUM_CLKS         : natural := 4;

    subtype MMAP_ADDR_RANGE is natural range C_MMAP_ADDR_WIDTH-1    downto 0;
    subtype MMAP_DATA_RANGE is natural range C_MMAP_DATA_WIDTH-1    downto 0;

    subtype CLKS_RANGE      is natural range C_NUM_CLKS-1           downto 0;

end config_pkg;
