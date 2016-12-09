-- Greg Stitt
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity user_app is
    port (
        clks : in std_logic_vector(CLKS_RANGE);
        rst  : in std_logic;

        -- memory-map interface
        mmap_wr_en   : in  std_logic;
        mmap_wr_addr : in  std_logic_vector(MMAP_ADDR_RANGE);
        mmap_wr_data : in  std_logic_vector(MMAP_DATA_RANGE);
        mmap_rd_en   : in  std_logic;
        mmap_rd_addr : in  std_logic_vector(MMAP_ADDR_RANGE);
        mmap_rd_data : out std_logic_vector(MMAP_DATA_RANGE)
        );
end user_app;

architecture default of user_app is

    signal go   : std_logic;
    signal done : std_logic;
    signal size : std_logic_vector(C_MEM_ADDR_WIDTH downto 0);

    signal mem_in_wr_data : std_logic_vector(C_MEM_IN_WIDTH-1 downto 0);
    signal mem_in_wr_addr : std_logic_vector(C_MEM_ADDR_WIDTH-1 downto 0);
    signal mem_in_rd_data : std_logic_vector(C_MEM_IN_WIDTH-1 downto 0);
    signal mem_in_rd_addr : std_logic_vector(C_MEM_ADDR_WIDTH-1 downto 0);
    signal mem_in_wr_en   : std_logic;

    signal mem_out_wr_data : std_logic_vector(C_MEM_OUT_WIDTH-1 downto 0);
    signal mem_out_wr_addr : std_logic_vector(C_MEM_ADDR_WIDTH-1 downto 0);
    signal mem_out_rd_data : std_logic_vector(C_MEM_OUT_WIDTH-1 downto 0);
    signal mem_out_rd_addr : std_logic_vector(C_MEM_ADDR_WIDTH-1 downto 0);
    signal mem_out_wr_en   : std_logic;

    signal mem_in_addr_valid : std_logic;
    signal mem_in_data_valid : std_logic;

    signal dp_data_in   : std_logic_vector(C_MEM_IN_WIDTH-1 downto 0);
    signal dp_data_out  : std_logic_vector(C_MEM_OUT_WIDTH-1 downto 0);
    signal dp_valid_in  : std_logic;
    signal dp_valid_out : std_logic;
    signal dp_en        : std_logic;
    signal dp_stall     : std_logic;

    signal mem_in_en               : std_logic;
    signal mem_in_fifo_empty       : std_logic;
    signal mem_in_fifo_full        : std_logic;
    signal mem_in_fifo_almost_full : std_logic;
    signal mem_in_fifo_wr          : std_logic;
    signal mem_in_fifo_data_in     : std_logic_vector(C_MEM_IN_WIDTH-1 downto 0);

    signal mem_out_fifo_empty : std_logic;
    signal mem_out_fifo_full  : std_logic;

begin

    ---------------------------------------------------------------------------
    -- Clock domain 1

    U_MMAP : entity work.memory_map
        port map (
            clk     => clks(0),
            rst     => rst,
            wr_en   => mmap_wr_en,
            wr_addr => mmap_wr_addr,
            wr_data => mmap_wr_data,
            rd_en   => mmap_rd_en,
            rd_addr => mmap_rd_addr,
            rd_data => mmap_rd_data,

            go              => go,
            size            => size,
            done            => done,
            mem_in_wr_data  => mem_in_wr_data,
            mem_in_wr_addr  => mem_in_wr_addr,
            mem_in_wr_en    => mem_in_wr_en,
            mem_out_rd_data => mem_out_rd_data,
            mem_out_rd_addr => mem_out_rd_addr
            );

    -- Input bram
    U_MEM_IN : entity work.ram(SYNC_READ)
        generic map (
            num_words  => 2**C_MEM_ADDR_WIDTH,
            word_width => C_MEM_IN_WIDTH,
            addr_width => C_MEM_ADDR_WIDTH)
        port map (
            clk   => clks(0),
            wen   => mem_in_wr_en,
            waddr => mem_in_wr_addr,
            wdata => mem_in_wr_data,
            raddr => mem_in_rd_addr,
            rdata => mem_in_rd_data);

    -- address generator for input memory. Notice there is only one addr_gen
    -- entity now instead of a separate one for the input and output memories.
    -- This simplification is enabled by the simplicity of the control required
    -- by the FIFO. The input address generator produces an address anytime the
    -- input FIFO isn't almost full. Because there is one cycle of latency for a
    -- read, it must stop when the FIFO is almost full to guarantee that there is
    -- enough room in the FIFO to store outstanding requests. For memories with
    -- longer delays (e.g. external memories), you must use a FIFO with a
    -- programmable full flag that leaves enough room for all outstanding
    -- requests. 

    U_MEM_IN_ADDR_GEN : entity work.addr_gen
        generic map (
            width => C_MEM_ADDR_WIDTH)
        port map (
            clk   => clks(0),
            rst   => rst,
            size  => size,
            go    => go,
            stall => mem_in_fifo_almost_full,
            addr  => mem_in_rd_addr,
            valid => mem_in_addr_valid,
            done  => open);

    -- signifies valid data that has been read from the input memory. Creates a
    -- one cycle delay of the mem_in_valid signal, which corresponds to the time
    -- when valid data is available from the input memory

    U_DELAY : entity work.delay
        generic map (
            cycles => 1,
            width  => 1,
            init   => "0")
        port map (
            clk       => clks(0),
            rst       => rst,
            en        => mem_in_en,
            input(0)  => mem_in_addr_valid,
            output(0) => mem_in_data_valid);

    -- enables the valid delay register when the fifo isn't full (i.e., stalls
    -- when the fifo is full)
    mem_in_en <= not mem_in_fifo_full;

    -- writes to the input FIFO anytime there is valid input data and the FIFO
    -- isn't full. Checking for the full FIFO should be optional, because a FIFO
    -- should protect against writing when full, but I do it here just to be safe
    mem_in_fifo_wr <= mem_in_data_valid and not mem_in_fifo_full;

    -- input FIFO. Note that the input FIFO requires an almost_full flag because
    -- there will be outstanding memory reads when the FIFO is actually full. The
    -- almost_full flag ensures enough room for an outstanding request when
    -- the read latency is 1 cycle.
    U_MEM_IN_FIFO : entity work.fifo_in
        port map (
            clk_src     => clks(0),
            clk_dest    => clks(1),
            rst         => rst,
            empty       => mem_in_fifo_empty,
            full        => mem_in_fifo_full,
            almost_full => mem_in_fifo_almost_full,
            -- read anytime the dp is enabled (reading an empty FIFO won't hurt)
            rd          => dp_en,
            wr          => mem_in_fifo_wr,
            data_in     => mem_in_rd_data,  -- data from input memory
            data_out    => dp_data_in       -- data to datapath
            );

    -----------------------------------------------------------------------------
    -- Clock domain 2
    -- Simple datapath from pipelining lab

    U_PIPELINE : entity work.pipeline
        port map (
            clk       	=> clks(1),
            rst       	=> rst,
				mode			=> dp_data_in(3*(C_MEM_IN_WIDTH/4)),
				valid_in		=> dp_valid_in,
				X_in			=> dp_data_in(3*(C_MEM_IN_WIDTH/4)-1 downto C_MEM_IN_WIDTH/2),
				Y_in			=> dp_data_in(C_MEM_IN_WIDTH/2-1 downto C_MEM_IN_WIDTH/4),
				theta_in		=> dp_data_in(C_MEM_IN_WIDTH/4-1 downto 0),
				valid_out	=> dp_valid_out,
				X_out			=> dp_data_out(C_MEM_OUT_WIDTH-1 downto 2*(C_MEM_OUT_WIDTH/3)),
				Y_out			=> dp_data_out(2*(C_MEM_OUT_WIDTH/3)-1 downto C_MEM_OUT_WIDTH/3),
				theta_out	=> dp_data_out(C_MEM_OUT_WIDTH/3-1 downto 0)
				);

    -- datapath has valid data whenever the input fifo isn't empty. Note that
    -- this requires the input memory to be "first-word fall through", which
    -- means that the front of the queue is already on the output. If there is
    -- latency involved in reading from the FIFO, then this valid signal must be
    -- delayed.
    dp_valid_in <= not mem_in_fifo_empty;

    -- stall when the output fifo is full
    dp_stall <= mem_out_fifo_full;
    dp_en    <= not dp_stall;

    ---------------------------------------------------------------------------
    -- Clock domain 1

    -- output FIFO. This FIFO does not require the almost_full flag because the
    -- datapath can immediately stall, which prevents data loss.
    U_MEM_OUT_FIFO : entity work.fifo_out
        port map (
            clk_src  => clks(1),
            clk_dest => clks(0),
            rst      => rst,
            empty    => mem_out_fifo_empty,
            full     => mem_out_fifo_full,
            rd       => mem_out_wr_en,
            wr       => dp_valid_out,
            data_in  => dp_data_out,
            data_out => mem_out_wr_data);

    -- Output memory
    U_MEM_OUT : entity work.ram(SYNC_READ)
        generic map (
            num_words  => 2**C_MEM_ADDR_WIDTH,
            word_width => C_MEM_OUT_WIDTH,
            addr_width => C_MEM_ADDR_WIDTH)
        port map (
            clk   => clks(0),
            wen   => mem_out_wr_en,
            waddr => mem_out_wr_addr,
            wdata => mem_out_wr_data,
            raddr => mem_out_rd_addr,
            rdata => mem_out_rd_data);

    -- write to the memory any time there is data in the output FIFO. This
    -- assumes there is a valid address from the address generator, but that
    -- is a valid assumption in this case because the address generator can
    -- produce an address every cycle
    mem_out_wr_en <= not mem_out_fifo_empty;

    -- output address generator. Note that this is the same entity used by the
    -- input address generator.
    U_MEM_OUT_ADDR_GEN : entity work.addr_gen
        generic map (
            width => C_MEM_ADDR_WIDTH)
        port map (
            clk   => clks(0),
            rst   => rst,
            size  => size,
            go    => go,
            -- stall whenever the output fifo is empty (nothing to write
            -- to memory)
            stall => mem_out_fifo_empty,
            addr  => mem_out_wr_addr,
            -- could potentially use valid to ensure that data isn't written
            -- to an invald address, but this will never occur in this example.
            valid => open,
            -- the circuit is done once the output address generator has
            -- finished. Note that this isn't always safe. For example, if it
            -- takes 20 cycles to write to memory, this could assert done
            -- before the data is actually written. If this is a concern,
            -- simply delay the done signal.
            done  => done);

end default;
