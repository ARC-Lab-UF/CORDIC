library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;


entity pipeline_tb is
end pipeline_tb;

architecture TB of pipeline_tb is
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
			variable theta				: std_logic_vector(WIDTH-1 downto 0);
		begin
			arc_tan_rad 	:= ARCTAN(REAL(2**REAL(-I))) * REAL(256);
			arc_tan_deg 	:= ROUND(arc_tan_rad * MATH_RAD_TO_DEG);
			theta				:= STD_LOGIC_VECTOR(TO_UNSIGNED(NATURAL(arc_tan_deg), WIDTH));
		
			return to_integer(unsigned(theta));

		end gen_theta_value;

		function check_coordic(Xin, Yin : integer) return std_logic_vector is
		variable X, Y, THETA : integer;
		
		variable shift_value	: REAL;
		variable shifted_X,
					shifted_Y		: INTEGER;
		begin
			X	:= Xin;
			Y	:= Yin;
			theta   := 0;
			for I in 0 to ROUNDS loop
				shift_value := 2**REAL(-I);
				shifted_X	:= integer(floor(real(X) * shift_value));
				shifted_Y 	:= integer(floor(real(Y) * shift_value));
				
				if Y >= 0 then
					X := X + shifted_Y;
					Y := Y - shifted_X;
					theta := theta + gen_theta_value(NATURAL(I));
				else
					X := X - shifted_Y;
					Y := Y + shifted_X;
					theta := theta - gen_theta_value(NATURAL(I));
				end if;
				
			end loop;
			
			return std_logic_vector(to_signed(theta, WIDTH));
		end check_coordic;
		
	begin
	
		valid_in <= '0';
		rst <= '1';
		
		wait for 200 ns;
		
		rst <= '0';
		
		wait until clk'event and clk = '1';
		wait until clk'event and clk = '1';

		for X in 200 to 200 loop
			for Y in 100 to 100 loop
			
			mode	<= '0';
			X_in	<= std_logic_vector(to_signed(X, WIDTH));
			Y_in	<= std_logic_vector(to_signed(Y,WIDTH));
			theta_in <= (others => '0');
			
			valid_in <= '1';
			wait until valid_out <= '1';
			assert(theta_out = check_coordic(X, Y)) report "Wrong value for x = " & integer'image(X) & " and y = " & integer'image(Y) & " Got " & integer'image(to_integer(unsigned(theta_out))) & " instead of " & integer'image(to_integer(unsigned(check_coordic(X, Y ))));	
			valid_in <= '0';		
			wait for 50 ns;
			end loop;
		end loop;
		
		done <= '1';
		wait;
	end process;
end TB;