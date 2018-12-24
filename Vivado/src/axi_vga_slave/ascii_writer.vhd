----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/30/2016 04:17:29 PM
-- Design Name: 
-- Module Name: ascii_writer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ascii_writer is
    GENERIC (
	    CHARS_PER_LINE : integer := 80;
        LINES_PER_PAGE : integer := 40
    );
    PORT (
        current_char : in integer range 0 to CHARS_PER_LINE-1;
        current_line : in integer range 0 to LINES_PER_PAGE-1;
        ascii : in std_logic_vector(7 downto 0);
        we : in std_logic;
        ram_addr : out std_logic_vector(15 downto 0);
        ram_data : out std_logic_vector(31 downto 0);
        ram_we : out std_logic;
        writes_done : out std_logic;
        clk_in : in std_logic;
        resetn : in std_logic
    );
end ascii_writer;

architecture Behavioral of ascii_writer is
    constant CHARS_PER_PAGE : integer := CHARS_PER_LINE * LINES_PER_PAGE;
    constant CHAR_WIDTH : integer := 8;
    constant CHAR_HEIGHT : integer := 12;
    constant PIXELS_PER_WORD : integer := 8;
    constant BITS_PER_PIXEL : integer := 4;
    
    type state_type is ( WAIT4ASCII,  -- Wait for write of ASCII code
                         GETPIXELS1,-- Wait for pixel data to be ready
                         GETPIXELS2,-- Wait for pixel data to be ready
                         NEXT_LINE);-- write pixels to memory 
    signal state : state_type;

    signal reset : std_logic;

	signal txtcolor, bgcolor : std_logic_vector(BITS_PER_PIXEL-1 downto 0);
	signal color_pixels : std_logic_vector(31 downto 0);
	signal pixels : std_logic_vector(CHAR_WIDTH-1 downto 0);
	signal reg_pixels : std_logic_vector(CHAR_WIDTH-1 downto 0);
    signal scan_line : integer range 0 to CHAR_HEIGHT-1;
    signal current_char_local : integer range 0 to CHARS_PER_LINE-1;
    signal current_line_local : integer range 0 to LINES_PER_PAGE-1;
    signal ascii_local: std_logic_vector(7 downto 0);
begin

    process(clk_in, resetn)
    begin
        if (resetn = '0') then
            state <= WAIT4ASCII;
            ram_we <= '0';
            writes_done <= '0';
        elsif (clk_in'event and clk_in='1') then
            case (state) is
                when WAIT4ASCII =>
                    writes_done <= '0';
                    if ( WE = '1' ) then
                        -- hold on to the inputs
                        current_char_local <= current_char;
                        current_line_local <= current_line;
                        ascii_local <= ascii;
                        
                        scan_line <= 0;
                        state <= GETPIXELS1;                                                        
                    end if;
                                                       
                when GETPIXELS1 =>
                    -- wait for pixels to be ready from lookup table
                    state <= GETPIXELS2;

                when GETPIXELS2 =>
                    ram_we <= '1';
                    reg_pixels <= pixels;
                    state <= NEXT_LINE;

                when NEXT_LINE =>
                    ram_we <= '0';
                    if (scan_line = (CHAR_HEIGHT-1)) then
                        state <= WAIT4ASCII;
                        writes_done <= '1';                                                  
                    else
                        scan_line <= scan_line + 1;
                        state <= GETPIXELS1;
                    end if;
                                                                                                        
                when others  =>                                                                           
                    state  <= WAIT4ASCII;
            end case;                                                            

        end if;
    end process;
    
    reset <= not resetn;
    -- the lookup table maps the ascii code to the pixels for that particular character.  
    -- The line input determines which of the 12 lines of the character we want.  The
    -- lookup table is implemented with the builtin registered BRAM, so the output is
    -- available only at the next clock cycle
    lut : entity work.char8x12_lookup_table
        port map( clk => clk_in, reset => reset, ascii => ascii_local, line => scan_line, pixels => pixels );
      
    -- txtcolor is the color of the text and bgcolor is the color of the background
    txtcolor <= "1111"; -- white
    bgcolor <= "0001"; -- blue
      
    -- the following code sets the color_pixels word based on the reg_pixels byte which is a registered
    -- version of the pixels byte that comes from the lookup table.  When reg_pixels is '1', we use the
    -- text color, otherwise we use the background color
    gen1 : for i in 0 to PIXELS_PER_WORD-1 generate
        color_pixels(BITS_PER_PIXEL*i+BITS_PER_PIXEL-1 downto BITS_PER_PIXEL*i) <= txtcolor when reg_pixels(i)='1' else bgcolor;
    end generate;
                            
	ram_addr <= conv_std_logic_vector ((current_line_local*CHARS_PER_LINE*CHAR_HEIGHT + current_char_local + scan_line*CHARS_PER_LINE)*CHAR_WIDTH/PIXELS_PER_WORD,16);
    ram_data <= color_pixels;

end Behavioral;
