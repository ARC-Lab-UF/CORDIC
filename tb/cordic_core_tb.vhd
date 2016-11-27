library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity cordic_core_tb is
end cordic_core_tb;

architecture TB of cordic_core_tb is

	constant WIDTH		: positive := 32;

	signal done			: std_logic := '0';
	
	-- UUT
	signal mode			: std_logic := '0';
	signal itr			: natural	:= 0;
	
	signal Xin, Yin	: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal Xout, Yout	: std_logic_vector(WIDTH-1 downto 0);
			
	signal thetain		: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal thetaout	: std_logic_vector(WIDTH-1 downto 0);
				
	signal delta		: std_logic_vector(WIDTH-1 downto 0) := (others => '0');

begin
	UUT : entity work.cordic_core
		GENERIC MAP
		(
			WIDTH		=> WIDTH
		)
		PORT MAP
		(
			mode		=> mode,
			itr		=> itr,
			
			Xin		=> Xin,
			Yin		=> Yin,
			thetain	=> thetain,
			
			delta		=> delta,
			
			Xout		=> Xout,
			Yout		=> Yout,
			thetaout => thetaout
		);
	
	process
		---------------------------------------------------------------------------------------
		-- gen_theta_value is used to generate the fixed point theta value for a given iteration
		--	 of the CORDIC algorithm.
		---------------------------------------------------------------------------------------
		function gen_theta_value(I : NATURAL) return integer is
			variable arc_tan_rad,
							arc_tan_deg	: real;
			variable theta				: std_logic_vector(WIDTH-1 downto 0);
		begin
			arc_tan_rad 	:= ARCTAN(REAL(2**REAL(-I))) * REAL(256);
			arc_tan_deg 	:= ROUND(arc_tan_rad * MATH_RAD_TO_DEG);
			theta				:= STD_LOGIC_VECTOR(TO_UNSIGNED(NATURAL(arc_tan_deg), WIDTH));
		
			if (TO_INTEGER(UNSIGNED(theta)) <= 1) then
				return to_integer(unsigned(std_logic_vector(to_unsigned(NATURAL(1),WIDTH))));
			else
				return to_integer(unsigned(theta));
			end if;
		end gen_theta_value;
		
		-- TB Signals
		variable shift_value : real;
		variable shifted_X,
					shifted_Y	: integer;
		variable Xout_ex,
					Yout_ex,
					theta_ex		: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	begin
	
		wait for 10 ns; -- Just a pause at the start
		
		itr_loop : for I in 0 to 50 loop
			x_loop : for X in 0 to 50 loop
				y_loop : for Y in -50 to 50 loop
					theta_loop : for THETA in 0 to 50 loop
						delta_loop : for DELTAA in 0 to 50 loop
							-- Set the values to input into CORDIC core
							itr 		<= i;
							Xin 		<= std_logic_vector(to_signed(X, WIDTH));
							Yin 		<= std_logic_vector(to_signed(Y, WIDTH));
							thetain 	<= std_logic_vector(to_signed(THETA, WIDTH));
							delta		<= std_logic_vector(to_signed(DELTAA, WIDTH));
					
							mode <= '0';
							wait for 1 ns; -- wait for output
							
							-- Check the outputs
							shift_value := 2**REAL(-I);
							
							shifted_X	:= integer(floor(real(to_integer(signed(Xin))) * shift_value));
							shifted_Y 	:= integer(floor(real(to_integer(signed(Yin))) * shift_value));
							
							
							if (signed(Yin) >= 0) then
								Xout_ex 		:= std_logic_vector(signed(Xin) + to_signed(shifted_Y, WIDTH));
								Yout_ex 		:= std_logic_vector(signed(Yin) - to_signed(shifted_X, WIDTH));
								theta_ex		:= std_logic_vector(signed(thetain) + signed(delta));
								
								assert (Xout = Xout_ex)
									report 	"!!! Xout was incorrect !!!" & CR &
												"Mode = 0" 		& CR &
												"Y Positive"	& CR &
												"ITR = " 		& integer'image(I) & CR &
												"Xin = " 		& integer'image(to_integer(signed(Xin))) & CR &
												"Yin = " 		& integer'image(to_integer(signed(Yin))) & CR &
												CR & -- Add a little space
												"Xout = "		& integer'image(to_integer(signed(Xout))) & CR &
												"Xout_ex = " 	& integer'image(to_integer(signed(Xout_ex)));
												
								assert (Yout = Yout_ex)
									report 	"!!! Yout was incorrect !!!" & CR &
												"Mode = 0" 		& CR &
												"Y Positive"	& CR &
												"ITR = " 		& integer'image(I) & CR &
												"Xin = " 		& integer'image(to_integer(signed(Xin))) & CR &
												"Yin = " 		& integer'image(to_integer(signed(Yin))) & CR &
												CR & -- Add a little space
												"Yout = "		& integer'image(to_integer(signed(Yout))) & CR &
												"Yout_ex = " 	& integer'image(to_integer(signed(Yout_ex)));
												
								assert (thetaout = theta_ex)
									report 	"!!! thetaout was incorrect !!!" & CR &
												"Mode = 0" 		& CR &
												"Y Positive"	& CR &
												"thetain = " 	& integer'image(to_integer(signed(thetain))) & CR &
												"delta = " 		& integer'image(to_integer(signed(delta))) & CR &
												CR & -- Add a little space
												"thetaout = "	& integer'image(to_integer(signed(thetaout))) & CR &
												"theta_ex = " 	& integer'image(to_integer(signed(theta_ex)));
							else
								Xout_ex 		:= std_logic_vector(signed(Xin) - to_signed(shifted_Y, WIDTH));
								Yout_ex 		:= std_logic_vector(signed(Yin) + to_signed(shifted_X, WIDTH));
								theta_ex		:= std_logic_vector(signed(thetain) - signed(delta));
								
								assert (Xout = Xout_ex)
									report 	"!!! Xout was incorrect !!!" & CR &
												"Mode = 0" 		& CR &
												"Y Negative"	& CR &
												"ITR = " 		& integer'image(I) & CR &
												"Xin = " 		& integer'image(to_integer(signed(Xin))) & CR &
												"Yin = " 		& integer'image(to_integer(signed(Yin))) & CR &
												CR & -- Add a little space
												"Xout = "		& integer'image(to_integer(signed(Xout))) & CR &
												"Xout_ex = " 	& integer'image(to_integer(signed(Xout_ex)));
												
								assert (Yout = Yout_ex)
									report 	"!!! Yout was incorrect !!!" & CR &
												"Mode = 0" 		& CR &
												"Y Negative"	& CR &
												"ITR = " 		& integer'image(I) & CR &
												"Xin = " 		& integer'image(to_integer(signed(Xin))) & CR &
												"Yin = " 		& integer'image(to_integer(signed(Yin))) & CR &
												CR & -- Add a little space
												"Yout = "		& integer'image(to_integer(signed(Yout))) & CR &
												"Yout_ex = " 	& integer'image(to_integer(signed(Yout_ex)));
												
								assert (thetaout = theta_ex)
									report 	"!!! thetaout was incorrect !!!" & CR &
												"Mode = 0" 		& CR &
												"Y Negative"	& CR &
												"thetain = " 	& integer'image(to_integer(signed(thetain))) & CR &
												"delta = " 		& integer'image(to_integer(signed(delta))) & CR &
												CR & -- Add a little space
												"thetaout = "	& integer'image(to_integer(signed(thetaout))) & CR &
												"theta_ex = " 	& integer'image(to_integer(signed(theta_ex)));
							end if;
							
							wait for 1 ns; -- wait a little longer
							
							-- Change modes
							mode <= '1';
							wait for 1 ns;
							
							if (signed(thetain) >= 0) then
								Xout_ex 		:= std_logic_vector(signed(Xin) - to_signed(shifted_Y, WIDTH));
								Yout_ex 		:= std_logic_vector(signed(Yin) + to_signed(shifted_X, WIDTH));
								theta_ex		:= std_logic_vector(signed(thetain) - signed(delta));
								
								assert (Xout = Xout_ex)
									report 	"!!! Xout was incorrect !!!" & CR &
												"Mode = 1" 		& CR &
												"Theta Pos." 	& CR &
												"ITR = " 		& integer'image(I) & CR &
												"Xin = " 		& integer'image(to_integer(signed(Xin))) & CR &
												"Yin = " 		& integer'image(to_integer(signed(Yin))) & CR &
												CR & -- Add a little space
												"Xout = "		& integer'image(to_integer(signed(Xout))) & CR &
												"Xout_ex = " 	& integer'image(to_integer(signed(Xout_ex)));
												
								assert (Yout = Yout_ex)
									report 	"!!! Yout was incorrect !!!" & CR &
												"Mode = 1" 		& CR &
												"Theta Pos." 	& CR &
												"ITR = " 		& integer'image(I) & CR &
												"Xin = " 		& integer'image(to_integer(signed(Xin))) & CR &
												"Yin = " 		& integer'image(to_integer(signed(Yin))) & CR &
												CR & -- Add a little space
												"Yout = "		& integer'image(to_integer(signed(Yout))) & CR &
												"Yout_ex = " 	& integer'image(to_integer(signed(Yout_ex)));
												
								assert (thetaout = theta_ex)
									report 	"!!! thetaout was incorrect !!!" & CR &
												"Mode = 1" 		& CR &
												"Theta Pos."	& CR &
												"thetain = " 	& integer'image(to_integer(signed(thetain))) & CR &
												"delta = " 		& integer'image(to_integer(signed(delta))) & CR &
												CR & -- Add a little space
												"thetaout = "	& integer'image(to_integer(signed(thetaout))) & CR &
												"theta_ex = " 	& integer'image(to_integer(signed(theta_ex)));
							else
								Xout_ex 		:= std_logic_vector(signed(Xin) + to_signed(shifted_Y, WIDTH));
								Yout_ex 		:= std_logic_vector(signed(Yin) - to_signed(shifted_X, WIDTH));
								theta_ex		:= std_logic_vector(signed(thetain) + signed(delta));
								
								assert (Xout = Xout_ex)
									report 	"!!! Xout was incorrect !!!" & CR &
												"Mode = 0" 		& CR &
												"Theta Neg." 	& CR &
												"ITR = " 		& integer'image(I) & CR &
												"Xin = " 		& integer'image(to_integer(signed(Xin))) & CR &
												"Yin = " 		& integer'image(to_integer(signed(Yin))) & CR &
												CR & -- Add a little space
												"Xout = "		& integer'image(to_integer(signed(Xout))) & CR &
												"Xout_ex = " 	& integer'image(to_integer(signed(Xout_ex)));
												
								assert (Yout = Yout_ex)
									report 	"!!! Yout was incorrect !!!" & CR &
												"Mode = 0" 		& CR &
												"Theta Neg." 	& CR &
												"ITR = " 		& integer'image(I) & CR &
												"Xin = " 		& integer'image(to_integer(signed(Xin))) & CR &
												"Yin = " 		& integer'image(to_integer(signed(Yin))) & CR &
												CR & -- Add a little space
												"Yout = "		& integer'image(to_integer(signed(Yout))) & CR &
												"Yout_ex = " 	& integer'image(to_integer(signed(Yout_ex)));
												
								assert (thetaout = theta_ex)
									report 	"!!! thetaout was incorrect !!!" & CR &
												"Mode = 1" 		& CR &
												"Theta Neg."	& CR &
												"thetain = " 	& integer'image(to_integer(signed(thetain))) & CR &
												"delta = " 		& integer'image(to_integer(signed(delta))) & CR &
												CR & -- Add a little space
												"thetaout = "	& integer'image(to_integer(signed(thetaout))) & CR &
												"theta_ex = " 	& integer'image(to_integer(signed(theta_ex)));
							end if;
						end loop;
					end loop;
				end loop;
			end loop;
		end loop;
		
		wait; -- inf loop
	end process;
end TB;