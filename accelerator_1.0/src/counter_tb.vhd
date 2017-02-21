library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
use work.config_pkg.all;
use work.user_pkg.all;
 
entity COUNTER_tb is
end COUNTER_tb;
 
architecture counter_tb_arch of COUNTER_tb is
	signal clk 			: std_logic := '0';
    signal rst 			: std_logic := '1';
	signal size 		: std_logic_vector(RAM0_RD_SIZE_RANGE) := (others => '0');
    signal rd_en 		: std_logic := '0';
	signal done 		: std_logic ;
	signal clear 		: std_logic ;
begin
	UUT : entity work.COUNTER
		port map(
			clk 	=> clk,
			rst		=> rst,
			clear   => clear,
			size	=> size,
			rd_en 	=> rd_en,
			done 	=> done
		);
	clk <= not clk after 20 ns;
	process
	begin
		rst <= '1';
		clear <= '1';
		wait for 100 ns;
		rst <= '0';
		wait until clk'event and clk = '1';
		size <= std_logic_vector(to_unsigned(10,C_RAM0_RD_SIZE_WIDTH));
		clear <= '0';
		for i in 1 to 11 loop
			rd_en <= '1';
			wait until clk'event and clk = '1';
			rd_en <= '0';
			wait until clk'event and clk = '1';
		end loop;
		--wait until done = '1';
		wait until clk'event and clk = '1';
		 rst <= '1';
		 clear <= '1';
		wait for 100 ns;
	wait;
	end process;
end counter_tb_arch;