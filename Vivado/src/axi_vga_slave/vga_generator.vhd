----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/30/2016 03:54:51 PM
-- Design Name: 
-- Module Name: vga_generator - Behavioral
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
--use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_generator is
    PORT (
      	VGA_R : out std_logic_vector(3 downto 0);
        VGA_G : out std_logic_vector(3 downto 0);
        VGA_B : out std_logic_vector(3 downto 0);
        VGA_HS : out std_logic;
        VGA_VS : out std_logic;
        clk_in : in std_logic;
        resetn : in std_logic;
        key_pressed     : in std_logic_vector(11 downto 0)
);
end vga_generator;

architecture Behavioral of vga_generator is
-- 640x480 requires 25MHz pixel clock
	constant VISIBLE_LINES_PER_FRAME : integer := 480;
	constant LINES_PER_FRAME : integer := 521;
	constant VSYNC_FRONT_PORCH : integer := 10;
	constant VSYNC_WIDTH : integer := 2;
	constant VSYNC_BACK_PORCH : integer := 29;

	constant VISIBLE_PIXELS_PER_LINE : integer := 640;
	constant PIXELS_PER_LINE : integer := 800;
	constant HSYNC_FRONT_PORCH : integer := 16;
	constant HSYNC_WIDTH : integer := 96;
	constant HSYNC_BACK_PORCH : integer := 48;

    constant BOX_CENTER_X         : integer := 320;
    constant BOX_CENTER_Y         : integer := 240;
    
    constant BG_COLOR             : std_logic_vector(11 downto 0) := X"FFF";

	constant BITS_PER_PIXEL : integer := 4;
	constant PIXELS_PER_WORD : integer := 8;

	type state_type is (WAIT4ACK, EXTRAWAIT, WAIT4NEXT);
	signal state : state_type;
	
	signal box_size_reg : std_logic_vector(11 downto 0);
    signal box_color_reg : std_logic_vector(11 downto 0);
    signal key_pressed_reg : std_logic_vector(11 downto 0);
    
    signal draw_box : std_logic;
    
    signal box_size_top : integer;
    signal box_size_bottom : integer;
    signal box_size_left : integer;
    signal box_size_right : integer;
	

	signal pixel_clk : std_logic;
	signal line_count : integer range 0 to LINES_PER_FRAME;
	signal pixel_count : integer range 0 to 800;
	signal next_pixel_line : integer range 0 to LINES_PER_FRAME;
	signal next_pixel : integer range 0 to 800;
	signal hsync_internal : std_logic;
	signal display_valid, hdisplay_valid, vdisplay_valid : std_logic;

	signal pixel : std_logic_vector(BITS_PER_PIXEL-1 downto 0);
	signal pixnum : integer range 0 to PIXELS_PER_WORD-1;
	signal reg_pixel_data : std_logic_vector(BITS_PER_PIXEL*PIXELS_PER_WORD-1 downto 0);
    
    signal color   : std_logic_vector(11 downto 0);
    signal box_size : std_logic_vector(11 downto 0) := X"01E";
    signal box_color : std_logic_vector(11 downto 0) := X"00F";
    signal flag : std_logic;
    
    signal move_size : integer := 5;
    
    signal box_x : integer;
    signal box_y : integer;
    
begin
	-- move the box based on the arrow keys.
	-- Utilizes the current position + or - a set move amount
	
	box_moving : process(key_pressed_reg, resetn)
	begin
	   if(resetn = '0') then
	       box_x <= BOX_CENTER_X;
	       box_y <= BOX_CENTER_Y;
	       box_size <= X"01E";
	       box_color <= X"00F";
	   elsif(pixel_clk'event and pixel_clk = '1') then
	       if(key_pressed_reg = X"001") then
	           box_y <= (box_y - move_size);
	       elsif(key_pressed_reg = X"002") then
	           box_y <= (box_y + move_size);
	       elsif(key_pressed_reg = X"003") then
	           box_x <= (box_x + move_size);
	       elsif(key_pressed_reg = X"004") then
	           box_x <= (box_x - move_size);
	       elsif(key_pressed_reg = X"005") then
	           box_size <= X"005";
	       elsif(key_pressed_reg = X"006") then
	           box_size <= X"01E";
	       elsif(key_pressed_reg = X"007") then
	           box_size <= X"032";
	       elsif(key_pressed_reg = X"008") then
	           box_color <= X"F00";
	       elsif(key_pressed_reg = X"009") then
	           box_color <= X"0F0";
	       elsif(key_pressed_reg = X"00A") then
	           box_color <= X"00F";
	       else
	           box_y <= box_y;
	           box_size <= box_size;
	           box_color <= box_color;
	       end if;
	   end if;
    end process; 
	
	
	box_clock : process(pixel_clk)
	begin
	   if(pixel_clk'event and pixel_clk = '1') then
        box_size_left <= box_x - to_integer(unsigned(box_size));
        box_size_right <= box_x + to_integer(unsigned(box_size));    
        box_size_top <= box_y - to_integer(unsigned(box_size));    
        box_size_bottom <= box_y + to_integer(unsigned(box_size));
       end if;
    end process;
	
    draw_box <= '1' when pixel_count > (box_size_left)
                   and  pixel_count < (box_size_right)
                   and  line_count > (box_size_top)
                   and  line_count < (box_size_bottom)
                   else '0';

	    
   clk_divider : entity work.clock_divider
       generic map ( divisor => 4 )
       port map ( clk_in => clk_in, reset => resetn, clk_out => pixel_clk );

    color <= box_color when draw_box = '1' else BG_COLOR;
		
	-- Signal Buffering
	signal_buffer : process(pixel_clk)
	begin
		if(pixel_clk'event and pixel_clk = '1') then
			key_pressed_reg <= key_pressed;	
		end if;
	end process;
   
   pixel_count_process: process( pixel_clk, resetn )
   begin
       if ( resetn = '0' ) then
           pixel_count <= 0;
       elsif ( pixel_clk'event and pixel_clk='1' ) then

           if ( pixel_count = PIXELS_PER_LINE-1 ) then
               pixel_count <= 0;
           else
               pixel_count <= pixel_count + 1;
           end if;

       end if;
    end process;
    VGA_HS <= '0' when (pixel_count >= (VISIBLE_PIXELS_PER_LINE+HSYNC_FRONT_PORCH) and 
                        pixel_count < (VISIBLE_PIXELS_PER_LINE+HSYNC_FRONT_PORCH+HSYNC_WIDTH)) else '1';

    line_count_process: process( pixel_clk, resetn, pixel_count )
    begin
        if ( resetn = '0' ) then
            line_count <= 0;
        elsif ( pixel_clk'event and pixel_clk='1' ) then
            if ( pixel_count = PIXELS_PER_LINE-1) then
                if ( line_count = LINES_PER_FRAME-1 ) then
                    line_count <= 0;
                else
                    line_count <= line_count + 1;
                end if;
            end if;
        end if;
    end process;
    VGA_VS <= '0' when (line_count >= (VISIBLE_LINES_PER_FRAME+VSYNC_FRONT_PORCH) and 
                        line_count < (VISIBLE_LINES_PER_FRAME+VSYNC_FRONT_PORCH+VSYNC_WIDTH)) else '1';

    vdisplay_valid <= '1' when (line_count < VISIBLE_LINES_PER_FRAME) else '0';
    hdisplay_valid <= '1' when (pixel_count < VISIBLE_PIXELS_PER_LINE) else '0';
    display_valid <= hdisplay_valid and vdisplay_valid;
    
    VGA_R <= "0000" when (display_valid <= '0') else color(11 downto 8);
    VGA_G <= "0000" when (display_valid <= '0') else color(7 downto 4);
    VGA_B <= "0000" when (display_valid <= '0') else color(3 downto 0);

end Behavioral;
