-- Author: Saad Afzal
--         Vyas Sundaresh Kovakkat
-- University of Florida

-- Kernel Buffer Entity
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity kernel_buffer is
	port(
		clk		: in std_logic;
		rst 	: in std_logic;
		
		--input ports 
		kernel_load : in std_logic;
		kernel_data : in std_logic_vector(KERNEL_WIDTH_RANGE);
		
		--output ports
		full_flag		: out std_logic;
		kernel_rd_data 	: out std_logic_vector((C_KERNEL_SIZE * C_KERNEL_WIDTH)-1 downto 0)
);
end kernel_buffer;


architecture kernel_buf of kernel_buffer is
	signal regs			:	window (0 to 127);
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
			if(kernel_load='1') then
					regs(127) <= kernel_data;
					count_temp := count_temp+1;
					for j in 0 to 126 loop
						regs(j) <= regs(j+1);
					end loop;
			end if;
			
			for i in 0 to 127 loop
					kernel_rd_data((((C_KERNEL_SIZE-i)* C_KERNEL_WIDTH)-1) downto ((C_KERNEL_SIZE-(i+1))* C_KERNEL_WIDTH)) <= regs((C_KERNEL_SIZE-i)-1);
			end loop;
			
			--shifting value of registers to the left by 1;
			
			count <= std_logic_vector(to_unsigned(count_temp,8));
		end if;
	end process;
	
	process(count)
	begin
		if(unsigned(count) = to_unsigned(128, 8)) then
			full_flag <= '1';
		else 
			full_flag <= '0';
		end if;
			
	end process;
end kernel_buf;