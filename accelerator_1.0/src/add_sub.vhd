---------------------------------------------------------------------------------------
-- Simple signed adder/subtractor without carry.
---------------------------------------------------------------------------------------
entity add_sub is
    GENERIC
    (
        WIDTH       : positive := 8
    );
    PORT
    (
        input_a     : in    std_logic_vector(WIDTH-1 downto 0);
        input_b     : in    std_logic_vector(WIDTH-1 downto 0);

        add_nsub    : in    std_logic;
        
        output      : out   std_logic_vector(WIDTH-1 downto 0)
    );
end add_sub;

-- This was just added so different adder implementations may be used later on. For now,
--  it's more of a place holder than anything really useful.
architecture BHV of add_sub is
begin
    process(input_a, input_b, add_nsub)
    begin
        if(add_nsub = '1') then
            output <= std_logic_vector(signed(input_a) + signed(input_b));
        else
            output <= std_logic_vector(signed(input_a) - signed(input_b));
        end if;
    end process;
end BHV;