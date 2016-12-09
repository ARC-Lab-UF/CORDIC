library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity addr_gen is
  generic(width :     positive);
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    size        : in  std_logic_vector(width downto 0);
    go          : in  std_logic;
    stall       : in  std_logic;
    addr        : out std_logic_vector(width-1 downto 0);
    valid       : out std_logic;
    done        : out std_logic);
end addr_gen;

architecture BHV of addr_gen is

  type state_type is (S_INIT, S_EXECUTE);
  signal state, next_state : state_type;

  signal size_reg, next_size_reg : unsigned(width downto 0);
  signal addr_s, next_addr_s     : std_logic_vector(width downto 0);

begin  -- BHV

  process (clk, rst)
  begin
    if (rst = '1') then
      addr_s   <= (others => '0');
      size_reg <= (others => '0');
      state    <= S_INIT;
    elsif (clk'event and clk = '1') then
      addr_s   <= next_addr_s;
      size_reg <= next_size_reg;
      state    <= next_state;
    end if;
  end process;

  process(addr_s, size_reg, size, state, go, stall)
  begin

    next_state    <= state;
    next_addr_s   <= addr_s;
    next_size_reg <= size_reg;
    done          <= '1';

    case state is
      when S_INIT =>

        next_addr_s <= std_logic_vector(to_unsigned(0, width+1));
        valid       <= '0';

        if (go = '1') then
          done          <= '0';
          next_size_reg <= unsigned(size);
          next_state    <= S_EXECUTE;
        end if;

      when S_EXECUTE =>

        valid <= '1';
        done  <= '0';

        if (unsigned(addr_s) = size_reg) then
          done        <= '1';
          next_state  <= S_INIT;
        elsif (stall = '0') then
          next_addr_s <= std_logic_vector(unsigned(addr_s)+1);
        elsif (stall = '1') then
          valid       <= '0';
        end if;

      when others => null;
    end case;

  end process;

  addr <= addr_s(width-1 downto 0);

end BHV;

