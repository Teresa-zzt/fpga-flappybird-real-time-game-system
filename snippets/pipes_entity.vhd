-- Portfolio Snippet: Pipe Entity Module (Movement, Recycling, Scoring Triggers)
-- Updates on vert_sync (frame tick) to ensure deterministic frame-based simulation.
-- Features:
--   - Object recycling (reposition to right edge when off-screen)
--   - Difficulty scaling via level_up affecting x_motion
--   - One-shot score trigger when pipe passes player x position
--   - next_pipe_enable / gift_enable triggers for system orchestration
-- Authorship: Implemented by Teresa Zhang (university group project; snippet extracted for portfolio)

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;


ENTITY pipes IS
	PORT
		(Enable_p				: IN STD_LOGIC;
		 clk						: IN STD_LOGIC; 
		 vert_sync				: IN STD_LOGIC; 
		 enable					: IN STD_LOGIC;
		 level_up				: IN std_logic;
       pixel_row				: IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
		 pixel_column			: IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
		 ball_y_pos				: IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
		 random_height			: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 pipe_on					: OUT STD_LOGIC;
		 ball_enable			: OUT STD_LOGIC;
		 next_pipe_enable		: OUT STD_LOGIC; 
		 gift_enable			: OUT STD_LOGIC; 
		 score_up				: OUT STD_LOGIC; 
		 x_pos 					: OUT STD_LOGIC_VECTOR(10 downto 0));		
END ENTITY pipes;

architecture behavior of pipes is
SIGNAL height_1 					: STD_LOGIC_VECTOR(9 DOWNTO 0);  
SIGNAL height_2 					: STD_LOGIC_VECTOR(9 DOWNTO 0); 
SIGNAL pipe_x_pos					: STD_LOGIC_VECTOR(10 DOWNTO 0);
SIGNAL pipe_y_pos_1				: STD_LOGIC_VECTOR(9 DOWNTO 0):= CONV_STD_LOGIC_VECTOR(0,10);
SIGNAL pipe_y_pos_2				: STD_LOGIC_VECTOR(9 DOWNTO 0):= CONV_STD_LOGIC_VECTOR(479,10);
SIGNAL width        				: STD_LOGIC_VECTOR(10 DOWNTO 0):= CONV_STD_LOGIC_VECTOR(20,11);
SIGNAL reset						: STD_LOGIC;
SIGNAL rand_number 				: STD_LOGIC_VECTOR(8 downto 0);
SIGNAL rand_number1				: STD_LOGIC_VECTOR(8 downto 0);
SIGNAL ball_x_pos					: STD_LOGIC_VECTOR(10 DOWNTO 0):= CONV_STD_LOGIC_VECTOR(120,11);


 BEGIN
	pipe_on <= '1' when ( ('0' & pipe_x_pos <= '0' & pixel_column + width) and ('0' & pixel_column <= '0' & pipe_x_pos + width) 	-- x_pos - size <= pixel_column <= x_pos + size
					and ('0' & pixel_row >= pipe_y_pos_2 - height_2) )  else
					'1' when ( ('0' & pipe_x_pos <= '0' & pixel_column + width) and ('0' & pixel_column <= '0' & pipe_x_pos + width) 	-- x_pos - size <= pixel_column <= x_pos + size
					and ('0' & pixel_row <= pipe_y_pos_1 + height_1) )  else
					'0';
	ball_enable <= '0' when ((ball_y_pos <= height_1) or ( ball_y_pos >= CONV_STD_LOGIC_VECTOR(479,10)- height_2)) and ((ball_x_pos >= pipe_x_pos- width) and (ball_x_pos <= pipe_x_pos + width))  else '1';
	
	
	
	PIPES: process 
  --variable pipe_height_1: std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(30,10); --mim height
  --variable pipe_height_2: std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(329,10); --gap=120
	variable x_position: std_logic_vector(10 DOWNTO 0);
	variable x_motion: std_logic_vector(10 DOWNTO 0):= CONV_STD_LOGIC_VECTOR(-2,11);
	variable next_pipe_enable_q, gift_enable_q: std_logic := '0';
	variable score_up_enable: std_logic := '1';

	variable size : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(8,10);
		BEGIN
		height_1 <= random_height;
		height_2 <= CONV_STD_LOGIC_VECTOR((479-120-unsigned(height_1)),10);
		wait until (rising_edge(vert_sync)); 
		if (Enable_p ='0') then
		  -- initialise pipe position
			x_position:= CONV_STD_LOGIC_VECTOR(679,11)+width;
			next_pipe_enable_q := '0';
			gift_enable_q := '0';
			x_motion:= CONV_STD_LOGIC_VECTOR(-2,11);
			score_up_enable := '1';
		else
				if (level_up = '1') then
					x_motion:= x_motion + CONV_STD_LOGIC_VECTOR(-1,11);
				end if;
				if (enable ='1') then
					-- move the pipe to the left 
				  x_position:= x_position + x_motion;
				  -- once the pipe has reached the 490th column enable the next pipe
				  if (x_position < CONV_STD_LOGIC_VECTOR(453,11)) then
						next_pipe_enable_q:= '1';
					elsif (x_position < CONV_STD_LOGIC_VECTOR(600,11)) then
						gift_enable_q := '1';
				  end if;
				  
				  if ((x_position + width) < CONV_STD_LOGIC_VECTOR(0,11)) then 
						x_position := CONV_STD_LOGIC_VECTOR(679,11)+width;
						score_up_enable := '1';
				  end if;
				 end if;
				 
				 if (ball_x_pos > x_position and score_up_enable ='1') then
					score_up<= '1';
					score_up_enable := '0';
				 else
					score_up<= '0';
				 end if;			
			end if;
		pipe_x_pos <= x_position;
		x_pos <= x_position;
		next_pipe_enable <= next_pipe_enable_q;
		gift_enable <= gift_enable_q;
  end process PIPES;
  END architecture behavior;