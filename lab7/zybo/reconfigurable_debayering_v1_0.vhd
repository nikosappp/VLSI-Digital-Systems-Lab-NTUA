library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reconfigurable_debayering_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4;

		-- Parameters of Axi Slave Bus Interface S00_AXIS
		C_S00_AXIS_TDATA_WIDTH	: integer	:= 8;

		-- Parameters of Axi Master Bus Interface M00_AXIS
		C_M00_AXIS_TDATA_WIDTH	: integer	:= 32;
		C_M00_AXIS_START_COUNT	: integer	:= 32
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_aclk	: in std_logic;
		s00_axis_aresetn	: in std_logic;
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		-- s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- s00_axis_tlast	: in std_logic;
		s00_axis_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_aclk	: in std_logic;
		m00_axis_aresetn	: in std_logic;
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		-- m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast	: out std_logic;
		m00_axis_tready	: in std_logic
	);
end reconfigurable_debayering_v1_0;

architecture arch_imp of reconfigurable_debayering_v1_0 is

	-- component declaration
	component reconfigurable_debayering_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic;
		
		o_image_dim 	: out std_logic_vector(11-1 downto 0);
		o_image_dim_vld : out std_logic
		);
	end component reconfigurable_debayering_v1_0_S00_AXI;

	-- component reconfigurable_debayering_v1_0_S00_AXIS is
	-- 	generic (
	-- 	C_S_AXIS_TDATA_WIDTH	: integer	:= 32
	-- 	);
	-- 	port (
	-- 	S_AXIS_ACLK	: in std_logic;
	-- 	S_AXIS_ARESETN	: in std_logic;
	-- 	S_AXIS_TREADY	: out std_logic;
	-- 	S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	-- 	S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
	-- 	S_AXIS_TLAST	: in std_logic;
	-- 	S_AXIS_TVALID	: in std_logic
	-- 	);
	-- end component reconfigurable_debayering_v1_0_S00_AXIS;

	-- component reconfigurable_debayering_v1_0_M00_AXIS is
	-- 	generic (
	-- 	C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
	-- 	C_M_START_COUNT	: integer	:= 32
	-- 	);
	-- 	port (
	-- 	M_AXIS_ACLK	: in std_logic;
	-- 	M_AXIS_ARESETN	: in std_logic;
	-- 	M_AXIS_TVALID	: out std_logic;
	-- 	M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
	-- 	M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
	-- 	M_AXIS_TLAST	: out std_logic;
	-- 	M_AXIS_TREADY	: in std_logic
	-- 	);
	-- end component reconfigurable_debayering_v1_0_M00_AXIS;

	-- Reconfigurable Debayering Filter Component Declaration
	component debayering_filter is
		port (
    	    clk            : in std_logic;
    	    rst_n          : in std_logic;
    	    new_image      : in std_logic;
    	    valid_in       : in std_logic;
    	    pixel          : in std_logic_vector(8-1 downto 0);
		
    	    -- Bonus Ports (Runtime Reconfiguration)
    	    image_dim      : in std_logic_vector(11-1 downto 0);
    	    image_dim_vld  : in std_logic;
		
    	    valid_out      : out std_logic;
    	    image_finished : out std_logic;
    	    R, G, B        : out std_logic_vector(8-1 downto 0)
    	);
	end component;

	-- Internal Signals for routing
	signal s_new_image		: std_logic;

	signal s_image_dim 	   	: std_logic_vector(11-1 downto 0);
	signal s_image_dim_vld 	: std_logic;

	signal s_valid_out 		: std_logic;
	signal s_image_finished : std_logic;
	signal s_R, s_G, s_B 	: std_logic_vector(8-1 downto 0);

	-- Flag to control TREADY
	signal is_configured 	: std_logic := '0';
	-- Flag to control new_image pulse
	signal waiting			: std_logic := '0';

begin

-- Instantiation of Axi Bus Interface S00_AXI
reconfigurable_debayering_v1_0_S00_AXI_inst : reconfigurable_debayering_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready,

		o_image_dim		=> s_image_dim,
		o_image_dim_vld	=> s_image_dim_vld
	);

-- -- Instantiation of Axi Bus Interface S00_AXIS
-- reconfigurable_debayering_v1_0_S00_AXIS_inst : reconfigurable_debayering_v1_0_S00_AXIS
-- 	generic map (
-- 		C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH
-- 	)
-- 	port map (
-- 		S_AXIS_ACLK	=> s00_axis_aclk,
-- 		S_AXIS_ARESETN	=> s00_axis_aresetn,
-- 		S_AXIS_TREADY	=> s00_axis_tready,
-- 		S_AXIS_TDATA	=> s00_axis_tdata,
-- 		S_AXIS_TSTRB	=> s00_axis_tstrb,
-- 		S_AXIS_TLAST	=> s00_axis_tlast,
-- 		S_AXIS_TVALID	=> s00_axis_tvalid
-- 	);

-- -- Instantiation of Axi Bus Interface M00_AXIS
-- reconfigurable_debayering_v1_0_M00_AXIS_inst : reconfigurable_debayering_v1_0_M00_AXIS
-- 	generic map (
-- 		C_M_AXIS_TDATA_WIDTH	=> C_M00_AXIS_TDATA_WIDTH,
-- 		C_M_START_COUNT	=> C_M00_AXIS_START_COUNT
-- 	)
-- 	port map (
-- 		M_AXIS_ACLK	=> m00_axis_aclk,
-- 		M_AXIS_ARESETN	=> m00_axis_aresetn,
-- 		M_AXIS_TVALID	=> m00_axis_tvalid,
-- 		M_AXIS_TDATA	=> m00_axis_tdata,
-- 		M_AXIS_TSTRB	=> m00_axis_tstrb,
-- 		M_AXIS_TLAST	=> m00_axis_tlast,
-- 		M_AXIS_TREADY	=> m00_axis_tready
-- 	);

	-- Add user logic here
	-- Track if the filter has been configured
	process (s00_axi_aclk)
	begin
		if (rising_edge(s00_axi_aclk)) then
			if (s00_axi_aresetn = '0') then
				is_configured <= '0';
				waiting		  <= '0';
			else 
				if (s_image_dim_vld = '1') then
					is_configured <= '1';
					waiting		  <= '1';
				elsif (waiting = '1' and s00_axis_tvalid = '1') then
					waiting <= '0';
				elsif (s_image_finished = '1') then
					waiting <= '1';
				end if;
			end if;
		end if;
	end process;

	-- Pulse new_image when the first pixel is fed to the filter
	s_new_image <= '1' when (waiting = '1' and s00_axis_tvalid = '1') else '0';

	-- Instantiate Debayering Filter
	u_debayering_filter : debayering_filter
	port map(
		clk 			=> s00_axi_aclk,
		rst_n 			=> s00_axi_aresetn,
		new_image 		=> s_new_image,
		valid_in 		=> s00_axis_tvalid,
		pixel 			=> s00_axis_tdata(8-1 downto 0),

		image_dim 		=> s_image_dim,
		image_dim_vld 	=> s_image_dim_vld,
		
		valid_out 		=> s_valid_out,
		image_finished 	=> s_image_finished,
		R 				=> s_R,
		G 				=> s_G,
		B 				=> s_B
	);

	-- AXI-Stream Slave logic
	s00_axis_tready <= is_configured;

	-- AXI-Stream Master logic
	m00_axis_tvalid 			 <= s_valid_out;
	m00_axis_tdata(31 downto 24) <= (others => '0');
	m00_axis_tdata(23 downto 0)  <= s_R & s_G & s_B;
	m00_axis_tlast				 <= s_image_finished;
	-- User logic ends

end arch_imp;
