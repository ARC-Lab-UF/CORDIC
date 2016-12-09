library ieee;
use ieee.std_logic_1164.all;

use work.user_pkg.all;

entity fifo_out is
    port (
        clk_src  : in  std_logic;
        clk_dest : in  std_logic;
        rst      : in  std_logic;
        empty    : out std_logic;
        full     : out std_logic;
        rd       : in  std_logic;
        wr       : in  std_logic;
        data_in  : in  std_logic_vector(C_MEM_OUT_WIDTH-1 downto 0);
        data_out : out std_logic_vector(C_MEM_OUT_WIDTH-1 downto 0));
end fifo_out;

architecture STR of fifo_out is

--    component fifo_generator_1 is
--        Port ( 
--            rst : in STD_LOGIC;
--            wr_clk : in STD_LOGIC;
--            rd_clk : in STD_LOGIC;
--            din : in STD_LOGIC_VECTOR ( C_MEM_OUT_WIDTH-1 downto 0 );
--            wr_en : in STD_LOGIC;
--            rd_en : in STD_LOGIC;
--            dout : out STD_LOGIC_VECTOR ( C_MEM_OUT_WIDTH-1 downto 0 );
--            full : out STD_LOGIC;
--            empty : out STD_LOGIC
--      );
--     end component;
--  
begin  -- STR
--
--    U_FIFO_out : fifo_generator_1
--        PORT MAP
--        ( 
--            rst     => rst,
--            wr_clk  => clk_src,
--            rd_clk  => clk_dest,
--            din     => data_in,
--            wr_en   => wr,
--            rd_en   => rd,
--            dout    => data_out,
--            full    => full,
--            empty   => empty
--      ); 

end STR;
