library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity LG_Layer2 is
  Generic (
    --
    START_OUTPUT            : integer := 0;
    STOP_OUTPUT             : integer := 3;
    -- CNN value generics
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
    -- MAC generics
    MAC_LAYER2_A_WIDTH      : integer := 8;
    MAC_LAYER2_B_WIDTH      : integer := 8;
    MAC_LAYER2_OUT_WIDTH    : integer := 24);
  Port (
    input_tensor            : in  std_logic_vector(3*3*16*INPUTS_WIDTH-1 downto 0);  -- (3x3x16) (x,y,z)
    output_vector           : out std_logic_vector((STOP_OUTPUT-START_OUTPUT+1)*ACT_WIDTH-1 downto 0);          -- (?)
    data_rdy_in             : in  std_logic;                                         -- done writing input_tensor
    data_rdy_out            : out std_logic;                                         -- PL signal that it's done processing
    rst_in                  : in  std_logic;                                         -- active low reset
    clk                     : in  std_logic);
end LG_Layer2;

architecture behave of LG_Layer2 is

  component LG_MAC_layer2
    generic (
      A_WIDTH   : integer := 8;
      B_WIDTH   : integer := 8;
      OUT_WIDTH : integer := 24);
    port (
      a         : in  unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
      b         : in  signed (MAC_LAYER2_B_WIDTH-1 downto 0);
      clk       : in  std_logic;
      sload     : in  std_logic;
      accum_out : out signed (MAC_LAYER2_OUT_WIDTH-1 downto 0));
  end component;
  
  -- MAC0 signals
  signal mac0_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac0_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac0_sload_s     : std_logic;
  signal mac0_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC1 signals
  signal mac1_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac1_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac1_sload_s     : std_logic;
  signal mac1_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC2 signals
  signal mac2_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac2_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac2_sload_s     : std_logic;
  signal mac2_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC3 signals
  signal mac3_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac3_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac3_sload_s     : std_logic;
  signal mac3_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC4 signals
  signal mac4_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac4_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac4_sload_s     : std_logic;
  signal mac4_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC5 signals
  signal mac5_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac5_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac5_sload_s     : std_logic;
  signal mac5_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC6 signals
  signal mac6_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac6_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac6_sload_s     : std_logic;
  signal mac6_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC7 signals
  signal mac7_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac7_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac7_sload_s     : std_logic;
  signal mac7_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC8 signals
  signal mac8_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac8_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac8_sload_s     : std_logic;
  signal mac8_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC9 signals
  signal mac9_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac9_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac9_sload_s     : std_logic;
  signal mac9_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC10 signals
  signal mac10_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac10_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac10_sload_s     : std_logic;
  signal mac10_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC11 signals
  signal mac11_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac11_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac11_sload_s     : std_logic;
  signal mac11_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC12 signals
  signal mac12_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac12_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac12_sload_s     : std_logic;
  signal mac12_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC13 signals
  signal mac13_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac13_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac13_sload_s     : std_logic;
  signal mac13_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC14 signals
  signal mac14_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac14_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac14_sload_s     : std_logic;
  signal mac14_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  -- MAC15 signals
  signal mac15_a_s         : unsigned (MAC_LAYER2_A_WIDTH-1 downto 0);
  signal mac15_b_s         : signed (MAC_LAYER2_B_WIDTH-1 downto 0);
  signal mac15_sload_s     : std_logic;
  signal mac15_accum_out_s : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);
  
  -- definition of weights ram
  subtype gen_int_0 is signed (WEIGHTS_WIDTH-1 downto 0);
  type weight_matrix_layer2 is array (0 to 2, 0 to 2, 0 to 15, 0 to 7) of gen_int_0;
  
  signal weight_ram_s : weight_matrix_layer2;  -- Weight RAM (3x3x16x8)
  
  -- definition of input tensor
  subtype gen_int_1 is unsigned (INPUTS_WIDTH-1 downto 0);
  type input_matrix_layer2 is array (0 to 2, 0 to 2, 0 to 15) of gen_int_1;
  
  -- definition of scale and bias array
  subtype gen_int_2 is signed (SCALE2_WIDTH-1 downto 0);
  type scale_bias_array_layer2 is array (0 to 7) of gen_int_2;
  
  -- definition of output tensor
  subtype gen_int_3 is unsigned (ACT_WIDTH-1 downto 0);
  type output_vector_layer2 is array (0 to (STOP_OUTPUT-START_OUTPUT)) of gen_int_3;

  -- signals for entity inputs and outputs
  signal input_tensor_s           : input_matrix_layer2 := (others => (others => (others => (others => '0'))));
  signal output_vector_s          : output_vector_layer2 := (others => (others => '0'));
  signal scale2_s                 : scale_bias_array_layer2 := (others => (others => '0'));
  signal layer2_batch_norm_bias_s : scale_bias_array_layer2 := (others => (others => '0'));
  signal data_rdy_in_s            : std_logic;
  signal data_rdy_out_s           : std_logic;
  signal data_ack_in_s            : std_logic;
  signal rst_in_s                 : std_logic;
  
  type state is ( IDLE,                  -- idle state (reset frame index and MACs)
                  INIT_MAC,              -- One cycle for MAC to reset
                  EXEC_MAC,              -- CNN Layer 2 (Multiply-And-Add)
                  WAIT_MAC_0,            -- wait two cycles for MAC result
                  WAIT_MAC_1,
                  FETCH_MAC_RES,         -- fetch result
                  SCALING,               -- apply scaling factor
                  BATCH_BIAS,            -- add batch bias
                  RELU,                  -- apply relu activation function
                  INIT_ROUNDING,         -- prepare values for rounding
                  ROUNDING_0,            -- rounding
                  ROUNDING_1,            -- rounding
                  OUTPUT_LAYER_COUNTING, -- Increase output layer index (and repeat from INIT (or stop))
                  WAIT_FOR_ACK);         -- issue ready flag and wait for ACK from PS
                  
  signal statem_state : state := IDLE; -- stores state of state machine
  
  signal output_index         : integer;                                   -- running output index
  signal frame_index_1        : integer;                                   -- running frame index
  signal frame_index_2        : integer;                                   -- running frame index
  signal rdy_flag_count       : integer;                                   -- leaves the output data ready flag for some cycles
  signal mac_result_s         : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);  -- result of all MACs
  signal post_proc_temp0      : signed (MAC_LAYER2_OUT_WIDTH-1 downto 0);  -- MAC result
  signal post_proc_temp1      : signed (POST_PROC_WIDTH-1 downto 0);       -- post Scaling
  signal post_proc_temp2      : signed (POST_PROC_WIDTH-1 downto 0);       -- post Bias
  signal post_proc_temp3      : signed (POST_PROC_WIDTH-1 downto 0);       -- post ReLU
  signal rounding_natural_num : signed (POST_PROC_WIDTH-1 downto 0);
  signal rounding_fract_num   : signed (POST_PROC_WIDTH-1 downto 0);

begin

  -- CNN kernel weights (3,3,16,8)
  weight_ram_s(0, 0, 0, 0) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 0) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 0) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 0) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 0) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 0) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 0) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 0) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 0) <= to_signed(-27, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 0) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 0) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 0) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 0) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 0) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 0) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 0) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 0) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 0) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 2, 0) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 2, 0) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 2, 0) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 2, 0) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 2, 0) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 2, 0) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 2, 0) <= to_signed(75, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 2, 0) <= to_signed(70, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 2, 0) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 3, 0) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 3, 0) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 3, 0) <= to_signed(38, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 3, 0) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 3, 0) <= to_signed(42, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 3, 0) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 3, 0) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 3, 0) <= to_signed(-43, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 3, 0) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 4, 0) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 4, 0) <= to_signed(46, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 4, 0) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 4, 0) <= to_signed(-27, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 4, 0) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 4, 0) <= to_signed(-29, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 4, 0) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 4, 0) <= to_signed(-20, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 4, 0) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 5, 0) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 5, 0) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 5, 0) <= to_signed(-29, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 5, 0) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 5, 0) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 5, 0) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 5, 0) <= to_signed(-53, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 5, 0) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 5, 0) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 6, 0) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 6, 0) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 6, 0) <= to_signed(-35, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 6, 0) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 6, 0) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 6, 0) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 6, 0) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 6, 0) <= to_signed(-67, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 6, 0) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 7, 0) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 7, 0) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 7, 0) <= to_signed(-44, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 7, 0) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 7, 0) <= to_signed(42, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 7, 0) <= to_signed(37, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 7, 0) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 7, 0) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 7, 0) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 8, 0) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 8, 0) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 8, 0) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 8, 0) <= to_signed(-38, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 8, 0) <= to_signed(-37, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 8, 0) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 8, 0) <= to_signed(-68, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 8, 0) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 8, 0) <= to_signed(-91, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 9, 0) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 9, 0) <= to_signed(29, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 9, 0) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 9, 0) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 9, 0) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 9, 0) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 9, 0) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 9, 0) <= to_signed(-61, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 9, 0) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 10, 0) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 10, 0) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 10, 0) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 10, 0) <= to_signed(-26, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 10, 0) <= to_signed(-34, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 10, 0) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 10, 0) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 10, 0) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 10, 0) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 11, 0) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 11, 0) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 11, 0) <= to_signed(65, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 11, 0) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 11, 0) <= to_signed(47, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 11, 0) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 11, 0) <= to_signed(40, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 11, 0) <= to_signed(36, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 11, 0) <= to_signed(21, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 12, 0) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 12, 0) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 12, 0) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 12, 0) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 12, 0) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 12, 0) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 12, 0) <= to_signed(-45, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 12, 0) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 12, 0) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 13, 0) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 13, 0) <= to_signed(-35, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 13, 0) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 13, 0) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 13, 0) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 13, 0) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 13, 0) <= to_signed(-45, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 13, 0) <= to_signed(-55, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 13, 0) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 14, 0) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 14, 0) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 14, 0) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 14, 0) <= to_signed(-23, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 14, 0) <= to_signed(58, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 14, 0) <= to_signed(45, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 14, 0) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 14, 0) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 14, 0) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 15, 0) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 15, 0) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 15, 0) <= to_signed(55, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 15, 0) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 15, 0) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 15, 0) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 15, 0) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 15, 0) <= to_signed(69, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 15, 0) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 1) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 1) <= to_signed(31, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 1) <= to_signed(41, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 1) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 1) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 1) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 1) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 1) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 1) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 1) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 1) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 1) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 1) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 1) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 1) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 1) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 1) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 1) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 2, 1) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 2, 1) <= to_signed(69, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 2, 1) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 2, 1) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 2, 1) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 2, 1) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 2, 1) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 2, 1) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 2, 1) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 3, 1) <= to_signed(37, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 3, 1) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 3, 1) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 3, 1) <= to_signed(67, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 3, 1) <= to_signed(31, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 3, 1) <= to_signed(50, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 3, 1) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 3, 1) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 3, 1) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 4, 1) <= to_signed(-41, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 4, 1) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 4, 1) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 4, 1) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 4, 1) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 4, 1) <= to_signed(-20, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 4, 1) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 4, 1) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 4, 1) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 5, 1) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 5, 1) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 5, 1) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 5, 1) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 5, 1) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 5, 1) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 5, 1) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 5, 1) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 5, 1) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 6, 1) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 6, 1) <= to_signed(-36, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 6, 1) <= to_signed(-35, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 6, 1) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 6, 1) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 6, 1) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 6, 1) <= to_signed(-21, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 6, 1) <= to_signed(-34, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 6, 1) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 7, 1) <= to_signed(-33, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 7, 1) <= to_signed(-56, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 7, 1) <= to_signed(-56, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 7, 1) <= to_signed(-51, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 7, 1) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 7, 1) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 7, 1) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 7, 1) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 7, 1) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 8, 1) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 8, 1) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 8, 1) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 8, 1) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 8, 1) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 8, 1) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 8, 1) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 8, 1) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 8, 1) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 9, 1) <= to_signed(-27, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 9, 1) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 9, 1) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 9, 1) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 9, 1) <= to_signed(-24, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 9, 1) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 9, 1) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 9, 1) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 9, 1) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 10, 1) <= to_signed(-23, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 10, 1) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 10, 1) <= to_signed(-28, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 10, 1) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 10, 1) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 10, 1) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 10, 1) <= to_signed(-28, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 10, 1) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 10, 1) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 11, 1) <= to_signed(33, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 11, 1) <= to_signed(52, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 11, 1) <= to_signed(41, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 11, 1) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 11, 1) <= to_signed(43, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 11, 1) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 11, 1) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 11, 1) <= to_signed(37, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 11, 1) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 12, 1) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 12, 1) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 12, 1) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 12, 1) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 12, 1) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 12, 1) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 12, 1) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 12, 1) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 12, 1) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 13, 1) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 13, 1) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 13, 1) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 13, 1) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 13, 1) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 13, 1) <= to_signed(-20, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 13, 1) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 13, 1) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 13, 1) <= to_signed(-21, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 14, 1) <= to_signed(56, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 14, 1) <= to_signed(57, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 14, 1) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 14, 1) <= to_signed(50, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 14, 1) <= to_signed(62, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 14, 1) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 14, 1) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 14, 1) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 14, 1) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 15, 1) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 15, 1) <= to_signed(35, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 15, 1) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 15, 1) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 15, 1) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 15, 1) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 15, 1) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 15, 1) <= to_signed(-33, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 15, 1) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 2) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 2) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 2) <= to_signed(-32, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 2) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 2) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 2) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 2) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 2) <= to_signed(-32, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 2) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 2) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 2) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 2) <= to_signed(55, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 2) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 2) <= to_signed(51, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 2) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 2) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 2) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 2) <= to_signed(-35, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 2, 2) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 2, 2) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 2, 2) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 2, 2) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 2, 2) <= to_signed(41, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 2, 2) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 2, 2) <= to_signed(-44, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 2, 2) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 2, 2) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 3, 2) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 3, 2) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 3, 2) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 3, 2) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 3, 2) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 3, 2) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 3, 2) <= to_signed(45, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 3, 2) <= to_signed(53, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 3, 2) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 4, 2) <= to_signed(-56, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 4, 2) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 4, 2) <= to_signed(-56, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 4, 2) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 4, 2) <= to_signed(42, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 4, 2) <= to_signed(-83, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 4, 2) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 4, 2) <= to_signed(-56, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 4, 2) <= to_signed(-55, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 5, 2) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 5, 2) <= to_signed(-90, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 5, 2) <= to_signed(-41, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 5, 2) <= to_signed(-127, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 5, 2) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 5, 2) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 5, 2) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 5, 2) <= to_signed(-77, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 5, 2) <= to_signed(-20, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 6, 2) <= to_signed(-48, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 6, 2) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 6, 2) <= to_signed(-26, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 6, 2) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 6, 2) <= to_signed(-117, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 6, 2) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 6, 2) <= to_signed(-34, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 6, 2) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 6, 2) <= to_signed(-75, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 7, 2) <= to_signed(-43, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 7, 2) <= to_signed(-74, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 7, 2) <= to_signed(-63, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 7, 2) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 7, 2) <= to_signed(-51, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 7, 2) <= to_signed(-43, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 7, 2) <= to_signed(-21, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 7, 2) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 7, 2) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 8, 2) <= to_signed(-35, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 8, 2) <= to_signed(-127, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 8, 2) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 8, 2) <= to_signed(-20, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 8, 2) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 8, 2) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 8, 2) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 8, 2) <= to_signed(-127, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 8, 2) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 9, 2) <= to_signed(-38, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 9, 2) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 9, 2) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 9, 2) <= to_signed(-58, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 9, 2) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 9, 2) <= to_signed(-20, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 9, 2) <= to_signed(-41, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 9, 2) <= to_signed(-69, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 9, 2) <= to_signed(-32, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 10, 2) <= to_signed(-72, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 10, 2) <= to_signed(-120, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 10, 2) <= to_signed(-33, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 10, 2) <= to_signed(-68, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 10, 2) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 10, 2) <= to_signed(-47, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 10, 2) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 10, 2) <= to_signed(-127, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 10, 2) <= to_signed(-33, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 11, 2) <= to_signed(40, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 11, 2) <= to_signed(33, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 11, 2) <= to_signed(54, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 11, 2) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 11, 2) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 11, 2) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 11, 2) <= to_signed(37, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 11, 2) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 11, 2) <= to_signed(38, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 12, 2) <= to_signed(44, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 12, 2) <= to_signed(69, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 12, 2) <= to_signed(42, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 12, 2) <= to_signed(-23, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 12, 2) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 12, 2) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 12, 2) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 12, 2) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 12, 2) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 13, 2) <= to_signed(-58, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 13, 2) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 13, 2) <= to_signed(-56, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 13, 2) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 13, 2) <= to_signed(-70, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 13, 2) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 13, 2) <= to_signed(-102, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 13, 2) <= to_signed(-21, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 13, 2) <= to_signed(-90, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 14, 2) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 14, 2) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 14, 2) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 14, 2) <= to_signed(63, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 14, 2) <= to_signed(40, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 14, 2) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 14, 2) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 14, 2) <= to_signed(35, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 14, 2) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 15, 2) <= to_signed(-43, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 15, 2) <= to_signed(-66, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 15, 2) <= to_signed(-27, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 15, 2) <= to_signed(-58, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 15, 2) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 15, 2) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 15, 2) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 15, 2) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 15, 2) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 3) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 3) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 3) <= to_signed(47, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 3) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 3) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 3) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 3) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 3) <= to_signed(-38, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 3) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 3) <= to_signed(36, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 3) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 3) <= to_signed(-55, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 3) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 3) <= to_signed(44, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 3) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 3) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 3) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 3) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 2, 3) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 2, 3) <= to_signed(51, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 2, 3) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 2, 3) <= to_signed(52, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 2, 3) <= to_signed(37, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 2, 3) <= to_signed(40, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 2, 3) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 2, 3) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 2, 3) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 3, 3) <= to_signed(55, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 3, 3) <= to_signed(-27, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 3, 3) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 3, 3) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 3, 3) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 3, 3) <= to_signed(-33, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 3, 3) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 3, 3) <= to_signed(67, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 3, 3) <= to_signed(-24, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 4, 3) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 4, 3) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 4, 3) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 4, 3) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 4, 3) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 4, 3) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 4, 3) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 4, 3) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 4, 3) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 5, 3) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 5, 3) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 5, 3) <= to_signed(49, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 5, 3) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 5, 3) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 5, 3) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 5, 3) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 5, 3) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 5, 3) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 6, 3) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 6, 3) <= to_signed(-50, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 6, 3) <= to_signed(-41, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 6, 3) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 6, 3) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 6, 3) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 6, 3) <= to_signed(35, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 6, 3) <= to_signed(57, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 6, 3) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 7, 3) <= to_signed(-32, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 7, 3) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 7, 3) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 7, 3) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 7, 3) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 7, 3) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 7, 3) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 7, 3) <= to_signed(-29, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 7, 3) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 8, 3) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 8, 3) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 8, 3) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 8, 3) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 8, 3) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 8, 3) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 8, 3) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 8, 3) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 8, 3) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 9, 3) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 9, 3) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 9, 3) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 9, 3) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 9, 3) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 9, 3) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 9, 3) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 9, 3) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 9, 3) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 10, 3) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 10, 3) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 10, 3) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 10, 3) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 10, 3) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 10, 3) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 10, 3) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 10, 3) <= to_signed(33, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 10, 3) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 11, 3) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 11, 3) <= to_signed(-41, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 11, 3) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 11, 3) <= to_signed(41, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 11, 3) <= to_signed(-52, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 11, 3) <= to_signed(61, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 11, 3) <= to_signed(-27, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 11, 3) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 11, 3) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 12, 3) <= to_signed(-27, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 12, 3) <= to_signed(-36, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 12, 3) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 12, 3) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 12, 3) <= to_signed(-24, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 12, 3) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 12, 3) <= to_signed(41, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 12, 3) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 12, 3) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 13, 3) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 13, 3) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 13, 3) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 13, 3) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 13, 3) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 13, 3) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 13, 3) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 13, 3) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 13, 3) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 14, 3) <= to_signed(49, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 14, 3) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 14, 3) <= to_signed(-36, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 14, 3) <= to_signed(72, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 14, 3) <= to_signed(78, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 14, 3) <= to_signed(43, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 14, 3) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 14, 3) <= to_signed(47, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 14, 3) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 15, 3) <= to_signed(48, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 15, 3) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 15, 3) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 15, 3) <= to_signed(41, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 15, 3) <= to_signed(60, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 15, 3) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 15, 3) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 15, 3) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 15, 3) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 4) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 4) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 4) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 4) <= to_signed(43, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 4) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 4) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 4) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 4) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 4) <= to_signed(31, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 4) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 4) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 4) <= to_signed(47, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 4) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 4) <= to_signed(57, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 4) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 4) <= to_signed(33, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 4) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 4) <= to_signed(-36, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 2, 4) <= to_signed(53, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 2, 4) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 2, 4) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 2, 4) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 2, 4) <= to_signed(43, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 2, 4) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 2, 4) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 2, 4) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 2, 4) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 3, 4) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 3, 4) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 3, 4) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 3, 4) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 3, 4) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 3, 4) <= to_signed(67, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 3, 4) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 3, 4) <= to_signed(53, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 3, 4) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 4, 4) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 4, 4) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 4, 4) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 4, 4) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 4, 4) <= to_signed(36, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 4, 4) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 4, 4) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 4, 4) <= to_signed(44, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 4, 4) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 5, 4) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 5, 4) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 5, 4) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 5, 4) <= to_signed(48, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 5, 4) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 5, 4) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 5, 4) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 5, 4) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 5, 4) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 6, 4) <= to_signed(44, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 6, 4) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 6, 4) <= to_signed(33, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 6, 4) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 6, 4) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 6, 4) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 6, 4) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 6, 4) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 6, 4) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 7, 4) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 7, 4) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 7, 4) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 7, 4) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 7, 4) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 7, 4) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 7, 4) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 7, 4) <= to_signed(-35, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 7, 4) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 8, 4) <= to_signed(-20, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 8, 4) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 8, 4) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 8, 4) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 8, 4) <= to_signed(42, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 8, 4) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 8, 4) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 8, 4) <= to_signed(42, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 8, 4) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 9, 4) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 9, 4) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 9, 4) <= to_signed(-23, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 9, 4) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 9, 4) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 9, 4) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 9, 4) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 9, 4) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 9, 4) <= to_signed(-27, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 10, 4) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 10, 4) <= to_signed(39, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 10, 4) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 10, 4) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 10, 4) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 10, 4) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 10, 4) <= to_signed(-49, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 10, 4) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 10, 4) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 11, 4) <= to_signed(38, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 11, 4) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 11, 4) <= to_signed(-41, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 11, 4) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 11, 4) <= to_signed(-29, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 11, 4) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 11, 4) <= to_signed(-20, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 11, 4) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 11, 4) <= to_signed(71, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 12, 4) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 12, 4) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 12, 4) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 12, 4) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 12, 4) <= to_signed(-33, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 12, 4) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 12, 4) <= to_signed(-56, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 12, 4) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 12, 4) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 13, 4) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 13, 4) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 13, 4) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 13, 4) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 13, 4) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 13, 4) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 13, 4) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 13, 4) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 13, 4) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 14, 4) <= to_signed(127, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 14, 4) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 14, 4) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 14, 4) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 14, 4) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 14, 4) <= to_signed(-35, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 14, 4) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 14, 4) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 14, 4) <= to_signed(66, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 15, 4) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 15, 4) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 15, 4) <= to_signed(-33, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 15, 4) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 15, 4) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 15, 4) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 15, 4) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 15, 4) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 15, 4) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 5) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 5) <= to_signed(21, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 5) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 5) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 5) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 5) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 5) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 5) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 5) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 5) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 5) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 5) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 5) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 5) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 5) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 5) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 5) <= to_signed(-24, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 5) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 2, 5) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 2, 5) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 2, 5) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 2, 5) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 2, 5) <= to_signed(48, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 2, 5) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 2, 5) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 2, 5) <= to_signed(31, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 2, 5) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 3, 5) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 3, 5) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 3, 5) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 3, 5) <= to_signed(43, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 3, 5) <= to_signed(47, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 3, 5) <= to_signed(21, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 3, 5) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 3, 5) <= to_signed(36, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 3, 5) <= to_signed(48, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 4, 5) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 4, 5) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 4, 5) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 4, 5) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 4, 5) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 4, 5) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 4, 5) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 4, 5) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 4, 5) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 5, 5) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 5, 5) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 5, 5) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 5, 5) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 5, 5) <= to_signed(31, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 5, 5) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 5, 5) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 5, 5) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 5, 5) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 6, 5) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 6, 5) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 6, 5) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 6, 5) <= to_signed(-34, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 6, 5) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 6, 5) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 6, 5) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 6, 5) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 6, 5) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 7, 5) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 7, 5) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 7, 5) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 7, 5) <= to_signed(-42, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 7, 5) <= to_signed(21, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 7, 5) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 7, 5) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 7, 5) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 7, 5) <= to_signed(-31, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 8, 5) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 8, 5) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 8, 5) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 8, 5) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 8, 5) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 8, 5) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 8, 5) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 8, 5) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 8, 5) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 9, 5) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 9, 5) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 9, 5) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 9, 5) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 9, 5) <= to_signed(-36, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 9, 5) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 9, 5) <= to_signed(-23, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 9, 5) <= to_signed(-53, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 9, 5) <= to_signed(-28, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 10, 5) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 10, 5) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 10, 5) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 10, 5) <= to_signed(-26, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 10, 5) <= to_signed(-36, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 10, 5) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 10, 5) <= to_signed(-52, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 10, 5) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 10, 5) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 11, 5) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 11, 5) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 11, 5) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 11, 5) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 11, 5) <= to_signed(63, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 11, 5) <= to_signed(49, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 11, 5) <= to_signed(33, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 11, 5) <= to_signed(50, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 11, 5) <= to_signed(38, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 12, 5) <= to_signed(29, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 12, 5) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 12, 5) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 12, 5) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 12, 5) <= to_signed(40, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 12, 5) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 12, 5) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 12, 5) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 12, 5) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 13, 5) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 13, 5) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 13, 5) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 13, 5) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 13, 5) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 13, 5) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 13, 5) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 13, 5) <= to_signed(-36, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 13, 5) <= to_signed(-29, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 14, 5) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 14, 5) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 14, 5) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 14, 5) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 14, 5) <= to_signed(47, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 14, 5) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 14, 5) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 14, 5) <= to_signed(51, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 14, 5) <= to_signed(40, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 15, 5) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 15, 5) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 15, 5) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 15, 5) <= to_signed(35, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 15, 5) <= to_signed(-46, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 15, 5) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 15, 5) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 15, 5) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 15, 5) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 6) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 6) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 6) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 6) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 6) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 6) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 6) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 6) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 6) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 6) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 6) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 6) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 6) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 6) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 6) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 6) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 6) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 6) <= to_signed(-21, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 2, 6) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 2, 6) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 2, 6) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 2, 6) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 2, 6) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 2, 6) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 2, 6) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 2, 6) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 2, 6) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 3, 6) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 3, 6) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 3, 6) <= to_signed(29, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 3, 6) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 3, 6) <= to_signed(54, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 3, 6) <= to_signed(52, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 3, 6) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 3, 6) <= to_signed(40, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 3, 6) <= to_signed(54, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 4, 6) <= to_signed(-47, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 4, 6) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 4, 6) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 4, 6) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 4, 6) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 4, 6) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 4, 6) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 4, 6) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 4, 6) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 5, 6) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 5, 6) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 5, 6) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 5, 6) <= to_signed(-21, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 5, 6) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 5, 6) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 5, 6) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 5, 6) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 5, 6) <= to_signed(-32, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 6, 6) <= to_signed(-26, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 6, 6) <= to_signed(-38, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 6, 6) <= to_signed(-23, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 6, 6) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 6, 6) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 6, 6) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 6, 6) <= to_signed(21, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 6, 6) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 6, 6) <= to_signed(-26, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 7, 6) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 7, 6) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 7, 6) <= to_signed(-29, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 7, 6) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 7, 6) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 7, 6) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 7, 6) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 7, 6) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 7, 6) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 8, 6) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 8, 6) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 8, 6) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 8, 6) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 8, 6) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 8, 6) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 8, 6) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 8, 6) <= to_signed(-23, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 8, 6) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 9, 6) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 9, 6) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 9, 6) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 9, 6) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 9, 6) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 9, 6) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 9, 6) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 9, 6) <= to_signed(-37, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 9, 6) <= to_signed(-47, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 10, 6) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 10, 6) <= to_signed(-35, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 10, 6) <= to_signed(-28, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 10, 6) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 10, 6) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 10, 6) <= to_signed(-23, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 10, 6) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 10, 6) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 10, 6) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 11, 6) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 11, 6) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 11, 6) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 11, 6) <= to_signed(31, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 11, 6) <= to_signed(51, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 11, 6) <= to_signed(42, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 11, 6) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 11, 6) <= to_signed(36, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 11, 6) <= to_signed(58, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 12, 6) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 12, 6) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 12, 6) <= to_signed(21, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 12, 6) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 12, 6) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 12, 6) <= to_signed(41, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 12, 6) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 12, 6) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 12, 6) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 13, 6) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 13, 6) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 13, 6) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 13, 6) <= to_signed(-28, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 13, 6) <= to_signed(-28, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 13, 6) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 13, 6) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 13, 6) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 13, 6) <= to_signed(-21, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 14, 6) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 14, 6) <= to_signed(35, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 14, 6) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 14, 6) <= to_signed(21, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 14, 6) <= to_signed(53, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 14, 6) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 14, 6) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 14, 6) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 14, 6) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 15, 6) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 15, 6) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 15, 6) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 15, 6) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 15, 6) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 15, 6) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 15, 6) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 15, 6) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 15, 6) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 7) <= to_signed(40, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 7) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 7) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 7) <= to_signed(29, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 7) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 7) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 7) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 7) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 7) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 7) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 7) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 7) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 7) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 7) <= to_signed(-37, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 7) <= to_signed(-32, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 7) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 7) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 7) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 2, 7) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 2, 7) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 2, 7) <= to_signed(-49, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 2, 7) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 2, 7) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 2, 7) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 2, 7) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 2, 7) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 2, 7) <= to_signed(-50, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 3, 7) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 3, 7) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 3, 7) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 3, 7) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 3, 7) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 3, 7) <= to_signed(38, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 3, 7) <= to_signed(36, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 3, 7) <= to_signed(37, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 3, 7) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 4, 7) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 4, 7) <= to_signed(-127, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 4, 7) <= to_signed(-58, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 4, 7) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 4, 7) <= to_signed(38, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 4, 7) <= to_signed(-42, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 4, 7) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 4, 7) <= to_signed(-127, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 4, 7) <= to_signed(-49, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 5, 7) <= to_signed(-23, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 5, 7) <= to_signed(-85, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 5, 7) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 5, 7) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 5, 7) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 5, 7) <= to_signed(-109, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 5, 7) <= to_signed(-70, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 5, 7) <= to_signed(-33, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 5, 7) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 6, 7) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 6, 7) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 6, 7) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 6, 7) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 6, 7) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 6, 7) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 6, 7) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 6, 7) <= to_signed(-28, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 6, 7) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 7, 7) <= to_signed(-66, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 7, 7) <= to_signed(-67, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 7, 7) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 7, 7) <= to_signed(-49, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 7, 7) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 7, 7) <= to_signed(-90, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 7, 7) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 7, 7) <= to_signed(-91, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 7, 7) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 8, 7) <= to_signed(-43, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 8, 7) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 8, 7) <= to_signed(-78, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 8, 7) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 8, 7) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 8, 7) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 8, 7) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 8, 7) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 8, 7) <= to_signed(-57, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 9, 7) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 9, 7) <= to_signed(-127, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 9, 7) <= to_signed(33, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 9, 7) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 9, 7) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 9, 7) <= to_signed(-115, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 9, 7) <= to_signed(-84, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 9, 7) <= to_signed(-101, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 9, 7) <= to_signed(-47, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 10, 7) <= to_signed(-66, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 10, 7) <= to_signed(-68, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 10, 7) <= to_signed(-45, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 10, 7) <= to_signed(-62, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 10, 7) <= to_signed(54, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 10, 7) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 10, 7) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 10, 7) <= to_signed(33, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 10, 7) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 11, 7) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 11, 7) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 11, 7) <= to_signed(51, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 11, 7) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 11, 7) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 11, 7) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 11, 7) <= to_signed(51, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 11, 7) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 11, 7) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 12, 7) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 12, 7) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 12, 7) <= to_signed(53, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 12, 7) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 12, 7) <= to_signed(45, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 12, 7) <= to_signed(45, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 12, 7) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 12, 7) <= to_signed(28, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 12, 7) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 13, 7) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 13, 7) <= to_signed(46, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 13, 7) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 13, 7) <= to_signed(-50, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 13, 7) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 13, 7) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 13, 7) <= to_signed(-88, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 13, 7) <= to_signed(-75, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 13, 7) <= to_signed(-63, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 14, 7) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 14, 7) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 14, 7) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 14, 7) <= to_signed(21, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 14, 7) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 14, 7) <= to_signed(36, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 14, 7) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 14, 7) <= to_signed(41, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 14, 7) <= to_signed(17, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 15, 7) <= to_signed(-41, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 15, 7) <= to_signed(-24, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 15, 7) <= to_signed(-81, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 15, 7) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 15, 7) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 15, 7) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 15, 7) <= to_signed(-29, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 15, 7) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 15, 7) <= to_signed(-56, WEIGHTS_WIDTH);
  
  scale2_s(0)                 <= to_signed(SCALE2_0, SCALE2_WIDTH);
  scale2_s(1)                 <= to_signed(SCALE2_1, SCALE2_WIDTH);
  scale2_s(2)                 <= to_signed(SCALE2_2, SCALE2_WIDTH);
  scale2_s(3)                 <= to_signed(SCALE2_3, SCALE2_WIDTH);
  scale2_s(4)                 <= to_signed(SCALE2_4, SCALE2_WIDTH);
  scale2_s(5)                 <= to_signed(SCALE2_5, SCALE2_WIDTH);
  scale2_s(6)                 <= to_signed(SCALE2_6, SCALE2_WIDTH);
  scale2_s(7)                 <= to_signed(SCALE2_7, SCALE2_WIDTH);
  layer2_batch_norm_bias_s(0) <= to_signed(LAYER2_BATCH_NORM_BIAS0, SCALE2_WIDTH);
  layer2_batch_norm_bias_s(1) <= to_signed(LAYER2_BATCH_NORM_BIAS1, SCALE2_WIDTH);
  layer2_batch_norm_bias_s(2) <= to_signed(LAYER2_BATCH_NORM_BIAS2, SCALE2_WIDTH);
  layer2_batch_norm_bias_s(3) <= to_signed(LAYER2_BATCH_NORM_BIAS3, SCALE2_WIDTH);
  layer2_batch_norm_bias_s(4) <= to_signed(LAYER2_BATCH_NORM_BIAS4, SCALE2_WIDTH);
  layer2_batch_norm_bias_s(5) <= to_signed(LAYER2_BATCH_NORM_BIAS5, SCALE2_WIDTH);
  layer2_batch_norm_bias_s(6) <= to_signed(LAYER2_BATCH_NORM_BIAS6, SCALE2_WIDTH);
  layer2_batch_norm_bias_s(7) <= to_signed(LAYER2_BATCH_NORM_BIAS7, SCALE2_WIDTH);

  process(clk)  -- fetch inputs at rising clock (=Flip Flop)
  begin
    if (rising_edge (clk)) then
      --input_tensor_s <= input_tensor;
      
      input_tensor_s(0, 0, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*0 downto INPUTS_WIDTH*0));
      input_tensor_s(0, 0, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*1 downto INPUTS_WIDTH*1));
      input_tensor_s(0, 0, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*2 downto INPUTS_WIDTH*2));
      input_tensor_s(0, 0, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*3 downto INPUTS_WIDTH*3));
      input_tensor_s(0, 0, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*4 downto INPUTS_WIDTH*4));
      input_tensor_s(0, 0, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*5 downto INPUTS_WIDTH*5));
      input_tensor_s(0, 0, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*6 downto INPUTS_WIDTH*6));
      input_tensor_s(0, 0, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*7 downto INPUTS_WIDTH*7));
      input_tensor_s(0, 0, 8) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*8 downto INPUTS_WIDTH*8));
      input_tensor_s(0, 0, 9) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*9 downto INPUTS_WIDTH*9));
      input_tensor_s(0, 0, 10) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*10 downto INPUTS_WIDTH*10));
      input_tensor_s(0, 0, 11) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*11 downto INPUTS_WIDTH*11));
      input_tensor_s(0, 0, 12) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*12 downto INPUTS_WIDTH*12));
      input_tensor_s(0, 0, 13) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*13 downto INPUTS_WIDTH*13));
      input_tensor_s(0, 0, 14) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*14 downto INPUTS_WIDTH*14));
      input_tensor_s(0, 0, 15) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*15 downto INPUTS_WIDTH*15));
      
      input_tensor_s(0, 1, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*16 downto INPUTS_WIDTH*16));
      input_tensor_s(0, 1, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*17 downto INPUTS_WIDTH*17));
      input_tensor_s(0, 1, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*18 downto INPUTS_WIDTH*18));
      input_tensor_s(0, 1, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*19 downto INPUTS_WIDTH*19));
      input_tensor_s(0, 1, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*20 downto INPUTS_WIDTH*20));
      input_tensor_s(0, 1, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*21 downto INPUTS_WIDTH*21));
      input_tensor_s(0, 1, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*22 downto INPUTS_WIDTH*22));
      input_tensor_s(0, 1, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*23 downto INPUTS_WIDTH*23));
      input_tensor_s(0, 1, 8) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*24 downto INPUTS_WIDTH*24));
      input_tensor_s(0, 1, 9) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*25 downto INPUTS_WIDTH*25));
      input_tensor_s(0, 1, 10) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*26 downto INPUTS_WIDTH*26));
      input_tensor_s(0, 1, 11) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*27 downto INPUTS_WIDTH*27));
      input_tensor_s(0, 1, 12) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*28 downto INPUTS_WIDTH*28));
      input_tensor_s(0, 1, 13) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*29 downto INPUTS_WIDTH*29));
      input_tensor_s(0, 1, 14) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*30 downto INPUTS_WIDTH*30));
      input_tensor_s(0, 1, 15) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*31 downto INPUTS_WIDTH*31));
      
      input_tensor_s(0, 2, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*32 downto INPUTS_WIDTH*32));
      input_tensor_s(0, 2, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*33 downto INPUTS_WIDTH*33));
      input_tensor_s(0, 2, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*34 downto INPUTS_WIDTH*34));
      input_tensor_s(0, 2, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*35 downto INPUTS_WIDTH*35));
      input_tensor_s(0, 2, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*36 downto INPUTS_WIDTH*36));
      input_tensor_s(0, 2, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*37 downto INPUTS_WIDTH*37));
      input_tensor_s(0, 2, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*38 downto INPUTS_WIDTH*38));
      input_tensor_s(0, 2, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*39 downto INPUTS_WIDTH*39));
      input_tensor_s(0, 2, 8) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*40 downto INPUTS_WIDTH*40));
      input_tensor_s(0, 2, 9) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*41 downto INPUTS_WIDTH*41));
      input_tensor_s(0, 2, 10) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*42 downto INPUTS_WIDTH*42));
      input_tensor_s(0, 2, 11) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*43 downto INPUTS_WIDTH*43));
      input_tensor_s(0, 2, 12) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*44 downto INPUTS_WIDTH*44));
      input_tensor_s(0, 2, 13) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*45 downto INPUTS_WIDTH*45));
      input_tensor_s(0, 2, 14) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*46 downto INPUTS_WIDTH*46));
      input_tensor_s(0, 2, 15) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*47 downto INPUTS_WIDTH*47));
      
      input_tensor_s(1, 0, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*48 downto INPUTS_WIDTH*48));
      input_tensor_s(1, 0, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*49 downto INPUTS_WIDTH*49));
      input_tensor_s(1, 0, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*50 downto INPUTS_WIDTH*50));
      input_tensor_s(1, 0, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*51 downto INPUTS_WIDTH*51));
      input_tensor_s(1, 0, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*52 downto INPUTS_WIDTH*52));
      input_tensor_s(1, 0, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*53 downto INPUTS_WIDTH*53));
      input_tensor_s(1, 0, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*54 downto INPUTS_WIDTH*54));
      input_tensor_s(1, 0, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*55 downto INPUTS_WIDTH*55));
      input_tensor_s(1, 0, 8) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*56 downto INPUTS_WIDTH*56));
      input_tensor_s(1, 0, 9) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*57 downto INPUTS_WIDTH*57));
      input_tensor_s(1, 0, 10) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*58 downto INPUTS_WIDTH*58));
      input_tensor_s(1, 0, 11) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*59 downto INPUTS_WIDTH*59));
      input_tensor_s(1, 0, 12) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*60 downto INPUTS_WIDTH*60));
      input_tensor_s(1, 0, 13) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*61 downto INPUTS_WIDTH*61));
      input_tensor_s(1, 0, 14) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*62 downto INPUTS_WIDTH*62));
      input_tensor_s(1, 0, 15) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*63 downto INPUTS_WIDTH*63));
      
      input_tensor_s(1, 1, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*64 downto INPUTS_WIDTH*64));
      input_tensor_s(1, 1, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*65 downto INPUTS_WIDTH*65));
      input_tensor_s(1, 1, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*66 downto INPUTS_WIDTH*66));
      input_tensor_s(1, 1, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*67 downto INPUTS_WIDTH*67));
      input_tensor_s(1, 1, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*68 downto INPUTS_WIDTH*68));
      input_tensor_s(1, 1, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*69 downto INPUTS_WIDTH*69));
      input_tensor_s(1, 1, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*70 downto INPUTS_WIDTH*70));
      input_tensor_s(1, 1, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*71 downto INPUTS_WIDTH*71));
      input_tensor_s(1, 1, 8) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*72 downto INPUTS_WIDTH*72));
      input_tensor_s(1, 1, 9) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*73 downto INPUTS_WIDTH*73));
      input_tensor_s(1, 1, 10) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*74 downto INPUTS_WIDTH*74));
      input_tensor_s(1, 1, 11) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*75 downto INPUTS_WIDTH*75));
      input_tensor_s(1, 1, 12) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*76 downto INPUTS_WIDTH*76));
      input_tensor_s(1, 1, 13) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*77 downto INPUTS_WIDTH*77));
      input_tensor_s(1, 1, 14) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*78 downto INPUTS_WIDTH*78));
      input_tensor_s(1, 1, 15) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*79 downto INPUTS_WIDTH*79));
      
      input_tensor_s(1, 2, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*80 downto INPUTS_WIDTH*80));
      input_tensor_s(1, 2, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*81 downto INPUTS_WIDTH*81));
      input_tensor_s(1, 2, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*82 downto INPUTS_WIDTH*82));
      input_tensor_s(1, 2, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*83 downto INPUTS_WIDTH*83));
      input_tensor_s(1, 2, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*84 downto INPUTS_WIDTH*84));
      input_tensor_s(1, 2, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*85 downto INPUTS_WIDTH*85));
      input_tensor_s(1, 2, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*86 downto INPUTS_WIDTH*86));
      input_tensor_s(1, 2, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*87 downto INPUTS_WIDTH*87));
      input_tensor_s(1, 2, 8) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*88 downto INPUTS_WIDTH*88));
      input_tensor_s(1, 2, 9) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*89 downto INPUTS_WIDTH*89));
      input_tensor_s(1, 2, 10) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*90 downto INPUTS_WIDTH*90));
      input_tensor_s(1, 2, 11) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*91 downto INPUTS_WIDTH*91));
      input_tensor_s(1, 2, 12) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*92 downto INPUTS_WIDTH*92));
      input_tensor_s(1, 2, 13) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*93 downto INPUTS_WIDTH*93));
      input_tensor_s(1, 2, 14) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*94 downto INPUTS_WIDTH*94));
      input_tensor_s(1, 2, 15) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*95 downto INPUTS_WIDTH*95));
     
      input_tensor_s(2, 0, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*96 downto INPUTS_WIDTH*96));
      input_tensor_s(2, 0, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*97 downto INPUTS_WIDTH*97));
      input_tensor_s(2, 0, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*98 downto INPUTS_WIDTH*98));
      input_tensor_s(2, 0, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*99 downto INPUTS_WIDTH*99));
      input_tensor_s(2, 0, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*100 downto INPUTS_WIDTH*100));
      input_tensor_s(2, 0, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*101 downto INPUTS_WIDTH*101));
      input_tensor_s(2, 0, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*102 downto INPUTS_WIDTH*102));
      input_tensor_s(2, 0, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*103 downto INPUTS_WIDTH*103));
      input_tensor_s(2, 0, 8) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*104 downto INPUTS_WIDTH*104));
      input_tensor_s(2, 0, 9) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*105 downto INPUTS_WIDTH*105));
      input_tensor_s(2, 0, 10) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*106 downto INPUTS_WIDTH*106));
      input_tensor_s(2, 0, 11) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*107 downto INPUTS_WIDTH*107));
      input_tensor_s(2, 0, 12) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*108 downto INPUTS_WIDTH*108));
      input_tensor_s(2, 0, 13) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*109 downto INPUTS_WIDTH*109));
      input_tensor_s(2, 0, 14) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*110 downto INPUTS_WIDTH*110));
      input_tensor_s(2, 0, 15) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*111 downto INPUTS_WIDTH*111));
     
      input_tensor_s(2, 1, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*112 downto INPUTS_WIDTH*112));
      input_tensor_s(2, 1, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*113 downto INPUTS_WIDTH*113));
      input_tensor_s(2, 1, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*114 downto INPUTS_WIDTH*114));
      input_tensor_s(2, 1, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*115 downto INPUTS_WIDTH*115));
      input_tensor_s(2, 1, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*116 downto INPUTS_WIDTH*116));
      input_tensor_s(2, 1, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*117 downto INPUTS_WIDTH*117));
      input_tensor_s(2, 1, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*118 downto INPUTS_WIDTH*118));
      input_tensor_s(2, 1, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*119 downto INPUTS_WIDTH*119));
      input_tensor_s(2, 1, 8) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*120 downto INPUTS_WIDTH*120));
      input_tensor_s(2, 1, 9) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*121 downto INPUTS_WIDTH*121));
      input_tensor_s(2, 1, 10) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*122 downto INPUTS_WIDTH*122));
      input_tensor_s(2, 1, 11) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*123 downto INPUTS_WIDTH*123));
      input_tensor_s(2, 1, 12) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*124 downto INPUTS_WIDTH*124));
      input_tensor_s(2, 1, 13) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*125 downto INPUTS_WIDTH*125));
      input_tensor_s(2, 1, 14) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*126 downto INPUTS_WIDTH*126));
      input_tensor_s(2, 1, 15) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*127 downto INPUTS_WIDTH*127));
      
      input_tensor_s(2, 2, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*128 downto INPUTS_WIDTH*128));
      input_tensor_s(2, 2, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*129 downto INPUTS_WIDTH*129));
      input_tensor_s(2, 2, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*130 downto INPUTS_WIDTH*130));
      input_tensor_s(2, 2, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*131 downto INPUTS_WIDTH*131));
      input_tensor_s(2, 2, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*132 downto INPUTS_WIDTH*132));
      input_tensor_s(2, 2, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*133 downto INPUTS_WIDTH*133));
      input_tensor_s(2, 2, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*134 downto INPUTS_WIDTH*134));
      input_tensor_s(2, 2, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*135 downto INPUTS_WIDTH*135));
      input_tensor_s(2, 2, 8) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*136 downto INPUTS_WIDTH*136));
      input_tensor_s(2, 2, 9) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*137 downto INPUTS_WIDTH*137));
      input_tensor_s(2, 2, 10) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*138 downto INPUTS_WIDTH*138));
      input_tensor_s(2, 2, 11) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*139 downto INPUTS_WIDTH*139));
      input_tensor_s(2, 2, 12) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*140 downto INPUTS_WIDTH*140));
      input_tensor_s(2, 2, 13) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*141 downto INPUTS_WIDTH*141));
      input_tensor_s(2, 2, 14) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*142 downto INPUTS_WIDTH*142));
      input_tensor_s(2, 2, 15) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*143 downto INPUTS_WIDTH*143));
      
      data_rdy_in_s  <= data_rdy_in;
      rst_in_s       <= rst_in;
    end if;
  end process;
  
  -- map output signals to ports
  process(output_vector_s)
  begin
    for i in 0 to STOP_OUTPUT-START_OUTPUT loop
      output_vector(ACT_WIDTH-1+ACT_WIDTH*i downto ACT_WIDTH*i) <= std_logic_vector(output_vector_s(i));
      --output_vector(ACT_WIDTH-1+ACT_WIDTH*1 downto ACT_WIDTH*1) <= std_logic_vector(output_vector_s(1));
      --output_vector(ACT_WIDTH-1+ACT_WIDTH*2 downto ACT_WIDTH*2) <= std_logic_vector(output_vector_s(2));
      --output_vector(ACT_WIDTH-1+ACT_WIDTH*3 downto ACT_WIDTH*3) <= std_logic_vector(output_vector_s(3));
      --output_vector(ACT_WIDTH-1+ACT_WIDTH*4 downto ACT_WIDTH*4) <= std_logic_vector(output_vector_s(4));
      --output_vector(ACT_WIDTH-1+ACT_WIDTH*5 downto ACT_WIDTH*5) <= std_logic_vector(output_vector_s(5));
      --output_vector(ACT_WIDTH-1+ACT_WIDTH*6 downto ACT_WIDTH*6) <= std_logic_vector(output_vector_s(6));
      --output_vector(ACT_WIDTH-1+ACT_WIDTH*7 downto ACT_WIDTH*7) <= std_logic_vector(output_vector_s(7));  
    end loop;
  end process;
  
  data_rdy_out  <= data_rdy_out_s;
  
  process(clk)  -- Statemachine
  begin
    if (rising_edge (clk)) then
    
      if(rst_in_s = '0') then
        statem_state <= IDLE;
        output_index <= START_OUTPUT;
        frame_index_1 <= 0;
        frame_index_2 <= 0;
        rdy_flag_count <= 0;
      else
      
        case (statem_state) is
        
          when (IDLE) =>
            frame_index_1 <= 0;
            frame_index_2 <= 0;
            rdy_flag_count <= 0;
            if (data_rdy_in_s = '1') then  -- start with start signal
              statem_state <= INIT_MAC;
            end if;
           if (output_index > START_OUTPUT) then      -- or if already running
              statem_state <= INIT_MAC;
            end if;
          
          when (INIT_MAC) =>  -- wait one cycle for MAC reset
            statem_state <= EXEC_MAC;
            
          when (EXEC_MAC) =>  -- load MAC with consecutive values over 3x3 map (index2 first, then index1)
            if (frame_index_2 = 2) then     -- (frame_index_2++)
              frame_index_2 <= 0;
              if (frame_index_1 = 2) then   -- (frame_index_1++)
                frame_index_1 <= 0;
                statem_state <= WAIT_MAC_0;
              else
                frame_index_1 <= frame_index_1 + 1;
              end if;
            else
              frame_index_2 <= frame_index_2 + 1;              
            end if;
            
          when (WAIT_MAC_0) =>  -- wait two cycles for MAC result
            statem_state <= WAIT_MAC_1;
            
          when (WAIT_MAC_1) =>
            statem_state <= FETCH_MAC_RES;
            
          when (FETCH_MAC_RES) =>  -- fetch result
            statem_state <= SCALING;
          
          when (SCALING) =>  -- apply scaling factor
            statem_state <= BATCH_BIAS;
          
          when (BATCH_BIAS) =>  -- add batch bias
            statem_state <= RELU;
          
          when (RELU) =>  -- apply activation function
            statem_state <= INIT_ROUNDING;
            
          when (INIT_ROUNDING) =>  -- preperations for rounding
            statem_state <= ROUNDING_0;
          
          when (ROUNDING_0) =>  -- execute rounding
            statem_state <= ROUNDING_1;
          
          when (ROUNDING_1) =>  -- execute rounding and write to output vector
            statem_state <= OUTPUT_LAYER_COUNTING;
          
          when (OUTPUT_LAYER_COUNTING) =>  -- compute 16 output features (output_index++)
            if (output_index = STOP_OUTPUT) then
              statem_state <= WAIT_FOR_ACK;
              output_index <= START_OUTPUT;
            else
              output_index <= output_index + 1;
              statem_state <= IDLE;
            end if;
            
          when (WAIT_FOR_ACK) =>  -- wait for PS to receive data
            if (rdy_flag_count = 2) then
              statem_state <= IDLE;
            else
              rdy_flag_count <= rdy_flag_count + 1;
            end if;
            
          when others =>
            statem_state <= IDLE;
            
        end case;
        
      end if;
    end if;
  end process;

  process(clk)  -- Reset MAC result register
  begin
    if (rising_edge (clk)) then
      if (statem_state = IDLE) then
          mac0_sload_s <= '1';
          mac1_sload_s <= '1';
          mac2_sload_s <= '1';
          mac3_sload_s <= '1';
          mac4_sload_s <= '1';
          mac5_sload_s <= '1';
          mac6_sload_s <= '1';
          mac7_sload_s <= '1';
          mac8_sload_s <= '1';
          mac9_sload_s <= '1';
          mac10_sload_s <= '1';
          mac11_sload_s <= '1';
          mac12_sload_s <= '1';
          mac13_sload_s <= '1';
          mac14_sload_s <= '1';
          mac15_sload_s <= '1';
        else
          mac0_sload_s <= '0';
          mac1_sload_s <= '0';
          mac2_sload_s <= '0';
          mac3_sload_s <= '0';
          mac4_sload_s <= '0';
          mac5_sload_s <= '0';
          mac6_sload_s <= '0';
          mac7_sload_s <= '0';
          mac8_sload_s <= '0';
          mac9_sload_s <= '0';
          mac10_sload_s <= '0';
          mac11_sload_s <= '0';
          mac12_sload_s <= '0';
          mac13_sload_s <= '0';
          mac14_sload_s <= '0';
          mac15_sload_s <= '0';
      end if;
    end if;
  end process;

  process(clk)  -- output flag (data_rdy_out)
  begin
    if (rising_edge (clk)) then
      if (statem_state = WAIT_FOR_ACK) then
        data_rdy_out_s <= '1';
      else
        data_rdy_out_s <= '0';
      end if;
    end if;
  end process;
  
  process(clk)  -- feed MAC
  begin
    if (rising_edge (clk)) then
      if (statem_state = EXEC_MAC) then
        mac0_a_s <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac1_a_s <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac2_a_s <= input_tensor_s(frame_index_2, frame_index_1, 2);
        mac3_a_s <= input_tensor_s(frame_index_2, frame_index_1, 3);
        mac4_a_s <= input_tensor_s(frame_index_2, frame_index_1, 4);
        mac5_a_s <= input_tensor_s(frame_index_2, frame_index_1, 5);
        mac6_a_s <= input_tensor_s(frame_index_2, frame_index_1, 6);
        mac7_a_s <= input_tensor_s(frame_index_2, frame_index_1, 7);
        mac8_a_s <= input_tensor_s(frame_index_2, frame_index_1, 8);
        mac9_a_s <= input_tensor_s(frame_index_2, frame_index_1, 9);
        mac10_a_s <= input_tensor_s(frame_index_2, frame_index_1, 10);
        mac11_a_s <= input_tensor_s(frame_index_2, frame_index_1, 11);
        mac12_a_s <= input_tensor_s(frame_index_2, frame_index_1, 12);
        mac13_a_s <= input_tensor_s(frame_index_2, frame_index_1, 13);
        mac14_a_s <= input_tensor_s(frame_index_2, frame_index_1, 14);
        mac15_a_s <= input_tensor_s(frame_index_2, frame_index_1, 15);
        mac0_b_s <= weight_ram_s(frame_index_2, frame_index_1, 0, output_index);
        mac1_b_s <= weight_ram_s(frame_index_2, frame_index_1, 1, output_index);
        mac2_b_s <= weight_ram_s(frame_index_2, frame_index_1, 2, output_index);
        mac3_b_s <= weight_ram_s(frame_index_2, frame_index_1, 3, output_index);
        mac4_b_s <= weight_ram_s(frame_index_2, frame_index_1, 4, output_index);
        mac5_b_s <= weight_ram_s(frame_index_2, frame_index_1, 5, output_index);
        mac6_b_s <= weight_ram_s(frame_index_2, frame_index_1, 6, output_index);
        mac7_b_s <= weight_ram_s(frame_index_2, frame_index_1, 7, output_index);
        mac8_b_s <= weight_ram_s(frame_index_2, frame_index_1, 8, output_index);
        mac9_b_s <= weight_ram_s(frame_index_2, frame_index_1, 9, output_index);
        mac10_b_s <= weight_ram_s(frame_index_2, frame_index_1, 10, output_index);
        mac11_b_s <= weight_ram_s(frame_index_2, frame_index_1, 11, output_index);
        mac12_b_s <= weight_ram_s(frame_index_2, frame_index_1, 12, output_index);
        mac13_b_s <= weight_ram_s(frame_index_2, frame_index_1, 13, output_index);
        mac14_b_s <= weight_ram_s(frame_index_2, frame_index_1, 14, output_index);
        mac15_b_s <= weight_ram_s(frame_index_2, frame_index_1, 15, output_index);
      else
        mac0_a_s <= (others => '0');
        mac1_a_s <= (others => '0');
        mac2_a_s <= (others => '0');
        mac3_a_s <= (others => '0');
        mac4_a_s <= (others => '0');
        mac5_a_s <= (others => '0');
        mac6_a_s <= (others => '0');
        mac7_a_s <= (others => '0');
        mac8_a_s <= (others => '0');
        mac9_a_s <= (others => '0');
        mac10_a_s <= (others => '0');
        mac11_a_s <= (others => '0');
        mac12_a_s <= (others => '0');
        mac13_a_s <= (others => '0');
        mac14_a_s <= (others => '0');
        mac15_a_s <= (others => '0');
        mac0_b_s <= (others => '0');
        mac1_b_s <= (others => '0');
        mac2_b_s <= (others => '0');
        mac3_b_s <= (others => '0');
        mac4_b_s <= (others => '0');
        mac5_b_s <= (others => '0');
        mac6_b_s <= (others => '0');
        mac7_b_s <= (others => '0');
        mac8_b_s <= (others => '0');
        mac9_b_s <= (others => '0');
        mac10_b_s <= (others => '0');
        mac11_b_s <= (others => '0');
        mac12_b_s <= (others => '0');
        mac13_b_s <= (others => '0');
        mac14_b_s <= (others => '0');
        mac15_b_s <= (others => '0');
      end if;
    end if;
  end process;

  process(clk)  -- fetch result from MAC(s) (no bitshifting because max. 24 bit)
  begin
    if (rising_edge (clk)) then
      if (statem_state = FETCH_MAC_RES) then
          post_proc_temp0 <= mac_result_s;
      end if;
    end if;
  end process;
  
  process(clk)  -- apply scaling factor
  begin
    if (rising_edge (clk)) then
      if (statem_state = SCALING) then
          post_proc_temp1 <= resize(shift_right(post_proc_temp0 * scale2_s(output_index), LAYER2_POST_SCAL_SHFT), POST_PROC_WIDTH);
      end if;
    end if;
  end process;
  
  process(clk)  -- add batch norm bias
  begin
    if (rising_edge (clk)) then
      if (statem_state = BATCH_BIAS) then
          post_proc_temp2 <= resize(shift_right(post_proc_temp1 + layer2_batch_norm_bias_s(output_index), LAYER2_POST_BIAS_SHFT), POST_PROC_WIDTH);
      end if;
    end if;
  end process;

  process(clk)  -- apply Relu activation function
  begin
    if (rising_edge (clk)) then
      if (statem_state = RELU) then
        if (post_proc_temp2 > 0) then
          post_proc_temp3 <= post_proc_temp2;
        else
          post_proc_temp3 <= (others => '0');
        end if;
      end if;
    end if;
  end process;
  
  process(clk)  -- prepare values for rounding
  begin
    if (rising_edge (clk)) then
      if (statem_state = INIT_ROUNDING) then
        rounding_natural_num <= post_proc_temp3 AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 20:12 
      end if;
    end if;
  end process;
  
  process(clk)  -- execute rounding
  begin
    if (rising_edge (clk)) then
      if (statem_state = ROUNDING_0) then
        rounding_fract_num <= post_proc_temp3 - rounding_natural_num;
      end if;
    end if;
  end process;
  
  process(clk)  -- write to output_vector (and bit shifting)
  begin
    if (rising_edge (clk)) then
      if (statem_state = ROUNDING_1) then
        output_vector_s(output_index-START_OUTPUT) <= unsigned(resize(shift_right(unsigned(post_proc_temp3) + unsigned(rounding_fract_num), LAYER2_POST_RNDG_SHFT), ACT_WIDTH));
      end if;
    end if;
  end process;

  MAC0_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac0_a_s,
    b         => mac0_b_s,
    clk       => clk,
    sload     => mac0_sload_s,
    accum_out => mac0_accum_out_s);
  
  MAC1_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac1_a_s,
    b         => mac1_b_s,
    clk       => clk,
    sload     => mac1_sload_s,
    accum_out => mac1_accum_out_s);
    
  MAC2_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac2_a_s,
    b         => mac2_b_s,
    clk       => clk,
    sload     => mac2_sload_s,
    accum_out => mac2_accum_out_s);
  
  MAC3_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac3_a_s,
    b         => mac3_b_s,
    clk       => clk,
    sload     => mac3_sload_s,
    accum_out => mac3_accum_out_s);
  
  MAC4_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac4_a_s,
    b         => mac4_b_s,
    clk       => clk,
    sload     => mac4_sload_s,
    accum_out => mac4_accum_out_s);
  
  MAC5_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac5_a_s,
    b         => mac5_b_s,
    clk       => clk,
    sload     => mac5_sload_s,
    accum_out => mac5_accum_out_s);
  
  MAC6_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac6_a_s,
    b         => mac6_b_s,
    clk       => clk,
    sload     => mac6_sload_s,
    accum_out => mac6_accum_out_s);
  
  MAC7_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac7_a_s,
    b         => mac7_b_s,
    clk       => clk,
    sload     => mac7_sload_s,
    accum_out => mac7_accum_out_s);
  
  MAC8_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac8_a_s,
    b         => mac8_b_s,
    clk       => clk,
    sload     => mac8_sload_s,
    accum_out => mac8_accum_out_s);
  
  MAC9_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac9_a_s,
    b         => mac9_b_s,
    clk       => clk,
    sload     => mac9_sload_s,
    accum_out => mac9_accum_out_s);
  
  MAC10_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac10_a_s,
    b         => mac10_b_s,
    clk       => clk,
    sload     => mac10_sload_s,
    accum_out => mac10_accum_out_s);
  
  MAC11_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac11_a_s,
    b         => mac11_b_s,
    clk       => clk,
    sload     => mac11_sload_s,
    accum_out => mac11_accum_out_s);
  
  MAC12_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac12_a_s,
    b         => mac12_b_s,
    clk       => clk,
    sload     => mac12_sload_s,
    accum_out => mac12_accum_out_s);
  
  MAC13_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac13_a_s,
    b         => mac13_b_s,
    clk       => clk,
    sload     => mac13_sload_s,
    accum_out => mac13_accum_out_s);
  
  MAC14_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac14_a_s,
    b         => mac14_b_s,
    clk       => clk,
    sload     => mac14_sload_s,
    accum_out => mac14_accum_out_s);
  
  MAC15_Instance : LG_MAC_layer2
  generic map (
    A_WIDTH => MAC_LAYER2_A_WIDTH,
    B_WIDTH => MAC_LAYER2_B_WIDTH,
    OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
  port map (
    a         => mac15_a_s,
    b         => mac15_b_s,
    clk       => clk,
    sload     => mac15_sload_s,
    accum_out => mac15_accum_out_s);
    
  process (mac0_accum_out_s, mac1_accum_out_s, mac2_accum_out_s, mac3_accum_out_s, mac4_accum_out_s, mac5_accum_out_s, mac6_accum_out_s, mac7_accum_out_s, mac8_accum_out_s, mac9_accum_out_s, mac10_accum_out_s, mac11_accum_out_s, mac12_accum_out_s, mac13_accum_out_s, mac14_accum_out_s, mac15_accum_out_s)
  begin
    
    mac_result_s <= mac0_accum_out_s + mac1_accum_out_s + mac2_accum_out_s + mac3_accum_out_s + mac4_accum_out_s + mac5_accum_out_s + mac6_accum_out_s + mac7_accum_out_s + mac8_accum_out_s + mac9_accum_out_s + mac10_accum_out_s + mac11_accum_out_s + mac12_accum_out_s + mac13_accum_out_s + mac14_accum_out_s + mac15_accum_out_s;
      
  end process;
 

end behave;
