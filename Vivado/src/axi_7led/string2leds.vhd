--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Design Name:    
-- Module Name:    string2leds - Behavioral
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description: Converts eight characters to the necessary signals to display
--              the characters on a 4x7-segment display
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity string2leds is
    Port ( 
	   char0, char1, char2, char3, char4, char5, char6, char7 : in std_logic_vector(7 downto 0);
	   char8, char9, charA, charB, charC, charD, charE, charF : in std_logic_vector(7 downto 0);
		segment : out std_logic_vector(6 downto 0);
		dp : out std_logic;
		an : out std_logic_vector(7 downto 0);
		enable : in std_logic;
		onemsec_clk : in std_logic;
		sys_rst : in std_logic );
end string2leds;

architecture Behavioral of string2leds is
	signal c0, c1, c2, c3, c4, c5, c6, c7 : std_logic_vector(7 downto 0);
	signal s0, s1, s2, s3, s4, s5, s6 : integer;
	signal segment0 : std_logic_vector(6 downto 0);
	signal segment1 : std_logic_vector(6 downto 0);
	signal segment2 : std_logic_vector(6 downto 0);
	signal segment3 : std_logic_vector(6 downto 0);
	signal segment4 : std_logic_vector(6 downto 0);
	signal segment5 : std_logic_vector(6 downto 0);
	signal segment6 : std_logic_vector(6 downto 0);
	signal segment7 : std_logic_vector(6 downto 0);
	signal dp0,dp1,dp2,dp3,dp4,dp5,dp6,dp7 : std_logic;
begin

	-- c0, c1, c2, c3, c4, c5, c6, and c7 are the characters passed to char2led
	-- s0, s1, s2, s3, s4, s5, s6 keep track of how many characters have been shifted
	-- due to the presence of '.' (0x2e) characters.
	-- We determine what c0-c7 are by looking at the last
	-- 16 characters and keeping track of the s0-s6 signals
	-- to see how many of the list of characters we have to shift

	dp0 <= '0' when char0 = X"2E" else '1';
	c0 <= X"20" when char0=X"2E" and char1 = X"2E" else
			char1 when char0=X"2E" else char0;
	s0 <= 1 when char0=X"2E" and char1 /= X"2E" else 0;

	dp1 <= '0' when s0=0 and char1 = X"2E" else
			 '0' when s0=1 and char2 = X"2E" else
			 '1';
	c1 <= X"20" when s0=0 and char1=X"2E" and char2 = X"2E" else
			X"20" when s0=1 and char2=X"2E" and char3 = X"2E" else
			char2 when s0=0 and char1=X"2E" else
			char3 when s0=1 and char2=X"2E" else
			char2 when s0=1 else
			char1;
	s1 <= 1 when s0=0 and char1=X"2E" and char2 /= X"2E" else
			2 when s0=1 and char2=X"2E" and char3 /= X"2E" else
			s0;

	dp2 <= '0' when s1=0 and char2 = X"2E" else
			 '0' when s1=1 and char3 = X"2E" else
			 '0' when s1=2 and char4 = X"2E" else
			 '1';
	c2 <= X"20" when s1=0 and char2=X"2E" and char3 = X"2E" else
			X"20" when s1=1 and char3=X"2E" and char4 = X"2E" else
			X"20" when s1=2 and char4=X"2E" and char5 = X"2E" else
			char3 when s1=0 and char2=X"2E" else
			char4 when s1=1 and char3=X"2E" else
			char5 when s1=2 and char4=X"2E" else
			char4 when s1=2 else
			char3 when s1=1 else
			char2;
	s2 <= 1 when s1=0 and char2=X"2E" and char3 /= X"2E" else
			2 when s1=1 and char3=X"2E" and char4 /= X"2E" else
			3 when s1=2 and char4=X"2E" and char5 /= X"2E" else
			s1;

	dp3 <= '0' when s2=0 and char3 = X"2E" else
			 '0' when s2=1 and char4 = X"2E" else
			 '0' when s2=2 and char5 = X"2E" else
			 '0' when s2=3 and char6 = X"2E" else
			 '1';
	c3 <= X"20" when s2=0 and char3=X"2E" and char4 = X"2E" else
			X"20" when s2=1 and char4=X"2E" and char5 = X"2E" else
			X"20" when s2=2 and char5=X"2E" and char6 = X"2E" else
			X"20" when s2=3 and char6=X"2E" and char7 = X"2E" else
			char4 when s2=0 and char3=X"2E" else
			char5 when s2=1 and char4=X"2E" else
			char6 when s2=2 and char5=X"2E" else
			char7 when s2=3 and char6=X"2E" else
			char6 when s2=3 else
			char5 when s2=2 else
			char4 when s2=1 else
			char3;
	s3 <= 1 when s2=0 and char3=X"2E" and char4 /= X"2E" else
			2 when s2=1 and char4=X"2E" and char5 /= X"2E" else
			3 when s2=2 and char5=X"2E" and char6 /= X"2E" else
			4 when s2=3 and char6=X"2E" and char7 /= X"2E" else
			s2;

	dp4 <= '0' when s3=0 and char4 = X"2E" else
			 '0' when s3=1 and char5 = X"2E" else
			 '0' when s3=2 and char6 = X"2E" else
			 '0' when s3=3 and char7 = X"2E" else
			 '0' when s3=4 and char8 = X"2E" else
			 '1';
	c4 <= X"20" when s3=0 and char4=X"2E" and char5 = X"2E" else
			X"20" when s3=1 and char5=X"2E" and char6 = X"2E" else
			X"20" when s3=2 and char6=X"2E" and char7 = X"2E" else
			X"20" when s3=3 and char7=X"2E" and char8 = X"2E" else
			X"20" when s3=4 and char8=X"2E" and char9 = X"2E" else
			char5 when s3=0 and char4=X"2E" else
			char6 when s3=1 and char5=X"2E" else
			char7 when s3=2 and char6=X"2E" else
			char8 when s3=3 and char7=X"2E" else
			char9 when s3=4 and char8=X"2E" else
			char8 when s3=4 else
			char7 when s3=3 else
			char6 when s3=2 else
			char5 when s3=1 else
			char4;
	s4 <= 1 when s3=0 and char4=X"2E" and char5 /= X"2E" else
			2 when s3=1 and char5=X"2E" and char6 /= X"2E" else
			3 when s3=2 and char6=X"2E" and char7 /= X"2E" else
			4 when s3=3 and char7=X"2E" and char8 /= X"2E" else
			5 when s3=4 and char8=X"2E" and char9 /= X"2E" else
			s2;

	dp5 <= '0' when s4=0 and char5 = X"2E" else
			 '0' when s4=1 and char6 = X"2E" else
			 '0' when s4=2 and char7 = X"2E" else
			 '0' when s4=3 and char8 = X"2E" else
			 '0' when s4=4 and char9 = X"2E" else
			 '0' when s4=5 and charA = X"2E" else
			 '1';
	c5 <= X"20" when s4=0 and char5=X"2E" and char6 = X"2E" else
			X"20" when s4=1 and char6=X"2E" and char7 = X"2E" else
			X"20" when s4=2 and char7=X"2E" and char8 = X"2E" else
			X"20" when s4=3 and char8=X"2E" and char9 = X"2E" else
			X"20" when s4=4 and char9=X"2E" and charA = X"2E" else
			X"20" when s4=5 and charA=X"2E" and charB = X"2E" else
			char6 when s4=0 and char5=X"2E" else
			char7 when s4=1 and char6=X"2E" else
			char8 when s4=2 and char7=X"2E" else
			char9 when s4=3 and char8=X"2E" else
			charA when s4=4 and char9=X"2E" else
			charB when s4=5 and charA=X"2E" else
			charA when s4=5 else
			char9 when s4=4 else
			char8 when s4=3 else
			char7 when s4=2 else
			char6 when s4=1 else
			char5;
	s5 <= 1 when s4=0 and char5=X"2E" and char6 /= X"2E" else
			2 when s4=1 and char6=X"2E" and char7 /= X"2E" else
			3 when s4=2 and char7=X"2E" and char8 /= X"2E" else
			4 when s4=3 and char8=X"2E" and char9 /= X"2E" else
			5 when s4=4 and char9=X"2E" and charA /= X"2E" else
			6 when s4=5 and charA=X"2E" and charB /= X"2E" else
			s2;

	dp6 <= '0' when s5=0 and char6 = X"2E" else
			 '0' when s5=1 and char7 = X"2E" else
			 '0' when s5=2 and char8 = X"2E" else
			 '0' when s5=3 and char9 = X"2E" else
			 '0' when s5=4 and charA = X"2E" else
			 '0' when s5=5 and charB = X"2E" else
			 '0' when s5=6 and charC = X"2E" else
			 '1';
	c6 <= X"20" when s5=0 and char6=X"2E" and char7 = X"2E" else
			X"20" when s5=1 and char7=X"2E" and char8 = X"2E" else
			X"20" when s5=2 and char8=X"2E" and char9 = X"2E" else
			X"20" when s5=3 and char9=X"2E" and charA = X"2E" else
			X"20" when s5=4 and charA=X"2E" and charB = X"2E" else
			X"20" when s5=5 and charB=X"2E" and charC = X"2E" else
			X"20" when s5=6 and charC=X"2E" and charD = X"2E" else
			char7 when s5=0 and char6=X"2E" else
			char8 when s5=1 and char7=X"2E" else
			char9 when s5=2 and char8=X"2E" else
			charA when s5=3 and char9=X"2E" else
			charB when s5=4 and charA=X"2E" else
			charC when s5=5 and charB=X"2E" else
			charD when s5=6 and charD=X"2E" else
			charC when s5=6 else
			charB when s5=5 else
			charA when s5=4 else
			char9 when s5=3 else
			char8 when s5=2 else
			char7 when s5=1 else
			char6;
	s6 <= 1 when s5=0 and char6=X"2E" and char7 /= X"2E" else
			2 when s5=1 and char7=X"2E" and char8 /= X"2E" else
			3 when s5=2 and char8=X"2E" and char9 /= X"2E" else
			4 when s5=3 and char9=X"2E" and charA /= X"2E" else
			5 when s5=4 and charA=X"2E" and charB /= X"2E" else
			6 when s5=5 and charB=X"2E" and charC /= X"2E" else
			7 when s5=6 and charC=X"2E" and charD /= X"2E" else
			s2;

	dp7 <= '0' when s6=0 and char6 = X"2E" else
			 '0' when s6=1 and char8 = X"2E" else
			 '0' when s6=2 and char9 = X"2E" else
			 '0' when s6=3 and charA = X"2E" else
			 '0' when s6=4 and charB = X"2E" else
			 '0' when s6=5 and charC = X"2E" else
			 '0' when s6=6 and charD = X"2E" else
			 '0' when s6=7 and charE = X"2E" else
			 '1';
	c7 <= X"20" when s6=0 and char7=X"2E" and char8 = X"2E" else
			X"20" when s6=1 and char8=X"2E" and char9 = X"2E" else
			X"20" when s6=2 and char9=X"2E" and charA = X"2E" else
			X"20" when s6=3 and charA=X"2E" and charB = X"2E" else
			X"20" when s6=4 and charB=X"2E" and charC = X"2E" else
			X"20" when s6=5 and charC=X"2E" and charD = X"2E" else
			X"20" when s6=6 and charD=X"2E" and charE = X"2E" else
			X"20" when s6=7 and charE=X"2E" and charF = X"2E" else
			char8 when s6=0 and char7=X"2E" else
			char9 when s6=1 and char8=X"2E" else
			charA when s6=2 and char9=X"2E" else
			charB when s6=3 and charA=X"2E" else
			charC when s6=4 and charB=X"2E" else
			charD when s6=5 and charC=X"2E" else
			charE when s6=6 and charD=X"2E" else
			charF when s6=7 and charE=X"2E" else
			charE when s6=7 else
			charD when s6=6 else
			charC when s6=5 else
			charB when s6=4 else
			charA when s6=3 else
			char9 when s6=2 else
			char8 when s6=1 else
			char7;

	char0led : entity work.char2led
		port map ( segment => segment0, ascii => c0 );

	char1led : entity work.char2led
		port map ( segment => segment1, ascii => c1 );

	char2led : entity work.char2led
		port map ( segment => segment2, ascii => c2 );

	char3led : entity work.char2led
		port map ( segment => segment3, ascii => c3 );

	char4led : entity work.char2led
		port map ( segment => segment4, ascii => c4 );

	char5led : entity work.char2led
		port map ( segment => segment5, ascii => c5 );

	char6led : entity work.char2led
		port map ( segment => segment6, ascii => c6 );

	char7led : entity work.char2led
		port map ( segment => segment7, ascii => c7 );

	led_control : entity work.char_led_control
		port map ( clk => onemsec_clk,
				 reset => sys_rst,
				 enable => enable,
				 segment0 => segment0,
			 	 segment1 => segment1,
			 	 segment2 => segment2,
			 	 segment3 => segment3,
				 segment4 => segment4,
			 	 segment5 => segment5,
			 	 segment6 => segment6,
			 	 segment7 => segment7,
				 dp0 => dp0,
				 dp1 => dp1,
				 dp2 => dp2,
				 dp3 => dp3,
				 dp4 => dp4,
				 dp5 => dp5,
				 dp6 => dp6,
				 dp7 => dp7,
			 	 segment => segment,
				 dp => dp,
			 	 an => an );

end Behavioral;
