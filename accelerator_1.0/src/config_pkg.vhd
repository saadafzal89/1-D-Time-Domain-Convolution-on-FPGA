-- Greg Stitt
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package config_pkg is

    constant C_NUM_CLKS        : natural  := 4;
    constant C_CLK_USER : integer := 0;
    constant C_CLK_DRAM : integer := 1;
    subtype NUM_CLKS_RANGE is natural range C_NUM_CLKS-1 downto 0;    
    
    constant C_MMAP_ADDR_WIDTH : positive := 18;
    constant C_MMAP_DATA_WIDTH : positive := 32;

    subtype MMAP_ADDR_RANGE is natural range C_MMAP_ADDR_WIDTH-1 downto 0;
    subtype MMAP_DATA_RANGE is natural range C_MMAP_DATA_WIDTH-1 downto 0;

    constant C_DRAM0_ADDR_WIDTH : positive := 15;
    constant C_DRAM0_DATA_WIDTH : positive := 32;
    constant C_DRAM0_SIZE_WIDTH : positive := C_DRAM0_ADDR_WIDTH+1;
    constant C_DRAM1_ADDR_WIDTH : positive := 15;
    constant C_DRAM1_DATA_WIDTH : positive := 32;
    constant C_DRAM1_SIZE_WIDTH : positive := C_DRAM1_ADDR_WIDTH+1;
    constant C_RAM_CLEAR_CYCLES : positive := 10;
   
    subtype DRAM0_ADDR_RANGE is natural range C_DRAM0_ADDR_WIDTH-1 downto 0;
    subtype DRAM0_DATA_RANGE is natural range C_DRAM0_DATA_WIDTH-1 downto 0;
    subtype DRAM0_SIZE_RANGE is natural range C_DRAM0_SIZE_WIDTH-1 downto 0;
    subtype DRAM1_ADDR_RANGE is natural range C_DRAM1_ADDR_WIDTH-1 downto 0;
    subtype DRAM1_DATA_RANGE is natural range C_DRAM1_DATA_WIDTH-1 downto 0;
    subtype DRAM1_SIZE_RANGE is natural range C_DRAM1_SIZE_WIDTH-1 downto 0;

    constant C_MAX_FIFO_DELAY : positive := 5;
    
end config_pkg;
