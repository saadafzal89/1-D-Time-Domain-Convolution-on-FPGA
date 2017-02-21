-- Author: Vyas Sundaresh Kovakkat
--         Saad Afzal
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.user_pkg.all;
 
entity Address_Generator is
    port(
        clk,rst		: in std_logic;
		start 		: in std_logic;					 
		size		: in std_logic_vector(RAM0_RD_SIZE_RANGE);
		start_addr	: in std_logic_vector(C_RAM0_ADDR_WIDTH-1 downto 0);
        raddr       : out std_logic_vector(C_RAM0_ADDR_WIDTH-1 downto 0);
		gen_ack 	: out std_logic;
		clear       : in std_logic;
		valid       : out std_logic;
		stall       : in std_logic;
		flush_data  : out std_logic
        );
end Address_Generator;
 
architecture Address_Arch of Address_Generator is
  type state_type is (S_INIT, S_EXECUTE,S_DONE);
  signal state, next_state : state_type;
  signal size_reg, next_size_reg : unsigned(RAM0_RD_SIZE_RANGE);
  signal address, next_address     : std_logic_vector(C_RAM0_ADDR_WIDTH-1 downto 0);
begin

  process (clk, rst)
  begin
    if (rst = '1') then
      address   <= (others => '0');
      size_reg <= (others => '0');
      state    <= S_INIT;
    elsif (clk'event and clk = '1') then
      address   <= next_address;
      size_reg <= next_size_reg;
      state    <= next_state;
    end if;
  end process;

  process(address, size_reg, size, state, start, stall)
  begin

    next_state    <= state;
    next_address  <= address;
    next_size_reg <= size_reg;
	flush_data    <= '0';
	valid    <= '0';
	gen_ack       <= '0';
    case state is
      when S_INIT =>
        next_address <= start_addr;
        if (start = '1') then
          next_size_reg <= unsigned(size)+ unsigned(start_addr)+to_unsigned(1,C_RAM0_ADDR_WIDTH);
          next_state    <= S_EXECUTE;
		  gen_ack       <='1';
        end if;
		if clear = '1' then 
			flush_data <= '1';
		end if;
      when S_EXECUTE =>
        valid <= '1';
        if (unsigned(address) = (size_reg/2)-1) then
          next_state  <= S_DONE;
        elsif (stall = '0') then
          next_address <= std_logic_vector(unsigned(address)+1);
        elsif (stall = '1') then
         valid <= '0';
        end if;
	  WHEN S_DONE =>
		if clear = '1' then 
			flush_data <= '1';
			next_state <= S_INIT;
		end if;
      when others => null;
    end case;
  end process;
  
  raddr <= address(C_RAM0_ADDR_WIDTH-1 downto 0);
end Address_Arch;