library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.math_real.all;
use IEEE.numeric_std.all;

---------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------
entity pipeline is
	GENERIC
	(
		WIDTH			: positive := 32;
		ROUNDS		: positive := 16
	);
	PORT
	(
		clk, rst		: in 	std_logic;
		mode			: in  std_logic;
		valid_in		: in	std_logic;
		X_in, Y_in	: in 	std_logic_vector(WIDTH-1 downto 0);
		theta_in		: in 	std_logic_vector(WIDTH-1 downto 0);
		valid_out	: out	std_logic;
		X_out, Y_out: out	std_logic_vector(WIDTH-1 downto 0);
		theta_out	: out	std_logic_vector(WIDTH-1 downto 0)
	);
end pipeline;

architecture STR of pipeline is
	---------------------------------------------------------------------------------------
	-- gen_theta_value(I	: NATURAL) return STD_LOGIC_VECTOR
	--		Function used to generate the round theta constants used in the CORDIC
	--		operations.
	--
	--		TODO: Right now the resolution is 1/256th of a degree. This should be
	--				adjustable.
	---------------------------------------------------------------------------------------
	function gen_theta_value(I : NATURAL) return std_logic_vector is
		variable arc_tan_rad, arc_tan_deg	: real;
		variable theta								: std_logic_vector(13 downto 0);
	begin
		arc_tan_rad :=	ARCTAN(REAL(2**REAL(-I))) * REAL(256);
		arc_tan_deg	:= ROUND(arc_tan_rad * MATH_RAD_TO_DEG);
		theta			:=	STD_LOGIC_VECTOR(TO_UNSIGNED(NATURAL(arc_tan_deg), 14));
		
		if (TO_INTEGER(UNSIGNED(theta)) <= 1) then
			return std_logic_vector(to_unsigned(NATURAL(1),14));
		else
			return theta;
		end if;
	end gen_theta_value;
	
	---------------------------------------------------------------------------------------
	-- Signals
	---------------------------------------------------------------------------------------
	type array_type1 is array (0 to ROUNDS) of std_logic_vector(WIDTH-1 downto 0);
	type array_type3 is array (0 to ROUNDS+1) of std_logic_vector(0 downto 0);
	signal X,Y,theta : array_type1;
	signal Xnext,Ynext,thetanext : array_type1;
	signal valid, modeBuff : array_type3;
	
begin	
	
	Xnext(0)			<= X_in;
	Ynext(0)			<= Y_in;
	thetanext(0)	<= theta_in;
	modeBuff(0)(0)	<= mode;
	valid(0)(0)		<= valid_in;
	
	G1: for I in 0 to ROUNDS generate
			X_I: entity work.gen_reg
			GENERIC MAP
			(
				WIDTH => WIDTH
			)
			PORT MAP
			(
				clk 		=> clk,
				rst		=> rst,
				input		=> Xnext(I),
				output	=> X(I)
			);
			
		Y_I: entity work.gen_reg
			GENERIC MAP
			(
				WIDTH => WIDTH
			)
			PORT MAP
			(
				clk 		=> clk,
				rst		=> rst,
				input		=> Ynext(I),
				output	=> Y(I)
			);
			
		THETA_I: entity work.gen_reg
			GENERIC MAP
			(
				WIDTH => WIDTH
			)
			PORT MAP
			(
				clk 		=> clk,
				rst		=> rst,
				input		=> thetanext(I),
				output	=> theta(I)
			);
			
		VALID_I: entity work.gen_reg
			GENERIC MAP
			(
				WIDTH => 1
			)
			PORT MAP
			(
				clk 		=> clk,
				rst		=> rst,
				input		=> valid(I),
				output	=> valid(I+1)
			);
		
		G2: if I /= ROUNDS generate
			MODE_I: entity work.gen_reg
				GENERIC MAP
				(
					WIDTH => 1
				)
				PORT MAP
				(
					clk 		=> clk,
					rst		=> rst,
					input		=> modeBuff(I),
					output	=> modeBuff(I+1)
				);
				
			CORE_I: entity work.cordic_core
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					mode		=> modeBuff(I+1)(0),
					Xin		=>	X(I),
					Yin		=> Y(I),
					thetain	=> theta(I),
					delta		=> gen_theta_value(I),
					Xout		=> Xnext(I+1),
					Yout		=> Ynext(I+1),
					thetaout => thetanext(I+1)
				);
		end generate G2;
	end generate G1;
	
	X_out 		<= X(ROUNDS);
	Y_out 		<= Y(ROUNDS);
	theta_out 	<= theta(ROUNDS);
	valid_out 	<= valid(ROUNDS+1)(0);
	
end STR;