library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ps2_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
		PS2_CLK : in std_logic;
        PS2_DATA : in std_logic;

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
end ps2_v1_0_S00_AXI;

architecture arch_imp of ps2_v1_0_S00_AXI is

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

	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;

	type state_type is (START, DATA0, DATA1, DATA2, DATA3, DATA4, DATA5, DATA6, DATA7, PARITY, STOP);
	signal state : state_type;
	type state2_type is (WAIT4CODE,WAIT4IRQACK,WAIT4ZERO);
	signal state2 : state2_type;
	signal scancode : std_logic_vector(7 downto 0);
	signal scancode_available : std_logic;
	signal irq_o : std_logic;
	signal key_pressed : std_logic_vector (11 downto 0);

begin
	-- I/O Connections assignments

	S_AXI_AWREADY	<= '0';
	S_AXI_WREADY	<= '0';
	S_AXI_BRESP	<= (others => '0');
	S_AXI_BVALID	<= '0';
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA	<= axi_rdata;
	S_AXI_RRESP	<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;

	-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- Read Address latching 
	        axi_araddr  <= S_AXI_ARADDR;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	    else
	      if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
	        -- Valid read data is available at the read data bus
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        -- Read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;

	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;
	
	

	-- Output register or memory read data
	process( S_AXI_ACLK ) is
	begin
	  if (rising_edge (S_AXI_ACLK)) then
	    if ( S_AXI_ARESETN = '0' ) then
	      axi_rdata  <= (others => '0');
	    else
	      if (slv_reg_rden = '1') then
	        -- When there is a valid read address (S_AXI_ARVALID) with 
	        -- acceptance of read address by the slave (axi_arready), 
	        -- output the read dada 
	        -- Read address mux
	          axi_rdata <= X"00000" & key_pressed;     -- register read data
	      end if;   
	    end if;
	  end if;
	end process;


	-- Add user logic here
	
	process(S_AXI_ACLK) is
	variable ku : std_logic;
	begin
	   if(S_AXI_ARESETN = '0') then
	       ku := '0';
	       key_pressed <= X"000";
	   elsif(S_AXI_ACLK'event and S_AXI_ACLK = '1') then
	       if(scancode = X"F0") then
	           ku := '1';
	       else
	           if(ku = '1') then
	               case scancode is
	                   when X"1D" => key_pressed <= X"001"; -- w
	                   when X"22" => key_pressed <= X"002"; -- x
	                   when X"23" => key_pressed <= X"003"; -- d
	                   when X"1C" => key_pressed <= X"004"; -- a
	                   when X"1B" => key_pressed <= X"005"; -- S small box
	                   when X"3A" => key_pressed <= X"006"; -- M medium box
	                   when X"4B" => key_pressed <= X"007"; -- L large box
	                   when X"2D" => key_pressed <= X"008"; -- R red box
	                   when X"34" => key_pressed <= X"009"; -- G green box
	                   when X"32" => key_pressed <= X"00A"; -- B blue box
	                   when others => key_pressed <= X"000"; -- nothing
	               end case;
	               ku := '0';
	           end if;
	       end if;
	   end if;
    end process;

	process( ps2_clk, S_AXI_ARESETN )
		variable code : std_logic_vector(7 downto 0);
		variable p : std_logic;
	begin
		if ( S_AXI_ARESETN = '0' ) then
			state <= START;
			scancode_available <= '0';
		elsif ( PS2_CLK'event and PS2_CLK='0' ) then
            case state is
                when START =>
                    if(PS2_DATA = '0') then
                        STATE <= DATA0;
                    else
                        STATE <= START;
                    end if;
                    
                    scancode_available <= '0';
                    
                when DATA0 =>
                    p := '1' xor PS2_DATA;
                    code(0) := PS2_DATA;
                    STATE <= DATA1;
                when DATA1 =>
                    p := p xor PS2_DATA;
                    code(1) := PS2_DATA;
                    STATE <= DATA2;
                when DATA2 => 
                    p := p xor PS2_DATA;
                    code(2) := PS2_DATA;
                    STATE <= DATA3;
                when DATA3 =>
                    p := p xor PS2_DATA;
                    code(3) := PS2_DATA;
                    STATE <= DATA4;
                when DATA4 =>
                    p := p xor PS2_DATA;
                    code(4) := PS2_DATA;
                    STATE <= DATA5;
                when DATA5 =>
                    p := p xor PS2_DATA;
                    code(5) := PS2_DATA;
                    STATE <= DATA6;
                when DATA6 =>
                    p := p xor PS2_DATA;
                    code(6) := PS2_DATA;
                    STATE <= DATA7;
                when DATA7 =>
                    p := p xor PS2_DATA;
                    code(7) := PS2_DATA;
                    STATE <= PARITY;
                when PARITY =>
                    if (p = PS2_DATA) then
                        STATE <= STOP;
                    else
                        STATE <= START;
                    end if;
                when STOP =>
                    scancode <= code;
                    scancode_available <= '1';
                    STATE <= START;
                end case;
                    
		end if;
	end process;

	-- User logic ends

end arch_imp;