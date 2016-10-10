library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

---------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------
entity pipeline is
	GENERIC
	(
		WIDTH		: positive := 32;
		ROUNDS	: positive := 16;
	);
	PORT
	(
		mode		: in  std_logic
	);
end pipeline;