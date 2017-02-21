-- Greg Stitt
-- University of Florida
-- EEL 5721/4720 Reconfigurable Computing
--
-- File: wrapper_tb.vhd
--
-- Description: This file implements a testbench for the simple pipeline
-- when running on the ZedBoard. 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity wrapper_tb is
end wrapper_tb;

architecture behavior of wrapper_tb is

    constant TEST_SIZE  : integer := 8;
    constant DMA_SIZE   : integer := integer(ceil(real(TEST_SIZE+C_KERNEL_WIDTH)*real(C_RAM0_RD_DATA_WIDTH)/real(C_DRAM0_DATA_WIDTH)));
    constant MAX_CYCLES : integer := TEST_SIZE*100;

    constant CLK0_HALF_PERIOD : time := 5 ns;

    signal clk0 : std_logic                        := '0';
    signal clk1 : std_logic                        := '0';
    signal clks : std_logic_vector(NUM_CLKS_RANGE) := (others => '0');
    signal rst  : std_logic                        := '1';

    signal mmap_wr_en   : std_logic                         := '0';
    signal mmap_wr_addr : std_logic_vector(MMAP_ADDR_RANGE) := (others => '0');
    signal mmap_wr_data : std_logic_vector(MMAP_DATA_RANGE) := (others => '0');

    signal mmap_rd_en   : std_logic                         := '0';
    signal mmap_rd_addr : std_logic_vector(MMAP_ADDR_RANGE) := (others => '0');
    signal mmap_rd_data : std_logic_vector(MMAP_DATA_RANGE);

    signal sim_done : std_logic := '0';

    constant C_MMAP_CYCLES : positive := 1;

begin

    UUT : entity work.wrapper
        port map (
            clks         => clks,
            rst          => rst,
            mmap_wr_en   => mmap_wr_en,
            mmap_wr_addr => mmap_wr_addr,
            mmap_wr_data => mmap_wr_data,
            mmap_rd_en   => mmap_rd_en,
            mmap_rd_addr => mmap_rd_addr,
            mmap_rd_data => mmap_rd_data);

    -- toggle clock
    clk0    <= not clk0 after 5 ns when sim_done = '0' else clk0;
    clk1    <= not clk1 after 3 ns when sim_done = '0' else clk1;
    clks(0) <= clk0;
    clks(1) <= clk1;

    -- process to test different inputs
    process

        -- function to check if the outputs is correct
        function checkOutput (
            i : integer)
            return integer is

        begin
            return i+1;
        end checkOutput;

        procedure clearMMAP is
        begin
            mmap_rd_en <= '0';
            mmap_wr_en <= '0';
        end clearMMAP;

        variable errors       : integer := 0;
        variable total_points : real    := 50.0;
        variable min_grade    : real    := total_points*0.25;
        variable grade        : real;

        variable result : std_logic_vector(C_MMAP_DATA_WIDTH-1 downto 0);
        variable done   : std_logic;
        variable count  : integer;

    begin

        -- reset circuit  
        rst <= '1';
        clearMMAP;
--        wait for 500 ns;
        for i in 0 to 20 loop
            wait until rising_edge(clk0);
        end loop;

        rst <= '0';
        for i in 0 to 20 loop
            wait until rising_edge(clk0);
        end loop;

        -- configure DMA to write to RAM0 through memory map
        mmap_wr_addr                                                    <= C_RAM0_DMA_ADDR;
        mmap_wr_en                                                      <= '1';
        mmap_wr_data                                                    <= (others => '0');
        mmap_wr_data(C_RAM0_WR_SIZE_WIDTH+C_RAM0_ADDR_WIDTH-1 downto 0) <= std_logic_vector(to_unsigned(DMA_SIZE, C_RAM0_WR_SIZE_WIDTH) & to_unsigned(0, C_RAM0_ADDR_WIDTH));

        for i in 0 to 20 loop
            wait until rising_edge(clk0);
            clearMMAP;
        end loop;

        -- write contents to input ram, which starts at addr 0
        for i in 0 to DMA_SIZE-1 loop
            mmap_wr_addr <= std_logic_vector(to_unsigned(i, C_MMAP_ADDR_WIDTH));
            mmap_wr_en   <= '1';
            mmap_wr_data <= std_logic_vector(to_unsigned(i, C_MMAP_DATA_WIDTH/2) & to_unsigned(i+1, C_MMAP_DATA_WIDTH/2));

            for j in 0 to C_MMAP_CYCLES-1 loop
                wait until rising_edge(clk0);
                clearMMAP;
            end loop;
        end loop;

        -- send size
        mmap_wr_addr <= C_SIGNAL_SIZE_ADDR;
        mmap_wr_en   <= '1';
        mmap_wr_data <= std_logic_vector(to_unsigned(TEST_SIZE, C_MMAP_DATA_WIDTH));
        wait until rising_edge(clk0);
        clearMMAP;

        for i in 0 to C_KERNEL_SIZE-1 loop
            -- send kernel
            mmap_wr_addr <= C_KERNEL_DATA_ADDR;
            mmap_wr_en   <= '1';
            mmap_wr_data <= std_logic_vector(to_unsigned(1, C_MMAP_DATA_WIDTH));
            wait until rising_edge(clk0);
            clearMMAP;
        end loop;

        -- send go = 1 over memory map
        mmap_wr_addr <= C_GO_ADDR;
        mmap_wr_en   <= '1';
        mmap_wr_data <= std_logic_vector(to_unsigned(1, C_MMAP_DATA_WIDTH));
        wait until rising_edge(clk0);
        clearMMAP;

        done  := '0';
        count := 0;

        -- read the done signal every cycle to see if the circuit has
        -- completed.
        --
        -- equivalent to wait until (done = '1') for TIMEOUT;      
        while done = '0' and count < MAX_CYCLES loop

            mmap_rd_addr <= C_DONE_ADDR;
            mmap_rd_en   <= '1';

            for j in 0 to C_MMAP_CYCLES-1 loop
                wait until rising_edge(clk0);
                clearMMAP;
            end loop;

            -- give entity one cycle to respond
            wait until rising_edge(clk0);

            done  := mmap_rd_data(0);
            count := count + 1;
        end loop;

        if (done /= '1') then
            errors := errors + 1;
            report "Done signal not asserted before timeout.";
        end if;


        -- configure DMA to read from RAM1 through memory map
        mmap_wr_addr                                                    <= C_RAM1_DMA_ADDR;
        mmap_wr_en                                                      <= '1';
        mmap_wr_data                                                    <= (others => '0');
        mmap_wr_data(C_RAM1_RD_SIZE_WIDTH+C_RAM1_ADDR_WIDTH-1 downto 0) <= std_logic_vector(to_unsigned(DMA_SIZE, C_RAM1_RD_SIZE_WIDTH) & to_unsigned(0, C_RAM1_ADDR_WIDTH));
        wait until rising_edge(clk0);
        clearMMAP;
        for i in 0 to 20 loop
            wait until rising_edge(clk0);
        end loop;


        -- read outputs from output memory
        for i in 0 to DMA_SIZE-1 loop
            mmap_rd_addr <= std_logic_vector(to_unsigned(i, C_MMAP_ADDR_WIDTH));
            mmap_rd_en   <= '1';
            wait until rising_edge(clk0);
            clearMMAP;
            -- give entity one cycle to respond
            wait until rising_edge(clk0);

            -- TODO: check output
           
            for j in 0 to C_MMAP_CYCLES-1 loop
                wait until rising_edge(clk0);
                clearMMAP;
            end loop;

        end loop;  -- i

        report "SIMULATION FINISHED!!!";
        sim_done <= '1';
        wait;

    end process;
end behavior;
