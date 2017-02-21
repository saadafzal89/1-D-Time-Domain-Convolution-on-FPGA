-- Author: Vyas Sundaresh Kovakkat
--         Saad Afzal
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl is
    port(clk          : in  std_logic;
         rst          : in  std_logic;
         go           : in  std_logic;
         mem_in_go    : out std_logic;
         mem_out_go   : out std_logic;
         mem_in_clear : out std_logic;
         mem_out_clear : out std_logic;
         mem_out_done : in  std_logic;
         done         : out std_logic);
end ctrl;

architecture bhv of ctrl is

    type STATE_TYPE is (S_WAIT_0, S_WAIT_1, S_WAIT_DONE);
    signal state, next_state   : STATE_TYPE;
    signal done_s, next_done_s : std_logic;

begin

    process(clk, rst)
    begin
        if (rst = '1') then
            state  <= S_WAIT_0;
            done_s <= '0';
        elsif (clk = '1' and clk'event) then
            state  <= next_state;
            done_s <= next_done_s;
        end if;
    end process;

    process(go, state, done_s, mem_out_done)
    begin

        -- defaults
        done        <= done_s;
        next_done_s <= done_s;
        next_state  <= state;

        mem_in_go     <= '0';
        mem_out_go    <= '0';
        mem_in_clear  <= '0';
        mem_out_clear <= '0';

        case state is
            when S_WAIT_0 =>

                mem_in_clear  <= '1';
                mem_out_clear <= '1';

                if (go = '0') then
                    next_state <= S_WAIT_1;
                end if;

            when S_WAIT_1 =>

                if (go = '1') then
                    mem_in_go   <= '1';
                    mem_out_go  <= '1';
                    next_done_s <= '0';
                    done        <= '0';  -- make sure done updated immediately
                    next_state  <= S_WAIT_DONE;
                end if;

            when S_WAIT_DONE =>

                if (mem_out_done = '1') then
                    next_done_s <= '1';  -- could potentially update done also
                                         -- if we don't want to wait one cycle
                    next_state  <= S_WAIT_0;
                end if;

            when others => null;
        end case;
    end process;
end bhv;
