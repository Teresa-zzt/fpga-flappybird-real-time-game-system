-- Portfolio Snippet: Top-Level Game State Controller (Moore FSM + UI Click Routing)
-- Context: Hardware-based Flappy Bird implementation (VHDL on Cyclone V FPGA)
--
-- Role in architecture:
--   - Acts as the central game state manager: Main Menu -> Playing -> Death Menu
--   - Selects RGB output source per state (menu/play/death) via deterministic muxing
--   - Gates gameplay enable (Enable_p) so score/life systems reset cleanly between runs
--   - Routes PS/2 mouse click regions into semantic actions:
--       * Start + gamemode selection in Main Menu
--       * Retry / Back-to-main actions in Death Menu
--
-- Key systems concepts demonstrated:
--   - Deterministic state transitions (dead-driven transition into Death Menu)
--   - Separation of concerns: state orchestration vs. per-entity behavior
--   - Input-to-intent mapping (click areas -> state transitions)
--
-- Authorship: Implemented by Teresa Zhang (university group project; snippet extracted for portfolio)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;

entity control is 
port( clk : IN std_logic;
		reset : IN std_logic; 
		dead : IN std_logic; 
		RGB_mm : IN std_logic_vector(11 downto 0);
		RGB_p : IN std_logic_vector(11 downto 0);
		RGB_dm : IN std_logic_vector(11 downto 0);
		right_click,mouse_click : IN std_logic;
		mouse_row, mouse_column : IN std_logic_vector(9 downto 0);
		Enable_p : OUT std_logic;
		Gamemode_out : OUT std_logic;
		RGB_out : OUT std_logic_vector(11 downto 0); 
		dead_out : out std_logic; 
		retry_out : out std_logic; 
		back_to_main_out : out std_logic;
		gamemode_debug : out std_logic;
		in_dead : out std_logic;
		in_playing : out std_logic);
end entity control;

architecture beh of control is 
	type state_type is (main_menu,playing,death_menu);
	signal state, next_state: state_type;
	signal start,retry, back_to_main,Enable_dm,Enable_mm: std_logic;
begin 
	SYNC : process (clk) 
		begin
		if(rising_edge(clk)) then
			if (reset = '0') then
				state <= main_menu;
			else 
				state <= next_state;
			end if;
		end if;
	end process;
	
	output : process (clk) 
		begin
		case(state) is
		when main_menu =>
		Enable_dm <= '0';
			RGB_out <= RGB_mm; 
				in_dead <= '0';
				in_playing <= '0';
				Enable_p <= '0';
				
		when playing =>
		Enable_dm <= '0';
			in_dead <= '0';
			in_playing <= '1';
			RGB_out <= RGB_p;
		
			if (right_click = '1') then
				Enable_p <= '1';
			elsif (reset = '0') then
				Enable_p <= '0';
			end if;

		when death_menu =>
		Enable_dm <= '1';
				RGB_out <= RGB_dm;
				Enable_p <= '0';
				in_dead <= '1';
				in_playing <= '0';
				
		end case;
	end process;

	Next_state_proc : process (state,dead,start,retry,back_to_main) 
	begin
	case(state) is
		when main_menu =>
			if(start = '1') then
				next_state <= playing;
			else 
				next_state <= main_menu;
			end if;
		when playing =>
			if (dead = '1') then
				next_state <= death_menu;
			else
				next_state <= playing;
			end if;
		when death_menu =>
			if(retry ='1') then
				next_state <= playing;
			elsif (back_to_main = '1') then 
				next_state <= main_menu;
			else
				next_state <= death_menu;
			end if;
		when others =>
			next_state <= state;
		end case;
	end process;
	
button_pressed_main : process (mouse_row, mouse_column,mouse_click)

 begin
  
	if((298 <= mouse_row) and ( mouse_row < 318) and (400 <= mouse_column) and (mouse_column < 496)) and ( mouse_click = '1' )then
			Gamemode_out <= '0'; 
			gamemode_debug <= '0';
			start <= '1';
	elsif((298 <= mouse_row) and ( mouse_row < 318) and (142 <= mouse_column) and (mouse_column < 274) ) and (mouse_click = '1') then
			Gamemode_out <= '1';
			gamemode_debug <= '1';	
			start <= '1';
	else 
			start <= '0';
	end if;



end process button_pressed_main;
 
button_pressed_death : process (mouse_row, mouse_column,mouse_click)

 begin
 if Enable_dm = '1' then
	if((348 <= mouse_row) and ( mouse_row < 368) and (334 <= mouse_column) and (mouse_column < 482)) and ( mouse_click = '1' )then
		back_to_main <= '1';
	elsif((348 <= mouse_row) and ( mouse_row < 368) and (158 <= mouse_column) and (mouse_column < 242) ) and (mouse_click = '1') then
		retry <= '1';
	else 
		retry <= '0';
      back_to_main <= '0';
	end if;
else
      retry <= '0';
      back_to_main <= '0';
end if;

end process button_pressed_death;
	
	   dead_out  <= dead;
		retry_out <= retry;
		back_to_main_out <= back_to_main;
	
end architecture beh;