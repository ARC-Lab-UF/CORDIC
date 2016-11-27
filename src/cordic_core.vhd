library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

---------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------
entity cordic_core is
	GENERIC
	(
		WIDTH		: positive := 32
	);
	PORT
	(
		mode		: in  std_logic;
		itr		: in	natural;
		
		Xin		: in  std_logic_vector(WIDTH-1 downto 0);
		Yin		: in  std_logic_vector(WIDTH-1 downto 0);
		thetain	: in  std_logic_vector(WIDTH-1 downto 0);
		
		delta		: in 	std_logic_vector(WIDTH-1 downto 0);
		
		Xout		: out std_logic_vector(WIDTH-1 downto 0);
		Yout		: out std_logic_vector(WIDTH-1 downto 0);
		thetaout : out std_logic_vector(WIDTH-1 downto 0)
	);
end cordic_core;

architecture BHV of cordic_core is
	 ---------------------------------------------------------------------------------------
	 -- Constants
	 ---------------------------------------------------------------------------------------
	 constant MODE_NORMAL_VECTORING	: std_logic := '0';
	 constant MODE_NORMAL_ROTATION	: std_logic	:= '1';

	 
	 ---------------------------------------------------------------------------------------
	 -- Signals
	 ---------------------------------------------------------------------------------------
	signal dir	: boolean;
	
begin
	
	DIR_PROC :	process(mode, Yin, thetain)
	begin
		-- dir will default false
		dir <= false;
		
		case mode is
			when MODE_NORMAL_VECTORING =>
				dir <= (signed(Yin) < 0);
				
			when MODE_NORMAL_ROTATION =>
				dir <= (signed(thetain) >= 0);
				
			when OTHERS =>
				NULL;
		end case;
	end process;
	
	ROT_PROC :	process(dir, itr, Xin, Yin, thetaIn, delta)
	begin
		case dir is
			when true	=>
				Xout 		<= std_logic_vector(signed(Xin) - shift_right(signed(Yin), itr));
				Yout 		<= std_logic_vector(signed(Yin) + shift_right(signed(Xin), itr));
				thetaOut <= std_logic_vector(signed(thetaIn) - signed(delta));
				
			when false	=>
				Xout 		<= std_logic_vector(signed(Xin) + shift_right(signed(Yin), itr));
				Yout 		<= std_logic_vector(signed(Yin) - shift_right(signed(Xin), itr));
				thetaOut <= std_logic_vector(signed(thetaIn) + signed(delta));
					
			when OTHERS =>
				NULL;
		end case;
	end process;
 
 end BHV;