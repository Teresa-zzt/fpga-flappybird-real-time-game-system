-- Portfolio Snippet: Gameplay System Top-Level Orchestrator
-- Context: Hardware-based Flappy Bird implementation (VHDL on Cyclone V FPGA)
--
-- Role in architecture:
--   - Integrates core gameplay subsystems:
--       * Player entity (bouncy_ball)
--       * Multi-pipe obstacle system (pipes x3)
--       * Collectible system (gift x3)
--       * Procedural variation (LFSR)
--       * Score/life text rendering
--       * Sprite ROM and character ROM
--       * Seven-segment timer display
--
--   - Implements entity interaction wiring:
--       * Aggregates score triggers across pipe instances
--       * Merges gift effects from multiple sources
--       * Gates player enable based on multi-pipe collision checks
--
--   - Coordinates procedural regeneration:
--       * Reassigns randomized pipe heights when entities recycle
--
-- Key systems concepts demonstrated:
--   - Modular entity composition (multiple pipe/gift instances)
--   - Deterministic frame-based simulation via vert_sync
--   - Event aggregation (score_up OR chaining)
--   - System-level signal orchestration (collision gating + difficulty scaling)
--   - Top-level separation of rendering and gameplay logic
--
-- Authorship: Major system integration and signal orchestration implemented by Teresa Zhang
-- (University group project; snippet extracted for portfolio)

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_arith.all;

ENTITY flappy_bird IS
    PORT
        ( pb1, sw0, left_click, right_click, clk, vert_sync, Gamemode_out : IN STD_LOGIC;
          pixel_row, pixel_column: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
          Enable_p : IN STD_LOGIC;
          HEX0, HEX1, HEX2, HEX5, HEX3, HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
          RGB     : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);    
          dead    : OUT STD_LOGIC;
          score_out : OUT INTEGER);    
END flappy_bird;

ARCHITECTURE behaviour OF flappy_bird IS 

COMPONENT bouncy_ball IS
    PORT
        ( pb1                : IN STD_LOGIC;
          clk                : IN STD_LOGIC; 
          vert_sync          : IN STD_LOGIC; 
          enable             : IN STD_LOGIC;
          score_up           : IN STD_LOGIC;
          pixel_row          : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
          pixel_column       : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
          gift_func          : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
          Enable_p           : IN STD_LOGIC;
          Gamemode_out       : IN STD_LOGIC;
          ball_on            : OUT STD_LOGIC;
          ball_y_pos_out     : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
          score              : OUT INTEGER;
          life               : OUT INTEGER;
          death              : OUT STD_LOGIC;
          level_up           : OUT STD_LOGIC;
          bird_rom_out       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));    
END COMPONENT bouncy_ball;

COMPONENT pipes IS
    PORT
        ( Enable_p           : IN STD_LOGIC;
          clk                : IN STD_LOGIC; 
          vert_sync          : IN STD_LOGIC; 
          enable             : IN STD_LOGIC;
          level_up           : IN STD_LOGIC;
          pixel_row          : IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
          pixel_column       : IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
          ball_y_pos         : IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
          random_height      : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
          pipe_on            : OUT STD_LOGIC;
          ball_enable        : OUT STD_LOGIC;
          next_pipe_enable   : OUT STD_LOGIC; 
          gift_enable        : OUT STD_LOGIC; 
          score_up           : OUT STD_LOGIC; 
          x_pos              : OUT STD_LOGIC_VECTOR(10 DOWNTO 0));        
END COMPONENT pipes;

COMPONENT gift IS
	PORT
		( Enable_p				: IN std_logic; 
		  clk						: IN std_logic; 
		  vert_sync				: IN std_logic;
		  motion_enable		: IN std_logic; -- enable is 0 when the ball hit the pipe
		  level_up				: IN std_logic;
		  gamemode				: IN STD_LOGIC;
        pixel_row				: IN std_logic_vector(9 DOWNTO 0); 
		  pixel_column			: IN std_logic_vector(9 DOWNTO 0);
		  ball_y_pos			: IN std_logic_vector(9 DOWNTO 0); 
		  height_1				: IN std_logic_vector(9 DOWNTO 0);
		  y_pos					: IN integer;
		  gift_on				: OUT std_logic;
		  gift_func	   		: OUT std_logic_vector(1 DOWNTO 0));		
END COMPONENT gift;

COMPONENT LFSR IS
    PORT ( clk    : IN STD_LOGIC;
           reset  : IN STD_LOGIC;
           enable : IN STD_LOGIC;
           Q      : OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
END COMPONENT LFSR;

COMPONENT timer IS
    PORT(CLOCK_25 : IN STD_LOGIC; 
          right_click : IN STD_LOGIC;
          dead : IN STD_LOGIC;
          HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); 
          HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); 
          HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
          HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); 
          HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); 
          HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));
END COMPONENT timer;

COMPONENT char_rom IS 
    PORT ( character_address : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
           font_row, font_col : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
           clock : IN STD_LOGIC;
           rom_mux_output : OUT STD_LOGIC);
END COMPONENT char_rom;

COMPONENT bird_rom IS
    PORT
    ( font_row, font_col : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
      clock : IN STD_LOGIC ;
      rom_mux_output : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END COMPONENT bird_rom;

COMPONENT text IS
    PORT ( clk : IN STD_LOGIC; 
           Enable_p : IN STD_LOGIC;
           pixel_row : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
           pixel_column : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
           score : IN INTEGER;
           life  : IN INTEGER;
           character_address : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
           font_row, font_col : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)); 
END COMPONENT text;

SIGNAL ball_on_s, level_up, pipe_on_s, pipe_on_s1, pipe_on_s2, pipe_on_s3, pipe_on_s4, pipe_on_s5 : STD_LOGIC;
SIGNAL rand_num : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL next_pipe_enable1, next_pipe_enable2, next_pipe_enable3, ball_enable_in : STD_LOGIC;
SIGNAL ball_enable1, ball_enable2, ball_enable3 : STD_LOGIC;
SIGNAL gift_enable1, gift_enable2, gift_enable3 : STD_LOGIC;
SIGNAL gift_on1, gift_on2, gift_on3 : STD_LOGIC;
SIGNAL x_pos1, x_pos2, x_pos3 : STD_LOGIC_VECTOR(10 DOWNTO 0);
SIGNAL ball_y_pos_out_s, random, random1, random2, random3 : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL pixel_row_zero, pixel_col_zero : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
SIGNAL font_row, font_col : STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL font_row1, font_col1 : STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL character_address : STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL rom_out : STD_LOGIC;
SIGNAL rom_out_bird : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL combined_rom_out : STD_LOGIC_VECTOR(16 DOWNTO 0) := (OTHERS => '0');
SIGNAL flappy_array_size : INTEGER := 11;
SIGNAL score : INTEGER RANGE 0 TO 999 := 0;
SIGNAL life : INTEGER;
SIGNAL death : STD_LOGIC;
SIGNAL gift_func_s, gift_func1, gift_func2, gift_func3 : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL score_up1, score_up2, score_up3, score_up : STD_LOGIC;

BEGIN
    -- generate and display bouncy_ball on screen
    bounce : bouncy_ball PORT MAP (left_click, clk, vert_sync, ball_enable_in, score_up, pixel_row, pixel_column, gift_func_s, Enable_p, Gamemode_out, ball_on_s, ball_y_pos_out_s, score, life, death, level_up, rom_out_bird);
    -- generate random number for pipes
    gen_random : LFSR PORT MAP (clk, '0', '1', random);
    
    -- generate pipes, 
    gen_pipe1 : pipes PORT MAP (Enable_p, clk, vert_sync, '1', level_up, pixel_row, pixel_column, ball_y_pos_out_s, random1, pipe_on_s, ball_enable1, next_pipe_enable1, gift_enable1, score_up1, x_pos1);
    gen_pipe2 : pipes PORT MAP (Enable_p, clk, vert_sync, next_pipe_enable1, level_up, pixel_row, pixel_column, ball_y_pos_out_s, random2, pipe_on_s1, ball_enable2, next_pipe_enable2, gift_enable2, score_up2, x_pos2);
    gen_pipe3 : pipes PORT MAP (Enable_p, clk, vert_sync, next_pipe_enable2, level_up, pixel_row, pixel_column, ball_y_pos_out_s, random3, pipe_on_s2, ball_enable3, next_pipe_enable3, gift_enable3, score_up3, x_pos3);
    
    gen_gift1 : gift PORT MAP (Enable_p, clk, vert_sync, gift_enable1, level_up, Gamemode_out, pixel_row, pixel_column, ball_y_pos_out_s, random1, 0, gift_on1, gift_func1);
    gen_gift2 : gift PORT MAP (Enable_p, clk, vert_sync, gift_enable2, level_up, Gamemode_out, pixel_row, pixel_column, ball_y_pos_out_s, random2, 1, gift_on2, gift_func2);
    gen_gift3 : gift PORT MAP (Enable_p, clk, vert_sync, gift_enable3, level_up, Gamemode_out, pixel_row, pixel_column, ball_y_pos_out_s, random3, 2, gift_on3, gift_func3);

    -- seven segment display
    time_game : timer PORT MAP (clk, right_click, death, HEX0, HEX1, HEX2, HEX5, HEX3, HEX4);
    
    -- component of character 
    char_roms : char_rom PORT MAP (character_address, font_row, font_col, clk, rom_out);
    
    bird_sprite_rom : bird_rom PORT MAP (font_row1, font_col1, clk, rom_out_bird);
    
    -- generate text
    text_display : text PORT MAP (clk, Enable_p, pixel_row, pixel_column, score, life, character_address, font_row, font_col); 
    
    -- enable ball 
    ball_enable_in <= '1' WHEN (ball_enable1 = '1' AND ball_enable2 = '1' AND ball_enable3 = '1') ELSE '0';
    
    -- gift function
    gift_func_s <= gift_func1 OR gift_func2 OR gift_func3;
    
    -- score up
    score_up <= score_up1 OR score_up2 OR score_up3;
    
    -- combined_rom_out
    combined_rom_out <= (rom_out & rom_out_bird);
    
    -- Draw objects (bird, pipes, etc.)
    RGB(11 downto 8) <= "1010" WHEN (ball_on_s ='1' OR pb1 = '0') OR (gift_on1 ='1' OR gift_on2 ='1' OR gift_on3 ='1') OR (rom_out = '1') ELSE "0000";
    RGB(7 downto 4) <= "0000" WHEN (sw0 ='1') ELSE "1010";
    RGB(3 downto 0) <= "0000" WHEN ((ball_on_s = '1' OR pipe_on_s ='1' OR pipe_on_s1 = '1' OR pipe_on_s2 = '1' OR pipe_on_s3 = '1') AND rom_out = '0') ELSE "1000";
    dead <= death;
    score_out <= score;

    -- enable pipes
    PROCESS (next_pipe_enable1, next_pipe_enable2, next_pipe_enable3)
    BEGIN
        IF (x_pos1 = CONV_STD_LOGIC_VECTOR(679, 11)) THEN
            random1 <= random;
        ELSIF (x_pos2 = CONV_STD_LOGIC_VECTOR(679, 11)) THEN
            random2 <= random;
        ELSIF (x_pos3 = CONV_STD_LOGIC_VECTOR(679, 11)) THEN
            random3 <= random;
        END IF;
    END PROCESS;
END ARCHITECTURE behaviour;
	