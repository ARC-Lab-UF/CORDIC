library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

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
		
	begin
		wait for 200 ns; -- Just a pause at the start
	
		Xin <= std_logic_vector(to_signed(300, WIDTH));
		Yin <= std_logic_vector(to_signed(-100, WIDTH));
		thetain <= std_logic_vector(to_signed(11520, WIDTH));
		delta <= std_logic_vector(to_signed(gen_theta_value(1), WIDTH));
	
		wait for 100 ns;
		
		wait; -- inf loop
	end process;
end TB;