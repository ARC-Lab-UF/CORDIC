-- Greg Stitt
-- University of Florida

-- File: reg.vhd
-- Entity: reg
--
-- Description: This entity implements a register with generic width.
--

library ieee;
use ieee.std_logic_1164.all;

entity reg is
  generic (width :     positive  := 32);
  port(clk       : in  std_logic;
       rst       : in  std_logic;
       en        : in  std_logic;
       input     : in  std_logic_vector(width-1 downto 0);
       output    : out std_logic_vector(width-1 downto 0));
end reg;

architecture bhv of reg is
begin
  process(clk, rst)
  begin
    if rst = '1' then
      output   <= (others => '0');
    elsif (clk = '1' and clk'event) then
      if (en = '1') then
        output <= input;
      end if;
    end if;
  end process;
end bhv;