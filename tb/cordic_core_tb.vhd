library IEEE;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity cordic_core_tb is
end cordic_core_tb;

architecture TB of cordic_core_tb is

	constant WIDTH		: positive := 32;

	signal done			: std_logic := '0';
	
	// UUT
	signal mode			: std_logic := '0';
	signal itr			: natural	:= 0;
	
	signal Xin, Yin	: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal Xouy, Yout	: std_logic_vector(WIDTH-1 downto 0);
			
	signal thetain		: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal thetaout	: std_logic_vector(WIDTH-1 downto 0);
				
	signal delta		: std_logic_vector(13 downto 0) := (others => '0');

begin
	UUT : work.entity cordic_core
		GENERIC MAP
		(
			WIDTH		=> WIDTH
		)
		PORT
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
			variable theta				: std_logic_vector(13 downto 0);
		begin
			arc_tan_rad 	:= ARCTAN(REAL(2**REAL(-I))) * REAL(256);
			arc_tan_deg 	:= ROUND(arc_tan_rad * MATH_RAD_TO_DEG);
			theta				:= STD_LOGIC_VECTOR(TO_UNSIGNED(NATURAL(arc_tan_deg), 14));
		
			if (TO_INTEGER(UNSIGNED(theta)) <= 1) then
				return to_integer(unsigned(std_logic_vector(to_unsigned(NATURAL(1),14))));
			else
				return to_integer(unsigned(theta));
			end if;
		end gen_theta_value;
		
	begin
		wait for 200ns; -- Just a pause at the start
	
		Xin <= std_logic_vector(to_unsigned(200, WIDTH));
		Yin <= std_logic_vector(to_unsigned(300, WIDTH));
		delta <= std_logic_vector(to_signed(gen_theta_value(0), 14);
	
		wait for 100 ns;
		
		wait; -- inf loop
	end process;
end TB;