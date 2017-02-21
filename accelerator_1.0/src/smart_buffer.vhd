-- Author: Saad Afzal
--         Vyas Sundaresh Kovakkat
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity smart_buffer is
	port(
		clk		: in std_logic;
		rst 	: in std_logic;
		
		--input ports 
		wr_en 	: in std_logic;
		wr_data : in std_logic_vector(C_KERNEL_WIDTH-1 downto 0);
		rd_en 	: in std_logic;
		
		--output ports
		full_flag		: out std_logic;
		empty_flag		: out std_logic;
		rd_data_smart 	: out std_logic_vector((C_KERNEL_SIZE * C_KERNEL_WIDTH)-1 downto 0)
);
end smart_buffer;

architecture smart_buf of smart_buffer is
	signal regs			:	window (0 to C_KERNEL_SIZE-1);
	signal count		:	std_logic_vector(7 downto 0);
begin
	process(clk, rst)
	variable count_temp : integer;
	begin
		if(rst ='1') then 
			for i in 0 to 127 loop 
				regs(i) <= (others => '0');
			end loop;
			count <= (others => '0');
			
		elsif(clk'event and clk = '1') then
			count_temp := to_integer(unsigned(count));
			
			--reading data into rightmost register of the window
			if(wr_en='1') then
					regs(127) <= wr_data;
					count_temp := count_temp+1;
					for j in 0 to 126 loop
						regs(j) <= regs(j+1);
					end loop;
			end if;
			
			if(rd_en='1')then
					for i in 0 to 127 loop
						rd_data_smart((((C_KERNEL_SIZE-i)* C_KERNEL_WIDTH)-1) downto ((C_KERNEL_SIZE-(i+1))* C_KERNEL_WIDTH)) <= regs(i);
					end loop;
					count_temp := count_temp-1;
			end if;
			
			--shifting value of registers to the left by 1;
			count <= std_logic_vector(to_unsigned(count_temp,8));
		end if;
	end process;
	
	process(wr_en, rd_en, count)
	begin
		if(unsigned(count) = to_unsigned(128, 8) and rd_en='1' and wr_en = '1') then
			full_flag <= '0';
			empty_flag <= '0';
		elsif(unsigned(count) = to_unsigned(128, 8))then
			full_flag <= '1';
			empty_flag <= '0';			
		elsif(unsigned(count) < to_unsigned(128, 8)) then
			empty_flag <= '1';
			full_flag  <= '0';
		end if;
		
	end process;
end smart_buf;