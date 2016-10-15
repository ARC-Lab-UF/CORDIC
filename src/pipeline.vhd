library IEEE;
use IEEE.std_logic_1164.all;
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
		Xin, Yin		: in 	std_logic_vector(WIDTH-1 downto 0);
		thetain		: in 	std_logic_vector(WIDTH-1 downto 0);
		Xout, Yout	: out	std_logic_vector(WIDTH-1 downto 0);
		thetaout		: out	std_logic_vector(WIDTH-1 downto 0)
	);
end pipeline;

architecture STR of pipeline is
	type array_type1 is array (0 to ROUNDS) of std_logic_vector(WIDTH-1 downto 0);
	type array_type2 is array (0 to ROUNDS) of std_logic_vector(0 downto 0);
	signal X,Y,theta : array_type1;
	signal Xnext,Ynext,thetanext : array_type1;
	signal modeBuff : array_type2;
begin	
	G1: for I in 0 to ROUNDS-1 generate
		-- Generate CORE for the first round
		
		G2: if (I = 0) generate
			XR0: entity work.gen_reg
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					clk 		=> clk,
					rst		=> rst,
					input		=> Xin,
					output	=> X(I)
				);
				
			YR0: entity work.gen_reg
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					clk 		=> clk,
					rst		=> rst,
					input		=> Yin,
					output	=> Y(I)
				);
				
			TR0: entity work.gen_reg
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					clk 		=> clk,
					rst		=> rst,
					input		=> thetain,
					output	=> theta(I)
				);
		
			MR0: entity work.gen_reg
				GENERIC MAP
				(
					WIDTH => 1
				)
				PORT MAP
				(
					clk 		=> clk,
					rst		=> rst,
					input		=> (0 => mode),
					output	=> modeBuff(I)
				);
				
			CORE_1: entity work.cordic_core
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					mode		=> modeBuff(I)(0),
					Xin		=>	X(I),
					Yin		=> Y(I),
					thetain	=> theta(I),
					delta		=> (others => '0'),
					Xout		=> Xnext(I),
					Yout		=> Ynext(I),
					thetaout => thetanext(I)
				);
				
			XR1: entity work.gen_reg
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					clk 		=> clk,
					rst		=> rst,
					input		=> Xnext(I),
					output	=> X(I+1)
				);
				
			YR1: entity work.gen_reg
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					clk 		=> clk,
					rst		=> rst,
					input		=> Ynext(I),
					output	=> Y(I+1)
				);
				
			TR1: entity work.gen_reg
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					clk 		=> clk,
					rst		=> rst,
					input		=> thetanext(I),
					output	=> theta(I+1)
				);
				
			MR1: entity work.gen_reg
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
		end generate G2;
		
		-- Generate CORE for all the rounds in between
		G3: if (I /= 0) generate
			CORE_I: entity work.cordic_core
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					mode		=> modeBuff(I)(0),
					Xin		=>	X(I),
					Yin		=> Y(I),
					thetain	=> theta(I),
					delta		=> (others => '0'),
					Xout		=> Xnext(I),
					Yout		=> Ynext(I),
					thetaout => thetanext(I)
				);
				
			XRI: entity work.gen_reg
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					clk 		=> clk,
					rst		=> rst,
					input		=> Xnext(I),
					output	=> X(I+1)
				);
				
			YRI: entity work.gen_reg
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					clk 		=> clk,
					rst		=> rst,
					input		=> Ynext(I),
					output	=> Y(I+1)
				);
				
			TRI: entity work.gen_reg
				GENERIC MAP
				(
					WIDTH => WIDTH
				)
				PORT MAP
				(
					clk 		=> clk,
					rst		=> rst,
					input		=> thetanext(I),
					output	=> theta(I+1)
				);
			
			G4: if I /= ROUNDS-1 generate
				MRI: entity work.gen_reg
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
				end generate G4;
			end generate G3;
	end generate G1;
	
	Xout <= X(ROUNDS);
	Yout <= Y(ROUNDS);
	thetaout <= theta(ROUNDS);
	
end STR;