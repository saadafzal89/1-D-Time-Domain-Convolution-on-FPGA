-- Greg Stitt
-- University of Florida

-- Description:
-- The ram entity implements a ram with a standard 1-read port, 1-write port
-- interface. The ram is configurable in terms of data width (width of each
-- word), the address width, and the number of words. The ram has a write
-- enable for writes, but does not contain a read enable. Instead, the ram
-- reads from the read address every cycle.
--
-- The entity contains several different architectures that implement different
-- ram behaviors. e.g. synchronous reads, asynchronous reads, synchronoous
-- reads during writes.
--

-- Notes:
-- Asychronous reads are not supported by all FPGAs.
--

-------------------------------------------------------------------------------
-- Generics Description
-- word_width        : The width in bits of a single word (required)
-- addr_width        : The width in bits of an address, which also defines the
--                     number of words (required)
-- num_words         : The number of words in the memory. This generic will
--                     usually be 2**addr_width, but the entity supports
--                     non-powers of 2 (required)
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Port Description:
-- clk    : clock input
-- wen    : write enable (active high)
-- waddr  : write address
-- wdata  : write data
-- raddr  : read address
-- rdata  : read data
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_custom.all;

entity dram_model is
    generic (
        num_words              : positive;
        word_width             : positive;
        addr_width             : positive;
        wr_only_when_ready     : boolean  := true;
        rd_latency             : positive := 10;
        cycles_between_refresh : positive := 100;
        cycles_for_refresh     : positive := 10
        );
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        ready : out std_logic;

        -- write port
        wr_en      : in  std_logic;
        wr_addr    : in  std_logic_vector(addr_width-1 downto 0);
        wr_data    : in  std_logic_vector(word_width-1 downto 0);
        wr_pending : out std_logic;

        -- read port
        rd_en    : in  std_logic;
        rd_addr  : in  std_logic_vector(addr_width-1 downto 0);
        rd_data  : out std_logic_vector(word_width-1 downto 0);
        rd_valid : out std_logic;
        rd_flush : in  std_logic
        );
end entity;


architecture DEFAULT of dram_model is

    signal count : unsigned(bitsNeeded(cycles_between_refresh+cycles_for_refresh)-1 downto 0);

    signal ready_s       : std_logic;
    signal wr_en_s       : std_logic;
    signal rd_data_s     : std_logic_vector(word_width-1 downto 0);
    signal rd_en_delayed : std_logic;
    signal rd_valid_s    : std_logic;
    signal flush_s       : std_logic;

    constant ZERO_WORD    : std_logic_vector(word_width-1 downto 0) := (others => '0');
    constant C1           : std_logic                               := '1';
    constant TOTAL_CYCLES : integer                                 := cycles_between_refresh + cycles_for_refresh;

begin

    U_WR_READY : if (wr_only_when_ready = true) generate
        wr_en_s <= wr_en and ready_s;
    end generate;

    U_WR_ANY : if (wr_only_when_ready = false) generate
        wr_en_s <= wr_en;
    end generate;

    -- use a block RAM to imitate a DRAM
    U_BRAM : entity work.ram(SYNC_READ)
        generic map (
            num_words  => num_words,
            word_width => word_width,
            addr_width => addr_width)
        port map (
            clk   => clk,
            wen   => wr_en_s,
            waddr => wr_addr,
            wdata => wr_data,
            raddr => rd_addr,
            rdata => rd_data_s);

    flush_s <= rst or rd_flush;

    -- delay read data by rd_latency
    U_RD_DELAY : entity work.delay
        generic map (
            width  => word_width,
            cycles => rd_latency-1,     -- BRAM has 1-cycle latency already
            init   => ZERO_WORD)
        port map (
            clk    => clk,
            rst    => flush_s,
--            en     => ready_s,
            en     => C1,
            input  => rd_data_s,
            output => rd_data);

    -- delay the read enable to account for the 1-cycle BRAM latency
    U_RD_EN_DELAY : entity work.delay
        generic map (
            width  => 1,
            cycles => 1,
            init   => "0")
        port map (
            clk       => clk,
            rst       => flush_s,
            en        => C1,
            input(0)  => rd_en,
            output(0) => rd_en_delayed);

    -- determine the valid output by delaying the same amount as the data
    U_VALID_DELAY : entity work.delay
        generic map (
            width  => 1,
            cycles => rd_latency-1,     -- BRAM has 1-cycle latency already
            init   => "0")
        port map (
            clk       => clk,
            rst       => flush_s,
--            en        => ready_s,
            en        => C1,
            input(0)  => rd_en_delayed,
            output(0) => rd_valid_s);

--    rd_valid <= rd_valid_s and ready_s;
    rd_valid <= rd_valid_s;
--    ready_s  <= '1' when count < cycles_between_refresh else '0';
    ready_s  <= '1';
    ready    <= ready_s;

    -- counter to implement ready state
    process(clk, rst)
    begin
        if (rst = '1') then
            count <= (others => '0');

        elsif (rising_edge(clk)) then

            count <= count + 1;

            if (count = TOTAL_CYCLES-1) then
                count <= (others => '0');
            end if;
        end if;
    end process;

    -- quick hack to support 1-cycle writes
    wr_pending <= wr_en;

end DEFAULT;

