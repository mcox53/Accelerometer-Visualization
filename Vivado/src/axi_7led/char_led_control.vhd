--------------------------------------------------------------------------------
-- Module Name:    char_led_control - Behavioral
-- Additional Comments:
--   This module controls the segment lines on the bank 7-segment LED displays
--   on the Digilent Board.  Each digit is displayed for
--   approximately 1 millisecond.  It is assumed that the clk that is passed in
--   to this module has a period of 1 ms.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity char_led_control is
    Port ( clk : in std_logic;
    		 reset : in std_logic;
		 enable : in std_logic;
           segment0 : in std_logic_vector(6 downto 0);
           dp0 : in std_logic;
           segment1 : in std_logic_vector(6 downto 0);
           dp1 : in std_logic;
           segment2 : in std_logic_vector(6 downto 0);
           dp2 : in std_logic;
           segment3 : in std_logic_vector(6 downto 0);
           dp3 : in std_logic;
           segment4 : in std_logic_vector(6 downto 0);
           dp4 : in std_logic;
           segment5 : in std_logic_vector(6 downto 0);
           dp5 : in std_logic;
           segment6 : in std_logic_vector(6 downto 0);
           dp6 : in std_logic;
           segment7 : in std_logic_vector(6 downto 0);
           dp7 : in std_logic;
           segment : out std_logic_vector(6 downto 0);
           dp : out std_logic;
           an : out std_logic_vector(7 downto 0));
end char_led_control;

architecture Behavioral of char_led_control is
	signal count : std_logic_vector(2 downto 0);
begin

 	process(clk,reset)
	begin
		if (reset = '0') then
			count <= "000";
		elsif (clk'event and clk = '1') then
			count <= count + 1;
		end if;
	end process;

  	process(count,enable,segment0,segment1,segment2,segment3,segment4,segment5,segment6,segment7,dp0,dp1,dp2,dp3,dp4,dp5,dp6,dp7)
	begin
		if ( enable = '1' ) then
			if ( count = "000" ) then
				an <= "11111110";
				segment <= segment0;
				dp <= dp0;
			elsif ( count = "001" ) then
				an <= std_logic_vector'("11111101");
				segment <= segment1;
				dp <= dp1;
			elsif ( count = "010" ) then
				an <= std_logic_vector'("11111011");
				segment <= segment2;
				dp <= dp2;
			elsif ( count = "011" ) then
				an <= std_logic_vector'("11110111");
                segment <= segment3;
                dp <= dp3;
			elsif ( count = "100" ) then
                an <= std_logic_vector'("11101111");
                segment <= segment4;
                dp <= dp4;
			elsif ( count = "101" ) then
                an <= std_logic_vector'("11011111");
                segment <= segment5;
                dp <= dp5;
			elsif ( count = "110" ) then
                an <= std_logic_vector'("10111111");
                segment <= segment6;
                dp <= dp6;
			else
				an <= std_logic_vector'("01111111");
                segment <= segment7;
                dp <= dp7;
			end if;
		else
			an <= "11111111";
            segment <= "1111111";
            dp <= '1';
		end if;
	end process;

end Behavioral;
