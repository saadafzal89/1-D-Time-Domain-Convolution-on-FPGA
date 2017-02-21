-- Author: Vyas Sundaresh Kovakkat
--         Saad Afzal
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.user_pkg.all;

entity COUNTER is
port(
    clk,rst		: in std_logic;
	clear       : in std_logic;
	size		: in std_logic_vector(RAM0_RD_SIZE_RANGE);
	rd_en 		: in std_logic;
	done 		: out std_logic
);
end COUNTER;


architecture Counter_Arch of COUNTER is 

  type STATE_TYPE is (S_START, S_COUNT, S_DONE);
  signal state, next_state : STATE_TYPE;
  signal   count, next_count : unsigned(C_RAM0_ADDR_WIDTH+1 downto 0);
  signal finaladdr : unsigned(C_RAM0_ADDR_WIDTH+1 downto 0);
begin

  process (clk, rst)
  begin
    if (rst = '1') then
      state <= S_START;
	  count <= (others => '0');
    elsif (clk = '1' and clk'event) then
      state <= next_state;
      count <= next_count;
    end if;
  end process;

  process(rd_en, state, count)
  begin

    case state is
      when S_START =>

        done       <= '0';
        next_count <= to_unsigned(1, count'length);

        if (rd_en = '0') then
          next_state <= S_START;
        else
          next_state <= S_COUNT;
        end if;

      when S_COUNT =>

        done       <= '0';
        next_count <= count + 1;

        if (count = (unsigned(size)/2)-1) then
          next_state <= S_DONE;
		  done       <= '1';
        else
          next_state <= S_COUNT;
        end if;

      when S_DONE =>

        next_count <= (unsigned(size)/2);
        done       <= '1';
		if clear = '1' then
			next_state <= S_START;
		else
			next_state <= S_DONE;
		end if;
      when others => null;
    end case;

  end process;
end Counter_Arch;