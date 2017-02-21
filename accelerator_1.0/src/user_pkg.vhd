-- Greg Stitt
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_pkg.all;
use work.math_custom.all;

package user_pkg is

    constant C_RAM0_ADDR_WIDTH    : positive := 15;
    constant C_RAM0_RD_DATA_WIDTH : positive := 16;
    constant C_RAM0_WR_DATA_WIDTH : positive := 32;
    -- adjust for ratio of data width and ram width
    constant C_RAM0_RD_SIZE_WIDTH : positive := C_DRAM0_ADDR_WIDTH+1+1;
    constant C_RAM0_WR_SIZE_WIDTH : positive := C_DRAM0_ADDR_WIDTH+1;
    constant C_RAM1_ADDR_WIDTH    : positive := 15;
    constant C_RAM1_RD_DATA_WIDTH : positive := 32;
    constant C_RAM1_WR_DATA_WIDTH : positive := 16;
    -- adjust for ratio of data width and ram width
    constant C_RAM1_RD_SIZE_WIDTH : positive := C_DRAM1_ADDR_WIDTH+1;
    constant C_RAM1_WR_SIZE_WIDTH : positive := C_DRAM1_ADDR_WIDTH+1+1;

    subtype RAM0_ADDR_RANGE is natural range C_RAM0_ADDR_WIDTH-1 downto 0;
    subtype RAM0_RD_DATA_RANGE is natural range C_RAM0_RD_DATA_WIDTH-1 downto 0;
	subtype KERNEL_DATA_RANGE is natural range 128*C_RAM0_RD_DATA_WIDTH-1 downto 0;
	subtype SIGNAL_DATA_RANGE is natural range 128*C_RAM0_RD_DATA_WIDTH-1 downto 0;
    subtype RAM0_WR_DATA_RANGE is natural range C_RAM0_WR_DATA_WIDTH-1 downto 0;
    subtype RAM0_RD_SIZE_RANGE is natural range C_RAM0_RD_SIZE_WIDTH-1 downto 0;
    subtype RAM0_WR_SIZE_RANGE is natural range C_RAM0_WR_SIZE_WIDTH-1 downto 0;
    subtype RAM1_ADDR_RANGE is natural range C_RAM1_ADDR_WIDTH-1 downto 0;
    subtype RAM1_RD_DATA_RANGE is natural range C_RAM1_RD_DATA_WIDTH-1 downto 0;
    subtype RAM1_WR_DATA_RANGE is natural range C_RAM1_WR_DATA_WIDTH-1 downto 0;
    subtype RAM1_RD_SIZE_RANGE is natural range C_RAM1_RD_SIZE_WIDTH-1 downto 0;
    subtype RAM1_WR_SIZE_RANGE is natural range C_RAM1_WR_SIZE_WIDTH-1 downto 0;

    -- app specific constants and ranges
    constant C_KERNEL_SIZE           : positive := 128;
    constant C_KERNEL_WIDTH          : positive := 16;
    constant C_MAX_SIGNAL_SIZE       : positive := 2**(C_RAM1_ADDR_WIDTH+1);
    constant C_MAX_SIGNAL_SIZE_WIDTH : positive := C_RAM0_RD_SIZE_WIDTH;
    constant C_SIGNAL_WIDTH          : positive := 16;
    constant C_MAX_OUTPUT_SIZE       : positive := C_MAX_SIGNAL_SIZE + C_KERNEL_SIZE - 1;
    constant C_OUTPUT_SIZE_WIDTH     : positive := bitsNeeded(C_MAX_OUTPUT_SIZE);

    subtype KERNEL_SIZE_RANGE is natural range C_KERNEL_SIZE-1 downto 0;
    subtype KERNEL_WIDTH_RANGE is natural range C_KERNEL_WIDTH-1 downto 0;
    subtype MAX_SIGNAL_SIZE_RANGE is natural range C_MAX_SIGNAL_SIZE_WIDTH-1 downto 0;
    subtype SIGNAL_WIDTH_RANGE is natural range C_SIGNAL_WIDTH-1 downto 0;
    subtype OUTPUT_SIZE_RANGE is natural range C_OUTPUT_SIZE_WIDTH-1 downto 0;

    type window is array(integer range<>) of std_logic_vector(SIGNAL_WIDTH_RANGE);

--    constant C_MEM_START_ADDR : std_logic_vector(MMAP_ADDR_RANGE) := (others => '0');
--    constant C_MEM_END_ADDR   : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(unsigned(C_MEM_START_ADDR)+(2**C_MEM_ADDR_WIDTH-1));

    constant C_RAM0_DMA_ADDR      : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-8, C_MMAP_ADDR_WIDTH));
    constant C_RAM1_DMA_ADDR      : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-7, C_MMAP_ADDR_WIDTH));
    constant C_GO_ADDR            : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-6, C_MMAP_ADDR_WIDTH));
    constant C_RST_ADDR           : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-5, C_MMAP_ADDR_WIDTH));
    constant C_KERNEL_LOADED_ADDR : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-4, C_MMAP_ADDR_WIDTH));
    constant C_KERNEL_DATA_ADDR   : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-3, C_MMAP_ADDR_WIDTH));
    constant C_SIGNAL_SIZE_ADDR   : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-2, C_MMAP_ADDR_WIDTH));
    constant C_DONE_ADDR          : std_logic_vector(MMAP_ADDR_RANGE) := std_logic_vector(to_unsigned(2**C_MMAP_ADDR_WIDTH-1, C_MMAP_ADDR_WIDTH));

    constant C_1 : std_logic := '1';
    constant C_0 : std_logic := '0';

end user_pkg;
