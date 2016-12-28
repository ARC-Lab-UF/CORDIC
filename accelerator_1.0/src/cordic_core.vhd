library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.user_pkg.all;

---------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------
entity cordic_core is
    GENERIC
    (
        WIDTH       : positive := C_CORDIC_WIDTH
    );
    PORT
    (
        mode        : in    std_logic_vector(2 downto 0);
        itr         : in    natural;

        Xin         : in    std_logic_vector(WIDTH-1 downto 0);
        Yin         : in    std_logic_vector(WIDTH-1 downto 0);
        zin         : in    std_logic_vector(WIDTH-1 downto 0);

        alpha       : in    std_logic_vector(WIDTH-1 downto 0);

        Xout        : out   std_logic_vector(WIDTH-1 downto 0);
        Yout        : out   std_logic_vector(WIDTH-1 downto 0);
        zout        : out   std_logic_vector(WIDTH-1 downto 0)
    );
end cordic_core;

architecture STR of cordic_core is
    ---------------------------------------------------------------------------------------
    -- Constants
    ---------------------------------------------------------------------------------------
    constant COORD_SYS_CIRCULAR         : std_logic_vector(1 downto 0)  := "01";
    constant COORD_SYS_LINEAR           : std_logic_vector(1 downto 0)  := "00";
    constant COORD_SYS_HYPERBOLIC       : std_logic_vector(1 downto 0)  := "11";

    constant MODE_VECTORING             : std_logic                     := '0';
    constant MODE_ROTATION              : std_logic                     := '1';

    ---------------------------------------------------------------------------------------
    -- Signals
    ---------------------------------------------------------------------------------------
    alias coor_system_a                 : std_logic_vector(1 downto 0) is mode(2 downto 1);
    alias mode_a                        : std_logic is mode(0);
    
    signal dir                          : boolean;
    
    signal sigma, x_sigma               : std_logic;
    signal x_addr_out                   : std_logic_vector(WIDTH-1 downto 0);

begin
    ---------------------------------------------------------------------------------------
    -- Handling the Y and Z inputs is simple, since they function the same regardless of the
    --  coordinate system. Sigma determines the sign of the add_sub.
    ---------------------------------------------------------------------------------------
    -- Yout = Yin + (sigma * Xin * 2^(-i))
    Y_ADDR  :   entity work.add_sub
        GENERIC MAP
        (
            WIDTH       => WIDTH
        )
        PORT MAP
        (
            input_a     => Yin,
            input_b     => std_logic_vector(shift_right(signed(Xin), itr)),
            add_nsub    => sigma,
            output      => Yout
        );

    -- Zout = Zin - (sigma * alpha)
    Z_ADDR  :   entity work.add_sub
        GENERIC MAP
        (
            WIDTH       => WIDTH
        )
        PORT MAP
        (
            input_a     => Zin,
            input_b     => alpha,
            add_nsub    => not(sigma),
            output      => Zout
        );

    ---------------------------------------------------------------------------------------
    -- X is a little more complicated, since the output for X is dependant on the coordinate
    --  system being used. An adder is used for the addition performed in the Circular and
    --  Hyperbolic coordinate systems. The adder is fed into a mux that selects either the
    --  adder output or Xin (for the Linear coordinate system).
    ---------------------------------------------------------------------------------------
    -- if(COORD_SYS_CIRCULAR) {
    --  Xout = Xin - (sigma * Yin * 2^(-i));
    -- } else if(COORD_SYS_LINEAR) {
    --  Xout = Xin;
    -- } else if(COORD_SYS_HYPERBOLIC) {
    --  Xout = Xin + (sigms * Yin * 2^(-i));
    -- }
    X_ADDR  :   entity work.add_sub
        GENERIC MAP
        (
            WIDTH       => WIDTH
        )
        PORT MAP
        (
            input_a     => Xin,
            input_b     => std_logic_vector(shift_right(signed(Yin), itr)),
            add_nsub    => x_sigma,
            output      => x_addr_out
        );
        
    X_MUX : process(coor_system_a)
    begin
        case(coor_system_a) is
            when "00" =>
                Xout <= Xin;

            when others =>
                Xout <= x_addr_out;
        end case;
    end process;
        
    DIR_PROC :  process(mode_a, Yin, Zin)
    begin
        -- dir will default false
        dir <= false;

        case mode_a is
            when MODE_VECTORING =>
                dir <= (signed(Yin) < 0);

            when MODE_ROTATION =>
                dir <= (signed(Zin) >= 0);

            when OTHERS =>
                NULL;
        end case;
    end process;

    Y_ROT_PROC :  process(dir, itr, Xin, Yin, Zin, alpha)
    begin
        case dir is
            when true   =>
                Xout    <= std_logic_vector(signed(Xin) - shift_right(signed(Yin), itr));

            when false  =>
                Xout    <= std_logic_vector(signed(Xin) + shift_right(signed(Yin), itr));

            when OTHERS =>
                NULL;
        end case;
    end process; 
 end BHV;