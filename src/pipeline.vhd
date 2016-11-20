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
	type array_type2 is array (0 to ROUNDS+1) of std_logic;
	signal X,Y,theta : array_type1;
	signal Xnext,Ynext,thetanext : array_type1;
	signal valid, modeBuff : array_type2;
	
begin	
	
	Xnext(0)			<= X_in;
	Ynext(0)			<= Y_in;
	thetanext(0)	<= theta_in;
	modeBuff(0)		<= mode;
	valid(0)			<= valid_in;
	
	G1: for I in 0 to ROUNDS generate
		X_I : process(clk, rst, Xnext)
		begin
			if (rising_edge(clk)) then
				X(I)	<= Xnext(I);
			end if;
		end process X_I;

		Y_I : process(clk, rst, Ynext)
		begin
			if (rising_edge(clk)) then
				Y(I)	<= Ynext(I);
			end if;
		end process Y_I;
		
		
		THETA_I : process(clk, rst, THETAnext)
		begin
			if (rising_edge(clk)) then
				THETA(I)	<= THETAnext(I);
			end if;
		end process THETA_I;
		
		VALID_I : process(clk, rst, valid)
		begin
			if (rising_edge(clk)) then
				if (rst = '1') then
					valid(I+1)	<= '0';
				else
					valid(I+1)	<= valid(I);
				end if;
			end if;
		end process VALID_I;

		G2: if I /= ROUNDS generate	
			MODE_I : process(clk, rst, valid)
			begin
				if (rising_edge(clk)) then
					modeBuff(I+1)	<= modeBuff(I);
				end if;
			end process MODE_I;
				
			CORE_I: entity work.cordic_core
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					mode		=> modeBuff(I+1),
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
	valid_out 	<= valid(ROUNDS+1);
	
end STR;