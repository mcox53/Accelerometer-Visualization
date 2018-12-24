-- Author: M. Cox
-- Date: 11/6/18
-- Description: Reads frequency and volume from toggle switches and converts to a sine wave
-- Notes: Initial version, not checked for syntax or other errors


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sine_generator is 
	port(
		freq_input		: in std_logic_vector(7 downto 0);
		vol_input		: in std_logic_vector(3 downto 0);
		sys_clk			: in std_logic;
		sys_rstn		: in std_logic;
		AUD_PWM			: out std_logic;
		AUD_SD			: out std_logic
		);
		
end sine_generator;

architecture behavioral of sine_generator is

	signal pwm_counter	: integer range 0 to 256;
	signal sine_addr	: std_logic_vector(11 downto 0);
	signal scaled_freq	: std_logic_vector(13 downto 0);
	signal sine_data	: std_logic_vector(3 downto 0);
	signal sine_incr	: std_logic_vector(7 downto 0);
	signal pwm_duty		: std_logic_vector(7 downto 0);
	signal scale_var    : std_logic_vector(15 downto 0);

begin
    
    -- AUD_SD is always 1
	AUD_SD 		<= '1';
	
	-- Scale frequency input by 64
	scale_var <= X"40" * freq_input;
	scaled_freq <= scale_var(13 downto 0);
	
	-- PWM duty is determined by volume level
	pwm_duty 	<= vol_input * sine_data;
	
	
	-- AUD_PWM is driven to high impedance when logic '1'
	output_gen : process(sys_clk, sys_rstn)
	begin
		if(sys_rstn = '0') then
			AUD_PWM <= 'Z';
		elsif(sys_clk'event and sys_clk = '1') then
			if(pwm_counter <= pwm_duty) then
				AUD_PWM <= 'Z';
			else
				AUD_PWM <= '0';
			end if;
		end if;
	end process;

    -- Compare the duty with the pwm counter to determine on cycle of AUD_PWM
    -- Reset for every cycle
	duty_count : process(sys_clk, sys_rstn)
	begin
		if(sys_rstn = '0') then
			pwm_counter <= 0;
		elsif(sys_clk'event and sys_clk = '1') then
			pwm_counter <= pwm_counter + 1;
			if(pwm_counter >= 256) then
				pwm_counter <= 0;
			end if;
        end if;
	end process;
	
	-- Increment the Sine LUT address by the increment from the Frequency step LUT
	-- Reset if over the boundary
	addr_incr : process(sys_clk, sys_rstn)
	begin
		if(sys_rstn = '0') then
			sine_addr <= (others => '0');
		elsif(sys_clk'event and sys_clk = '1') then
			if(sine_addr >= X"FFF") then
				sine_addr <= (others => '0');
			else
				sine_addr <= sine_addr + sine_incr;
			end if;
		end if;
	end process;
	
	sine_mem : entity work.sine_mem
		port map(
			addr => sine_addr,
			data => sine_data,
			clk  => sys_clk
			);
	
	freq_step_LUT : entity work.freq_to_addr_LUT
		port map(
			freq => scaled_freq,
			addr => sine_incr
			);
			
end behavioral;