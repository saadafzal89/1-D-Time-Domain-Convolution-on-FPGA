library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
use work.config_pkg.all;
use work.user_pkg.all;
 
entity Address_Generator_tb is
end Address_Generator_tb;
 
architecture Address_BHV_TB of Address_Generator_tb is
	signal clk 			: std_logic := '0';
    	signal rst 			: std_logic := '1';
	signal en 			: std_logic := '1';
	signal size 		: std_logic_vector(RAM0_RD_SIZE_RANGE) := (others => '0');
	signal raddr		: std_logic_vector(C_RAM0_ADDR_WIDTH-1 downto 0) := (others => '0');
    	signal start_addr   : std_logic_vector(C_RAM0_ADDR_WIDTH-1 downto 0) := (others => '0');
	signal gen_ack 			: std_logic ;
	signal clear 			: std_logic ;
	signal valid       : std_logic;
	signal stall       : std_logic;
	signal flush_data  : std_logic;
begin
    UUT : entity work.Address_Generator
        port map (
            clk          => clk,
            rst          => rst,
            size   		 => size,
            start 		 => en,
            raddr 		 => raddr,
            start_addr   => start_addr,
			clear        => clear,
			gen_ack 	=> gen_ack,
	    valid  => valid,
	    stall  => stall,
	    flush_data => flush_data
);	
			
			
	clk <= not clk after 20 ns;
	process
	begin
		rst <= '1';
		wait for 200 ns;
		rst <= '0';
		en <= '0';
		wait until clk'event and clk = '1';
		size <= std_logic_vector(to_unsigned(10, C_RAM0_RD_SIZE_WIDTH));
		start_addr <= std_logic_vector(to_unsigned(10, C_RAM0_ADDR_WIDTH));
		en<='1';
		stall <='0';
		wait until gen_ack = '0';
		en<='0';
		rst<='0';
		clear <='1';
		wait until clk'event and clk = '1';
		
		size <= std_logic_vector(to_unsigned(20, C_RAM0_RD_SIZE_WIDTH));
		start_addr <= std_logic_vector(to_unsigned(10, C_RAM0_ADDR_WIDTH));
		en<='1';
	wait;
	end process;
end Address_BHV_TB;