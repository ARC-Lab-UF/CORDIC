-- Greg Stitt
-- Austin Baylis and Madison Emas
-- University of Florida

-- Entity: memory_map
-- This entity establishes connections with user-defined addresses and
-- internal FPGA components (e.g. registers and blockRAMs).
--
-- Note: Make sure to add any new addresses to user_pkg. Also, in your C code,
-- make sure to use the same constants.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity memory_map is
    port (
        clk                 : in  std_logic;
        rst                 : in  std_logic;

        wr_en               : in  std_logic;
        wr_addr             : in  std_logic_vector(MMAP_ADDR_RANGE);
        wr_data             : in  std_logic_vector(MMAP_DATA_RANGE);

        rd_en               : in  std_logic;
        rd_addr             : in  std_logic_vector(MMAP_ADDR_RANGE);
        rd_data             : out std_logic_vector(MMAP_DATA_RANGE);

        -- app-specific signals
        go                  : out std_logic;
        size                : out std_logic_vector(C_MEM_ADDR_WIDTH downto 0);
        done                : in  std_logic;

        mem_in_wr_data      : out std_logic_vector(C_MEM_IN_WIDTH-1 downto 0);
        mem_in_wr_addr      : out std_logic_vector(C_MEM_ADDR_WIDTH-1 downto 0);

        mem_out_rd_data     : in  std_logic_vector(C_FIFO_WIDTH-1 downto 0);
        mem_out_rd_addr     : out std_logic_vector(C_MEM_ADDR_WIDTH-1 downto 0);

        mem_load_mode       : out std_logic;
        mem_load_x          : out std_logic;
        mem_load_y          : out std_logic;
        mem_load_z          : out std_logic
    );
end memory_map;

architecture BHV of memory_map is
    -- Internal Registers
    signal reg_go                       : std_logic;
    signal reg_size                     : std_logic_vector(C_MEM_ADDR_WIDTH downto 0);
    signal reg_rd_data                  : std_logic_vector(C_MMAP_DATA_WIDTH-1 downto 0);

    -- RD_DATA MUX select constants
    signal rd_data_sel                  : std_logic_vector(1 downto 0);

    constant C_RD_DATA_SEL_REG          : std_logic_vector(1 downto 0) := "00";
    constant C_RD_DATA_SEL_X_MEM_OUT    : std_logic_vector(1 downto 0) := "01";
    constant C_RD_DATA_SEL_Y_MEM_OUT    : std_logic_vector(1 downto 0) := "10";
    constant C_RD_DATA_SEL_Z_MEM_OUT    : std_logic_vector(1 downto 0) := "11";

begin

    -- Incoming signals
    mem_in_wr_data  <= wr_data(mem_in_wr_data'range);
    mem_in_wr_addr  <= wr_addr(mem_in_wr_addr'range);

    mem_load_x      <= '1' when wr_en = '1' AND unsigned(wr_addr) >= unsigned(C_X_MEM_START_ADDR) AND unsigned(wr_addr) <= unsigned(C_X_MEM_END_ADDR) else '0';
    mem_load_y      <= '1' when wr_en = '1' AND unsigned(wr_addr) >= unsigned(C_Y_MEM_START_ADDR) AND unsigned(wr_addr) <= unsigned(C_Y_MEM_END_ADDR) else '0';
    mem_load_z      <= '1' when wr_en = '1' AND unsigned(wr_addr) >= unsigned(C_Z_MEM_START_ADDR) AND unsigned(wr_addr) <= unsigned(C_Z_MEM_END_ADDR) else '0';

    -- Outgoing signals
    mem_out_rd_addr <= rd_addr(mem_out_rd_addr'range);

    -- Process for synchronous components
    process(clk, rst)
    begin
        if (rst = '1') then
            -- If rest = true, zero out registers
            reg_go      <= '0';
            reg_size    <= (others => '0');
            rd_data_sel <= (others => '0');
            reg_rd_data <= (others => '0');

        elsif (rising_edge(clk)) then

            mem_load_mode   <= '0';

            reg_go          <= '0';

            if (wr_en = '1') then
                -- If wr_en is true, and the contents are destine for a register, write to them
                case wr_addr is
                    when C_GO_ADDR =>
                        reg_go <= wr_data(0);

                    when C_SIZE_ADDR =>
                        reg_size <= wr_data(reg_size'range);

                    when C_MODE_ADDR =>
                        -- FIXME: This register is outside the memory map. If it doesn't function, then we should probably
                        --  move it to the inside (like similar registers).
                        mem_load_mode <= '1';

                    when others =>
                        null;
                end case;
            end if;

            if (rd_en = '1') then
                -- If rd_en is true, default to reading from the registers and reg_rd_data to zero
                rd_data_sel <= C_RD_DATA_SEL_REG;
                reg_rd_data <= (others => '0');

                -- check if rd_addr corresponds to memory or registers
                if ((unsigned(rd_addr) >= unsigned(C_X_MEM_START_ADDR))     AND (unsigned(rd_addr) <= unsigned(C_X_MEM_END_ADDR))) then
                    rd_data_sel <= C_RD_DATA_SEL_X_MEM_OUT;

                elsif ((unsigned(rd_addr) >= unsigned(C_Y_MEM_START_ADDR))  AND (unsigned(rd_addr) <= unsigned(C_Y_MEM_END_ADDR))) then
                    rd_data_sel <= C_RD_DATA_SEL_Y_MEM_OUT;

                elsif ((unsigned(rd_addr) >= unsigned(C_Z_MEM_START_ADDR))  AND (unsigned(rd_addr) <= unsigned(C_Z_MEM_END_ADDR))) then
                    rd_data_sel <= C_RD_DATA_SEL_Z_MEM_OUT;

                else
                    rd_data_sel <= C_RD_DATA_SEL_REG;
                end if;

                -- select the appropriate register for a read
                case rd_addr is
                    when C_GO_ADDR =>
                        reg_rd_data <= std_logic_vector(to_unsigned(0, C_MMAP_DATA_WIDTH-1)) & reg_go;

                    when C_SIZE_ADDR =>
                        reg_rd_data <= (others => '0');
                        reg_rd_data(reg_size'range) <= reg_size;

                    when C_DONE_ADDR =>
                        reg_rd_data <= std_logic_vector(to_unsigned(0, C_MMAP_DATA_WIDTH-1)) & done;

                    when others =>
                        null;
                end case;
            end if;

        end if;
    end process;

    go   <= reg_go;
    size <= reg_size;

    -- mux that defines dout based on where the read data come from
    process(rd_data_sel, reg_rd_data, mem_out_rd_data)
    begin
        rd_data <= (others => '0');

        case rd_data_sel is
            when C_RD_DATA_SEL_X_MEM_OUT =>
                rd_data(C_MEM_OUT_WIDTH-1 downto 0) <= mem_out_rd_data(X_SLICE);
            when C_RD_DATA_SEL_Y_MEM_OUT =>
                rd_data(C_MEM_OUT_WIDTH-1 downto 0) <= mem_out_rd_data(Y_SLICE);
            when C_RD_DATA_SEL_Z_MEM_OUT =>
                rd_data(C_MEM_OUT_WIDTH-1 downto 0) <= mem_out_rd_data(Z_SLICE);
            when C_RD_DATA_SEL_REG =>
                rd_data <= reg_rd_data;
            when others => null;
        end case;
    end process;
end BHV;
