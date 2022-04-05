library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity seq_cnn_hw_acc is
	generic (
		-- Users to add parameters here
		
		-- CNN value generics
		    LAYER1_INPUTS_WIDTH       : integer := 32;  -- 32-bit
		    --LAYER1_INPUTS_WIDTH       : integer := 16;  -- 16-bit
		    --LAYER1_INPUTS_WIDTH       : integer := 8;  -- 8-bit
        SCALE1                    : integer := 1970659685;
        SCALE1_WIDTH              : integer := 32;
        LAYER1_POST_PROC_WIDTH    : integer := 32;
        LAYER1_ACT_WIDTH          : integer := 8;
        LAYER1_WEIGHTS_WIDTH      : integer := 8;
        LAYER1_ROUNDING_MASK      : integer := -8192;
        -- CNN control generics
        DTA_RDY_DLY_CLKS          : integer := 20;
        -- MAC generics
        MAC_LAYER1_A_WIDTH        : integer := 32; -- 32-bit
        --MAC_LAYER1_A_WIDTH        : integer := 16; -- 16-bit
        --MAC_LAYER1_A_WIDTH        : integer := 8; -- 8-bit
        MAC_LAYER1_B_WIDTH        : integer := 8;
        MAC_LAYER1_OUT_WIDTH      : integer := 45;  -- 32-bit
        --MAC_LAYER1_OUT_WIDTH      : integer := 29;  -- 16-bit
        --MAC_LAYER1_OUT_WIDTH      : integer := 21;  -- 8-bit
        -- RAM generics
        RAM_LAYER1_SIZE           : integer := 96*96;
        RAM_LAYER1_WIDTH          : integer := 128;
    -- CNN value generics Layer 2
        LAYER2_INPUTS_WIDTH       : integer := 8;
        SCALE2_0                  : integer := 1067206272;
        SCALE2_1                  : integer := 977086912;
        SCALE2_2                  : integer := 1356887808;
        SCALE2_3                  : integer := 1112217984;
        SCALE2_4                  : integer := 1100564352;
        SCALE2_5                  : integer := 1024042880;
        SCALE2_6                  : integer := 970536832;
        SCALE2_7                  : integer := 1415932160;
        LAYER2_BATCH_NORM_BIAS0   : integer := 150;
        LAYER2_BATCH_NORM_BIAS1   : integer := -233;
        LAYER2_BATCH_NORM_BIAS2   : integer := 481;
        LAYER2_BATCH_NORM_BIAS3   : integer := 85;
        LAYER2_BATCH_NORM_BIAS4   : integer := 61;
        LAYER2_BATCH_NORM_BIAS5   : integer := -275;
        LAYER2_BATCH_NORM_BIAS6   : integer := -201;
        LAYER2_BATCH_NORM_BIAS7   : integer := 538;
        SCALE2_WIDTH              : integer := 32;
        LAYER2_POST_SCAL_SHFT     : integer := 24;
        LAYER2_POST_BIAS_SHFT     : integer := 1;
        LAYER2_POST_RNDG_SHFT     : integer := 12;
        LAYER2_POST_PROC_WIDTH    : integer := 32;
        LAYER2_ACT_WIDTH          : integer := 8;
        LAYER2_WEIGHTS_WIDTH      : integer := 8;
        LAYER2_ROUNDING_MASK      : integer := -4096;
        -- MAC generics
        MAC_LAYER2_A_WIDTH        : integer := 8;
        MAC_LAYER2_B_WIDTH        : integer := 8;
        MAC_LAYER2_OUT_WIDTH      : integer := 24;
        -- RAM generics
        RAM_LAYER2_SIZE           : integer := 96*96;
        RAM_LAYER2_WIDTH          : integer := 64;
    -- CNN value generics Layer 3
        LAYER3_INPUTS_WIDTH       : integer := 8;
        SCALE3                    : integer := 1540923957;
        LAYER3_CONV_BIAS0         : integer := -1443;
        LAYER3_CONV_BIAS1         : integer := -196;
        SCALE3_WIDTH              : integer := 32;
        LAYER3_POST_PROC_WIDTH    : integer := 32;
        LAYER3_POST_SCAL_SHFT     : integer := 23;
        LAYER3_POST_BIAS_SHFT     : integer := 1;
        LAYER3_WEIGHTS_WIDTH      : integer := 8;
        -- MAC generics
        MAC_LAYER3_A_WIDTH        : integer := 8;
        MAC_LAYER3_B_WIDTH        : integer := 8;
        MAC_LAYER3_OUT_WIDTH      : integer := 23;
        -- RAM generics
        RAM_LAYER3_SIZE           : integer := 96*96*2;
        RAM_LAYER3_WIDTH          : integer := 32;  -- 32-bit
        --RAM_LAYER3_WIDTH          : integer := 16;  -- 16-bit

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 8
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
		s00_axi_rready	: in std_logic
	);
end seq_cnn_hw_acc;

architecture arch_imp of seq_cnn_hw_acc is

	-- component declaration
	component seq_cnn_hw_acc_S00_AXI is
		generic (
		-- CNN value generics
		    LAYER1_INPUTS_WIDTH       : integer := 32;
        SCALE1                    : integer := 1970659685;
        SCALE1_WIDTH              : integer := 32;
        LAYER1_POST_PROC_WIDTH    : integer := 32;
        LAYER1_ACT_WIDTH          : integer := 8;
        LAYER1_WEIGHTS_WIDTH      : integer := 8;
        LAYER1_ROUNDING_MASK      : integer := -8192;
        -- CNN control generics
        DTA_RDY_DLY_CLKS          : integer := 20;
        -- MAC generics
        MAC_LAYER1_A_WIDTH        : integer := 32;
        MAC_LAYER1_B_WIDTH        : integer := 8;
        MAC_LAYER1_OUT_WIDTH      : integer := 45;
        -- RAM generics
        RAM_LAYER1_SIZE           : integer := 96*96;
        RAM_LAYER1_WIDTH          : integer := 128;
    -- CNN value generics Layer 2
        LAYER2_INPUTS_WIDTH       : integer := 8;
        SCALE2_0                  : integer := 1067206272;
        SCALE2_1                  : integer := 977086912;
        SCALE2_2                  : integer := 1356887808;
        SCALE2_3                  : integer := 1112217984;
        SCALE2_4                  : integer := 1100564352;
        SCALE2_5                  : integer := 1024042880;
        SCALE2_6                  : integer := 970536832;
        SCALE2_7                  : integer := 1415932160;
        LAYER2_BATCH_NORM_BIAS0   : integer := 150;
        LAYER2_BATCH_NORM_BIAS1   : integer := -233;
        LAYER2_BATCH_NORM_BIAS2   : integer := 481;
        LAYER2_BATCH_NORM_BIAS3   : integer := 85;
        LAYER2_BATCH_NORM_BIAS4   : integer := 61;
        LAYER2_BATCH_NORM_BIAS5   : integer := -275;
        LAYER2_BATCH_NORM_BIAS6   : integer := -201;
        LAYER2_BATCH_NORM_BIAS7   : integer := 538;
        SCALE2_WIDTH              : integer := 32;
        LAYER2_POST_SCAL_SHFT     : integer := 24;
        LAYER2_POST_BIAS_SHFT     : integer := 1;
        LAYER2_POST_RNDG_SHFT     : integer := 12;
        LAYER2_POST_PROC_WIDTH    : integer := 32;
        LAYER2_ACT_WIDTH          : integer := 8;
        LAYER2_WEIGHTS_WIDTH      : integer := 8;
        LAYER2_ROUNDING_MASK      : integer := -4096;
        -- MAC generics
        MAC_LAYER2_A_WIDTH        : integer := 8;
        MAC_LAYER2_B_WIDTH        : integer := 8;
        MAC_LAYER2_OUT_WIDTH      : integer := 24;
        -- RAM generics
        RAM_LAYER2_SIZE           : integer := 96*96;
        RAM_LAYER2_WIDTH          : integer := 64;
    -- CNN value generics Layer 3
        LAYER3_INPUTS_WIDTH       : integer := 8;
        SCALE3                    : integer := 1540923957;
        LAYER3_CONV_BIAS0         : integer := -1443;
        LAYER3_CONV_BIAS1         : integer := -196;
        SCALE3_WIDTH              : integer := 32;
        LAYER3_POST_PROC_WIDTH    : integer := 32;
        LAYER3_POST_SCAL_SHFT     : integer := 23;
        LAYER3_POST_BIAS_SHFT     : integer := 1;
        LAYER3_WEIGHTS_WIDTH      : integer := 8;
        -- MAC generics
        MAC_LAYER3_A_WIDTH        : integer := 8;
        MAC_LAYER3_B_WIDTH        : integer := 8;
        MAC_LAYER3_OUT_WIDTH      : integer := 23;
        -- RAM generics
        RAM_LAYER3_SIZE           : integer := 96*96*2;
        RAM_LAYER3_WIDTH          : integer := 32;
        
		C_S_AXI_DATA_WIDTH          	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	          : integer	:= 8
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
		S_AXI_RREADY	: in std_logic
		);
	end component seq_cnn_hw_acc_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
seq_cnn_hw_acc_S00_AXI_inst : seq_cnn_hw_acc_S00_AXI
	generic map (
	      LAYER1_INPUTS_WIDTH     => LAYER1_INPUTS_WIDTH,
	      SCALE1                  => SCALE1,
	      SCALE1_WIDTH            => SCALE1_WIDTH,
        LAYER1_POST_PROC_WIDTH  => LAYER1_POST_PROC_WIDTH,
        LAYER1_ACT_WIDTH        => LAYER1_ACT_WIDTH,
        LAYER1_WEIGHTS_WIDTH    => LAYER1_WEIGHTS_WIDTH,
        LAYER1_ROUNDING_MASK    => LAYER1_ROUNDING_MASK,
        DTA_RDY_DLY_CLKS        => DTA_RDY_DLY_CLKS,
        MAC_LAYER1_A_WIDTH             => MAC_LAYER1_A_WIDTH,
        MAC_LAYER1_B_WIDTH             => MAC_LAYER1_B_WIDTH,
        MAC_LAYER1_OUT_WIDTH           => MAC_LAYER1_OUT_WIDTH,
        RAM_LAYER1_SIZE         => RAM_LAYER1_SIZE,
        RAM_LAYER1_WIDTH        => RAM_LAYER1_WIDTH,
        LAYER2_INPUTS_WIDTH     => LAYER2_INPUTS_WIDTH,
        SCALE2_0                => SCALE2_0,
        SCALE2_1                => SCALE2_1,
        SCALE2_2                => SCALE2_2,
        SCALE2_3                => SCALE2_3,
        SCALE2_4                => SCALE2_4,
        SCALE2_5                => SCALE2_5,
        SCALE2_6                => SCALE2_6,
        SCALE2_7                => SCALE2_7,
        LAYER2_BATCH_NORM_BIAS0 => LAYER2_BATCH_NORM_BIAS0,
        LAYER2_BATCH_NORM_BIAS1 => LAYER2_BATCH_NORM_BIAS1,
        LAYER2_BATCH_NORM_BIAS2 => LAYER2_BATCH_NORM_BIAS2,
        LAYER2_BATCH_NORM_BIAS3 => LAYER2_BATCH_NORM_BIAS3,
        LAYER2_BATCH_NORM_BIAS4 => LAYER2_BATCH_NORM_BIAS4,
        LAYER2_BATCH_NORM_BIAS5 => LAYER2_BATCH_NORM_BIAS5,
        LAYER2_BATCH_NORM_BIAS6 => LAYER2_BATCH_NORM_BIAS6,
        LAYER2_BATCH_NORM_BIAS7 => LAYER2_BATCH_NORM_BIAS7,
        SCALE2_WIDTH            => SCALE2_WIDTH,
        LAYER2_POST_SCAL_SHFT   => LAYER2_POST_SCAL_SHFT,
        LAYER2_POST_BIAS_SHFT   => LAYER2_POST_BIAS_SHFT,
        LAYER2_POST_RNDG_SHFT   => LAYER2_POST_RNDG_SHFT,
        LAYER2_POST_PROC_WIDTH  => LAYER2_POST_PROC_WIDTH,
        LAYER2_ACT_WIDTH        => LAYER2_ACT_WIDTH,
        LAYER2_WEIGHTS_WIDTH    => LAYER2_WEIGHTS_WIDTH,
        LAYER2_ROUNDING_MASK    => LAYER2_ROUNDING_MASK,
        MAC_LAYER2_A_WIDTH      => MAC_LAYER2_A_WIDTH,
        MAC_LAYER2_B_WIDTH      => MAC_LAYER2_B_WIDTH,
        MAC_LAYER2_OUT_WIDTH    => MAC_LAYER2_OUT_WIDTH,
        RAM_LAYER2_SIZE         => RAM_LAYER2_SIZE,
        RAM_LAYER2_WIDTH        => RAM_LAYER2_WIDTH,
        LAYER3_INPUTS_WIDTH     => LAYER3_INPUTS_WIDTH,
        SCALE3                  => SCALE3,
        LAYER3_CONV_BIAS0       => LAYER3_CONV_BIAS0,
        LAYER3_CONV_BIAS1       => LAYER3_CONV_BIAS1,
        SCALE3_WIDTH            => SCALE3_WIDTH,
        LAYER3_POST_PROC_WIDTH  => LAYER3_POST_PROC_WIDTH,
        LAYER3_POST_SCAL_SHFT   => LAYER3_POST_SCAL_SHFT,
        LAYER3_POST_BIAS_SHFT   => LAYER3_POST_BIAS_SHFT,
        LAYER3_WEIGHTS_WIDTH    => LAYER3_WEIGHTS_WIDTH,
        MAC_LAYER3_A_WIDTH      => MAC_LAYER3_A_WIDTH,
        MAC_LAYER3_B_WIDTH      => MAC_LAYER3_B_WIDTH,
        MAC_LAYER3_OUT_WIDTH    => MAC_LAYER3_OUT_WIDTH,
        RAM_LAYER3_SIZE         => RAM_LAYER3_SIZE,
        RAM_LAYER3_WIDTH        => RAM_LAYER3_WIDTH,
		C_S_AXI_DATA_WIDTH	        => C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	        => C_S00_AXI_ADDR_WIDTH
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
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here

	-- User logic ends

end arch_imp;
