-- This vga module is a rewritten verison of my previous module for the accelerometer
-- This module specifically now writes data for 1280 x 1024 displays
-- The module I wrote for 640 x 480 gave me problems on some displays and needs to be accurate for this project
-- Most signals are double buffered by default
-- Let it be fully known that pieces of this code were borrowed or inspired by Digilent Nexys 4 DDR OOB Test
-- Module requires a 108 MHz clock for 1280 x 1024

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.math_real.all;


entity vga_top is
	port(
		PXL_CLK			: in std_logic;
		RESETN			: in std_logic;
		VGA_HS			: out std_logic;
		VGA_VS			: out std_logic;
		VGA_R			: out std_logic;
		VGA_G			: out std_logic;
		VGA_B			: out std_logic;
		
		-- Accelerometer specific signals
		ACC_BOX_SIZE	: in std_logic_vector(11 downto 0);
		ACC BOX_INNER 	: in std_logic_vector(11 downto 0);
		ACC_X_IN		: in std_logic_vector(8 downto 0);
		ACC_Y_IN		: in std_logic_vector(8 downto 0);
		ACC_MAG_IN		: in std_logic_vector(11 downto 0)
		);
		
end vga_top;

architecture behavioral of vga_top is 


-- instantiate modified version of Digilent VGA display module

	entity work.AccelDisplay
	GENERIC MAP(
		 X_XY_WIDTH   : natural := 511; -- Width of the Accelerometer frame X-Y region
         X_MAG_WIDTH  : natural := 50;  -- Width of the Accelerometer frame Magnitude region
         Y_HEIGHT     : natural := 511; -- Height of the Accelerometer frame
         X_START      : natural := 385; -- Accelerometer frame X-Y region starting horizontal location
         Y_START      : natural := 80; -- Accelerometer frame starting vertical location
         BG_COLOR : STD_LOGIC_VECTOR (11 downto 0) := x"FFF"; -- Background color - white
         ACTIVE_COLOR : STD_LOGIC_VECTOR (11 downto 0) := x"0F0"; -- Green when inside the threshold box
         WARNING_COLOR : STD_LOGIC_VECTOR (11 downto 0) := x"F00" -- Red when outside the threshold box
			)
			
    PORT MAP( 
         CLK_I : IN std_logic;
         H_COUNT_I : IN std_logic_vector(11 downto 0);
         V_COUNT_I : IN std_logic_vector(11 downto 0);
         ACCEL_X_I : IN std_logic_vector(8 downto 0); -- X acceleration input data
         ACCEL_Y_I : IN std_logic_vector(8 downto 0); -- Y acceleration input data
         ACCEL_MAG_I : IN std_logic_vector(8 downto 0); -- Acceleration magnitude input data
         ACCEL_RADIUS : IN  STD_LOGIC_VECTOR (11 downto 0); -- Size of the box moving according to acceleration data
         LEVEL_THRESH : IN  STD_LOGIC_VECTOR (11 downto 0); -- Size of the threshold box
         -- Accelerometer Red, Green and Blue signals
         RED_O    : OUT std_logic_vector(3 downto 0);
         BLUE_O   : OUT std_logic_vector(3 downto 0);
         GREEN_O  : OUT std_logic_vector(3 downto 0)
         );
	

-- VGA 1280 x 1024 60Hz constants from online resources

constant T_WIDTH : natural := 1280;
constant T_HEIGHT: natural := 1024;

constant HOR_FRT_POR : natural := 48
constant HOR_POR_WID : natural := 112;
constant HOR_BCK_POR : natural := 248;
constant HOR_PERIOD  : natural := 1688;

constant VER_FRT_POR : natural := 1;
constant VER_POR_WID : natural := 3;
constant VER_BCK_POR : natural := 38;
constant VER_PERIOD  : natural := 1066;

constant HOR_POL 	 : std_logic := '1';
constant VER_POL	 : std_logic := '1';

-- Accelerometer display constants
-- Includes location data for visualization
-- Used to write when within region
-- Taken directly form Digilent Github

constant SZ_ACL_XY_WIDTH   : natural := 511; -- Width of the Accelerometer frame X-Y Region
constant SZ_ACL_MAG_WIDTH  : natural := 45; -- Width of the Accelerometer frame Magnitude Region
constant SZ_ACL_WIDTH  		: natural := SZ_ACL_XY_WIDTH + SZ_ACL_MAG_WIDTH; -- Width of the entire Accelerometer frame
constant SZ_ACL_HEIGHT 		: natural := 511; -- Height of the Accelerometer frame

constant FRM_ACL_H_LOC 		: natural := 385; -- Accelerometer frame X-Y region starting horizontal location
constant FRM_ACL_MAG_LOC 	: natural := FRM_ACL_H_LOC + SZ_ACL_MAG_WIDTH; -- Accelerometer frame Magnitude Region starting horizontal location
constant FRM_ACL_V_LOC 		: natural := 80; -- Accelerometer frame starting vertical location
-- Accelerometer Display frame limits
constant ACL_LEFT				: natural := FRM_ACL_H_LOC - 1;
constant ACL_RIGHT			: natural := FRM_ACL_H_LOC + SZ_ACL_WIDTH + 1;
constant ACL_TOP				: natural := FRM_ACL_V_LOC - 1;
constant ACL_BOTTOM			: natural := FRM_ACL_V_LOC + SZ_ACL_HEIGHT + 1;


-- Signals

-- Display Signals

signal display_active : std_logic;

signal h_cnt : std_logic_vector(11 downto 0) := (others => '0');
signal v_cnt : std_logic_vector(11 downto 0) := (others => '0');

signal h_cnt_reg : std_logic_vector(11 downto 0) := (others => '0');
signal v_cnt_reg : std_logic_vector(11 downto 0) := (others => '0');

signal h_sync : std_logic := not(HOR_POL);
signal v_sync : std_logic := not(VER_POL);

signal h_sync_reg : std_logic := not(HOR_POL);
signal v_sync_reg : std_logic := not(VER_POL);

-- Color signals set by keyboard, accel, etc

signal vga_red : std_logic_vector(3 downto 0);
signal vga_green : std_logic_vector(3 downto 0);
signal vga_blue : std_logic_vector(3 downto 0);

-- Color signals verified with display active

signal vga_red_act : std_logic_vector(3 downto 0) := (others => '0');
signal vga_green_act : std_logic_vector(3 downto 0) := (others => '0');
signal vga_blue_act : std_logic_vector(3 downto 0) : = (others => '0');

-- Buffered color signals connected to output

signal vga_red_reg : std_logic_vector(3 downto 0); 
signal vga_green_reg : std_logic_vector(3 downto 0);
signal vga_blue_reg : std_logic_vector(3 downto 0);

-- Register Accelerometer signals

signal ACCEL_X_I_REG	: std_logic_vector(8 downto 0);
signal ACCEL_Y_I_REG	: std_logic_vector(8 downto 0);
signal ACCEL_MAG_I_REG	: std_logic_vector(11 downto 0);
signal ACCEL_RADIUS_REG	: std_logic_vector(11 downto 0);
signal LEVEL_THRESH_REG	: std_logic_vector(11 downto 0);

signal ACCEL_RED		: std_logic_vector(3 downto 0);
signal ACCEL_GREEN		: std_logic_vector(3 downto 0);
signal ACCEL_BLUE		: std_logic_vector(3 downto 0);

signal ACCEL_RED_REG	: std_logic_vector(3 downto 0);
signal ACCEL_GREEN_REG	: std_logic_vector(3 downto 0);
signal ACCEL_BLUE_REG	: std_logic_vector(3 downto 0);


begin

	display_active <= '1' when (h_cnt < T_WIDTH and v_cnt < T_HEIGHT)
					  else '0';

	vga_red_act <= (display_active & display_active & display_active & display_active) and vga_red;
	vga_green_act <= (display_active & display_active & display_active & display_active) and vga_green;
	vga_blue_act <= (display_active & display_active & display_active & display_active) and vga_blue;
	
	VGA_HS <= h_sync;
	VGA_VS <= v_sync;
	VGA_R <= vga_red_reg;
	VGA_G <= vga_green_reg;
	VGA_B <= vga_blue_reg;


-- Register incoming signals and other internal signals relating to VGA
signal_register : process(PXL_CLK)
begin
	if(PXL_CLK'event and PXL_CLK = '1') then
		
		ACCEL_RED_REG <= ACCEL_RED;
		ACCEL_GREEN_REG <= ACCEL_GREEN;
		ACCEL_BLUE_REG <= ACCEL_BLUE;
		
		h_cnt <= h_cnt_reg;
		v_cnt <= v_cnt_reg;
		
		h_sync <= h_sync_reg;
		v_sync <= v_sync_reg;
		
		vga_red_reg <= vga_red_act;
		vga_green_reg <= vga_green_act;
		vga_blue_act <= vga_blue_act;
		
	end if;
end process;

-- Register signals that have a slow refresh rate in the blanking area
slow_signal_register : process(PXL_CLK, v_sync_reg)
begin
	if(PXL_CLK'event and PXL_CLK = '1') then
		if(v_sync_reg = VER_POL) then
			
			ACCEL_X_I_REG <= ACCEL_X_I;	
			ACCEL_Y_I_REG <= ACCEl_Y_I;
			ACCEL_MAG_I_REG <= ACCEL_MAG_I;
			ACCEL_RADIUS_REG <= ACCEL_RADIUS;
            LEVEL_THRESH_REG <= LEVEL_THRESH;
			
		end if
	end if;
end process;

horizontal_count : process(PXL_CLK)
begin
	if(PXL_CLK'event and PXL_CLK = '1') then
		if(h_cnt_reg >= (HOR_PERIOD - 1)) then
			h_cnt_reg <= (others => '0');
		else
			h_cnt_reg <= h_cnt_reg + 1;
		end if;
	end if;
end process;

vertical_count : process(PXL_CLK)
begin
	if(PXL_CLK'event and PXL_CLK = '1') then
		if((h_cnt_reg >= (HOR_PERIOD - 1)) and (v_cnt_reg >= (VER_PERIOD - 1))) then
			v_cnt_reg <= (others => '0');
		elsif (h_cnt_reg = (HOR_PERIOD - 1)) then
			v_cnt_reg <= v_cnt_reg + 1;
		end if;
	end if;
end process;

horizontal_sync : process(PXL_CLK)
begin
	if(PXL_CLK'event and PXL_CLK = '1') then
		if(h_cnt_reg >= (T_WIDTH + HOR_FRT_POR - 1)) and (h_cnt_reg < (T_WIDTH + HOR_FRT_POR + HOR_POR_WID - 1)) then
			h_sync_reg <= HOR_POL;
		else
			h_sync_reg <= not(HOR_POL);
		end if;
	end if;
end proces;

vertical_sync : process(PXL_CLK)
begin
	if(PXL_CLK'event and PXL_CLK = '1') then
		if(v_cnt_reg >= (T_HEIGHT + VER_FRT_POR - 1)) and (v_cnt_reg < (T_HEIGHT + VER_FRT_POR + VER_POR_WID - 1)) then
			v_sync_reg <= VER_POL;
		else
			v_sync_reg <= not(VER_POL);
		end if;
	end if;
end process;

ACCEL_INST : AccelDisplay
	GENERIC MAP(
	
		)
	PORT(
		RED_O => ACCEL_RED,
		GREEN_O => ACCEL_GREEN,
		BLUE_O => ACCEL_BLUE
		);




