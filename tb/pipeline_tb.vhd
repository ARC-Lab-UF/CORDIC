library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;


entity tb is
end tb;

architecture my_TB of tb is
		signal done : std_logic := '0';

		constant WIDTH  : positive := 32;
		constant ROUNDS : positive := 16;

		signal clk, rst		: std_logic := '0';
		signal mode		: std_logic := '0';
		signal valid_in		: std_logic := '0';
		signal X_in, Y_in	: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
		signal theta_in		: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
		signal valid_out	: std_logic;
		signal X_out, Y_out	: std_logic_vector(WIDTH-1 downto 0);
		signal theta_out	: std_logic_vector(WIDTH-1 downto 0);

		signal k   : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
		signal l   : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

begin
	UUT : entity work.pipeline
	GENERIC MAP
	(
		WIDTH		=> WIDTH,
		ROUNDS		=> ROUNDS
	)
	PORT MAP
	(
		clk			=> clk,
		rst			=> rst,
		mode			=> mode,
		valid_in		=> valid_in,
		X_in			=> X_in,
		Y_in			=> Y_in,
		theta_in		=> theta_in,
		valid_out		=> valid_out,
		X_out			=> X_out,
		Y_out			=> Y_out,
		theta_out		=> theta_out
	);

	clk <= not clk after 10 ns when done = '0' else '0';

	process

		function gen_theta_value(I : NATURAL) return integer is
			variable arc_tan_rad, arc_tan_deg	: real;
			variable theta				: std_logic_vector(13 downto 0);
		begin
			arc_tan_rad 	:= ARCTAN(REAL(2**REAL(-I))) * REAL(256);
			arc_tan_deg 	:= ROUND(arc_tan_rad * MATH_RAD_TO_DEG);
			theta		:= STD_LOGIC_VECTOR(TO_UNSIGNED(NATURAL(arc_tan_deg), 14));
		
			if (TO_INTEGER(UNSIGNED(theta)) <= 1) then
				return to_integer(unsigned(std_logic_vector(to_unsigned(NATURAL(1),14))));
			else
				return to_integer(unsigned(theta));
			end if;
		end gen_theta_value;

		function check_coordic(X_in, Y_in : integer) return std_logic_vector is
		variable x,y,theta : integer;
		begin
			x	:= X_in;
			y	:= Y_in;
			theta   := 0;
			for i in 0 to ROUNDS loop
				if Y >= 0 then
					x := INTEGER(REAL(x) + REAL(y)*(2**REAL(-i)));
					y := INTEGER(REAL(y) - REAL(x)*(2**REAL(-i)));
					theta := theta + gen_theta_value(NATURAL(i));
				else
					x := INTEGER(REAL(x) - REAL(y)*(2**REAL(-i)));
					y := INTEGER(REAL(y) + REAL(x)*(2**REAL(-i)));
					theta := theta - gen_theta_value(NATURAL(i));
				end if;
			end loop;
			return std_logic_vector(to_unsigned(theta,WIDTH-1));
		end check_coordic;
	begin
		valid_in <= '0';
		rst <= '1';
		wait for 200 ns;
		rst <= '0';
		wait until clk'event and clk = '1';
		wait until clk'event and clk = '1';

		for i in 0 to 1 loop
			for j in 0 to 360 loop
			k <= std_logic_vector(to_unsigned(i,WIDTH));
			l <= std_logic_vector(to_unsigned(j,WIDTH));
			mode	<= '0';
			X_in	<= k;
			Y_in	<= l;
			theta_in <= (others => '0');
			valid_in <= '1';
			wait until valid_out <= '1';
			assert(theta_out = check_coordic(i, j)) report "Wrong value for x = " & integer'image(i) & " and y = " & integer'image(j) & " Got " & integer'image(to_integer(unsigned(theta_out))) & " instead of " & integer'image(to_integer(unsigned(check_coordic(i, j ))));	
			valid_in <= '0';		
			wait for 50 ns;
			end loop;
		end loop;
		done <= '1';
		wait;
	end process;
end my_TB;