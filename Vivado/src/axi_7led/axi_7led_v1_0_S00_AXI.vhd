library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_7led_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here
		
        -- if mode is 0, the write data is a 32-bit integer that is displayed in hex on the 8 7-segment digits
        -- if mode is 1, the write data is a 8-bit ASCII number that is displayed on right-most digit, all others shifted left
        C_S_7SEGLED_MODE : integer := 0;

		-- User parameters ends

		-- Do not modify the parameters beyond this line
		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here
		CA : out std_logic;
        CB : out std_logic;
        CC : out std_logic;
        CD : out std_logic;
        CE : out std_logic;
        CF : out std_logic;
        CG : out std_logic;
        DP : out std_logic;
        AN : out std_logic_vector(7 downto 0);
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end axi_7led_v1_0_S00_AXI;

architecture arch_imp of axi_7led_v1_0_S00_AXI is

	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 1;
	------------------------------------------------
	---- Signals for user logic register space example
    signal sys_rstn : std_logic;
    signal sys_clk : std_logic;

    signal segment0 : std_logic_vector(6 downto 0);
    signal segment : std_logic_vector(6 downto 0);

	signal onemsec_clk : std_logic;
    signal led_data : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal char0, char1, char2, char3 : std_logic_vector(7 downto 0);
    signal char4, char5, char6, char7 : std_logic_vector(7 downto 0);
    signal char8, char9, charA, charB : std_logic_vector(7 downto 0);
    signal charC, charD, charE, charF : std_logic_vector(7 downto 0);
	--------------------------------------------------
	---- Number of Slave Registers 4
	signal slv_reg_wren	: std_logic;
	signal byte_index	: integer;

begin
	-- I/O Connections assignments

	S_AXI_AWREADY	<= axi_awready;
	S_AXI_WREADY	<= axi_wready;
	S_AXI_BRESP	<= axi_bresp;
	S_AXI_BVALID	<= axi_bvalid;
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA	<= axi_rdata;
	S_AXI_RRESP	<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	        axi_awready <= '1';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

	process (S_AXI_ACLK)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
	variable ascii_data : std_logic_vector(7 downto 0);
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      led_data <= (others => '0');
		  charF <= X"20";
          charE <= X"20";
          charD <= X"20";
          charC <= X"20";
          charB <= X"20";
          charA <= X"20";
          char9 <= X"20";
          char8 <= X"20";
          char7 <= X"20";
          char6 <= X"20";
          char5 <= X"20";
          char4 <= X"20";
          char3 <= X"20";
          char2 <= X"20";
          char1 <= X"20";
          char0 <= X"20";
	    else
	      if (slv_reg_wren = '1') then
	          if (C_S_7SEGLED_MODE = 0) then
    	          led_data <= S_AXI_WDATA;
    	      else
                  -- use only the lower 8 bits of dat_i
                  ascii_data := S_AXI_WDATA(7 downto 0);
                  
                  -- if it is a backspace or delete key, shift the characters
                  -- down one and add it a space at the beginning.  Otherwise,
                  -- shift the characters up one and put the new character at the end.
    
                  if ( ascii_data = X"7F" or ascii_data = X"08" ) then
                      charF <= X"20";
                      charE <= charF;
                      charD <= charE;
                      charC <= charD;
                      charB <= charC;
                      charA <= charB;
                      char9 <= charA;
                      char8 <= char9;
                      char7 <= char8;
                      char6 <= char7;
                      char5 <= char6;
                      char4 <= char5;
                      char3 <= char4;
                      char2 <= char3;
                      char1 <= char2;
                      char0 <= char1;
                  else
                      charF <= charE;
                      charE <= charD;
                      charD <= charC;
                      charC <= charB;
                      charB <= charA;
                      charA <= char9;
                      char9 <= char8;
                      char8 <= char7;
                      char7 <= char6;
                      char6 <= char5;
                      char5 <= char4;
                      char4 <= char3;
                      char3 <= char2;
                      char2 <= char1;
                      char1 <= char0;
                      char0 <= ascii_data;
                  end if;
    	      end if;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Add user logic here

    sys_clk <= S_AXI_ACLK;
    sys_rstn <= S_AXI_ARESETN;
    (cg,cf,ce,cd,cc,cb,ca) <= segment;

 	onemsec_clk_divider : entity work.clock_divider
		generic map ( divisor => 100000 )
		port map ( clk_in => sys_clk, reset => sys_rstn, clk_out => onemsec_clk );

    data2ledsGEN : if (C_S_7SEGLED_MODE = 0) generate
    	data2leds : entity work.data2leds
            port map ( data => led_data,
                       onemsec_clk => onemsec_clk, 
                       sys_rst => sys_rstn,
                       enable => '1',
                       seg => segment,
                       dp => dp,
                       an => an );
    end generate;

    string2ledsGEN : if (C_S_7SEGLED_MODE /= 0) generate
        -- convert 16 characters to the appropriate digit and segment signals
        string2leds : entity work.string2leds
            port map ( char0 => char0, char1 => char1, char2 =>char2, char3 => char3,
					  char4 => char4, char5 => char5, char6 =>char6, char7 => char7,
					  char8 => char8, char9 => char9, charA =>charA, charB => charB,
					  charC => charC, charD => charD, charE =>charE, charF => charF,
					  onemsec_clk => onemsec_clk, 
					  sys_rst => sys_rstn,
				 	  enable => '1',
				      segment => segment,
					  dp => dp,
			 	 	  an => an );
    end generate;

	-- User logic ends

end arch_imp;
