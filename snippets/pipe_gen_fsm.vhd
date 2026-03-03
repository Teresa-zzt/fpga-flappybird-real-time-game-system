-- Portfolio Snippet: Pipe Spawn Orchestration FSM
-- Context: Hardware-based Flappy Bird implementation (VHDL on Cyclone V FPGA)
-- Role: Determines pacing and activation order of multiple pipe entities.
-- Key ideas:
--   - Moore-style FSM controlling spawn/enable chaining
--   - checkpoint-driven transitions (deterministic spacing)
--   - dead signal triggers transition to death_screen
-- Authorship: Implemented by Teresa Zhang (university group project; snippet extracted for portfolio)

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;

entity pipe_gen is 
	port( clk, pb1, pb2 , dead, checkpoint, reset   : in std_logic;
     		Enable_pipe, Enable_pipe2, Enable_pipe3, Enable_pipe4, start : out std_logic);
end entity pipe_gen;

architecture behaviour of pipe_gen is 
	type state_type is (start_screen, pipe1, pipe2, pipe3, pipe4, death_screen);
	signal state, next_state: state_type := start_screen;
begin 
	SYNC_PROC : process (clk) 
		begin
		if(rising_edge(clk)) then
			if reset = '1' then
				state <= start_screen;
			else 
				state <= next_state;
			end if;
		end if;
	end process;
	
	DECODE_OUTPUT : process (state)
		begin 
		Enable_pipe  <= '0';
		Enable_pipe2 <= '0';
		Enable_pipe3 <= '0';
		Enable_pipe4 <= '0';
		start <= '0';
		case(state) is 
		 when start_screen => 
			if (pb2 = '1' and pb1 = '0') then 
				Enable_pipe <= '1';
				start <= '1';
			end if;
		 when pipe1 => 
			if (checkpoint = '1') then 
				 Enable_pipe2 <= '1';
				 Enable_pipe <= '0';
			end if;
		 when pipe2 => 
			if (checkpoint = '1') then 
				 Enable_pipe2 <= '0';
				 Enable_pipe3 <= '1';
			end if;
		 when pipe3 => 
			if (checkpoint = '1') then 
				 Enable_pipe3 <= '0';
				 Enable_pipe4 <= '1';
			end if;
		 when pipe4 => 
			if (checkpoint = '1') then 
				 Enable_pipe4 <= '0';			
				 Enable_pipe <= '1';
			end if;
		when others => Enable_pipe <= '0'; Enable_pipe2 <= '0'; Enable_pipe3 <= '0'; Enable_pipe4 <= '0';
		end case;
	end process DECODE_OUTPUT;
	
	NEXT_STATE_DECODER : process (state, checkpoint, pb2)
	begin 
	next_state <= start_screen;
	case (state) is 
		when start_screen => 
			if (pb2 = '1' and pb1 = '0') then 
				next_state <= pipe1;
			end if;
		when pipe1 => 
			if (checkpoint = '1') then
				next_state <= pipe2;
			elsif (dead ='1') then
				next_state <= death_screen;
			end if;
		when pipe2 => 
			if (checkpoint = '1') then
				next_state <= pipe3;
			elsif (dead ='1') then
				next_state <= death_screen;
			end if;
		when pipe3 => 
			if (checkpoint = '1') then
				next_state <= pipe4;
			elsif (dead ='1') then
				next_state <= death_screen;
			end if;
		when pipe4 => 
			if (checkpoint = '1') then
				next_state <= pipe1;
			elsif (dead ='1') then
				next_state <= death_screen;
			end if;
		when others => next_state <= start_screen;
		end case; 
	end process NEXT_STATE_DECODER;
end architecture behaviour;

