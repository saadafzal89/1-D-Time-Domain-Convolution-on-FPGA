-- Author: Vyas Sundaresh Kovakkat
--         Saad Afzal
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;

entity handshake is
  port (
    clk_src   : in  std_logic;
    clk_dest  : in  std_logic;
    rst       : in  std_logic;
    go        : in  std_logic;
    delay_ack : in  std_logic;
    rcv       : out std_logic;
    ack       : out std_logic
    );
end handshake;

architecture TRANSITIONAL of handshake is

  type state_type is (S_READY, S_WAIT_FOR_ACK, S_RESET_ACK, S_DELAY, S_DELAY1);
  type state_type2 is (S_READY, S_SEND_ACK, S_RESET_ACK, S_DELAY, S_DELAY1);
  signal state_src   : state_type;
  signal state_dest : state_type2;
  signal rcv_signal : std_logic;
  signal send_s, ack_s : std_logic;
  signal send_s_in,send_s_out,ack_s_in,ack_s_out : std_logic_vector(0 downto 0);
begin

  -----------------------------------------------------------------------------
  -- State machine in source domain that sends to dest domain and then waits
  -- for an ack
  
  process(clk_src, rst)
  begin
    if (rst = '1') then
      state_src <= S_READY;
      send_s    <= '0';
      ack       <= '0';
    elsif (rising_edge(clk_src)) then
      ack    <= '0';
      case state_src is
        when S_READY =>
          if (go = '1') then
            send_s         <= '1';
            state_src <= S_WAIT_FOR_ACK;
          end if;
			
		--adding delay of 1 cycle for ack_s value to settle
		when S_WAIT_FOR_ACK =>
			if (ack_s_out(0) = '1') then 
			    send_s <= '0';
                state_src <= S_RESET_ACK;
            end if;
			
        --adding delay of 1 cycle for ack_s value to settle 
		when S_RESET_ACK =>
			if (ack_s_out(0) = '0') then
                ack            <= '1';
                state_src <= S_READY;
            end if;
        when others => null;
      end case;
    end if;
  end process;
  send_s_in <= (others => send_s);
  
  U_SEND_DELAY : entity work.delay
          generic map(cycles => 2,
                  width =>     1,
                  init  =>  "0")
          port map( clk  => clk_dest,    
                  rst      => rst,
                  en       => '1',
                  input    => send_s_in,
                  output   => send_s_out);
  

  -----------------------------------------------------------------------------
  -- State machine in dest domain that waits for source domain to send signal,
  -- which then gets acknowledged

  process(clk_dest, rst)
  begin
    if (rst = '1') then
      state_dest <= S_READY;
      ack_s      <= '0';
      rcv <= '0';
    elsif (rising_edge(clk_dest)) then
      rcv <= '0';
      case state_dest is
		  
		--adding delay of 1 cycle for send_s value to settle   
		when S_READY =>
			if (send_s_out(0) = '1') then
                rcv        <= '1';
                state_dest <= S_SEND_ACK;
            end if;
		when S_SEND_ACK =>
          -- send ack unless it is delayed
          if (delay_ack = '0') then
            ack_s      <= '1';
            state_dest <= S_RESET_ACK;
          end if;
		  
        --adding delay of 1 cycle for send_s value to settle    
		when S_RESET_ACK =>
			if (send_s_out(0) = '0') then
                ack_s      <= '0';
                state_dest <= S_READY;
            end if;
        when others => null;
      end case;
    end if;
  end process;
  
  ack_s_in <= (others => ack_s);
  
  U_ACK_DELAY : entity work.delay
            generic map(cycles => 2,
                width =>   1,
                init  =>  "0")
            port map( clk  => clk_src,    
                    rst      => rst,
                    en       => '1',
                    input    => ack_s_in,
                    output   => ack_s_out);
end TRANSITIONAL;