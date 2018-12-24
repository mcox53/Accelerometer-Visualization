--------------------------------------------------------------------------------
-- Company: UNIVERSITY OF CONNECTICUT
-- Module Name:    data2leds - Behavioral
-- Additional Comments:
--   This module takes a 32 bit number and outputs it to a bank of 8 7-segment
--   LED displays.  It is assumed that the segment lines are shared between the
--   digits as with the Digilent FPGA Boards.  The control for the
--   sharing is done with the char_led_control module
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity data2leds is
    Port ( data : in std_logic_vector(31 downto 0);
		seg : out std_logic_vector(6 downto 0);
		dp : out std_logic;
		an : out std_logic_vector(7 downto 0);
		enable : in std_logic;
		onemsec_clk : in std_logic;
		sys_rst : in std_logic );
end data2leds;

architecture Behavioral of data2leds is
	signal segment0 : std_logic_vector(6 downto 0);
	signal segment1 : std_logic_vector(6 downto 0);
	signal segment2 : std_logic_vector(6 downto 0);
	signal segment3 : std_logic_vector(6 downto 0);
	signal segment4 : std_logic_vector(6 downto 0);
	signal segment5 : std_logic_vector(6 downto 0);
	signal segment6 : std_logic_vector(6 downto 0);
	signal segment7 : std_logic_vector(6 downto 0);
begin

	hex0 : entity work.hex2led
		port map ( segment => segment0,
				 hex => data(3 downto 0) );

	hex1 : entity work.hex2led
		port map ( segment => segment1,
				 hex => data(7 downto 4) );

	hex2 : entity work.hex2led
		port map ( segment => segment2,
				 hex => data(11 downto 8) );

	hex3 : entity work.hex2led
		port map ( segment => segment3,
				 hex => data(15 downto 12) );

	hex4 : entity work.hex2led
		port map ( segment => segment4,
				 hex => data(19 downto 16) );

	hex5 : entity work.hex2led
		port map ( segment => segment5,
				 hex => data(23 downto 20) );

	hex6 : entity work.hex2led
		port map ( segment => segment6,
				 hex => data(27 downto 24) );

	hex7 : entity work.hex2led
		port map ( segment => segment7,
				 hex => data(31 downto 28) );

	led_control : entity work.char_led_control
		port map ( clk => onemsec_clk,
				 reset => sys_rst,
				 enable => enable,
				 segment0 => segment0,
				 dp0 => '1',
			 	 segment1 => segment1,
				 dp1 => '1',
			 	 segment2 => segment2,
				 dp2 => '1',
			 	 segment3 => segment3,
				 dp3 => '1',
				 segment4 => segment4,
				 dp4 => '1',
			 	 segment5 => segment5,
				 dp5 => '1',
			 	 segment6 => segment6,
				 dp6 => '1',
			 	 segment7 => segment7,
				 dp7 => '1',
			 	 segment => seg,
				 dp => dp,
			 	 an => an );

end Behavioral;
