library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity seq_cnn_hw_acc_S00_AXI is
	generic (
		-- Users to add parameters here
		
		-- CNN value generics Layer 1
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
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 8
	);
	port (
		-- Users to add ports here

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
end seq_cnn_hw_acc_S00_AXI;

architecture arch_imp of seq_cnn_hw_acc_S00_AXI is

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
	constant OPT_MEM_ADDR_BITS : integer := 5;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers 36
	signal slv_reg0	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg1	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg2	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg3	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg4	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg5	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg6	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg7	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg8	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg9	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg10	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg11	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg12	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg13	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg14	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg15	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg16	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg17	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg18	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg19	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg20	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg21	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg22	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg23	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg24	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg25	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg26	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg27	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg28	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg29	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg30	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg31	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg32	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg33	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg34	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg35	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal reg_data_out	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	: integer;
	signal aw_en	: std_logic;
	
	-- layer 1 component
	component LG_Layer1
    Generic (
      INPUTS_WIDTH     : integer := 32;
      SCALE1           : integer := 1970659685;
      SCALE1_WIDTH     : integer := 32;
      POST_PROC_WIDTH  : integer := 32;
      ACT_WIDTH        : integer := 8;
      WEIGHTS_WIDTH    : integer := 8;
      ROUNDING_MASK    : integer := -8192;
      DTA_RDY_DLY_CLKS : integer := 20;
      MAC_A_WIDTH      : integer := 32;
      MAC_B_WIDTH      : integer := 8;
      MAC_OUT_WIDTH    : integer := 45);
    Port (
      input_tensor     : in  std_logic_vector(3*3*2*INPUTS_WIDTH-1 downto 0);
      output_vector    : out std_logic_vector(16*ACT_WIDTH-1 downto 0);
      data_rdy_in      : in std_logic;
      data_rdy_out     : out std_logic;
      rst_in           : in std_logic;
      clk              : in std_logic);
    end component;
    
    -- layer 2 component
    component LG_Layer2
    Generic (
      START_OUTPUT            : integer := 0;
      STOP_OUTPUT             : integer := 3;
      INPUTS_WIDTH            : integer := 8;
      SCALE2_0                : integer := 1067206272;
      SCALE2_1                : integer := 977086912;
      SCALE2_2                : integer := 1356887808;
      SCALE2_3                : integer := 1112217984;
      SCALE2_4                : integer := 1100564352;
      SCALE2_5                : integer := 1024042880;
      SCALE2_6                : integer := 970536832;
      SCALE2_7                : integer := 1415932160;
      LAYER2_BATCH_NORM_BIAS0 : integer := 150;
      LAYER2_BATCH_NORM_BIAS1 : integer := -233;
      LAYER2_BATCH_NORM_BIAS2 : integer := 481;
      LAYER2_BATCH_NORM_BIAS3 : integer := 85;
      LAYER2_BATCH_NORM_BIAS4 : integer := 61;
      LAYER2_BATCH_NORM_BIAS5 : integer := -275;
      LAYER2_BATCH_NORM_BIAS6 : integer := -201;
      LAYER2_BATCH_NORM_BIAS7 : integer := 538;
      SCALE2_WIDTH            : integer := 32;
      LAYER2_POST_SCAL_SHFT   : integer := 24;
      LAYER2_POST_BIAS_SHFT   : integer := 1;
      LAYER2_POST_RNDG_SHFT   : integer := 12;
      POST_PROC_WIDTH         : integer := 32;
      ACT_WIDTH               : integer := 8;
      WEIGHTS_WIDTH           : integer := 8;
      ROUNDING_MASK           : integer := -4096;
      MAC_LAYER2_A_WIDTH      : integer := 8;
      MAC_LAYER2_B_WIDTH      : integer := 8;
      MAC_LAYER2_OUT_WIDTH    : integer := 24);
    Port (
      input_tensor            : in  std_logic_vector(3*3*16*INPUTS_WIDTH-1 downto 0);  -- (3x3x16) (x,y,z)
      output_vector           : out std_logic_vector(2*ACT_WIDTH-1 downto 0);          -- (8)
      --output_vector           : out std_logic_vector(2*2*ACT_WIDTH-1 downto 0);          -- (8)
      --output_vector           : out std_logic_vector(2*2*2*ACT_WIDTH-1 downto 0);          -- (8)
      data_rdy_in             : in  std_logic;                                         -- PS signal that it's done writing input_tensor
      data_rdy_out            : out std_logic;                                         -- PL signal that it's done processing
      rst_in                  : in  std_logic;                                         -- active low reset
      clk                     : in  std_logic);
    end component;
    
    -- layer 3 component
    component LG_Layer3
    Generic (
      INPUTS_WIDTH          : integer := 8;
      SCALE3                : integer := 1540923957;
      LAYER3_CONV_BIAS0     : integer := -1443;
      LAYER3_CONV_BIAS1     : integer := -196;
      SCALE3_WIDTH          : integer := 32;
      POST_PROC_WIDTH       : integer := 32;
      LAYER3_POST_SCAL_SHFT : integer := 23;
      LAYER3_POST_BIAS_SHFT : integer := 1;
      WEIGHTS_WIDTH         : integer := 8;
      MAC_LAYER3_A_WIDTH    : integer := 8;
      MAC_LAYER3_B_WIDTH    : integer := 8;
      MAC_LAYER3_OUT_WIDTH  : integer := 23);
    Port (
      input_tensor          : in  std_logic_vector(3*3*8*INPUTS_WIDTH-1 downto 0);  -- (3x3x8) (x,y,z)
      output_vector         : out std_logic_vector(2*POST_PROC_WIDTH-1 downto 0);   -- (2)  --32-bit
      --output_vector         : out std_logic_vector(2*16-1 downto 0);   -- (2)  --16-bit
      data_rdy_in           : in  std_logic;                                        -- PS signal that it's done writing input_tensor
      data_rdy_out          : out std_logic;                                        -- PL signal that it's done processing
      rst_in                : in  std_logic;                                        -- active low reset
      clk                   : in  std_logic);
    end component;
    
    -- layer 1 RAM component
    component layer1_output_mem
    Generic (
      WORD_SIZE     : integer := 128;
      RAM_SIZE      : integer := 96*96);
    Port (
      clk           : in std_logic;
      block_address : in integer range 0 to 96*96-1;  -- pixels in one row
      we            : in std_logic;
      re            : in std_logic;
      data_i        : in std_logic_vector(WORD_SIZE-1 downto 0);
      data_o        : out std_logic_vector(WORD_SIZE-1 downto 0));
    end component;
    
    -- layer 2 RAM component
    component layer2_output_mem
    Generic (
      WORD_SIZE     : integer := 64;
      RAM_SIZE      : integer := 96*96);
    Port (
      clk           : in std_logic;
      block_address : in integer range 0 to 96*96-1;  -- pixels in one row
      we            : in std_logic;
      re            : in std_logic;
      data_i        : in std_logic_vector(WORD_SIZE-1 downto 0);
      data_o        : out std_logic_vector(WORD_SIZE-1 downto 0));
    end component;
    
    -- layer 3 RAM component
    component layer3_output_mem
    Generic (
      WORD_SIZE     : integer := 32;
      RAM_SIZE      : integer := 96*96*2);
    Port (
      clk           : in std_logic;
      block_address : in integer range 0 to 96*96*2-1;  -- pixels in one row
      we            : in std_logic;
      re            : in std_logic;
      data_i        : in signed(WORD_SIZE-1 downto 0);
      data_o        : out signed(WORD_SIZE-1 downto 0));
    end component;
  
    -- definition of output tensor
    subtype gen_int_0 is unsigned (LAYER1_ACT_WIDTH-1 downto 0);
    type output_matrix_layer1 is array (0 to 15) of gen_int_0;
  
    -- direct layer 1 signals
    signal input_tensor_layer1_s          : std_logic_vector(3*3*2*LAYER1_INPUTS_WIDTH-1 downto 0);
    signal output_vector_layer1_s         : std_logic_vector(16*LAYER1_ACT_WIDTH-1 downto 0);
    --signal output_matrix_layer1_s         : output_matrix_layer1;
    signal data_rdy_in_layer1_s           : std_logic;
    signal data_rdy_in_register_layer1_s  : std_logic := '0';
    signal data_rdy_out_layer1_s          : std_logic;
    signal data_rdy_out_register_layer1_s : std_logic := '0';
    
    -- other layer 1 signal
    signal layer1_block_counter_s  : integer range 0 to 96-1:= 0;  -- counts the pixels in a row
    signal layer1_result_counter_s : integer range 0 to 96*96-1 := 0;  -- counts the progress of the image processing
    
    -- layer 1 ram signals
    signal layer1_mem_wr_data_s     : std_logic_vector(RAM_LAYER1_WIDTH-1 downto 0) := (others => '0');
    signal layer1_mem_rd_data_s     : std_logic_vector(RAM_LAYER1_WIDTH-1 downto 0) := (others => '0');
    signal layer1_mem_address_s     : integer range 0 to 96*96-1 := 0;
    signal layer1_mem_we_s          : std_logic := '0';  -- write enable for the layer1 output ram
    signal layer1_mem_re_s          : std_logic := '0';  -- read enable for the layer1 output ram
    --signal layer1_mem_read_buf_s    : std_logic_vector(127 downto 0) := (others => '0');  -- temporary read buffer
    --signal layer1_mem_shift_steps_s : integer range 0 to 16-1 := 0;  -- 16 steps are needed to store all outputs
    signal layer1_mem_wr_index_s    : integer range 0 to 96*96-1 := 0;  -- this is the running index in order to store values in ram
    
    -- layer 2 ram signals
    signal layer2_mem_wr_data_s     : std_logic_vector(RAM_LAYER2_WIDTH-1 downto 0) := (others => '0');
    signal layer2_mem_rd_data_s     : std_logic_vector(RAM_LAYER2_WIDTH-1 downto 0) := (others => '0');
    signal layer2_mem_address_s     : integer range 0 to 96*96-1 := 0;
    signal layer2_mem_we_s          : std_logic := '0';  -- write enable for the layer2 output ram
    signal layer2_mem_re_s          : std_logic := '0';  -- read enable for the layer2 output ram
    --signal layer2_mem_shift_steps_s : integer range 0 to 8-1 := 0;  -- 8 steps are needed to store all outputs
    signal layer2_mem_wr_index_s    : integer range 0 to 96*96-1 := 0;  -- this is the running index in order to store values in ram
    
    -- layer 3 ram signals
    signal layer3_mem_wr_data_s     : signed(RAM_LAYER3_WIDTH-1 downto 0) := (others => '0');
    signal layer3_mem_rd_data_s     : signed(RAM_LAYER3_WIDTH-1 downto 0) := (others => '0');
    signal layer3_mem_address_s     : integer range 0 to 96*96*2-1 := 0;
    signal layer3_mem_we_s          : std_logic := '0';  -- write enable for the layer3 output ram
    signal layer3_mem_re_s          : std_logic := '0';  -- read enable for the layer3 output ram
    signal layer3_mem_shift_steps_s : integer range 0 to 2-1 := 0;  -- 2 steps are needed to store all outputs
    signal layer3_mem_wr_index_s    : integer range 0 to 96*96*2-1 := 0;  -- this is the running index in order to store values in ram
    
    -- layer 1shift registers for input kernel maps
    signal input_buf_layer1_s  : std_logic_vector(2*3*2*LAYER1_INPUTS_WIDTH-1 downto 0) := (others => '0');
    --signal input_buf0_layer1_s  : signed(31 downto 0) := (others => '0');
    --signal input_buf1_layer1_s  : signed(31 downto 0) := (others => '0');
    --signal input_buf2_layer1_s  : signed(31 downto 0) := (others => '0');
    --signal input_buf3_layer1_s  : signed(31 downto 0) := (others => '0');
    --signal input_buf4_layer1_s  : signed(31 downto 0) := (others => '0');
    --signal input_buf5_layer1_s  : signed(31 downto 0) := (others => '0');
    --signal input_buf6_layer1_s  : signed(31 downto 0) := (others => '0');
    --signal input_buf7_layer1_s  : signed(31 downto 0) := (others => '0');
    --signal input_buf8_layer1_s  : signed(31 downto 0) := (others => '0');
    --signal input_buf9_layer1_s  : signed(31 downto 0) := (others => '0');
    --signal input_buf10_layer1_s : signed(31 downto 0) := (others => '0');
    --signal input_buf11_layer1_s : signed(31 downto 0) := (others => '0');
    
    -- definition of input tensor
    subtype gen_int_1 is unsigned (LAYER2_INPUTS_WIDTH-1 downto 0);
    type input_matrix_layer2 is array (0 to 2, 0 to 2, 0 to 15) of gen_int_1;
    
    -- definition of output tensor
    subtype gen_int_2 is unsigned (LAYER2_ACT_WIDTH-1 downto 0);
    type output_matrix_layer2 is array (0 to 7) of gen_int_2;
    
    -- layer 2 signals
    signal input_tensor_layer2_s     : std_logic_vector(3*3*16*LAYER2_INPUTS_WIDTH-1 downto 0);  -- (3x3x16) (x,y,z)
    signal input_matrix_layer2_s     : input_matrix_layer2;                                      -- (3x3x16) (x,y,z)
    signal output_vector_layer2_s    : std_logic_vector(8*LAYER2_ACT_WIDTH-1 downto 0);          -- (8)
    --signal output_matrix_layer2_s    : output_matrix_layer2;                                     -- (8)
    signal data_rdy_in_layer2_s      : std_logic;                                                -- PS signal that it's done writing input_tensor
    signal data_rdy_out_layer2_s     : std_logic;
    signal data_rdy_out_layer2_dummy0_s     : std_logic;
    signal data_rdy_out_layer2_dummy1_s     : std_logic;
    signal data_rdy_out_layer2_dummy2_s     : std_logic;
    signal layer2_index_x_s          : signed(7 downto 0) := (others => '0');
    signal layer2_index_y_s          : signed(7 downto 0) := (others => '0');
    signal layer2_kernel_x_s         : signed(2 downto 0) := (others => '0');
    signal layer2_kernel_y_s         : signed(2 downto 0) := (others => '0');
    signal layer2_kernel_x_dld0_s    : signed(2 downto 0) := (others => '0');
    signal layer2_kernel_y_dld0_s    : signed(2 downto 0) := (others => '0');
    signal layer2_kernel_x_dld1_s    : signed(2 downto 0) := (others => '0');
    signal layer2_kernel_y_dld1_s    : signed(2 downto 0) := (others => '0');
    signal layer2_kernel_x_dld2_s    : signed(2 downto 0) := (others => '0');
    signal layer2_kernel_y_dld2_s    : signed(2 downto 0) := (others => '0');
    signal layer2_kernel_x_dld3_s    : signed(2 downto 0) := (others => '0');
    signal layer2_kernel_y_dld3_s    : signed(2 downto 0) := (others => '0');
    signal layer2_kernel_x_dld4_s    : signed(2 downto 0) := (others => '0');
    signal layer2_kernel_y_dld4_s    : signed(2 downto 0) := (others => '0');
    --signal layer2_prev_output_s      : signed(4 downto 0) := (others => '0');
    --signal layer2_prev_output_dld0_s : signed(4 downto 0) := (others => '0');
    --signal layer2_prev_output_dld1_s : signed(4 downto 0) := (others => '0');
    --signal layer2_prev_output_dld2_s : signed(4 downto 0) := (others => '0');
    --signal layer2_prev_output_dld3_s : signed(4 downto 0) := (others => '0');
    --signal layer2_prev_output_dld4_s : signed(4 downto 0) := (others => '0');
    signal layer2_address_x_s        : signed(7 downto 0) := (others => '0');
    signal layer2_address_y_s        : signed(7 downto 0) := (others => '0');
    signal layer2_address_x_dld0_s   : signed(7 downto 0) := (others => '0');
    signal layer2_address_y_dld0_s   : signed(7 downto 0) := (others => '0');
    signal layer2_address_x_dld1_s   : signed(7 downto 0) := (others => '0');
    signal layer2_address_y_dld1_s   : signed(7 downto 0) := (others => '0');
    signal layer2_address_x_dld2_s   : signed(7 downto 0) := (others => '0');
    signal layer2_address_y_dld2_s   : signed(7 downto 0) := (others => '0');
    signal layer2_address_x_dld3_s   : signed(7 downto 0) := (others => '0');
    signal layer2_address_y_dld3_s   : signed(7 downto 0) := (others => '0');
    signal layer2_address_x_dld4_s   : signed(7 downto 0) := (others => '0');
    signal layer2_address_y_dld4_s   : signed(7 downto 0) := (others => '0');
    signal layer2_address_part1_s    : unsigned(17 downto 0);
    signal layer2_address_part2_s    : unsigned(17 downto 0);
    signal layer2_address_s          : unsigned(17 downto 0);
    
    -- definition of input tensor
    subtype gen_int_3 is unsigned (LAYER3_INPUTS_WIDTH-1 downto 0);
    type input_matrix_layer3 is array (0 to 2, 0 to 2, 0 to 7) of gen_int_3;
    
    -- definition of output tensor
    subtype gen_int_4 is signed (LAYER3_POST_PROC_WIDTH-1 downto 0); -- 32-bit
    --subtype gen_int_4 is signed (16-1 downto 0); -- 16-bit
    type output_matrix_layer3 is array (0 to 1) of gen_int_4;
    
    -- layer 3 signals
    signal input_tensor_layer3_s     : std_logic_vector(3*3*8*LAYER3_INPUTS_WIDTH-1 downto 0);  -- (3x3x8) (x,y,z)
    signal input_matrix_layer3_s     : input_matrix_layer3;                                     -- (3x3x8) (x,y,z)
    signal output_vector_layer3_s    : std_logic_vector(2*LAYER3_POST_PROC_WIDTH-1 downto 0);   -- (2) --32-bit
    --signal output_vector_layer3_s    : std_logic_vector(2*16-1 downto 0);   -- (2) --16-bit
    signal output_matrix_layer3_s    : output_matrix_layer3;                                    -- (2)
    signal data_rdy_in_layer3_s      : std_logic;                                               -- PS signal that it's done writing input_tensor
    signal data_rdy_out_layer3_s     : std_logic;
    signal layer3_index_x_s          : signed(7 downto 0) := (others => '0');
    signal layer3_index_y_s          : signed(7 downto 0) := (others => '0');
    signal layer3_kernel_x_s         : signed(2 downto 0) := (others => '0');
    signal layer3_kernel_y_s         : signed(2 downto 0) := (others => '0');
    signal layer3_kernel_x_dld0_s    : signed(2 downto 0) := (others => '0');
    signal layer3_kernel_y_dld0_s    : signed(2 downto 0) := (others => '0');
    signal layer3_kernel_x_dld1_s    : signed(2 downto 0) := (others => '0');
    signal layer3_kernel_y_dld1_s    : signed(2 downto 0) := (others => '0');
    signal layer3_kernel_x_dld2_s    : signed(2 downto 0) := (others => '0');
    signal layer3_kernel_y_dld2_s    : signed(2 downto 0) := (others => '0');
    signal layer3_kernel_x_dld3_s    : signed(2 downto 0) := (others => '0');
    signal layer3_kernel_y_dld3_s    : signed(2 downto 0) := (others => '0');
    signal layer3_kernel_x_dld4_s    : signed(2 downto 0) := (others => '0');
    signal layer3_kernel_y_dld4_s    : signed(2 downto 0) := (others => '0');
    --signal layer3_prev_output_s      : signed(4 downto 0) := (others => '0');
    --signal layer3_prev_output_dld0_s : signed(4 downto 0) := (others => '0');
    --signal layer3_prev_output_dld1_s : signed(4 downto 0) := (others => '0');
    --signal layer3_prev_output_dld2_s : signed(4 downto 0) := (others => '0');
    --signal layer3_prev_output_dld3_s : signed(4 downto 0) := (others => '0');
    --signal layer3_prev_output_dld4_s : signed(4 downto 0) := (others => '0');
    signal layer3_address_x_s        : signed(7 downto 0) := (others => '0');
    signal layer3_address_y_s        : signed(7 downto 0) := (others => '0');
    signal layer3_address_x_dld0_s   : signed(7 downto 0) := (others => '0');
    signal layer3_address_y_dld0_s   : signed(7 downto 0) := (others => '0');
    signal layer3_address_x_dld1_s   : signed(7 downto 0) := (others => '0');
    signal layer3_address_y_dld1_s   : signed(7 downto 0) := (others => '0');
    signal layer3_address_x_dld2_s   : signed(7 downto 0) := (others => '0');
    signal layer3_address_y_dld2_s   : signed(7 downto 0) := (others => '0');
    signal layer3_address_x_dld3_s   : signed(7 downto 0) := (others => '0');
    signal layer3_address_y_dld3_s   : signed(7 downto 0) := (others => '0');
    signal layer3_address_x_dld4_s   : signed(7 downto 0) := (others => '0');
    signal layer3_address_y_dld4_s   : signed(7 downto 0) := (others => '0');
    signal layer3_address_part1_s    : unsigned(16 downto 0);
    signal layer3_address_part2_s    : unsigned(16 downto 0);
    signal layer3_address_s          : unsigned(16 downto 0);
    
    -- definition of output buffer
    subtype gen_int_5 is signed (LAYER3_POST_PROC_WIDTH-1 downto 0); -- 32-bit
    --subtype gen_int_5 is signed (16-1 downto 0); -- 16-bit
    type output_buffer is array (0 to 15) of gen_int_5;
    
    -- signal for all layers
    signal rst_in_s        : std_logic := '0';
    signal RESET_s         : std_logic;
    signal data_transfered_in_s : std_logic;
    signal data_transfered_out_s : std_logic := '0';
    signal transfer_index_s : unsigned(15 downto 0) := (others => '0');
    signal transfer_counter_s : unsigned(7 downto 0) := (others => '0');
    signal transfer_counter_dld0_s : unsigned(7 downto 0) := (others => '0');
    signal transfer_counter_dld1_s : unsigned(7 downto 0) := (others => '0');
    signal transfer_buffer_s : output_buffer := (others => (others => '0'));
    
    -- state machine
    type state is ( INIT_LAYER1,                 -- inputs are taken directly from register
                    INIT_LAYER1_CONSECUTIVE,     -- This is the return state after the first block
                    START_LAYER1,
                    WAIT_FOR_LAYER1,
                    COPY_INPUTS_LAYER1_0,        -- copy the inputs for shifting
                    SHIFT_INPUTS_LAYER1_0,       -- old values are shifted
                    COPY_INPUTS_LAYER1_1,        -- copy the inputs for shifting
                    SHIFT_INPUTS_LAYER1_1,       -- old values are shifted
                    DATA_RDY_OUT_LAYER1,
                    WRITE_RAM_LAYER1,            -- store results and increase counter
                    CHECK_PROGRESS_LAYER1,       -- check the result counter
                    INIT_LAYER2,
                    LOAD_LAYER2,
                    PIPE_DELAY0_LAYER2,
                    PIPE_DELAY1_LAYER2,
                    PIPE_DELAY2_LAYER2,
                    PIPE_DELAY3_LAYER2,
                    START_LAYER2,
                    WAIT_FOR_LAYER2,
                    WRITE_RAM_LAYER2,
                    WAIT_DTA_RDY_LAYER2,
                    CHECK_PROGRESS_LAYER2,
                    INIT_LAYER3,
                    LOAD_LAYER3,
                    PIPE_DELAY0_LAYER3,
                    PIPE_DELAY1_LAYER3,
                    PIPE_DELAY2_LAYER3,
                    PIPE_DELAY3_LAYER3,
                    START_LAYER3,
                    WAIT_FOR_LAYER3,
                    WRITE_RAM_LAYER3,
                    WAIT_DTA_RDY_LAYER3,
                    CHECK_PROGRESS_LAYER3,
                    DONE_LAYER3,
                    INIT_TRANSFER,
                    PRE_TRANSFER0,
                    PRE_TRANSFER1,
                    TRANSFER,
                    POST_TRANSFER0,
                    POST_TRANSFER1,
                    WAIT_FOR_TRANSFER,
                    WAIT_FOR_TRANSFER_CLEAR,
                    CHECK_TRANSFER_PROGRESS,
                    END_OF_TRANSFER
                  );
                  
     signal statem_state_s : state := INIT_LAYER1; -- state of state machine

begin
	-- I/O Connections assignments

	S_AXI_AWREADY	  <= axi_awready;
	S_AXI_WREADY	  <= axi_wready;
	S_AXI_BRESP	    <= axi_bresp;
	S_AXI_BVALID	  <= axi_bvalid;
	S_AXI_ARREADY  	<= axi_arready;
	S_AXI_RDATA	    <= axi_rdata;
	S_AXI_RRESP	    <= axi_rresp;
	S_AXI_RVALID	  <= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	      aw_en <= '1';
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	           axi_awready <= '1';
	           aw_en <= '0';
	        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	           aw_en <= '1';
	           axi_awready <= '0';
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
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
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
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
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
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      slv_reg0 <= (others => '0');
	      slv_reg1 <= (others => '0');
	      slv_reg2 <= (others => '0');
	      slv_reg3 <= (others => '0');
	      slv_reg4 <= (others => '0');
	      slv_reg5 <= (others => '0');
	      slv_reg6 <= (others => '0');
	      slv_reg7 <= (others => '0');
	      slv_reg8 <= (others => '0');
	      slv_reg9 <= (others => '0');
	      slv_reg10 <= (others => '0');
	      slv_reg11 <= (others => '0');
	      slv_reg12 <= (others => '0');
	      slv_reg13 <= (others => '0');
	      slv_reg14 <= (others => '0');
	      slv_reg15 <= (others => '0');
	      slv_reg16 <= (others => '0');
	      slv_reg17 <= (others => '0');
	      slv_reg18 <= (others => '0');
	      slv_reg19 <= (others => '0');
	      slv_reg20 <= (others => '0');
	      slv_reg21 <= (others => '0');
	      slv_reg22 <= (others => '0');
	      slv_reg23 <= (others => '0');
	      slv_reg24 <= (others => '0');
	      slv_reg25 <= (others => '0');
	      slv_reg26 <= (others => '0');
	      slv_reg27 <= (others => '0');
	      slv_reg28 <= (others => '0');
	      slv_reg29 <= (others => '0');
	      slv_reg30 <= (others => '0');
	      slv_reg31 <= (others => '0');
	      slv_reg32 <= (others => '0');
	      slv_reg33 <= (others => '0');
	      slv_reg34 <= (others => '0');
	      slv_reg35 <= (others => '0');
	    else
	      loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	      if (slv_reg_wren = '1') then
	        case loc_addr is
	          when b"000000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 0
	                slv_reg0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 1
	                slv_reg1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 2
	                slv_reg2(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 3
	                slv_reg3(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 4
	                slv_reg4(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 5
	                slv_reg5(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 6
	                slv_reg6(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 7
	                slv_reg7(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 8
	                slv_reg8(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 9
	                slv_reg9(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 10
	                slv_reg10(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 11
	                slv_reg11(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 12
	                slv_reg12(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 13
	                slv_reg13(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 14
	                slv_reg14(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 15
	                slv_reg15(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 16
	                slv_reg16(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 17
	                slv_reg17(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 18
	                slv_reg18(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 19
	                slv_reg19(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 20
	                slv_reg20(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 21
	                slv_reg21(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 22
	                slv_reg22(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 23
	                slv_reg23(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 24
	                slv_reg24(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 25
	                slv_reg25(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 26
	                slv_reg26(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 27
	                slv_reg27(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 28
	                slv_reg28(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 29
	                slv_reg29(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 30
	                slv_reg30(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 31
	                slv_reg31(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 32
	                slv_reg32(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 33
	                slv_reg33(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 34
	                slv_reg34(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 35
	                slv_reg35(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when others =>
	            --slv_reg0 <= slv_reg0;
	            --slv_reg1 <= slv_reg1;
	            --slv_reg2 <= slv_reg2;
	            --slv_reg3 <= slv_reg3;
	            --slv_reg4 <= slv_reg4;
	            --slv_reg5 <= slv_reg5;
	            --slv_reg6 <= slv_reg6;
	            --slv_reg7 <= slv_reg7;
	            --slv_reg8 <= slv_reg8;
	            --slv_reg9 <= slv_reg9;
	            --slv_reg10 <= slv_reg10;
	            --slv_reg11 <= slv_reg11;
	            --slv_reg12 <= slv_reg12;
	            --slv_reg13 <= slv_reg13;
	            --slv_reg14 <= slv_reg14;
	            --slv_reg15 <= slv_reg15;
	            --slv_reg16 <= slv_reg16;
	            --slv_reg17 <= slv_reg17;
	            slv_reg18 <= slv_reg18;
	            slv_reg19 <= slv_reg19;
	            slv_reg20 <= slv_reg20;
	            slv_reg21 <= slv_reg21;
	            slv_reg22 <= slv_reg22;
	            slv_reg23 <= slv_reg23;
	            slv_reg24 <= slv_reg24;
	            slv_reg25 <= slv_reg25;
	            slv_reg26 <= slv_reg26;
	            slv_reg27 <= slv_reg27;
	            slv_reg28 <= slv_reg28;
	            slv_reg29 <= slv_reg29;
	            slv_reg30 <= slv_reg30;
	            slv_reg31 <= slv_reg31;
	            slv_reg32 <= slv_reg32;
	            slv_reg33 <= slv_reg33;
	            slv_reg34 <= slv_reg34;
	            slv_reg35 <= slv_reg35;
	        end case;
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

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

	process (input_tensor_layer1_s, transfer_buffer_s, slv_reg34, axi_araddr, S_AXI_ARESETN, slv_reg_rden, data_transfered_out_s, data_rdy_out_register_layer1_s)
        variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
    begin
      -- Address decoding for reading registers
      loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
      case loc_addr is
        when b"000000" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(0, 0, 0));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*0 downto LAYER1_INPUTS_WIDTH*0);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*0 downto LAYER1_INPUTS_WIDTH*0);  -- 32-bit
        when b"000001" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(0, 0, 1));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*1 downto LAYER1_INPUTS_WIDTH*1);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*1 downto LAYER1_INPUTS_WIDTH*1);  -- 32-bit
        when b"000010" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(0, 1, 0));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*2 downto LAYER1_INPUTS_WIDTH*2);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*2 downto LAYER1_INPUTS_WIDTH*2);  -- 32-bit
        when b"000011" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(0, 1, 1));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*3 downto LAYER1_INPUTS_WIDTH*3);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*3 downto LAYER1_INPUTS_WIDTH*3);  -- 32-bit
        when b"000100" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(0, 2, 0));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*4 downto LAYER1_INPUTS_WIDTH*4);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*4 downto LAYER1_INPUTS_WIDTH*4);  -- 32-bit
        when b"000101" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(0, 2, 1));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*5 downto LAYER1_INPUTS_WIDTH*5);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*5 downto LAYER1_INPUTS_WIDTH*5);  -- 32-bit
        when b"000110" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(1, 0, 0));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*6 downto LAYER1_INPUTS_WIDTH*6);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*6 downto LAYER1_INPUTS_WIDTH*6);  -- 32-bit
        when b"000111" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(1, 0, 1));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*7 downto LAYER1_INPUTS_WIDTH*7);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*7 downto LAYER1_INPUTS_WIDTH*7);  -- 32-bit
        when b"001000" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(1, 1, 0));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*8 downto LAYER1_INPUTS_WIDTH*8);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*8 downto LAYER1_INPUTS_WIDTH*8);  -- 32-bit
        when b"001001" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(1, 1, 1));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*9 downto LAYER1_INPUTS_WIDTH*9);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*9 downto LAYER1_INPUTS_WIDTH*9);  -- 32-bit
        when b"001010" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(1, 2, 0));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*10 downto LAYER1_INPUTS_WIDTH*10);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*10 downto LAYER1_INPUTS_WIDTH*10);  -- 32-bit
        when b"001011" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(1, 2, 1));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*11 downto LAYER1_INPUTS_WIDTH*11);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*11 downto LAYER1_INPUTS_WIDTH*11);  -- 32-bit
        when b"001100" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(2, 0, 0));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*12 downto LAYER1_INPUTS_WIDTH*12);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*12 downto LAYER1_INPUTS_WIDTH*12);  -- 32-bit
        when b"001101" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(2, 0, 1));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*13 downto LAYER1_INPUTS_WIDTH*13);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*13 downto LAYER1_INPUTS_WIDTH*13);  -- 32-bit
        when b"001110" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(2, 1, 0));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*14 downto LAYER1_INPUTS_WIDTH*14);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*14 downto LAYER1_INPUTS_WIDTH*14);  -- 32-bit
        when b"001111" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(2, 1, 1));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*15 downto LAYER1_INPUTS_WIDTH*15);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*15 downto LAYER1_INPUTS_WIDTH*15);  -- 32-bit
        when b"010000" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(2, 2, 0));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*16 downto LAYER1_INPUTS_WIDTH*16);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*16 downto LAYER1_INPUTS_WIDTH*16);  -- 32-bit
        when b"010001" =>
          --reg_data_out <= std_logic_vector(input_tensor_layer1_s(2, 2, 1));
          --reg_data_out <= b"0000000000000000"&input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*17 downto LAYER1_INPUTS_WIDTH*17);  -- 16-bit
          reg_data_out <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*17 downto LAYER1_INPUTS_WIDTH*17);  -- 32-bit
        when b"010010" =>
          --reg_data_out <= slv_reg18;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(0), 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(0), 32));
        when b"010011" =>
          --reg_data_out <= slv_reg19;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(1), 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(2), 32));
        when b"010101" =>
          --reg_data_out <= slv_reg21;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(3), 32));
          --reg_data_out <= std_logic_vector(to_signed(layer1_result_counter_s, 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(3), 32));
        when b"010110" =>
          --reg_data_out <= slv_reg22;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(4), 32));
          --reg_data_out <= std_logic_vector(to_signed(layer1_mem_wr_index_s, 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(4), 32));
        when b"010111" =>
          --reg_data_out <= slv_reg23;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(5), 32));
          --reg_data_out <= std_logic_vector(to_signed(layer1_mem_shift_steps_s, 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(5), 32));
        when b"011000" =>
          --reg_data_out <= slv_reg24;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(6), 32));
          --reg_data_out <= std_logic_vector(to_signed(layer1_block_counter_s, 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(6), 32));
        when b"011001" =>
          --reg_data_out <= slv_reg25;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(7), 32));
          --reg_data_out <= std_logic_vector(to_signed(layer_counter_s, 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(7), 32));
        when b"011010" =>
          --reg_data_out <= slv_reg26;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(8), 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(8), 32));
        when b"011011" =>
          --reg_data_out <= slv_reg27;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(9), 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(9), 32));
        when b"011100" =>
          --reg_data_out <= slv_reg28;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(10), 32));
          --reg_data_out <= std_logic_vector(resize(layer3_mem_rd_data_s, 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(10), 32));
        when b"011101" =>
          --reg_data_out <= slv_reg29;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(11), 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(11), 32));
        when b"011110" =>
          --reg_data_out <= slv_reg30;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(12), 32));
          --reg_data_out <= std_logic_vector(resize(layer2_mem_rd_data_s, 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(12), 32));
        when b"011111" =>
          --reg_data_out <= slv_reg31;
          --reg_data_out <= std_logic_vector(resize(output_vector_layer1_s(13), 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(13), 32));
        when b"100000" =>
          --reg_data_out <= slv_reg32;
          --reg_data_out <= std_logic_vector(resize(layer1_mem_rd_data_s, 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(14), 32));
        when b"100001" =>
          --reg_data_out <= slv_reg33;
          --reg_data_out <= std_logic_vector(resize(output_vector_s(15), 32));
          reg_data_out <= std_logic_vector(resize(transfer_buffer_s(15), 32));
        when b"100010" =>
          reg_data_out <= slv_reg34;                                                   -- control register 
                                                                                       -- 0: RESET (1 active)
                                                                                       -- 1: layer 1 data ready in
                                                                                       -- 2: layer 1 RAM read enable
                                                                                       -- 3: layer 2 RAM read enable
                                                                                       -- 4: layer 3 RAM read enable
                                                                                       -- 5: transfered in
        when b"100011" =>
          reg_data_out <= "000000000000000000000000000000"&data_transfered_out_s&data_rdy_out_register_layer1_s;
                                                                                       -- status register
                                                                                       -- 0: layer 1 data ready out
                                                                                       -- 1: transfered out
        when others =>
          reg_data_out  <= (others => '0');
      end case;
    end process; 

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
	          axi_rdata <= reg_data_out;     -- register read data
	      end if;   
	    end if;
	  end if;
	end process;

	-- Add user logic here
	
	  -- control register logic
	  process( S_AXI_ACLK ) is
    begin
      if (rising_edge (S_AXI_ACLK)) then
        rst_in_s                      <= slv_reg34(0);   -- reset
        data_rdy_in_register_layer1_s <= slv_reg34(1);   -- data ready in signal (layer1) (from register)
        data_transfered_in_s          <= slv_reg34(5);   -- data transfered in from PS
      end if;
    end process;
    
    process( rst_in_s, S_AXI_ARESETN ) is
    begin
        RESET_s <= S_AXI_ARESETN and not rst_in_s;
    end process;
    
	
	  -- layer 1 instance 0
    LG_Layer1_instance0 : LG_Layer1
    Generic map (
      INPUTS_WIDTH     => LAYER1_INPUTS_WIDTH,
      SCALE1           => SCALE1,
      SCALE1_WIDTH     => SCALE1_WIDTH,
      POST_PROC_WIDTH  => LAYER1_POST_PROC_WIDTH,
      ACT_WIDTH        => LAYER1_ACT_WIDTH,
      WEIGHTS_WIDTH    => LAYER1_WEIGHTS_WIDTH,
      ROUNDING_MASK    => LAYER1_ROUNDING_MASK,
      DTA_RDY_DLY_CLKS => DTA_RDY_DLY_CLKS,
      MAC_A_WIDTH      => MAC_LAYER1_A_WIDTH,
      MAC_B_WIDTH      => MAC_LAYER1_B_WIDTH,
      MAC_OUT_WIDTH    => MAC_LAYER1_OUT_WIDTH
      )
    Port map (
      input_tensor     => input_tensor_layer1_s,
      output_vector    => output_vector_layer1_s,
      data_rdy_in      => data_rdy_in_layer1_s,
      data_rdy_out     => data_rdy_out_layer1_s,
      rst_in           => RESET_s,
      clk              => S_AXI_ACLK
    );
    
    -- layer 2 instance 0
    LG_Layer2_instance0 : LG_Layer2
    Generic map (
      START_OUTPUT            => 0,
      STOP_OUTPUT             => 1,
      --STOP_OUTPUT             => 3,
      --STOP_OUTPUT             => 7,
      INPUTS_WIDTH            => LAYER2_INPUTS_WIDTH,
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
      POST_PROC_WIDTH         => LAYER2_POST_PROC_WIDTH,
      ACT_WIDTH               => LAYER2_ACT_WIDTH,
      WEIGHTS_WIDTH           => LAYER2_WEIGHTS_WIDTH,
      ROUNDING_MASK           => LAYER2_ROUNDING_MASK,
      -- MAC generics
      MAC_LAYER2_A_WIDTH      => MAC_LAYER2_A_WIDTH,
      MAC_LAYER2_B_WIDTH      => MAC_LAYER2_B_WIDTH,
      MAC_LAYER2_OUT_WIDTH    => MAC_LAYER2_OUT_WIDTH)
    Port map (
      input_tensor            => input_tensor_layer2_s,
      --output_vector           => output_vector_layer2_s(8*LAYER2_ACT_WIDTH-1 downto 0),
      --output_vector           => output_vector_layer2_s(4*LAYER2_ACT_WIDTH-1 downto 0),
      output_vector           => output_vector_layer2_s(2*LAYER2_ACT_WIDTH-1 downto 0),
      data_rdy_in             => data_rdy_in_layer2_s,
      data_rdy_out            => data_rdy_out_layer2_s,
      rst_in                  => RESET_s,
      clk                     => S_AXI_ACLK
    );
    
    -- layer 2 instance 1
    
    LG_Layer2_instance1 : LG_Layer2
    Generic map (
      START_OUTPUT            => 2,
      STOP_OUTPUT             => 3,
      INPUTS_WIDTH            => LAYER2_INPUTS_WIDTH,
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
      POST_PROC_WIDTH         => LAYER2_POST_PROC_WIDTH,
      ACT_WIDTH               => LAYER2_ACT_WIDTH,
      WEIGHTS_WIDTH           => LAYER2_WEIGHTS_WIDTH,
      ROUNDING_MASK           => LAYER2_ROUNDING_MASK,
      -- MAC generics
      MAC_LAYER2_A_WIDTH      => MAC_LAYER2_A_WIDTH,
      MAC_LAYER2_B_WIDTH      => MAC_LAYER2_B_WIDTH,
      MAC_LAYER2_OUT_WIDTH    => MAC_LAYER2_OUT_WIDTH)
    Port map (
      input_tensor            => input_tensor_layer2_s,
      output_vector           => output_vector_layer2_s(4*LAYER2_ACT_WIDTH-1 downto 2*LAYER2_ACT_WIDTH),
      data_rdy_in             => data_rdy_in_layer2_s,
      data_rdy_out            => data_rdy_out_layer2_dummy0_s,
      rst_in                  => RESET_s,
      clk                     => S_AXI_ACLK
    );
    
    
    -- layer 2 instance 2
    
    LG_Layer2_instance2 : LG_Layer2
    Generic map (
      START_OUTPUT            => 4,
      STOP_OUTPUT             => 5,
      --STOP_OUTPUT             => 7,
      INPUTS_WIDTH            => LAYER2_INPUTS_WIDTH,
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
      POST_PROC_WIDTH         => LAYER2_POST_PROC_WIDTH,
      ACT_WIDTH               => LAYER2_ACT_WIDTH,
      WEIGHTS_WIDTH           => LAYER2_WEIGHTS_WIDTH,
      ROUNDING_MASK           => LAYER2_ROUNDING_MASK,
      -- MAC generics
      MAC_LAYER2_A_WIDTH      => MAC_LAYER2_A_WIDTH,
      MAC_LAYER2_B_WIDTH      => MAC_LAYER2_B_WIDTH,
      MAC_LAYER2_OUT_WIDTH    => MAC_LAYER2_OUT_WIDTH)
    Port map (
      input_tensor            => input_tensor_layer2_s,
      output_vector           => output_vector_layer2_s(6*LAYER2_ACT_WIDTH-1 downto 4*LAYER2_ACT_WIDTH),
      --output_vector           => output_vector_layer2_s(8*LAYER2_ACT_WIDTH-1 downto 4*LAYER2_ACT_WIDTH),
      data_rdy_in             => data_rdy_in_layer2_s,
      data_rdy_out            => data_rdy_out_layer2_dummy1_s,
      rst_in                  => RESET_s,
      clk                     => S_AXI_ACLK
    );
    
    
    -- layer 2 instance 3
    
    LG_Layer2_instance3 : LG_Layer2
    Generic map (
      START_OUTPUT            => 6,
      STOP_OUTPUT             => 7,
      INPUTS_WIDTH            => LAYER2_INPUTS_WIDTH,
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
      POST_PROC_WIDTH         => LAYER2_POST_PROC_WIDTH,
      ACT_WIDTH               => LAYER2_ACT_WIDTH,
      WEIGHTS_WIDTH           => LAYER2_WEIGHTS_WIDTH,
      ROUNDING_MASK           => LAYER2_ROUNDING_MASK,
      -- MAC generics
      MAC_LAYER2_A_WIDTH      => MAC_LAYER2_A_WIDTH,
      MAC_LAYER2_B_WIDTH      => MAC_LAYER2_B_WIDTH,
      MAC_LAYER2_OUT_WIDTH    => MAC_LAYER2_OUT_WIDTH)
    Port map (
      input_tensor            => input_tensor_layer2_s,
      output_vector           => output_vector_layer2_s(8*LAYER2_ACT_WIDTH-1 downto 6*LAYER2_ACT_WIDTH),
      data_rdy_in             => data_rdy_in_layer2_s,
      data_rdy_out            => data_rdy_out_layer2_dummy2_s,
      rst_in                  => RESET_s,
      clk                     => S_AXI_ACLK
    );
    
    
    -- layer 3 instance
    LG_Layer3_instance0 : LG_Layer3
    Generic map (
      INPUTS_WIDTH          => LAYER3_INPUTS_WIDTH,
      SCALE3                => SCALE3,
      LAYER3_CONV_BIAS0     => LAYER3_CONV_BIAS0,
      LAYER3_CONV_BIAS1     => LAYER3_CONV_BIAS1,
      SCALE3_WIDTH          => SCALE3_WIDTH,
      POST_PROC_WIDTH       => LAYER3_POST_PROC_WIDTH,
      LAYER3_POST_SCAL_SHFT => LAYER3_POST_SCAL_SHFT,
      LAYER3_POST_BIAS_SHFT => LAYER3_POST_BIAS_SHFT,
      WEIGHTS_WIDTH         => LAYER3_WEIGHTS_WIDTH,
      MAC_LAYER3_A_WIDTH    => MAC_LAYER3_A_WIDTH,
      MAC_LAYER3_B_WIDTH    => MAC_LAYER3_B_WIDTH,
      MAC_LAYER3_OUT_WIDTH  => MAC_LAYER3_OUT_WIDTH)
    Port map (
      input_tensor          => input_tensor_layer3_s,
      output_vector         => output_vector_layer3_s,
      data_rdy_in           => data_rdy_in_layer3_s,
      data_rdy_out          => data_rdy_out_layer3_s,
      rst_in                => RESET_s,
      clk                   => S_AXI_ACLK
    );
    
    -- ram for results of layer1
    layer1_output_mem_instance0 : layer1_output_mem
    Generic map (
      WORD_SIZE     => RAM_LAYER1_WIDTH,
      RAM_SIZE      => RAM_LAYER1_SIZE)
    Port map (
      clk           => S_AXI_ACLK,
      block_address => layer1_mem_address_s,
      we            => layer1_mem_we_s,
      re            => layer1_mem_re_s,
      data_i        => layer1_mem_wr_data_s,
      data_o        => layer1_mem_rd_data_s
    );
    
    -- ram for results of layer2
    layer2_output_mem_instance0 : layer2_output_mem
    Generic map (
      WORD_SIZE     => RAM_LAYER2_WIDTH,
      RAM_SIZE      => RAM_LAYER2_SIZE)
    Port map (
      clk           => S_AXI_ACLK,
      block_address => layer2_mem_address_s,
      we            => layer2_mem_we_s,
      re            => layer2_mem_re_s,
      data_i        => layer2_mem_wr_data_s,
      data_o        => layer2_mem_rd_data_s
    );
    
    -- ram for results of layer3
    layer3_output_mem_instance0 : layer3_output_mem
    Generic map (
      WORD_SIZE     => RAM_LAYER3_WIDTH,
      RAM_SIZE      => RAM_LAYER3_SIZE)
    Port map (
      clk           => S_AXI_ACLK,
      block_address => layer3_mem_address_s,
      we            => layer3_mem_we_s,
      re            => layer3_mem_re_s,
      data_i        => layer3_mem_wr_data_s,
      data_o        => layer3_mem_rd_data_s
    );
    
    -- logic for data transfered out signal
    process( S_AXI_ACLK ) is
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if RESET_s = '0' then
          data_transfered_out_s <= '0';
        else
          if (statem_state_s = WAIT_FOR_TRANSFER) then
            data_transfered_out_s <= '1';
          else
            data_transfered_out_s <= '0';
          end if;
        end if;
      end if;
    end process;
    
    -- write transfer output buffer
    process( S_AXI_ACLK ) is
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if (statem_state_s = TRANSFER) or (statem_state_s = POST_TRANSFER0) or (statem_state_s = POST_TRANSFER1) then
          transfer_buffer_s(to_integer(transfer_counter_dld1_s)) <= layer3_mem_rd_data_s;
        end if;
      end if;
    end process;
    
    -- logic for layer 1 RAM read enable bit
    process( S_AXI_ACLK ) is
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if RESET_s = '0' then
          layer1_mem_re_s <= '0';
        else
          if (statem_state_s = INIT_LAYER2) or (statem_state_s = LOAD_LAYER2) or (statem_state_s = PIPE_DELAY0_LAYER2) or (statem_state_s = PIPE_DELAY1_LAYER2) or (statem_state_s = PIPE_DELAY2_LAYER2) then
            layer1_mem_re_s <= '1';
          else
            if (statem_state_s = CHECK_PROGRESS_LAYER2) and ((layer2_index_x_s < 95) and (layer2_index_y_s < 95)) then
              layer1_mem_re_s <= '1';
            else
              if (statem_state_s = DONE_LAYER3) then
                --layer1_mem_re_s <= slv_reg34(2);  -- 0x02
                layer1_mem_re_s <= '0';
              else
                layer1_mem_re_s <= '0';
              end if;
            end if;
          end if;
        end if;
      end if;
    end process;
    
    -- logic for layer 2 RAM read enable bit
    process( S_AXI_ACLK ) is
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if RESET_s = '0' then
          layer2_mem_re_s <= '0';
        else
          if (statem_state_s = INIT_LAYER3) or (statem_state_s = LOAD_LAYER3) or (statem_state_s = PIPE_DELAY0_LAYER3) or (statem_state_s = PIPE_DELAY1_LAYER3) or (statem_state_s = PIPE_DELAY2_LAYER3) then
            layer2_mem_re_s <= '1';
          else
            if (statem_state_s = CHECK_PROGRESS_LAYER3) and ((layer3_index_x_s < 95) and (layer3_index_y_s < 95)) then
              layer2_mem_re_s <= '1';
            else
              if (statem_state_s = DONE_LAYER3) then
                --layer2_mem_re_s <= slv_reg34(3);  -- 0x04
                layer2_mem_re_s <= '0';
              else
                layer2_mem_re_s <= '0';
              end if;
            end if;
          end if;
        end if;
      end if;
    end process;
    
    -- logic for layer 3 RAM read enable bit
    -- not important in this simulation
    process( S_AXI_ACLK ) is
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if RESET_s = '0' then
          layer3_mem_re_s <= '0';
        else
          if (statem_state_s = TRANSFER) or (statem_state_s = PRE_TRANSFER0) or (statem_state_s = PRE_TRANSFER1) or (statem_state_s = POST_TRANSFER0) or (statem_state_s = POST_TRANSFER0) then
            layer3_mem_re_s <= '1';
          else
            if (statem_state_s = DONE_LAYER3) then
              -- layer3_mem_re_s <= slv_reg34(4);  -- 0x08  all: 14, 0x0E
              layer3_mem_re_s <= '0';
            else
              layer3_mem_re_s <= '0';
            end if;
          end if;
        end if;
      end if;
    end process;
    
    -- logic for layer 1 data ready out flag
    process( S_AXI_ACLK ) is
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if RESET_s = '0' then
          data_rdy_out_register_layer1_s <= '0';
        else
          if (statem_state_s = DATA_RDY_OUT_LAYER1) then
            data_rdy_out_register_layer1_s <= '1';
          else
            data_rdy_out_register_layer1_s <= '0';
          end if;
        end if;
      end if;
    end process;
    
    -- logic for layer 1 data ready in flag
    process( S_AXI_ACLK ) is
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if RESET_s = '0' then
          data_rdy_in_layer1_s <= '0';
        else
          if (statem_state_s = START_LAYER1) then
            data_rdy_in_layer1_s <= '1';
          else
            data_rdy_in_layer1_s <= '0';
          end if;
        end if;
      end if;
    end process;
    
    -- logic for layer 2 data ready in flag
    process( S_AXI_ACLK ) is
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if RESET_s = '0' then
          data_rdy_in_layer2_s <= '0';
        else
          if (statem_state_s = START_LAYER2) then
            data_rdy_in_layer2_s <= '1';
          else
            data_rdy_in_layer2_s <= '0';
          end if;
        end if;
      end if;
    end process;
    
     -- logic for layer 3 data ready in flag
     process( S_AXI_ACLK ) is
     begin
       if (rising_edge (S_AXI_ACLK)) then
         if RESET_s = '0' then
           data_rdy_in_layer3_s <= '0';
         else
           if (statem_state_s = START_LAYER3) then
             data_rdy_in_layer3_s <= '1';
           else
             data_rdy_in_layer3_s <= '0';
           end if;
         end if;
       end if;
     end process;
    
    -- logic for LOADING ADDRESSES and WRITING RESULTS - layer 1 RAM
    -- addresses are only taken from computation in states LOAD_LAYER2, PIPE_DELAY0_LAYER2, PIPE_DELAY1_LAYER2, PIPE_DELAY2_LAYER2 and PIPE_DELAY3_LAYER2
    -- if the index is out of bounds, the address is set to 0.
    -- Also: Writing results to layer 1 RAM and setting address for reading
    process ( S_AXI_ACLK )
    begin
      if rising_edge( S_AXI_ACLK ) then
        if (statem_state_s = LOAD_LAYER2) or (statem_state_s = PIPE_DELAY0_LAYER2) or (statem_state_s = PIPE_DELAY1_LAYER2) or (statem_state_s = PIPE_DELAY2_LAYER2) or (statem_state_s = PIPE_DELAY3_LAYER2) then
          if (layer2_address_x_dld1_s >= 0) and (layer2_address_x_dld1_s < 96) and (layer2_address_y_dld1_s >= 0) and (layer2_address_y_dld1_s < 96) then
            layer1_mem_address_s <= to_integer(layer2_address_s);
          else
            layer1_mem_address_s <= 0;
          end if;
        else
          if (statem_state_s = WRITE_RAM_LAYER1) then
            layer1_mem_we_s      <= '1';
            layer1_mem_address_s <= layer1_mem_wr_index_s;
            --layer1_mem_wr_data_s <= output_vector_layer1_s(layer1_mem_shift_steps_s);
            --for g in 0 to 16-1 loop
              --layer1_mem_wr_data_s(7+8*g downto 8*g) <= std_logic_vector(output_vector_layer1_s(g));
            --end loop;
            layer1_mem_wr_data_s <= output_vector_layer1_s;
          else
            layer1_mem_we_s      <= '0';
            --layer1_mem_address_s <= to_integer(signed(slv_reg33));
            layer1_mem_address_s <= 0;
            layer1_mem_wr_data_s <= (others => '0');
          end if;
        end if;
      end if;
    end process;

    -- logic for LOADING ADDRESSES and WRITING RESULTS - layer 2 RAM
    -- addresses are only taken from computation in states LOAD_LAYER3, PIPE_DELAY0_LAYER3, PIPE_DELAY1_LAYER3, PIPE_DELAY2_LAYER3 and PIPE_DELAY3_LAYER3
    -- if the index is out of bounds, the address is set to 0.
    -- Also: Writing results to layer 2 RAM and setting address for reading
    process ( S_AXI_ACLK )
    begin
      if rising_edge( S_AXI_ACLK ) then
        if (statem_state_s = LOAD_LAYER3) or (statem_state_s = PIPE_DELAY0_LAYER3) or (statem_state_s = PIPE_DELAY1_LAYER3) or (statem_state_s = PIPE_DELAY2_LAYER3) or (statem_state_s = PIPE_DELAY3_LAYER3) then
          if (layer3_address_x_dld1_s >= 0) and (layer3_address_x_dld1_s < 96) and (layer3_address_y_dld1_s >= 0) and (layer3_address_y_dld1_s < 96) then
            layer2_mem_address_s <= to_integer(layer3_address_s);
          else
            layer2_mem_address_s <= 0;
          end if;
        else
          if (statem_state_s = WRITE_RAM_LAYER2) then
            layer2_mem_we_s      <= '1';
            layer2_mem_address_s <= layer2_mem_wr_index_s;
            --for g in 0 to 8-1 loop
              --layer2_mem_wr_data_s(7+8*g downto 8*g) <= std_logic_vector(output_vector_layer2_s(g));
            --end loop;
            layer2_mem_wr_data_s <= output_vector_layer2_s;
          else
            layer2_mem_we_s      <= '0';
            layer2_mem_address_s <= to_integer(signed(slv_reg31));
            layer2_mem_wr_data_s <= (others => '0');
          end if;
        end if;
      end if;
    end process;
    
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*0 downto LAYER2_INPUTS_WIDTH*0) <= std_logic_vector(input_matrix_layer2_s(0, 0, 0));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*1 downto LAYER2_INPUTS_WIDTH*1) <= std_logic_vector(input_matrix_layer2_s(0, 0, 1));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*2 downto LAYER2_INPUTS_WIDTH*2) <= std_logic_vector(input_matrix_layer2_s(0, 0, 2));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*3 downto LAYER2_INPUTS_WIDTH*3) <= std_logic_vector(input_matrix_layer2_s(0, 0, 3));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*4 downto LAYER2_INPUTS_WIDTH*4) <= std_logic_vector(input_matrix_layer2_s(0, 0, 4));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*5 downto LAYER2_INPUTS_WIDTH*5) <= std_logic_vector(input_matrix_layer2_s(0, 0, 5));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*6 downto LAYER2_INPUTS_WIDTH*6) <= std_logic_vector(input_matrix_layer2_s(0, 0, 6));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*7 downto LAYER2_INPUTS_WIDTH*7) <= std_logic_vector(input_matrix_layer2_s(0, 0, 7));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*8 downto LAYER2_INPUTS_WIDTH*8) <= std_logic_vector(input_matrix_layer2_s(0, 0, 8));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*9 downto LAYER2_INPUTS_WIDTH*9) <= std_logic_vector(input_matrix_layer2_s(0, 0, 9));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*10 downto LAYER2_INPUTS_WIDTH*10) <= std_logic_vector(input_matrix_layer2_s(0, 0, 10));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*11 downto LAYER2_INPUTS_WIDTH*11) <= std_logic_vector(input_matrix_layer2_s(0, 0, 11));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*12 downto LAYER2_INPUTS_WIDTH*12) <= std_logic_vector(input_matrix_layer2_s(0, 0, 12));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*13 downto LAYER2_INPUTS_WIDTH*13) <= std_logic_vector(input_matrix_layer2_s(0, 0, 13));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*14 downto LAYER2_INPUTS_WIDTH*14) <= std_logic_vector(input_matrix_layer2_s(0, 0, 14));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*15 downto LAYER2_INPUTS_WIDTH*15) <= std_logic_vector(input_matrix_layer2_s(0, 0, 15));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*16 downto LAYER2_INPUTS_WIDTH*16) <= std_logic_vector(input_matrix_layer2_s(0, 1, 0));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*17 downto LAYER2_INPUTS_WIDTH*17) <= std_logic_vector(input_matrix_layer2_s(0, 1, 1));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*18 downto LAYER2_INPUTS_WIDTH*18) <= std_logic_vector(input_matrix_layer2_s(0, 1, 2));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*19 downto LAYER2_INPUTS_WIDTH*19) <= std_logic_vector(input_matrix_layer2_s(0, 1, 3));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*20 downto LAYER2_INPUTS_WIDTH*20) <= std_logic_vector(input_matrix_layer2_s(0, 1, 4));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*21 downto LAYER2_INPUTS_WIDTH*21) <= std_logic_vector(input_matrix_layer2_s(0, 1, 5));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*22 downto LAYER2_INPUTS_WIDTH*22) <= std_logic_vector(input_matrix_layer2_s(0, 1, 6));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*23 downto LAYER2_INPUTS_WIDTH*23) <= std_logic_vector(input_matrix_layer2_s(0, 1, 7));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*24 downto LAYER2_INPUTS_WIDTH*24) <= std_logic_vector(input_matrix_layer2_s(0, 1, 8));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*25 downto LAYER2_INPUTS_WIDTH*25) <= std_logic_vector(input_matrix_layer2_s(0, 1, 9));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*26 downto LAYER2_INPUTS_WIDTH*26) <= std_logic_vector(input_matrix_layer2_s(0, 1, 10));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*27 downto LAYER2_INPUTS_WIDTH*27) <= std_logic_vector(input_matrix_layer2_s(0, 1, 11));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*28 downto LAYER2_INPUTS_WIDTH*28) <= std_logic_vector(input_matrix_layer2_s(0, 1, 12));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*29 downto LAYER2_INPUTS_WIDTH*29) <= std_logic_vector(input_matrix_layer2_s(0, 1, 13));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*30 downto LAYER2_INPUTS_WIDTH*30) <= std_logic_vector(input_matrix_layer2_s(0, 1, 14));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*31 downto LAYER2_INPUTS_WIDTH*31) <= std_logic_vector(input_matrix_layer2_s(0, 1, 15));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*32 downto LAYER2_INPUTS_WIDTH*32) <= std_logic_vector(input_matrix_layer2_s(0, 2, 0));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*33 downto LAYER2_INPUTS_WIDTH*33) <= std_logic_vector(input_matrix_layer2_s(0, 2, 1));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*34 downto LAYER2_INPUTS_WIDTH*34) <= std_logic_vector(input_matrix_layer2_s(0, 2, 2));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*35 downto LAYER2_INPUTS_WIDTH*35) <= std_logic_vector(input_matrix_layer2_s(0, 2, 3));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*36 downto LAYER2_INPUTS_WIDTH*36) <= std_logic_vector(input_matrix_layer2_s(0, 2, 4));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*37 downto LAYER2_INPUTS_WIDTH*37) <= std_logic_vector(input_matrix_layer2_s(0, 2, 5));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*38 downto LAYER2_INPUTS_WIDTH*38) <= std_logic_vector(input_matrix_layer2_s(0, 2, 6));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*39 downto LAYER2_INPUTS_WIDTH*39) <= std_logic_vector(input_matrix_layer2_s(0, 2, 7));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*40 downto LAYER2_INPUTS_WIDTH*40) <= std_logic_vector(input_matrix_layer2_s(0, 2, 8));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*41 downto LAYER2_INPUTS_WIDTH*41) <= std_logic_vector(input_matrix_layer2_s(0, 2, 9));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*42 downto LAYER2_INPUTS_WIDTH*42) <= std_logic_vector(input_matrix_layer2_s(0, 2, 10));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*43 downto LAYER2_INPUTS_WIDTH*43) <= std_logic_vector(input_matrix_layer2_s(0, 2, 11));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*44 downto LAYER2_INPUTS_WIDTH*44) <= std_logic_vector(input_matrix_layer2_s(0, 2, 12));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*45 downto LAYER2_INPUTS_WIDTH*45) <= std_logic_vector(input_matrix_layer2_s(0, 2, 13));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*46 downto LAYER2_INPUTS_WIDTH*46) <= std_logic_vector(input_matrix_layer2_s(0, 2, 14));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*47 downto LAYER2_INPUTS_WIDTH*47) <= std_logic_vector(input_matrix_layer2_s(0, 2, 15));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*48 downto LAYER2_INPUTS_WIDTH*48) <= std_logic_vector(input_matrix_layer2_s(1, 0, 0));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*49 downto LAYER2_INPUTS_WIDTH*49) <= std_logic_vector(input_matrix_layer2_s(1, 0, 1));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*50 downto LAYER2_INPUTS_WIDTH*50) <= std_logic_vector(input_matrix_layer2_s(1, 0, 2));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*51 downto LAYER2_INPUTS_WIDTH*51) <= std_logic_vector(input_matrix_layer2_s(1, 0, 3));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*52 downto LAYER2_INPUTS_WIDTH*52) <= std_logic_vector(input_matrix_layer2_s(1, 0, 4));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*53 downto LAYER2_INPUTS_WIDTH*53) <= std_logic_vector(input_matrix_layer2_s(1, 0, 5));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*54 downto LAYER2_INPUTS_WIDTH*54) <= std_logic_vector(input_matrix_layer2_s(1, 0, 6));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*55 downto LAYER2_INPUTS_WIDTH*55) <= std_logic_vector(input_matrix_layer2_s(1, 0, 7));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*56 downto LAYER2_INPUTS_WIDTH*56) <= std_logic_vector(input_matrix_layer2_s(1, 0, 8));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*57 downto LAYER2_INPUTS_WIDTH*57) <= std_logic_vector(input_matrix_layer2_s(1, 0, 9));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*58 downto LAYER2_INPUTS_WIDTH*58) <= std_logic_vector(input_matrix_layer2_s(1, 0, 10));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*59 downto LAYER2_INPUTS_WIDTH*59) <= std_logic_vector(input_matrix_layer2_s(1, 0, 11));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*60 downto LAYER2_INPUTS_WIDTH*60) <= std_logic_vector(input_matrix_layer2_s(1, 0, 12));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*61 downto LAYER2_INPUTS_WIDTH*61) <= std_logic_vector(input_matrix_layer2_s(1, 0, 13));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*62 downto LAYER2_INPUTS_WIDTH*62) <= std_logic_vector(input_matrix_layer2_s(1, 0, 14));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*63 downto LAYER2_INPUTS_WIDTH*63) <= std_logic_vector(input_matrix_layer2_s(1, 0, 15));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*64 downto LAYER2_INPUTS_WIDTH*64) <= std_logic_vector(input_matrix_layer2_s(1, 1, 0));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*65 downto LAYER2_INPUTS_WIDTH*65) <= std_logic_vector(input_matrix_layer2_s(1, 1, 1));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*66 downto LAYER2_INPUTS_WIDTH*66) <= std_logic_vector(input_matrix_layer2_s(1, 1, 2));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*67 downto LAYER2_INPUTS_WIDTH*67) <= std_logic_vector(input_matrix_layer2_s(1, 1, 3));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*68 downto LAYER2_INPUTS_WIDTH*68) <= std_logic_vector(input_matrix_layer2_s(1, 1, 4));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*69 downto LAYER2_INPUTS_WIDTH*69) <= std_logic_vector(input_matrix_layer2_s(1, 1, 5));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*70 downto LAYER2_INPUTS_WIDTH*70) <= std_logic_vector(input_matrix_layer2_s(1, 1, 6));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*71 downto LAYER2_INPUTS_WIDTH*71) <= std_logic_vector(input_matrix_layer2_s(1, 1, 7));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*72 downto LAYER2_INPUTS_WIDTH*72) <= std_logic_vector(input_matrix_layer2_s(1, 1, 8));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*73 downto LAYER2_INPUTS_WIDTH*73) <= std_logic_vector(input_matrix_layer2_s(1, 1, 9));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*74 downto LAYER2_INPUTS_WIDTH*74) <= std_logic_vector(input_matrix_layer2_s(1, 1, 10));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*75 downto LAYER2_INPUTS_WIDTH*75) <= std_logic_vector(input_matrix_layer2_s(1, 1, 11));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*76 downto LAYER2_INPUTS_WIDTH*76) <= std_logic_vector(input_matrix_layer2_s(1, 1, 12));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*77 downto LAYER2_INPUTS_WIDTH*77) <= std_logic_vector(input_matrix_layer2_s(1, 1, 13));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*78 downto LAYER2_INPUTS_WIDTH*78) <= std_logic_vector(input_matrix_layer2_s(1, 1, 14));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*79 downto LAYER2_INPUTS_WIDTH*79) <= std_logic_vector(input_matrix_layer2_s(1, 1, 15));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*80 downto LAYER2_INPUTS_WIDTH*80) <= std_logic_vector(input_matrix_layer2_s(1, 2, 0));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*81 downto LAYER2_INPUTS_WIDTH*81) <= std_logic_vector(input_matrix_layer2_s(1, 2, 1));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*82 downto LAYER2_INPUTS_WIDTH*82) <= std_logic_vector(input_matrix_layer2_s(1, 2, 2));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*83 downto LAYER2_INPUTS_WIDTH*83) <= std_logic_vector(input_matrix_layer2_s(1, 2, 3));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*84 downto LAYER2_INPUTS_WIDTH*84) <= std_logic_vector(input_matrix_layer2_s(1, 2, 4));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*85 downto LAYER2_INPUTS_WIDTH*85) <= std_logic_vector(input_matrix_layer2_s(1, 2, 5));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*86 downto LAYER2_INPUTS_WIDTH*86) <= std_logic_vector(input_matrix_layer2_s(1, 2, 6));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*87 downto LAYER2_INPUTS_WIDTH*87) <= std_logic_vector(input_matrix_layer2_s(1, 2, 7));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*88 downto LAYER2_INPUTS_WIDTH*88) <= std_logic_vector(input_matrix_layer2_s(1, 2, 8));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*89 downto LAYER2_INPUTS_WIDTH*89) <= std_logic_vector(input_matrix_layer2_s(1, 2, 9));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*90 downto LAYER2_INPUTS_WIDTH*90) <= std_logic_vector(input_matrix_layer2_s(1, 2, 10));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*91 downto LAYER2_INPUTS_WIDTH*91) <= std_logic_vector(input_matrix_layer2_s(1, 2, 11));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*92 downto LAYER2_INPUTS_WIDTH*92) <= std_logic_vector(input_matrix_layer2_s(1, 2, 12));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*93 downto LAYER2_INPUTS_WIDTH*93) <= std_logic_vector(input_matrix_layer2_s(1, 2, 13));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*94 downto LAYER2_INPUTS_WIDTH*94) <= std_logic_vector(input_matrix_layer2_s(1, 2, 14));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*95 downto LAYER2_INPUTS_WIDTH*95) <= std_logic_vector(input_matrix_layer2_s(1, 2, 15));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*96 downto LAYER2_INPUTS_WIDTH*96) <= std_logic_vector(input_matrix_layer2_s(2, 0, 0));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*97 downto LAYER2_INPUTS_WIDTH*97) <= std_logic_vector(input_matrix_layer2_s(2, 0, 1));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*98 downto LAYER2_INPUTS_WIDTH*98) <= std_logic_vector(input_matrix_layer2_s(2, 0, 2));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*99 downto LAYER2_INPUTS_WIDTH*99) <= std_logic_vector(input_matrix_layer2_s(2, 0, 3));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*100 downto LAYER2_INPUTS_WIDTH*100) <= std_logic_vector(input_matrix_layer2_s(2, 0, 4));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*101 downto LAYER2_INPUTS_WIDTH*101) <= std_logic_vector(input_matrix_layer2_s(2, 0, 5));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*102 downto LAYER2_INPUTS_WIDTH*102) <= std_logic_vector(input_matrix_layer2_s(2, 0, 6));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*103 downto LAYER2_INPUTS_WIDTH*103) <= std_logic_vector(input_matrix_layer2_s(2, 0, 7));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*104 downto LAYER2_INPUTS_WIDTH*104) <= std_logic_vector(input_matrix_layer2_s(2, 0, 8));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*105 downto LAYER2_INPUTS_WIDTH*105) <= std_logic_vector(input_matrix_layer2_s(2, 0, 9));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*106 downto LAYER2_INPUTS_WIDTH*106) <= std_logic_vector(input_matrix_layer2_s(2, 0, 10));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*107 downto LAYER2_INPUTS_WIDTH*107) <= std_logic_vector(input_matrix_layer2_s(2, 0, 11));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*108 downto LAYER2_INPUTS_WIDTH*108) <= std_logic_vector(input_matrix_layer2_s(2, 0, 12));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*109 downto LAYER2_INPUTS_WIDTH*109) <= std_logic_vector(input_matrix_layer2_s(2, 0, 13));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*110 downto LAYER2_INPUTS_WIDTH*110) <= std_logic_vector(input_matrix_layer2_s(2, 0, 14));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*111 downto LAYER2_INPUTS_WIDTH*111) <= std_logic_vector(input_matrix_layer2_s(2, 0, 15));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*112 downto LAYER2_INPUTS_WIDTH*112) <= std_logic_vector(input_matrix_layer2_s(2, 1, 0));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*113 downto LAYER2_INPUTS_WIDTH*113) <= std_logic_vector(input_matrix_layer2_s(2, 1, 1));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*114 downto LAYER2_INPUTS_WIDTH*114) <= std_logic_vector(input_matrix_layer2_s(2, 1, 2));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*115 downto LAYER2_INPUTS_WIDTH*115) <= std_logic_vector(input_matrix_layer2_s(2, 1, 3));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*116 downto LAYER2_INPUTS_WIDTH*116) <= std_logic_vector(input_matrix_layer2_s(2, 1, 4));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*117 downto LAYER2_INPUTS_WIDTH*117) <= std_logic_vector(input_matrix_layer2_s(2, 1, 5));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*118 downto LAYER2_INPUTS_WIDTH*118) <= std_logic_vector(input_matrix_layer2_s(2, 1, 6));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*119 downto LAYER2_INPUTS_WIDTH*119) <= std_logic_vector(input_matrix_layer2_s(2, 1, 7));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*120 downto LAYER2_INPUTS_WIDTH*120) <= std_logic_vector(input_matrix_layer2_s(2, 1, 8));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*121 downto LAYER2_INPUTS_WIDTH*121) <= std_logic_vector(input_matrix_layer2_s(2, 1, 9));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*122 downto LAYER2_INPUTS_WIDTH*122) <= std_logic_vector(input_matrix_layer2_s(2, 1, 10));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*123 downto LAYER2_INPUTS_WIDTH*123) <= std_logic_vector(input_matrix_layer2_s(2, 1, 11));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*124 downto LAYER2_INPUTS_WIDTH*124) <= std_logic_vector(input_matrix_layer2_s(2, 1, 12));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*125 downto LAYER2_INPUTS_WIDTH*125) <= std_logic_vector(input_matrix_layer2_s(2, 1, 13));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*126 downto LAYER2_INPUTS_WIDTH*126) <= std_logic_vector(input_matrix_layer2_s(2, 1, 14));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*127 downto LAYER2_INPUTS_WIDTH*127) <= std_logic_vector(input_matrix_layer2_s(2, 1, 15));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*128 downto LAYER2_INPUTS_WIDTH*128) <= std_logic_vector(input_matrix_layer2_s(2, 2, 0));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*129 downto LAYER2_INPUTS_WIDTH*129) <= std_logic_vector(input_matrix_layer2_s(2, 2, 1));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*130 downto LAYER2_INPUTS_WIDTH*130) <= std_logic_vector(input_matrix_layer2_s(2, 2, 2));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*131 downto LAYER2_INPUTS_WIDTH*131) <= std_logic_vector(input_matrix_layer2_s(2, 2, 3));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*132 downto LAYER2_INPUTS_WIDTH*132) <= std_logic_vector(input_matrix_layer2_s(2, 2, 4));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*133 downto LAYER2_INPUTS_WIDTH*133) <= std_logic_vector(input_matrix_layer2_s(2, 2, 5));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*134 downto LAYER2_INPUTS_WIDTH*134) <= std_logic_vector(input_matrix_layer2_s(2, 2, 6));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*135 downto LAYER2_INPUTS_WIDTH*135) <= std_logic_vector(input_matrix_layer2_s(2, 2, 7));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*136 downto LAYER2_INPUTS_WIDTH*136) <= std_logic_vector(input_matrix_layer2_s(2, 2, 8));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*137 downto LAYER2_INPUTS_WIDTH*137) <= std_logic_vector(input_matrix_layer2_s(2, 2, 9));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*138 downto LAYER2_INPUTS_WIDTH*138) <= std_logic_vector(input_matrix_layer2_s(2, 2, 10));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*139 downto LAYER2_INPUTS_WIDTH*139) <= std_logic_vector(input_matrix_layer2_s(2, 2, 11));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*140 downto LAYER2_INPUTS_WIDTH*140) <= std_logic_vector(input_matrix_layer2_s(2, 2, 12));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*141 downto LAYER2_INPUTS_WIDTH*141) <= std_logic_vector(input_matrix_layer2_s(2, 2, 13));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*142 downto LAYER2_INPUTS_WIDTH*142) <= std_logic_vector(input_matrix_layer2_s(2, 2, 14));
    input_tensor_layer2_s(LAYER2_INPUTS_WIDTH-1+LAYER2_INPUTS_WIDTH*143 downto LAYER2_INPUTS_WIDTH*143) <= std_logic_vector(input_matrix_layer2_s(2, 2, 15));
    -- logic for READING DATA from layer 1 RAM
    -- data is only read from output of layer 1 RAM in states LOAD_LAYER2, PIPE_DELAY0_LAYER2, PIPE_DELAY1_LAYER2, PIPE_DELAY2_LAYER2, PIPE_DELAY3_LAYER2 and START_LAYER2
    -- if the index is out of bounds, the data (for input of layer 2) is set to 0.
    -- otherwise, the input of layer 2 is not changed.
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        if (statem_state_s = LOAD_LAYER2) or (statem_state_s = PIPE_DELAY0_LAYER2) or (statem_state_s = PIPE_DELAY1_LAYER2) or (statem_state_s = PIPE_DELAY2_LAYER2) or (statem_state_s = PIPE_DELAY3_LAYER2) or (statem_state_s = START_LAYER2) then
          if (layer2_address_x_dld3_s >= 0) and (layer2_address_x_dld3_s < 96) and (layer2_address_y_dld3_s >= 0) and (layer2_address_y_dld3_s < 96) then
            --input_tensor_layer2_s(to_integer(layer2_kernel_x_dld4_s), to_integer(layer2_kernel_y_dld4_s), to_integer(layer2_prev_output_dld4_s)) <= layer1_mem_rd_data_s;
            for g in 0 to 16-1 loop
              input_matrix_layer2_s(to_integer(layer2_kernel_x_dld4_s), to_integer(layer2_kernel_y_dld4_s), g) <= unsigned(layer1_mem_rd_data_s(7+8*g downto 8*g));
            end loop;
          else
            for g in 0 to 16-1 loop
              input_matrix_layer2_s(to_integer(layer2_kernel_x_dld4_s), to_integer(layer2_kernel_y_dld4_s), g) <= (others => '0');
            end loop;
          end if;
        end if;
      end if;
    end process;
    
    
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*0 downto LAYER3_INPUTS_WIDTH*0) <= std_logic_vector(input_matrix_layer3_s(0, 0, 0));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*1 downto LAYER3_INPUTS_WIDTH*1) <= std_logic_vector(input_matrix_layer3_s(0, 0, 1));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*2 downto LAYER3_INPUTS_WIDTH*2) <= std_logic_vector(input_matrix_layer3_s(0, 0, 2));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*3 downto LAYER3_INPUTS_WIDTH*3) <= std_logic_vector(input_matrix_layer3_s(0, 0, 3));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*4 downto LAYER3_INPUTS_WIDTH*4) <= std_logic_vector(input_matrix_layer3_s(0, 0, 4));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*5 downto LAYER3_INPUTS_WIDTH*5) <= std_logic_vector(input_matrix_layer3_s(0, 0, 5));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*6 downto LAYER3_INPUTS_WIDTH*6) <= std_logic_vector(input_matrix_layer3_s(0, 0, 6));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*7 downto LAYER3_INPUTS_WIDTH*7) <= std_logic_vector(input_matrix_layer3_s(0, 0, 7));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*8 downto LAYER3_INPUTS_WIDTH*8) <= std_logic_vector(input_matrix_layer3_s(0, 1, 0));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*9 downto LAYER3_INPUTS_WIDTH*9) <= std_logic_vector(input_matrix_layer3_s(0, 1, 1));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*10 downto LAYER3_INPUTS_WIDTH*10) <= std_logic_vector(input_matrix_layer3_s(0, 1, 2));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*11 downto LAYER3_INPUTS_WIDTH*11) <= std_logic_vector(input_matrix_layer3_s(0, 1, 3));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*12 downto LAYER3_INPUTS_WIDTH*12) <= std_logic_vector(input_matrix_layer3_s(0, 1, 4));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*13 downto LAYER3_INPUTS_WIDTH*13) <= std_logic_vector(input_matrix_layer3_s(0, 1, 5));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*14 downto LAYER3_INPUTS_WIDTH*14) <= std_logic_vector(input_matrix_layer3_s(0, 1, 6));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*15 downto LAYER3_INPUTS_WIDTH*15) <= std_logic_vector(input_matrix_layer3_s(0, 1, 7));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*16 downto LAYER3_INPUTS_WIDTH*16) <= std_logic_vector(input_matrix_layer3_s(0, 2, 0));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*17 downto LAYER3_INPUTS_WIDTH*17) <= std_logic_vector(input_matrix_layer3_s(0, 2, 1));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*18 downto LAYER3_INPUTS_WIDTH*18) <= std_logic_vector(input_matrix_layer3_s(0, 2, 2));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*19 downto LAYER3_INPUTS_WIDTH*19) <= std_logic_vector(input_matrix_layer3_s(0, 2, 3));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*20 downto LAYER3_INPUTS_WIDTH*20) <= std_logic_vector(input_matrix_layer3_s(0, 2, 4));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*21 downto LAYER3_INPUTS_WIDTH*21) <= std_logic_vector(input_matrix_layer3_s(0, 2, 5));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*22 downto LAYER3_INPUTS_WIDTH*22) <= std_logic_vector(input_matrix_layer3_s(0, 2, 6));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*23 downto LAYER3_INPUTS_WIDTH*23) <= std_logic_vector(input_matrix_layer3_s(0, 2, 7));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*24 downto LAYER3_INPUTS_WIDTH*24) <= std_logic_vector(input_matrix_layer3_s(1, 0, 0));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*25 downto LAYER3_INPUTS_WIDTH*25) <= std_logic_vector(input_matrix_layer3_s(1, 0, 1));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*26 downto LAYER3_INPUTS_WIDTH*26) <= std_logic_vector(input_matrix_layer3_s(1, 0, 2));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*27 downto LAYER3_INPUTS_WIDTH*27) <= std_logic_vector(input_matrix_layer3_s(1, 0, 3));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*28 downto LAYER3_INPUTS_WIDTH*28) <= std_logic_vector(input_matrix_layer3_s(1, 0, 4));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*29 downto LAYER3_INPUTS_WIDTH*29) <= std_logic_vector(input_matrix_layer3_s(1, 0, 5));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*30 downto LAYER3_INPUTS_WIDTH*30) <= std_logic_vector(input_matrix_layer3_s(1, 0, 6));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*31 downto LAYER3_INPUTS_WIDTH*31) <= std_logic_vector(input_matrix_layer3_s(1, 0, 7));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*32 downto LAYER3_INPUTS_WIDTH*32) <= std_logic_vector(input_matrix_layer3_s(1, 1, 0));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*33 downto LAYER3_INPUTS_WIDTH*33) <= std_logic_vector(input_matrix_layer3_s(1, 1, 1));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*34 downto LAYER3_INPUTS_WIDTH*34) <= std_logic_vector(input_matrix_layer3_s(1, 1, 2));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*35 downto LAYER3_INPUTS_WIDTH*35) <= std_logic_vector(input_matrix_layer3_s(1, 1, 3));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*36 downto LAYER3_INPUTS_WIDTH*36) <= std_logic_vector(input_matrix_layer3_s(1, 1, 4));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*37 downto LAYER3_INPUTS_WIDTH*37) <= std_logic_vector(input_matrix_layer3_s(1, 1, 5));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*38 downto LAYER3_INPUTS_WIDTH*38) <= std_logic_vector(input_matrix_layer3_s(1, 1, 6));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*39 downto LAYER3_INPUTS_WIDTH*39) <= std_logic_vector(input_matrix_layer3_s(1, 1, 7));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*40 downto LAYER3_INPUTS_WIDTH*40) <= std_logic_vector(input_matrix_layer3_s(1, 2, 0));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*41 downto LAYER3_INPUTS_WIDTH*41) <= std_logic_vector(input_matrix_layer3_s(1, 2, 1));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*42 downto LAYER3_INPUTS_WIDTH*42) <= std_logic_vector(input_matrix_layer3_s(1, 2, 2));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*43 downto LAYER3_INPUTS_WIDTH*43) <= std_logic_vector(input_matrix_layer3_s(1, 2, 3));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*44 downto LAYER3_INPUTS_WIDTH*44) <= std_logic_vector(input_matrix_layer3_s(1, 2, 4));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*45 downto LAYER3_INPUTS_WIDTH*45) <= std_logic_vector(input_matrix_layer3_s(1, 2, 5));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*46 downto LAYER3_INPUTS_WIDTH*46) <= std_logic_vector(input_matrix_layer3_s(1, 2, 6));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*47 downto LAYER3_INPUTS_WIDTH*47) <= std_logic_vector(input_matrix_layer3_s(1, 2, 7));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*48 downto LAYER3_INPUTS_WIDTH*48) <= std_logic_vector(input_matrix_layer3_s(2, 0, 0));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*49 downto LAYER3_INPUTS_WIDTH*49) <= std_logic_vector(input_matrix_layer3_s(2, 0, 1));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*50 downto LAYER3_INPUTS_WIDTH*50) <= std_logic_vector(input_matrix_layer3_s(2, 0, 2));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*51 downto LAYER3_INPUTS_WIDTH*51) <= std_logic_vector(input_matrix_layer3_s(2, 0, 3));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*52 downto LAYER3_INPUTS_WIDTH*52) <= std_logic_vector(input_matrix_layer3_s(2, 0, 4));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*53 downto LAYER3_INPUTS_WIDTH*53) <= std_logic_vector(input_matrix_layer3_s(2, 0, 5));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*54 downto LAYER3_INPUTS_WIDTH*54) <= std_logic_vector(input_matrix_layer3_s(2, 0, 6));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*55 downto LAYER3_INPUTS_WIDTH*55) <= std_logic_vector(input_matrix_layer3_s(2, 0, 7));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*56 downto LAYER3_INPUTS_WIDTH*56) <= std_logic_vector(input_matrix_layer3_s(2, 1, 0));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*57 downto LAYER3_INPUTS_WIDTH*57) <= std_logic_vector(input_matrix_layer3_s(2, 1, 1));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*58 downto LAYER3_INPUTS_WIDTH*58) <= std_logic_vector(input_matrix_layer3_s(2, 1, 2));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*59 downto LAYER3_INPUTS_WIDTH*59) <= std_logic_vector(input_matrix_layer3_s(2, 1, 3));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*60 downto LAYER3_INPUTS_WIDTH*60) <= std_logic_vector(input_matrix_layer3_s(2, 1, 4));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*61 downto LAYER3_INPUTS_WIDTH*61) <= std_logic_vector(input_matrix_layer3_s(2, 1, 5));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*62 downto LAYER3_INPUTS_WIDTH*62) <= std_logic_vector(input_matrix_layer3_s(2, 1, 6));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*63 downto LAYER3_INPUTS_WIDTH*63) <= std_logic_vector(input_matrix_layer3_s(2, 1, 7));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*64 downto LAYER3_INPUTS_WIDTH*64) <= std_logic_vector(input_matrix_layer3_s(2, 2, 0));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*65 downto LAYER3_INPUTS_WIDTH*65) <= std_logic_vector(input_matrix_layer3_s(2, 2, 1));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*66 downto LAYER3_INPUTS_WIDTH*66) <= std_logic_vector(input_matrix_layer3_s(2, 2, 2));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*67 downto LAYER3_INPUTS_WIDTH*67) <= std_logic_vector(input_matrix_layer3_s(2, 2, 3));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*68 downto LAYER3_INPUTS_WIDTH*68) <= std_logic_vector(input_matrix_layer3_s(2, 2, 4));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*69 downto LAYER3_INPUTS_WIDTH*69) <= std_logic_vector(input_matrix_layer3_s(2, 2, 5));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*70 downto LAYER3_INPUTS_WIDTH*70) <= std_logic_vector(input_matrix_layer3_s(2, 2, 6));
    input_tensor_layer3_s(LAYER3_INPUTS_WIDTH-1+LAYER3_INPUTS_WIDTH*71 downto LAYER3_INPUTS_WIDTH*71) <= std_logic_vector(input_matrix_layer3_s(2, 2, 7));
    -- logic for READING DATA from layer 2 RAM
    -- data is only read from output of layer 2 RAM in states LOAD_LAYER3, PIPE_DELAY0_LAYER3, PIPE_DELAY1_LAYER3, PIPE_DELAY2_LAYER3, PIPE_DELAY3_LAYER3 and START_LAYER3
    -- if the index is out of bounds, the data (for input of layer 3) is set to 0.
    -- otherwise, the input of layer 3 is not changed.
    process (S_AXI_ACLK)
      begin
        if rising_edge(S_AXI_ACLK) then
          if (statem_state_s = LOAD_LAYER3) or (statem_state_s = PIPE_DELAY0_LAYER3) or (statem_state_s = PIPE_DELAY1_LAYER3) or (statem_state_s = PIPE_DELAY2_LAYER3) or (statem_state_s = PIPE_DELAY3_LAYER3) or (statem_state_s = START_LAYER3) then
            if (layer3_address_x_dld3_s >= 0) and (layer3_address_x_dld3_s < 96) and (layer3_address_y_dld3_s >= 0) and (layer3_address_y_dld3_s < 96) then
              for g in 0 to 8-1 loop
                input_matrix_layer3_s(to_integer(layer3_kernel_x_dld4_s), to_integer(layer3_kernel_y_dld4_s), g) <=  unsigned(layer2_mem_rd_data_s(7+8*g downto 8*g));
              end loop;
            else
              for g in 0 to 8-1 loop
                input_matrix_layer3_s(to_integer(layer3_kernel_x_dld4_s), to_integer(layer3_kernel_y_dld4_s), g) <= (others => '0');
              end loop;
            end if;
          end if;
        end if;
    end process;
    
    output_matrix_layer3_s(0) <= signed(output_vector_layer3_s(LAYER3_POST_PROC_WIDTH-1+LAYER3_POST_PROC_WIDTH*0 downto LAYER3_POST_PROC_WIDTH*0));  -- 32-bit
    output_matrix_layer3_s(1) <= signed(output_vector_layer3_s(LAYER3_POST_PROC_WIDTH-1+LAYER3_POST_PROC_WIDTH*1 downto LAYER3_POST_PROC_WIDTH*1));
    --output_matrix_layer3_s(0) <= signed(output_vector_layer3_s(16-1+16*0 downto 16*0));  -- 16-bit
    --output_matrix_layer3_s(1) <= signed(output_vector_layer3_s(16-1+16*1 downto 16*1));
    -- WRITING RESULTS and READING FROM - layer 3 RAM
    -- If the statemachine is in the writing state (writing results of layer 3), the write enable bit is set and address as well as
    -- data taken from the computational logic.
    -- Otherwise: write enable bit is always 0 and data & address too.
    process( S_AXI_ACLK ) is
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if (statem_state_s = WRITE_RAM_LAYER3) then
          layer3_mem_we_s <= '1';
          layer3_mem_address_s <= layer3_mem_wr_index_s;
          --layer3_mem_wr_data_s <= output_vector_layer3_s(layer3_mem_shift_steps_s);
          layer3_mem_wr_data_s <= output_matrix_layer3_s(layer3_mem_shift_steps_s);
        else
          if (statem_state_s = TRANSFER) or (statem_state_s = PRE_TRANSFER0) or (statem_state_s = PRE_TRANSFER1) or (statem_state_s = POST_TRANSFER0) or (statem_state_s = POST_TRANSFER0) then
            layer3_mem_we_s <= '0';
            layer3_mem_address_s <= to_integer(transfer_index_s);
            layer3_mem_wr_data_s <= (others => '0');
          else
            if (statem_state_s = DONE_LAYER3) then
              layer3_mem_we_s <= '0';
              layer3_mem_address_s <= to_integer(signed(slv_reg29));
              layer3_mem_wr_data_s <= (others => '0');
            else
              layer3_mem_we_s <= '0';
              layer3_mem_address_s <= 0;
              layer3_mem_wr_data_s <= (others => '0');
            end if;
          end if;
        end if;
      end if;
    end process;
    
    -- address computation for layer 1 RAM
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        layer2_address_x_s     <= resize(layer2_index_x_s + layer2_kernel_x_s - 1, 8);
      end if;
    end process;
    
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        layer2_address_y_s     <= resize(layer2_index_y_s + layer2_kernel_y_s - 1, 8);
      end if;
    end process;
    
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        layer2_address_part1_s <= resize(resize(unsigned(layer2_address_x_s), 18) * 1, 18);
      end if;
    end process;
    
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        layer2_address_part2_s <= resize(resize(unsigned(layer2_address_y_s), 18) * 96, 18);
      end if;
    end process;
    
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        --layer2_address_s       <= unsigned(resize(layer2_address_part1_s + layer2_address_part2_s + unsigned(layer2_prev_output_dld1_s), 18));
        layer2_address_s       <= unsigned(resize(layer2_address_part1_s + layer2_address_part2_s, 18));
      end if;
    end process;
    
    -- address computation for layer 2 RAM
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        layer3_address_x_s     <= resize(layer3_index_x_s + layer3_kernel_x_s - 1, 8);
      end if;
    end process;
    
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        layer3_address_y_s     <= resize(layer3_index_y_s + layer3_kernel_y_s - 1, 8);
      end if;
    end process;
    
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        layer3_address_part1_s <= resize(resize(unsigned(layer3_address_x_s), 17) * 1, 17);
      end if;
    end process;
    
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        layer3_address_part2_s <= resize(resize(unsigned(layer3_address_y_s), 17) * 96, 17);
      end if;
    end process;
    
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        --layer3_address_s       <= unsigned(resize(layer3_address_part1_s + layer3_address_part2_s + unsigned(layer3_prev_output_dld1_s), 17));
        layer3_address_s       <= unsigned(resize(layer3_address_part1_s + layer3_address_part2_s, 17));
      end if;
    end process;
    
    -- pipeline logic
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then
        -- layer 2 pipeline
        layer2_kernel_x_dld0_s    <= layer2_kernel_x_s;
        layer2_kernel_y_dld0_s    <= layer2_kernel_y_s;
        --layer2_prev_output_dld0_s <= layer2_prev_output_s;
        layer2_address_x_dld0_s   <= layer2_address_x_s;
        layer2_address_y_dld0_s   <= layer2_address_y_s;
        layer2_kernel_x_dld1_s    <= layer2_kernel_x_dld0_s;
        layer2_kernel_y_dld1_s    <= layer2_kernel_y_dld0_s;
        --layer2_prev_output_dld1_s <= layer2_prev_output_dld0_s;
        layer2_address_x_dld1_s   <= layer2_address_x_dld0_s;
        layer2_address_y_dld1_s   <= layer2_address_y_dld0_s;
        layer2_kernel_x_dld2_s    <= layer2_kernel_x_dld1_s;
        layer2_kernel_y_dld2_s    <= layer2_kernel_y_dld1_s;
        --layer2_prev_output_dld2_s <= layer2_prev_output_dld1_s;
        layer2_address_x_dld2_s   <= layer2_address_x_dld1_s;
        layer2_address_y_dld2_s   <= layer2_address_y_dld1_s;
        layer2_kernel_x_dld3_s    <= layer2_kernel_x_dld2_s;
        layer2_kernel_y_dld3_s    <= layer2_kernel_y_dld2_s;
        --layer2_prev_output_dld3_s <= layer2_prev_output_dld2_s;
        layer2_address_x_dld3_s   <= layer2_address_x_dld2_s;
        layer2_address_y_dld3_s   <= layer2_address_y_dld2_s;
        layer2_kernel_x_dld4_s    <= layer2_kernel_x_dld3_s;
        layer2_kernel_y_dld4_s    <= layer2_kernel_y_dld3_s;
        --layer2_prev_output_dld4_s <= layer2_prev_output_dld3_s;
        layer2_address_x_dld4_s   <= layer2_address_x_dld3_s;
        layer2_address_y_dld4_s   <= layer2_address_y_dld3_s;
        -- lyer 3 pipeline
        layer3_kernel_x_dld0_s    <= layer3_kernel_x_s;
        layer3_kernel_y_dld0_s    <= layer3_kernel_y_s;
        --layer3_prev_output_dld0_s <= layer3_prev_output_s;
        layer3_address_x_dld0_s   <= layer3_address_x_s;
        layer3_address_y_dld0_s   <= layer3_address_y_s;
        layer3_kernel_x_dld1_s    <= layer3_kernel_x_dld0_s;
        layer3_kernel_y_dld1_s    <= layer3_kernel_y_dld0_s;
        --layer3_prev_output_dld1_s <= layer3_prev_output_dld0_s;
        layer3_address_x_dld1_s   <= layer3_address_x_dld0_s;
        layer3_address_y_dld1_s   <= layer3_address_y_dld0_s;
        layer3_kernel_x_dld2_s    <= layer3_kernel_x_dld1_s;
        layer3_kernel_y_dld2_s    <= layer3_kernel_y_dld1_s;
        --layer3_prev_output_dld2_s <= layer3_prev_output_dld1_s;
        layer3_address_x_dld2_s   <= layer3_address_x_dld1_s;
        layer3_address_y_dld2_s   <= layer3_address_y_dld1_s;
        layer3_kernel_x_dld3_s    <= layer3_kernel_x_dld2_s;
        layer3_kernel_y_dld3_s    <= layer3_kernel_y_dld2_s;
        --layer3_prev_output_dld3_s <= layer3_prev_output_dld2_s;
        layer3_address_x_dld3_s   <= layer3_address_x_dld2_s;
        layer3_address_y_dld3_s   <= layer3_address_y_dld2_s;
        layer3_kernel_x_dld4_s    <= layer3_kernel_x_dld3_s;
        layer3_kernel_y_dld4_s    <= layer3_kernel_y_dld3_s;
        --layer3_prev_output_dld4_s <= layer3_prev_output_dld3_s;
        layer3_address_x_dld4_s   <= layer3_address_x_dld3_s;
        layer3_address_y_dld4_s   <= layer3_address_y_dld3_s;
        -- output transfer pipeline
        transfer_counter_dld0_s   <= transfer_counter_s;
        transfer_counter_dld1_s   <= transfer_counter_dld0_s;
      end if;
    end process;

    -- writing and shifting input data
    process (S_AXI_ACLK)
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if (statem_state_s = INIT_LAYER1) then
          -- col1
            --input_tensor_layer1_s(0, 0, 0) <= signed(slv_reg0);  -- (0, 0, 0)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*0 downto LAYER1_INPUTS_WIDTH*0) <= slv_reg0(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (0, 0, 0)
            --input_tensor_layer1_s(0, 0, 1) <= signed(slv_reg1);  -- (0, 0, 1)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*1 downto LAYER1_INPUTS_WIDTH*1) <= slv_reg1(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (0, 0, 1)
            --input_tensor_layer1_s(0, 1, 0) <= signed(slv_reg2);  -- (0, 1, 0)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*2 downto LAYER1_INPUTS_WIDTH*2) <= slv_reg2(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (0, 1, 0)
            --input_tensor_layer1_s(0, 1, 1) <= signed(slv_reg3);  -- (0, 1, 1)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*3 downto LAYER1_INPUTS_WIDTH*3) <= slv_reg3(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (0, 1, 1)
            --input_tensor_layer1_s(0, 2, 0) <= signed(slv_reg4);  -- (0, 2, 0)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*4 downto LAYER1_INPUTS_WIDTH*4) <= slv_reg4(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (0, 2, 0)
            --input_tensor_layer1_s(0, 2, 1) <= signed(slv_reg5);  -- (0, 2, 1)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*5 downto LAYER1_INPUTS_WIDTH*5) <= slv_reg5(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (0, 2, 1)
          else
            if (statem_state_s = SHIFT_INPUTS_LAYER1_0) then
              -- col1
              input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*5 downto LAYER1_INPUTS_WIDTH*0) <= input_buf_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*5 downto LAYER1_INPUTS_WIDTH*0);
              --input_tensor_layer1_s(0, 0, 0) <= input_buf0_layer1_s;
              --input_tensor_layer1_s(0, 0, 1) <= input_buf1_layer1_s;
              --input_tensor_layer1_s(0, 1, 0) <= input_buf2_layer1_s;
              --input_tensor_layer1_s(0, 1, 1) <= input_buf3_layer1_s;
              --input_tensor_layer1_s(0, 2, 0) <= input_buf4_layer1_s;
              --input_tensor_layer1_s(0, 2, 1) <= input_buf5_layer1_s;
            end if;
          end if;
        end if;
      end process;
      
    -- writing and shifting input data
    process (S_AXI_ACLK)
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if (statem_state_s = INIT_LAYER1) then
            -- col2
            --input_tensor_layer1_s(1, 0, 0) <= signed(slv_reg6);  -- (1, 0, 0)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*6 downto LAYER1_INPUTS_WIDTH*6) <= slv_reg6(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (1, 0, 0)
            --input_tensor_layer1_s(1, 0, 1) <= signed(slv_reg7);  -- (1, 0, 1)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*7 downto LAYER1_INPUTS_WIDTH*7) <= slv_reg7(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (1, 0, 1)
            --input_tensor_layer1_s(1, 1, 0) <= signed(slv_reg8);  -- (1, 1, 0)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*8 downto LAYER1_INPUTS_WIDTH*8) <= slv_reg8(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (1, 1, 0)
            --input_tensor_layer1_s(1, 1, 1) <= signed(slv_reg9);  -- (1, 1, 1)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*9 downto LAYER1_INPUTS_WIDTH*9) <= slv_reg9(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (1, 1, 1)
            --input_tensor_layer1_s(1, 2, 0) <= signed(slv_reg10); -- (1, 2, 0)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*10 downto LAYER1_INPUTS_WIDTH*10) <= slv_reg10(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (1, 2, 0)
            --input_tensor_layer1_s(1, 2, 1) <= signed(slv_reg11); -- (1, 2, 1)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*11 downto LAYER1_INPUTS_WIDTH*11) <= slv_reg11(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (1, 2, 1)
          else
            if (statem_state_s = SHIFT_INPUTS_LAYER1_1) then
              -- col2
              input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*11 downto LAYER1_INPUTS_WIDTH*6) <= input_buf_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*11 downto LAYER1_INPUTS_WIDTH*6);
              --input_tensor_layer1_s(1, 0, 0) <= input_buf6_layer1_s;
              --input_tensor_layer1_s(1, 0, 1) <= input_buf7_layer1_s;
              --input_tensor_layer1_s(1, 1, 0) <= input_buf8_layer1_s;
              --input_tensor_layer1_s(1, 1, 1) <= input_buf9_layer1_s;
              --input_tensor_layer1_s(1, 2, 0) <= input_buf10_layer1_s;
              --input_tensor_layer1_s(1, 2, 1) <= input_buf11_layer1_s;
            end if;
          end if;
        end if;
      end process;
      
    -- writing and shifting input data
    process (S_AXI_ACLK)
    begin
      if (rising_edge (S_AXI_ACLK)) then
        if (statem_state_s = INIT_LAYER1) then
            -- col3
            --input_tensor_layer1_s(2, 0, 0) <= signed(slv_reg12); -- (2, 0, 0)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*12 downto LAYER1_INPUTS_WIDTH*12) <= slv_reg12(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 0, 0)
            --input_tensor_layer1_s(2, 0, 1) <= signed(slv_reg13); -- (2, 0, 1)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*13 downto LAYER1_INPUTS_WIDTH*13) <= slv_reg13(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 0, 1)
            --input_tensor_layer1_s(2, 1, 0) <= signed(slv_reg14); -- (2, 1, 0)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*14 downto LAYER1_INPUTS_WIDTH*14) <= slv_reg14(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 1, 0)
            --input_tensor_layer1_s(2, 1, 1) <= signed(slv_reg15); -- (2, 1, 1)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*15 downto LAYER1_INPUTS_WIDTH*15) <= slv_reg15(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 1, 1)
            --input_tensor_layer1_s(2, 2, 0) <= signed(slv_reg16); -- (2, 2, 0)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*16 downto LAYER1_INPUTS_WIDTH*16) <= slv_reg16(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 2, 0)
            --input_tensor_layer1_s(2, 2, 1) <= signed(slv_reg17); -- (2, 2, 1)
            input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*17 downto LAYER1_INPUTS_WIDTH*17) <= slv_reg17(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 2, 1)
          else
            if (statem_state_s = INIT_LAYER1_CONSECUTIVE) then
              --input_tensor_layer1_s(2, 0, 0) <= signed(slv_reg12); -- (2, 0, 0)
              input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*12 downto LAYER1_INPUTS_WIDTH*12) <= slv_reg12(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 0, 0)
              --input_tensor_layer1_s(2, 0, 1) <= signed(slv_reg13); -- (2, 0, 1)
              input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*13 downto LAYER1_INPUTS_WIDTH*13) <= slv_reg13(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 0, 1)
              --input_tensor_layer1_s(2, 1, 0) <= signed(slv_reg14); -- (2, 1, 0)
              input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*14 downto LAYER1_INPUTS_WIDTH*14) <= slv_reg14(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 1, 0)
              --input_tensor_layer1_s(2, 1, 1) <= signed(slv_reg15); -- (2, 1, 1)
              input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*15 downto LAYER1_INPUTS_WIDTH*15) <= slv_reg15(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 1, 1)
              --input_tensor_layer1_s(2, 2, 0) <= signed(slv_reg16); -- (2, 2, 0)
              input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*16 downto LAYER1_INPUTS_WIDTH*16) <= slv_reg16(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 2, 0)
              --input_tensor_layer1_s(2, 2, 1) <= signed(slv_reg17); -- (2, 2, 1)
              input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*17 downto LAYER1_INPUTS_WIDTH*17) <= slv_reg17(LAYER1_INPUTS_WIDTH-1 downto 0);  -- (2, 2, 1)
            end if;
          end if;
        end if;
      end process;
      
      -- writing and shifting input data
      process (S_AXI_ACLK)
      begin
        if (rising_edge (S_AXI_ACLK)) then
          if (statem_state_s = COPY_INPUTS_LAYER1_0) then
            -- col1
            input_buf_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*5 downto LAYER1_INPUTS_WIDTH*0) <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*11 downto LAYER1_INPUTS_WIDTH*6);
            --input_buf0_layer1_s <= input_tensor_layer1_s(1, 0, 0);
            --input_buf1_layer1_s <= input_tensor_layer1_s(1, 0, 1);
            --input_buf2_layer1_s <= input_tensor_layer1_s(1, 1, 0);
            --input_buf3_layer1_s <= input_tensor_layer1_s(1, 1, 1);
            --input_buf4_layer1_s <= input_tensor_layer1_s(1, 2, 0);
            --input_buf5_layer1_s <= input_tensor_layer1_s(1, 2, 1); 
          end if;
        end if;
      end process;
      
      -- writing and shifting input data
      process (S_AXI_ACLK)
      begin
        if (rising_edge (S_AXI_ACLK)) then
          if (statem_state_s = COPY_INPUTS_LAYER1_1) then
            -- col2
            input_buf_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*11 downto LAYER1_INPUTS_WIDTH*6) <= input_tensor_layer1_s(LAYER1_INPUTS_WIDTH-1+LAYER1_INPUTS_WIDTH*17 downto LAYER1_INPUTS_WIDTH*12);
            --input_buf6_layer1_s  <= input_tensor_layer1_s(2, 0, 0);
            --input_buf7_layer1_s  <= input_tensor_layer1_s(2, 0, 1);
            --input_buf8_layer1_s  <= input_tensor_layer1_s(2, 1, 0);
            --input_buf9_layer1_s  <= input_tensor_layer1_s(2, 1, 1);
            --input_buf10_layer1_s <= input_tensor_layer1_s(2, 2, 0);
            --input_buf11_layer1_s <= input_tensor_layer1_s(2, 2, 1);
          end if;
        end if;
      end process;
    
    -- state machine
    process (S_AXI_ACLK)
    begin
      if rising_edge(S_AXI_ACLK) then 
        if RESET_s = '0' then                             -- RESET STATE
          statem_state_s                 <= INIT_LAYER1;
          -- layer 1 signals
          layer1_block_counter_s         <= 0;
          layer1_result_counter_s        <= 0;
          --layer1_mem_shift_steps_s       <= 0;
          layer1_mem_wr_index_s          <= 0;
          -- layer 2 signals
          layer2_index_x_s               <= to_signed(0, 8);
          layer2_index_y_s               <= to_signed(0, 8);
          layer2_kernel_x_s              <= to_signed(0, 3);
          layer2_kernel_y_s              <= to_signed(0, 3);
          --layer2_prev_output_s           <= to_signed(0, 5);
          layer2_mem_wr_index_s          <= 0;
          -- layer 3 signals
          layer3_index_x_s               <= to_signed(0, 8);
          layer3_index_y_s               <= to_signed(0, 8);
          layer3_kernel_x_s              <= to_signed(0, 3);
          layer3_kernel_y_s              <= to_signed(0, 3);
          --layer3_prev_output_s           <= to_signed(0, 5);
          layer3_mem_wr_index_s          <= 0;
          -- transfer signals
          transfer_index_s               <= to_unsigned(0, 16);
          transfer_counter_s             <= to_unsigned(0, 8);
      else
        case (statem_state_s) is
        
          when (INIT_LAYER1) =>
            if (data_rdy_in_register_layer1_s = '1') then
              statem_state_s         <= START_LAYER1;
              layer1_block_counter_s <= 0;
            else
              statem_state_s         <= INIT_LAYER1;
            end if;
          
          when (INIT_LAYER1_CONSECUTIVE) =>
            if (data_rdy_in_register_layer1_s = '1') then
              statem_state_s         <= START_LAYER1;
              layer1_block_counter_s <= layer1_block_counter_s + 1;
            else
              statem_state_s         <= INIT_LAYER1_CONSECUTIVE;
            end if;
          
          when (START_LAYER1) =>
            statem_state_s <= WAIT_FOR_LAYER1;
          
          when (WAIT_FOR_LAYER1) =>
            if (data_rdy_out_layer1_s = '1') then
              statem_state_s <= COPY_INPUTS_LAYER1_0;
            else
              statem_state_s <= WAIT_FOR_LAYER1;
            end if;
          
          when (COPY_INPUTS_LAYER1_0) =>                        -- layer1: shift input values (and wait until done processing)
            statem_state_s <= COPY_INPUTS_LAYER1_1;
          
          when (COPY_INPUTS_LAYER1_1) =>
            statem_state_s <= SHIFT_INPUTS_LAYER1_0;
          
          when (SHIFT_INPUTS_LAYER1_0) =>
            statem_state_s <= SHIFT_INPUTS_LAYER1_1;
          
          when (SHIFT_INPUTS_LAYER1_1) =>
            statem_state_s <= DATA_RDY_OUT_LAYER1;
          
          when (DATA_RDY_OUT_LAYER1) =>
            if (data_rdy_in_register_layer1_s = '0') then
              statem_state_s <= WRITE_RAM_LAYER1;
            else
              statem_state_s <= DATA_RDY_OUT_LAYER1;
            end if;
            
          when (WRITE_RAM_LAYER1) =>                            -- layer1: write results to ram
            layer1_mem_wr_index_s    <= layer1_mem_wr_index_s + 1;
            --if (layer1_mem_shift_steps_s = 15) then
              statem_state_s           <= CHECK_PROGRESS_LAYER1;
              --layer1_mem_shift_steps_s <= 0;
            --else
              --statem_state_s           <= WRITE_RAM_LAYER1;
              --layer1_mem_shift_steps_s <= layer1_mem_shift_steps_s + 1;
            --end if;
          
          when (CHECK_PROGRESS_LAYER1) =>                       -- layer1: check progress of whole map
            if (layer1_result_counter_s = 96*96-1) then
              layer1_result_counter_s <= 0;
              layer1_mem_wr_index_s   <= 0;
              statem_state_s          <= INIT_LAYER2;
            else
              layer1_result_counter_s <= layer1_result_counter_s + 1;
              if (layer1_block_counter_s = 95) then
                statem_state_s        <= INIT_LAYER1;
              else
                statem_state_s        <= INIT_LAYER1_CONSECUTIVE;
              end if;
            end if;
            
          when (INIT_LAYER2) =>
            layer2_index_x_s      <= to_signed(0, 8);
            layer2_index_y_s      <= to_signed(0, 8);
            layer2_kernel_x_s     <= to_signed(0, 3);
            layer2_kernel_y_s     <= to_signed(0, 3);
            --layer2_prev_output_s  <= to_signed(0, 5);
            layer2_mem_wr_index_s <= 0;
            statem_state_s        <= LOAD_LAYER2;
          
          when (LOAD_LAYER2) =>
            --if (layer2_prev_output_s = 15) then
              --layer2_prev_output_s  <= to_signed(0, 5);
              if (layer2_kernel_x_s = 2) then
                layer2_kernel_x_s   <= to_signed(0, 3);
                if (layer2_kernel_y_s = 2) then
                  layer2_kernel_y_s <= to_signed(0, 3);
                  statem_state_s    <= PIPE_DELAY0_LAYER2;
                else
                  layer2_kernel_y_s <= layer2_kernel_y_s + 1;
                  statem_state_s    <= LOAD_LAYER2;
                end if;
              else
                layer2_kernel_x_s <= layer2_kernel_x_s + 1;
                statem_state_s      <= LOAD_LAYER2;
              end if;
            --else
              --layer2_prev_output_s <= layer2_prev_output_s + 1;
              --statem_state_s        <= LOAD_LAYER2;
            --end if;
          
          when (PIPE_DELAY0_LAYER2) =>
            statem_state_s <= PIPE_DELAY1_LAYER2;
            
          when (PIPE_DELAY1_LAYER2) =>
            statem_state_s <= PIPE_DELAY2_LAYER2;
            
          when (PIPE_DELAY2_LAYER2) =>
            statem_state_s <= PIPE_DELAY3_LAYER2;
          
          when (PIPE_DELAY3_LAYER2) =>
            statem_state_s <= START_LAYER2;
            
          when (START_LAYER2) =>
            statem_state_s <= WAIT_FOR_LAYER2;
            
          when (WAIT_FOR_LAYER2) =>
            if (data_rdy_out_layer2_s = '1') then
              statem_state_s <= WRITE_RAM_LAYER2;
            else
              statem_state_s <= WAIT_FOR_LAYER2;
            end if;
              
          when (WRITE_RAM_LAYER2) =>
            layer2_mem_wr_index_s      <= layer2_mem_wr_index_s + 1;
            --if (layer2_mem_shift_steps_s = 7) then
              statem_state_s           <= WAIT_DTA_RDY_LAYER2;
              --layer2_mem_shift_steps_s <= 0;
            --else
              --statem_state_s           <= WRITE_RAM_LAYER2;
              --layer2_mem_shift_steps_s <= layer2_mem_shift_steps_s + 1;
            --end if;
            
          when (WAIT_DTA_RDY_LAYER2) =>
            if (data_rdy_out_layer2_s = '0') then
              statem_state_s <= CHECK_PROGRESS_LAYER2;
            else
              statem_state_s <= WAIT_DTA_RDY_LAYER2;
            end if;
            
          when (CHECK_PROGRESS_LAYER2) =>
            if (layer2_index_x_s = 95) then
              layer2_index_x_s   <= to_signed(0, 8);
              if (layer2_index_y_s = 95) then
                layer2_index_y_s <= to_signed(0, 8);
                statem_state_s   <= INIT_LAYER3;
              else
                layer2_index_y_s <= layer2_index_y_s + 1;
                statem_state_s   <= LOAD_LAYER2;
              end if;
            else
              layer2_index_x_s   <= layer2_index_x_s + 1;
              statem_state_s     <= LOAD_LAYER2;
            end if;
          
          when (INIT_LAYER3) =>
              layer3_index_x_s      <= to_signed(0, 8);
              layer3_index_y_s      <= to_signed(0, 8);
              layer3_kernel_x_s     <= to_signed(0, 3);
              layer3_kernel_y_s     <= to_signed(0, 3);
              --layer3_prev_output_s  <= to_signed(0, 5);
              layer3_mem_wr_index_s <= 0;
              statem_state_s        <= LOAD_LAYER3;

          when (LOAD_LAYER3) =>
            --if (layer3_prev_output_s = 7) then
              --layer3_prev_output_s  <= to_signed(0, 5);
              if (layer3_kernel_x_s = 2) then
                layer3_kernel_x_s   <= to_signed(0, 3);
                if (layer3_kernel_y_s = 2) then
                  layer3_kernel_y_s <= to_signed(0, 3);
                  statem_state_s    <= PIPE_DELAY0_LAYER3;
                else
                  layer3_kernel_y_s <= layer3_kernel_y_s + 1;
                  statem_state_s    <= LOAD_LAYER3;
                end if;
              else
                layer3_kernel_x_s <= layer3_kernel_x_s + 1;
                statem_state_s      <= LOAD_LAYER3;
              end if;
            --else
              --layer3_prev_output_s <= layer3_prev_output_s + 1;
              --statem_state_s        <= LOAD_LAYER3;
            --end if;
            
          when (PIPE_DELAY0_LAYER3) =>
            statem_state_s <= PIPE_DELAY1_LAYER3;
            
          when (PIPE_DELAY1_LAYER3) =>
            statem_state_s <= PIPE_DELAY2_LAYER3;
            
          when (PIPE_DELAY2_LAYER3) =>
            statem_state_s <= PIPE_DELAY3_LAYER3;
            
          when (PIPE_DELAY3_LAYER3) =>
            statem_state_s <= START_LAYER3;
            
          when (START_LAYER3) =>
            statem_state_s <= WAIT_FOR_LAYER3;
            
          when (WAIT_FOR_LAYER3) =>
            if (data_rdy_out_layer3_s = '1') then
              statem_state_s <= WRITE_RAM_LAYER3;
            else
              statem_state_s <= WAIT_FOR_LAYER3;
            end if;
              
          when (WRITE_RAM_LAYER3) =>
            layer3_mem_wr_index_s      <= layer3_mem_wr_index_s + 1;
            if (layer3_mem_shift_steps_s = 1) then
              statem_state_s           <= WAIT_DTA_RDY_LAYER3;
              layer3_mem_shift_steps_s <= 0;
            else
              statem_state_s           <= WRITE_RAM_LAYER3;
              layer3_mem_shift_steps_s <= layer3_mem_shift_steps_s + 1;
            end if;
            
          when (WAIT_DTA_RDY_LAYER3) =>
            if (data_rdy_out_layer3_s = '0') then
              statem_state_s <= CHECK_PROGRESS_LAYER3;
            else
              statem_state_s <= WAIT_DTA_RDY_LAYER3;
            end if;
            
          when (CHECK_PROGRESS_LAYER3) =>
            if (layer3_index_x_s = 95) then
              layer3_index_x_s   <= to_signed(0, 8);
              if (layer3_index_y_s = 95) then
                layer3_index_y_s <= to_signed(0, 8);
                statem_state_s   <= DONE_LAYER3;
              else
                layer3_index_y_s <= layer3_index_y_s + 1;
                statem_state_s   <= LOAD_LAYER3;
              end if;
            else
              layer3_index_x_s   <= layer3_index_x_s + 1;
              statem_state_s     <= LOAD_LAYER3;
            end if;
            
          when (DONE_LAYER3) =>
            statem_state_s <= INIT_TRANSFER;
          
          when (INIT_TRANSFER) =>
            transfer_index_s   <= to_unsigned(0, 16);
            transfer_counter_s <= to_unsigned(0, 8);
            statem_state_s     <= PRE_TRANSFER0;
          
          when (PRE_TRANSFER0) =>
            transfer_index_s   <= transfer_index_s + 1;
            transfer_counter_s <= transfer_counter_s + 1;
            statem_state_s     <= PRE_TRANSFER1;
          
          when (PRE_TRANSFER1) =>
            transfer_index_s   <= transfer_index_s + 1;
            transfer_counter_s <= transfer_counter_s + 1;
            statem_state_s     <= TRANSFER;
          
          when (TRANSFER) =>
            transfer_index_s     <= transfer_index_s + 1;
            if (transfer_counter_s = 15) then
              statem_state_s     <= POST_TRANSFER0;
              transfer_counter_s <= to_unsigned(0, 8);
            else
              statem_state_s     <= TRANSFER;
              transfer_counter_s <= transfer_counter_s + 1;
            end if;
          
          when (POST_TRANSFER0) =>
            statem_state_s <= POST_TRANSFER1;
          
          when (POST_TRANSFER1) =>
            statem_state_s <= WAIT_FOR_TRANSFER;
          
          when (WAIT_FOR_TRANSFER) =>
            if (data_transfered_in_s = '1') then
              statem_state_s <= WAIT_FOR_TRANSFER_CLEAR;
            else
              statem_state_s <= WAIT_FOR_TRANSFER;
            end if;
          
          when (WAIT_FOR_TRANSFER_CLEAR) =>
            if (data_transfered_in_s = '0') then
              statem_state_s <= CHECK_TRANSFER_PROGRESS;
            else
              statem_state_s <= WAIT_FOR_TRANSFER_CLEAR;
            end if;
          
          when (CHECK_TRANSFER_PROGRESS) =>
            if (transfer_index_s = 96*96*2-1) then
              transfer_index_s <= to_unsigned(0, 16);
              statem_state_s <= END_OF_TRANSFER;
            else
              statem_state_s <= TRANSFER;
            end if;
          
          when (END_OF_TRANSFER) =>
            statem_state_s <= INIT_LAYER1;


          when others =>
              statem_state_s <= INIT_LAYER1;
            
          end case;
        end if;
      end if;                   
    end process; 

	-- User logic ends

end arch_imp;
