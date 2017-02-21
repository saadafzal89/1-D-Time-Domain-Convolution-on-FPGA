-- Greg Stitt
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
        clk     : in  std_logic;
        rst     : in  std_logic;
        wr_en   : in  std_logic;
        wr_addr : in  std_logic_vector(MMAP_ADDR_RANGE);
        wr_data : in  std_logic_vector(MMAP_DATA_RANGE);
        rd_en   : in  std_logic;
        rd_addr : in  std_logic_vector(MMAP_ADDR_RANGE);
        rd_data : out std_logic_vector(MMAP_DATA_RANGE);

        -- DMA signals to allow software to access DRAM
        ram0_wr_ready : in  std_logic;
        ram0_wr_clear : out std_logic;
        ram0_wr_go    : out std_logic;
        ram0_wr_valid : out std_logic;
        ram0_wr_data  : out std_logic_vector(RAM0_WR_DATA_RANGE);
        ram0_wr_addr  : out std_logic_vector(RAM0_ADDR_RANGE);
        ram0_wr_size  : out std_logic_vector(RAM0_WR_SIZE_RANGE);
        ram0_wr_done  : in  std_logic;
		
        ram1_rd_rd_en : out std_logic;
        ram1_rd_clear : out std_logic;
        ram1_rd_go    : out std_logic;
        ram1_rd_valid : in  std_logic;
        ram1_rd_data  : in  std_logic_vector(RAM1_RD_DATA_RANGE);
        ram1_rd_addr  : out std_logic_vector(RAM1_ADDR_RANGE);
        ram1_rd_size  : out std_logic_vector(RAM1_RD_SIZE_RANGE);
        ram1_rd_done  : in  std_logic;

        -- circuit interface from software        
        go            : out std_logic;
        sw_rst        : out std_logic;
        signal_size   : out std_logic_vector(RAM0_RD_SIZE_RANGE);
        kernel_data   : out std_logic_vector(KERNEL_WIDTH_RANGE);
        kernel_load   : out std_logic;
        kernel_loaded : in  std_logic;
        done          : in  std_logic
        );
end memory_map;

architecture BHV of memory_map is

    signal reg_go          : std_logic;
    signal reg_rst         : std_logic;
    signal reg_signal_size : std_logic_vector(MAX_SIGNAL_SIZE_RANGE);
    signal reg_kernel_data : std_logic_vector(KERNEL_WIDTH_RANGE);

    signal ram0_wr_go_s    : std_logic;
    signal ram0_wr_valid_s : std_logic;
    signal ram0_wr_addr_s  : std_logic_vector(RAM0_ADDR_RANGE);
    signal ram0_wr_data_s  : std_logic_vector(RAM0_WR_DATA_RANGE);
    signal ram0_wr_size_s  : std_logic_vector(RAM0_WR_SIZE_RANGE);
    signal ram1_rd_go_s    : std_logic;
    signal ram1_rd_addr_s  : std_logic_vector(RAM1_ADDR_RANGE);
    signal ram1_rd_size_s  : std_logic_vector(RAM1_RD_SIZE_RANGE);

    signal prev_addr : std_logic_vector(MMAP_ADDR_RANGE);

    subtype DMA0_ADDR_RANGE is natural range C_DRAM0_ADDR_WIDTH-1 downto 0;
    subtype DMA0_SIZE_RANGE is natural range C_DRAM0_SIZE_WIDTH+C_DRAM0_ADDR_WIDTH-1 downto C_RAM0_ADDR_WIDTH;

    subtype DMA1_ADDR_RANGE is natural range C_DRAM1_ADDR_WIDTH-1 downto 0;
    subtype DMA1_SIZE_RANGE is natural range C_DRAM1_SIZE_WIDTH+C_DRAM1_ADDR_WIDTH-1 downto C_RAM1_ADDR_WIDTH;

begin

    process(clk, rst)
    begin
        if (rst = '1') then
            reg_go          <= '0';
            reg_rst         <= '0';
            reg_signal_size <= (others => '0');
            reg_kernel_data <= (others => '0');
            kernel_load <= '0';

            rd_data <= (others => '0');

            ram0_wr_clear  <= '0';
            ram0_wr_go_s   <= '0';
            ram0_wr_valid  <= '0';
            ram0_wr_data   <= (others => '0');
            ram0_wr_addr_s <= (others => '0');
            ram0_wr_size_s <= (others => '0');

            ram0_wr_go   <= '0';
            ram0_wr_addr <= (others => '0');
            ram0_wr_size <= (others => '0');

            ram1_rd_rd_en  <= '0';
            ram1_rd_clear  <= '0';
            ram1_rd_go_s   <= '0';
            ram1_rd_size_s <= (others => '0');
            ram1_rd_addr_s <= (others => '0');

            ram1_rd_go   <= '0';
            ram1_rd_addr <= (others => '0');
            ram1_rd_size <= (others => '0');

            prev_addr <= (others => '1');

        elsif (rising_edge(clk)) then

            reg_go      <= '0';
            reg_rst     <= '0';
            kernel_load <= '0';

            ram0_wr_clear  <= '0';
            ram0_wr_go_s   <= '0';
            ram0_wr_valid  <= '0';
            ram0_wr_data   <= (others => '0');
            ram0_wr_addr_s <= (others => '0');
            ram0_wr_size_s <= (others => '0');

            ram0_wr_go   <= ram0_wr_go_s;
            ram0_wr_addr <= ram0_wr_addr_s;
            ram0_wr_size <= ram0_wr_size_s;

            ram1_rd_rd_en  <= '0';
            ram1_rd_clear  <= '0';
            ram1_rd_go_s   <= '0';
            ram1_rd_size_s <= (others => '0');
            ram1_rd_addr_s <= (others => '0');

            ram1_rd_go   <= ram1_rd_go_s;
            ram1_rd_size <= ram1_rd_size_s;
            ram1_rd_addr <= ram1_rd_addr_s;

            if (wr_en = '1') then

                -- if address falls within address space of RAM0, write to the
                -- DMA interface. The data should be written regardless of
                -- whether or not the RAM is ready
                if (unsigned(wr_addr) < 2**C_RAM0_ADDR_WIDTH) then
                    ram0_wr_data  <= wr_data(ram0_wr_data'range);
                    ram0_wr_valid <= '1';
                end if;

                case wr_addr is

                    when C_RST_ADDR =>
                        reg_rst <= wr_data(0);

                    when C_GO_ADDR =>
                        reg_go <= wr_data(0);

                    when C_SIGNAL_SIZE_ADDR =>
                        reg_signal_size <= wr_data(reg_signal_size'range);

                    when C_KERNEL_DATA_ADDR =>
                        reg_kernel_data <= wr_data(kernel_data'range);
                        kernel_load     <= '1'; 

                    -- don't touch
                    -- needed to transfer data from software to "drams"
                    when C_RAM0_DMA_ADDR =>
                        ram0_wr_clear  <= '1';
                        -- these get delayed by a cycle to allow for the clear
                        ram0_wr_size_s <= wr_data(DMA0_SIZE_RANGE);
                        ram0_wr_addr_s <= wr_data(DMA0_ADDR_RANGE);
                        ram0_wr_go_s   <= '1';

                    when C_RAM1_DMA_ADDR =>
                        ram1_rd_clear  <= '1';
                        prev_addr      <= (others => '1');
                        -- these get delayed by a cycle to allow for the clear
                        ram1_rd_size_s <= wr_data(DMA1_SIZE_RANGE);
                        ram1_rd_addr_s <= wr_data(DMA1_ADDR_RANGE);
                        ram1_rd_go_s   <= '1';

                    when others => null;
                end case;
            end if;

            if (rd_en = '1') then

                rd_data <= (others => '0');

                -- if address falls within address space of RAM1, read from the
                -- DMA interface. The data should already be available assuming
                -- that the software first configured the DMA
                --
                -- NOTE: For some reason, each read from software accesses the
                -- same address twice, which will cause one of the elements of
                -- the read to be lost. To fix this, this code prevents repeated
                -- reads from the same address. If such behavior is needed for
                -- an application, this will have to be changed.
                if (unsigned(rd_addr) < 2**C_RAM1_ADDR_WIDTH and rd_addr /= prev_addr) then

                    prev_addr                   <= rd_addr;
                    rd_data(ram1_rd_data'range) <= ram1_rd_data;
                    ram1_rd_rd_en               <= '1';
--                    assert(ram1_rd_valid = '1');
                end if;

                case rd_addr is

                    when C_GO_ADDR =>
                        rd_data    <= (others => '0');
                        rd_data(0) <= reg_go;

                    when C_SIGNAL_SIZE_ADDR =>
                        rd_data                        <= (others => '0');
                        rd_data(reg_signal_size'range) <= reg_signal_size;

                    when C_KERNEL_DATA_ADDR =>
                        rd_data                        <= (others => '0');
                        rd_data(reg_kernel_data'range) <= reg_kernel_data;

                    when C_KERNEL_LOADED_ADDR =>
                        rd_data    <= (others => '0');
                        rd_data(0) <= kernel_loaded;

                    when C_DONE_ADDR =>
                        rd_data    <= (others => '0');
                        rd_data(0) <= done;

                    when others => null;
                end case;
            end if;

        end if;
    end process;

    go          <= reg_go;
    sw_rst      <= reg_rst;
    signal_size <= reg_signal_size;
    kernel_data <= reg_kernel_data;

end BHV;
