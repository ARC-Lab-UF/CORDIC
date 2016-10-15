library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

---------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------
entity gen_reg is
	GENERIC
	(
		WIDTH			: positive := 32
	);
	PORT
	(
		clk, rst	: in 	std_logic;
		input		: in 	std_logic_vector(WIDTH-1 downto 0);
		output	: out	std_logic_vector(WIDTH-1 downto 0)
	);
end gen_reg;

architecture BHV of gen_reg is
begin
	process(clk, rst)
	begin
		if rst = '1' then
			output <= (others => '0');
		elsif rising_edge(clk) then
			output <= input;
		end if;
	end process;
end BHV;