-- Portfolio Snippet: LFSR-Based Procedural Gap Height Generator (Deterministic RNG)
-- Context: Hardware-based Flappy Bird implementation (VHDL on Cyclone V FPGA)
--
-- Role in architecture:
--   - Produces pseudo-random pipe gap heights used by the pipe entity system
--   - Runs deterministically under clock control (no software RNG / libraries)
--   - Enforces gameplay constraints:
--       * Output clamped to a playable range (30..329)
--       * Avoids near-repeats by rejecting values within a small delta of the previous output
--       * Uses bounded retries to prevent unbounded stalls (counter limit)
--
-- Key systems concepts demonstrated:
--   - Procedural variation under strict constraints (playability + pacing)
--   - Deterministic randomness (replayable, testable behavior)
--   - Constraint satisfaction with bounded iteration (safety under real-time systems)
--
-- Authorship: Fully implemented by Teresa Zhang (university group project; snippet extracted for portfolio)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_SIGNED.all;

entity LFSR is
    Port (clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           enable    : in STD_LOGIC;
           Q : out STD_LOGIC_VECTOR(9 downto 0));
end entity LFSR;

architecture Behavioral of LFSR is

begin
    process(clk)
	 
	 variable counter : integer := 0;
      variable temp : STD_LOGIC := '0';
      variable Q1,Q2 : STD_LOGIC_VECTOR(9 downto 0) := "1000000000"; -- Initial seed value
    begin
      if (rising_edge(clk)) then
			if (reset = '1') then
				Q1 := "1000000000";
			elsif(enable = '1') then 
				-- psuedo-random behaviour S
				temp := Q1(4) XOR Q1(3) XOR Q1(2) XOR Q1(0);
				Q1 :=  temp & Q1(9 downto 1);
				counter := 0;
				
				while ((((unsigned(Q1) < 30) or (unsigned(Q1) > 329)) or (((Q2 - CONV_STD_LOGIC_VECTOR(5,10)) < Q1) and ((Q2 + CONV_STD_LOGIC_VECTOR(5,10)) > Q1))) and (counter <= 50) ) loop

					temp := Q1(4) XOR Q1(3) XOR Q1(2) XOR Q1(0);
					Q1 :=  temp & Q1(9 downto 1);
					counter := counter + 1;
				end loop;
			end if;	
			Q <= Q1;
			Q2 := Q1;
		 end if;
    end process;
end Behavioral;