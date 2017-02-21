-- Author: Vyas Sundaresh Kovakkat
--         Saad Afzal
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.user_pkg.all;
 
entity my_dram0 is
    port(
        dram_clk			: in std_logic;
		rst					: in std_logic;
		user_clk			: in std_logic;
		go 					: in std_logic;
		size				: in std_logic_vector(RAM0_RD_SIZE_RANGE);
		start_addr			: in std_logic_vector(C_RAM0_ADDR_WIDTH-1 downto 0);
        raddr       		: out std_logic_vector(C_RAM0_ADDR_WIDTH-1 downto 0);
		rd_en 				: in std_logic;
		done 				: out STD_LOGIC;
		clear			    : in std_logic;
		stall               : in std_logic;
		valid               : out std_logic;
		
		dram_ready			: in std_logic;
		dram_rd_en 			: out STD_LOGIC;
		dram_rd_flush 		: out STD_LOGIC;
		dram_rd_valid       : in std_logic;
		dram_rd_data        : in std_logic_vector(31 downto 0);
		dataout             : out std_logic_vector(15 downto 0)
        );
end my_dram0;
 
architecture DMA_Arch of my_dram0 is 
signal delay_ack_entity : std_logic;
signal datain : std_logic_vector(31 downto 0);
signal rcv : std_logic;
signal empty : std_logic;
signal ack : std_logic;
signal start_add_gen : std_logic;
signal address_gen_stall : std_logic;
signal dram_rd_flush_in : std_logic;

component fifo_generator_0 is
  Port ( 
    rst : in STD_LOGIC;
    wr_clk : in STD_LOGIC;
    rd_clk : in STD_LOGIC;
    din : in STD_LOGIC_VECTOR ( 31 downto 0 );
    wr_en : in STD_LOGIC;
    rd_en : in STD_LOGIC;
    dout : out STD_LOGIC_VECTOR ( 15 downto 0 );
    full : out STD_LOGIC;
    empty : out STD_LOGIC;
    prog_full : out STD_LOGIC
  );
end component fifo_generator_0;


begin
	U_COUNT : entity work.COUNTER
	port map(
		clk			=> user_clk,
		rst			=> rst,
		clear       => clear,
		size		=> size,
		rd_en 		=> rd_en,
		done 		=> done
	);
	
	U_SYNC : entity work.handshake
	port map (
		clk_src   => user_clk,
		clk_dest  => dram_clk,
		rst       => rst,
		delay_ack => delay_ack_entity,
		go        => go,
		rcv       => rcv,
		ack       => ack
	);
	
	start_add_gen <= rcv and dram_ready;
	
	U_GEN : entity work.Address_Generator
	port map (
		clk	   		=> dram_clk,				-- DRAM Clock Singal
		rst	   		=> rst,
		start  		=> start_add_gen,			-- Start Address gen
		size   		=> size,					--  Size of Memory Block
		start_addr	=> start_addr,				--  Start Address of Memory Block
        raddr  		=> raddr,					--  Address generator
		gen_ack     => delay_ack_entity,		-- Acknowledgement signal
		clear  		=> clear,
		valid       => dram_rd_en,
		flush_data  => dram_rd_flush,
		stall       => address_gen_stall	
	);      	
	
	
	U_FIFO: fifo_generator_0
	port map (
		rst 		=> rst,
		wr_clk 		=> dram_clk,
		rd_clk 		=> user_clk,
		din(15 DOWNTO 0) 		=> dram_rd_data(31 DOWNTO 16),
		din(31 DOWNTO 16) 		=> dram_rd_data(15 DOWNTO 0),
		wr_en 		=> dram_rd_valid,
		rd_en 		=> rd_en,
		dout        => dataout,
		full 		=> open,
		prog_full   => address_gen_stall,
		empty 		=> empty
	);

	valid <= not empty;
end DMA_Arch;