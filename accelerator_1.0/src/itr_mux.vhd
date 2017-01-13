library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

---------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------
entity itr_mux is
    PORT
    (
        sel         : in    std_logic_vector(1 downto 0);
        
        A, B, c, D  : in    std_logic_vector(7 downto 0);
        Y           : out   std_logic_vector(7 downto 0)
    );
end itr_mux;

architecture STR of itr_mux is
begin
    process(sel, A, B, C, D)
    begin
        case sel is
            when "00" =>
                Y <= A;

            when "01" =>
                Y <= B;

            when "10" =>
                Y <= C;

            when "11" =>
                Y <= D;

            when others =>
                null;
        end case;
    end process;
end STR;