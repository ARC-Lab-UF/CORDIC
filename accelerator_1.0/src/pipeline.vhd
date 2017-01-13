library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.math_real.all;
use IEEE.numeric_std.all;

use work.user_pkg.all;

---------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------
entity pipeline is
    GENERIC
    (
        WIDTH           : positive := C_CORDIC_WIDTH;
        ROUNDS          : positive := C_CORDIC_ROUNDS
    );
    PORT
    (
        clk, rst        : in    std_logic;
        mode            : in    std_logic_vector(2 downto 0);
        valid_in        : in    std_logic;
        X_in, Y_in      : in    std_logic_vector(WIDTH-1 downto 0);
        theta_in        : in    std_logic_vector(WIDTH-1 downto 0);
        valid_out       : out   std_logic;
        X_out, Y_out    : out   std_logic_vector(WIDTH-1 downto 0);
        theta_out       : out   std_logic_vector(WIDTH-1 downto 0)
    );
end pipeline;

architecture STR of pipeline is
    ---------------------------------------------------------------------------------------
    -- Constants
    ---------------------------------------------------------------------------------------
    constant COORD_SYS_CIRCULAR         : std_logic_vector(1 downto 0)  := "01";
    constant COORD_SYS_LINEAR           : std_logic_vector(1 downto 0)  := "00";
    constant COORD_SYS_HYPERBOLIC       : std_logic_vector(1 downto 0)  := "11";

    ---------------------------------------------------------------------------------------
    -- gen_alpha_value(I    : NATURAL) return STD_LOGIC_VECTOR
    --      Function used to generate the round alpha constants used in the CORDIC
    --      operations.
    --
    --      TODO: Right now the resolution is 1/256th of a degree. This should be
    --              adjustable.
    ---------------------------------------------------------------------------------------
    function gen_alpha_value(I : NATURAL) return std_logic_vector is
        variable arc_tan_rad, arc_tan_deg   : real;
        variable alpha                      : std_logic_vector(WIDTH-1 downto 0);
    begin
        arc_tan_rad :=  ARCTAN(REAL(2**REAL(-I))) * REAL(256);
        arc_tan_deg	:= ROUND(arc_tan_rad * MATH_RAD_TO_DEG);
        alpha           :=  STD_LOGIC_VECTOR(TO_UNSIGNED(NATURAL(arc_tan_deg), WIDTH));

        return alpha;

    end gen_alpha_value;

    ---------------------------------------------------------------------------------------
    -- Signals
    ---------------------------------------------------------------------------------------
    type array_type1 is array (0 to ROUNDS) of std_logic_vector(WIDTH-1 downto 0);
    type array_type2 is array (0 to ROUNDS+1) of std_logic;
    type array_type3 is array (0 to ROUNDS+1) of std_logic_vector(2 downto 0);
    type array_type4 is array (0 to ROUNDS-1) of natural;
    signal X,Y,Z                    : array_type1;
    signal Xnext,Ynext,Znext        : array_type1;
    signal valid                    : array_type2;
    signal modeBuff                 : array_type3;
    
    signal ITR : array_type4;

begin

    Xnext(0)        <= X_in;
    Ynext(0)        <= Y_in;
    Znext(0)        <= theta_in;
    modeBuff(0)     <= mode;
    valid(0)        <= valid_in;

    G1: for I in 0 to ROUNDS generate
        X_I : process(clk, rst, Xnext)
        begin
        if (rising_edge(clk)) then
        X(I)    <= Xnext(I);
            end if;
        end process X_I;

        Y_I : process(clk, rst, Ynext)
        begin
        if (rising_edge(clk)) then
        Y(I)    <= Ynext(I);
            end if;
        end process Y_I;

        Z_I : process(clk, rst, Znext)
        begin
            if (rising_edge(clk)) then
                Z(I)    <= Znext(I);
            end if;
        end process Z_I;

        VALID_I : process(clk, rst, valid)
        begin
            if (rst = '1') then
                valid(I+1)	<= '0';
            elsif (rising_edge(clk)) then
                valid(I+1)	<= valid(I);
            end if;
        end process VALID_I;

        G2: if I /= ROUNDS generate	
            MODE_I : process(clk, rst, valid)
            begin
                if (rising_edge(clk)) then
                    modeBuff(I+1)   <= modeBuff(I);
                end if;
            end process MODE_I;

        ITR_MUX: process(modeBuff(I+1)(2 downto 1))
            begin
                case modeBuff(I+1)(2 downto 1) is
                    when COORD_SYS_CIRCULAR =>
                        ITR(I) <= I;

                    when COORD_SYS_LINEAR =>
                        ITR(I) <= I + 1;

                    when COORD_SYS_HYPERBOLIC =>
                        ITR(I) <= I;

                    when OTHERS =>
                        ITR(I) <= I;
                end case;
            end process ITR_MUX;

        CORE_I: entity work.cordic_core
            GENERIC MAP
                (
                    WIDTH => WIDTH
                )
                PORT MAP
                (
                    mode        => modeBuff(I+1),
                    itr         => ITR(I),
                    Xin         => X(I),
                    Yin         => Y(I),
                    Zin         => Z(I),
                    alpha       => gen_alpha_value(I),
                    Xout        => Xnext(I+1),
                    Yout        => Ynext(I+1),
                    Zout        => Znext(I+1)
                );
        end generate G2;
    end generate G1;

    X_out       <= X(ROUNDS);
    Y_out       <= Y(ROUNDS);
    theta_out   <= Z(ROUNDS);
    valid_out   <= valid(ROUNDS+1);

end STR;