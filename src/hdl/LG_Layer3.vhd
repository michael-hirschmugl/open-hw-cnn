library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity LG_Layer3 is
  Generic (
    -- CNN value generics
    INPUTS_WIDTH            : integer := 8;
    SCALE3                  : integer := 1540923957;
    LAYER3_CONV_BIAS0       : integer := -1443;
    LAYER3_CONV_BIAS1       : integer := -196;
    SCALE3_WIDTH            : integer := 32;
    POST_PROC_WIDTH         : integer := 32;
    LAYER3_POST_SCAL_SHFT   : integer := 23;
    LAYER3_POST_BIAS_SHFT   : integer := 1;
    WEIGHTS_WIDTH           : integer := 8;
    -- MAC generics
    MAC_LAYER3_A_WIDTH      : integer := 8;
    MAC_LAYER3_B_WIDTH      : integer := 8;
    MAC_LAYER3_OUT_WIDTH    : integer := 23);
  Port (
    input_tensor            : in  std_logic_vector(3*3*8*INPUTS_WIDTH-1 downto 0);  -- (3x3x8) (x,y,z)
    output_vector           : out std_logic_vector(2*POST_PROC_WIDTH-1 downto 0);   -- (2) -- 32-bit
    --output_vector           : out std_logic_vector(2*16-1 downto 0);   -- (2) -- 16-bit
    data_rdy_in             : in  std_logic;                                        -- done writing input_tensor
    data_rdy_out            : out std_logic;                                        -- PL signal that it's done processing
    rst_in                  : in  std_logic;                                        -- active low reset
    clk                     : in  std_logic);
end LG_Layer3;

architecture behave of LG_Layer3 is

  component LG_MAC_layer3
    generic (
      A_WIDTH   : integer := 8;
      B_WIDTH   : integer := 8;
      OUT_WIDTH : integer := 23);
    port (
      a         : in  unsigned (MAC_LAYER3_A_WIDTH-1 downto 0);
      b         : in  signed (MAC_LAYER3_B_WIDTH-1 downto 0);
      clk       : in  std_logic;
      sload     : in  std_logic;
      accum_out : out signed (MAC_LAYER3_OUT_WIDTH-1 downto 0));
  end component;
  
  -- definition of MAC A vector
  subtype gen_int_0 is unsigned (MAC_LAYER3_A_WIDTH-1 downto 0);
  type mac_a_matrix is array (0 to 1, 0 to 7) of gen_int_0;
  
  -- definition of MAC B vector
  subtype gen_int_1 is signed (MAC_LAYER3_B_WIDTH-1 downto 0);
  type mac_b_matrix is array (0 to 1, 0 to 7) of gen_int_1;
  
  -- definition of MAC OUT vector
  subtype gen_int_2 is signed (MAC_LAYER3_OUT_WIDTH-1 downto 0);
  type mac_out_matrix is array (0 to 1, 0 to 7) of gen_int_2;
  
  -- definition of MAC RESULT vector
  subtype gen_int_3 is signed (MAC_LAYER3_OUT_WIDTH-1 downto 0);
  type mac_result_matrix is array (0 to 1) of gen_int_3;
  
  -- MAC signals
  signal mac_a_s           : mac_a_matrix;
  signal mac_b_s           : mac_b_matrix;
  signal mac_sload_s       : std_logic;
  signal mac_accum_out_s   : mac_out_matrix;
  signal mac_result_s      : mac_result_matrix;
  
  -- definition of weights ram
  subtype gen_int_4 is signed (WEIGHTS_WIDTH-1 downto 0);
  type weight_matrix_layer3 is array (0 to 2, 0 to 2, 0 to 7, 0 to 1) of gen_int_4;
  
  signal weight_ram_s : weight_matrix_layer3;  -- Weight RAM (3x3x8x2)
  
  -- definition of input tensor
  subtype gen_int_5 is unsigned (INPUTS_WIDTH-1 downto 0);
  type input_matrix_layer3 is array (0 to 2, 0 to 2, 0 to 8) of gen_int_5;
  
  -- definition of bias array
  subtype gen_int_6 is signed (SCALE3_WIDTH-1 downto 0);
  type scale_bias_array_layer3 is array (0 to 1) of gen_int_6;
  
  -- definition of output tensor
  subtype gen_int_7 is signed (POST_PROC_WIDTH-1 downto 0);  --32-bit
  --subtype gen_int_7 is signed (16-1 downto 0);  --16-bit
  type output_vector_layer3 is array (0 to 1) of gen_int_7;

  -- signals for entity inputs and outputs
  signal input_tensor_s           : input_matrix_layer3 := (others => (others => (others => (others => '0'))));
  signal output_vector_s          : output_vector_layer3 := (others => (others => '0'));
  signal scale3_s                 : signed (SCALE3_WIDTH-1 downto 0) := (others => '0');
  signal layer3_conv_bias_s       : scale_bias_array_layer3 := (others => (others => '0'));
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
                  CONV_BIAS,             -- add bias
                  OUTPUT,                -- write to output
                  OUTPUT_LAYER_COUNTING, -- Increase output layer index (and repeat from INIT (or stop))
                  WAIT_FOR_ACK);         -- issue ready flag and wait for ACK from PS
                  
  signal statem_state : state := IDLE; -- stores state of state machine
  
  -- definition of output tensor
  subtype gen_int_8 is signed (MAC_LAYER3_OUT_WIDTH-1 downto 0);
  type post_proc_temp0_vector is array (0 to 1) of gen_int_8;
  
  -- definition of output tensor
  subtype gen_int_9 is signed (POST_PROC_WIDTH-1 downto 0);
  type post_proc_rest_vector is array (0 to 1) of gen_int_9;
  
  --signal output_index         : integer;                                   -- running output index
  signal frame_index_1        : integer;                                   -- running frame index
  signal frame_index_2        : integer;                                   -- running frame index
  signal rdy_flag_count       : integer;                                   -- leaves the output data ready flag for some cycles
  --signal mac_result_s         : signed (MAC_LAYER3_OUT_WIDTH-1 downto 0);  -- result of all MACs
  signal post_proc_temp0      : post_proc_temp0_vector;  -- MAC result
  signal post_proc_temp1      : post_proc_rest_vector;       -- post Scaling
  signal post_proc_temp2      : post_proc_rest_vector;       -- post Bias
  signal post_proc_temp3      : post_proc_rest_vector;       -- post ReLU
  signal rounding_natural_num : post_proc_rest_vector;
  signal rounding_fract_num   : post_proc_rest_vector;

begin

  -- CNN kernel weights (3,3,8,2)
  weight_ram_s(0, 0, 0, 0) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 0) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 0) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 0) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 0) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 0) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 0) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 0) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 0) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 0) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 0) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 0) <= to_signed(36, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 0) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 0) <= to_signed(72, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 0) <= to_signed(-67, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 0) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 0) <= to_signed(-56, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 0) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 2, 0) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 2, 0) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 2, 0) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 2, 0) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 2, 0) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 2, 0) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 2, 0) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 2, 0) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 2, 0) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 3, 0) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 3, 0) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 3, 0) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 3, 0) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 3, 0) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 3, 0) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 3, 0) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 3, 0) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 3, 0) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 4, 0) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 4, 0) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 4, 0) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 4, 0) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 4, 0) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 4, 0) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 4, 0) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 4, 0) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 4, 0) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 5, 0) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 5, 0) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 5, 0) <= to_signed(49, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 5, 0) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 5, 0) <= to_signed(33, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 5, 0) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 5, 0) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 5, 0) <= to_signed(46, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 5, 0) <= to_signed(-48, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 6, 0) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 6, 0) <= to_signed(-79, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 6, 0) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 6, 0) <= to_signed(-53, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 6, 0) <= to_signed(127, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 6, 0) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 6, 0) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 6, 0) <= to_signed(-53, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 6, 0) <= to_signed(66, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 7, 0) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 7, 0) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 7, 0) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 7, 0) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 7, 0) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 7, 0) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 7, 0) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 7, 0) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 7, 0) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 1) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 1) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 1) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 1) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 1) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 1) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 1) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 1) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 1) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 1) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 1) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 1) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 1) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 1) <= to_signed(-28, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 1) <= to_signed(46, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 1) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 1) <= to_signed(56, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 1) <= to_signed(-114, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 2, 1) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 2, 1) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 2, 1) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 2, 1) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 2, 1) <= to_signed(16, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 2, 1) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 2, 1) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 2, 1) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 2, 1) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 3, 1) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 3, 1) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 3, 1) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 3, 1) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 3, 1) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 3, 1) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 3, 1) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 3, 1) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 3, 1) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 4, 1) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 4, 1) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 4, 1) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 4, 1) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 4, 1) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 4, 1) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 4, 1) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 4, 1) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 4, 1) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 5, 1) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 5, 1) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 5, 1) <= to_signed(-57, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 5, 1) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 5, 1) <= to_signed(-47, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 5, 1) <= to_signed(127, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 5, 1) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 5, 1) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 5, 1) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 6, 1) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 6, 1) <= to_signed(-56, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 6, 1) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 6, 1) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 6, 1) <= to_signed(52, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 6, 1) <= to_signed(-72, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 6, 1) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 6, 1) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 6, 1) <= to_signed(41, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 7, 1) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 7, 1) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 7, 1) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 7, 1) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 7, 1) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 7, 1) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 7, 1) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 7, 1) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 7, 1) <= to_signed(0, WEIGHTS_WIDTH);
  
  scale3_s              <= to_signed(SCALE3, SCALE3_WIDTH);
  layer3_conv_bias_s(0) <= to_signed(LAYER3_CONV_BIAS0, SCALE3_WIDTH);
  layer3_conv_bias_s(1) <= to_signed(LAYER3_CONV_BIAS1, SCALE3_WIDTH);

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
      input_tensor_s(0, 1, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*8 downto INPUTS_WIDTH*8));
      input_tensor_s(0, 1, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*9 downto INPUTS_WIDTH*9));
      input_tensor_s(0, 1, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*10 downto INPUTS_WIDTH*10));
      input_tensor_s(0, 1, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*11 downto INPUTS_WIDTH*11));
      input_tensor_s(0, 1, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*12 downto INPUTS_WIDTH*12));
      input_tensor_s(0, 1, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*13 downto INPUTS_WIDTH*13));
      input_tensor_s(0, 1, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*14 downto INPUTS_WIDTH*14));
      input_tensor_s(0, 1, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*15 downto INPUTS_WIDTH*15));
      input_tensor_s(0, 2, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*16 downto INPUTS_WIDTH*16));
      input_tensor_s(0, 2, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*17 downto INPUTS_WIDTH*17));
      input_tensor_s(0, 2, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*18 downto INPUTS_WIDTH*18));
      input_tensor_s(0, 2, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*19 downto INPUTS_WIDTH*19));
      input_tensor_s(0, 2, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*20 downto INPUTS_WIDTH*20));
      input_tensor_s(0, 2, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*21 downto INPUTS_WIDTH*21));
      input_tensor_s(0, 2, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*22 downto INPUTS_WIDTH*22));
      input_tensor_s(0, 2, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*23 downto INPUTS_WIDTH*23));
      input_tensor_s(1, 0, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*24 downto INPUTS_WIDTH*24));
      input_tensor_s(1, 0, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*25 downto INPUTS_WIDTH*25));
      input_tensor_s(1, 0, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*26 downto INPUTS_WIDTH*26));
      input_tensor_s(1, 0, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*27 downto INPUTS_WIDTH*27));
      input_tensor_s(1, 0, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*28 downto INPUTS_WIDTH*28));
      input_tensor_s(1, 0, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*29 downto INPUTS_WIDTH*29));
      input_tensor_s(1, 0, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*30 downto INPUTS_WIDTH*30));
      input_tensor_s(1, 0, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*31 downto INPUTS_WIDTH*31));
      input_tensor_s(1, 1, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*32 downto INPUTS_WIDTH*32));
      input_tensor_s(1, 1, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*33 downto INPUTS_WIDTH*33));
      input_tensor_s(1, 1, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*34 downto INPUTS_WIDTH*34));
      input_tensor_s(1, 1, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*35 downto INPUTS_WIDTH*35));
      input_tensor_s(1, 1, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*36 downto INPUTS_WIDTH*36));
      input_tensor_s(1, 1, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*37 downto INPUTS_WIDTH*37));
      input_tensor_s(1, 1, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*38 downto INPUTS_WIDTH*38));
      input_tensor_s(1, 1, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*39 downto INPUTS_WIDTH*39));
      input_tensor_s(1, 2, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*40 downto INPUTS_WIDTH*40));
      input_tensor_s(1, 2, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*41 downto INPUTS_WIDTH*41));
      input_tensor_s(1, 2, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*42 downto INPUTS_WIDTH*42));
      input_tensor_s(1, 2, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*43 downto INPUTS_WIDTH*43));
      input_tensor_s(1, 2, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*44 downto INPUTS_WIDTH*44));
      input_tensor_s(1, 2, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*45 downto INPUTS_WIDTH*45));
      input_tensor_s(1, 2, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*46 downto INPUTS_WIDTH*46));
      input_tensor_s(1, 2, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*47 downto INPUTS_WIDTH*47));
      input_tensor_s(2, 0, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*48 downto INPUTS_WIDTH*48));
      input_tensor_s(2, 0, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*49 downto INPUTS_WIDTH*49));
      input_tensor_s(2, 0, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*50 downto INPUTS_WIDTH*50));
      input_tensor_s(2, 0, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*51 downto INPUTS_WIDTH*51));
      input_tensor_s(2, 0, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*52 downto INPUTS_WIDTH*52));
      input_tensor_s(2, 0, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*53 downto INPUTS_WIDTH*53));
      input_tensor_s(2, 0, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*54 downto INPUTS_WIDTH*54));
      input_tensor_s(2, 0, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*55 downto INPUTS_WIDTH*55));
      input_tensor_s(2, 1, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*56 downto INPUTS_WIDTH*56));
      input_tensor_s(2, 1, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*57 downto INPUTS_WIDTH*57));
      input_tensor_s(2, 1, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*58 downto INPUTS_WIDTH*58));
      input_tensor_s(2, 1, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*59 downto INPUTS_WIDTH*59));
      input_tensor_s(2, 1, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*60 downto INPUTS_WIDTH*60));
      input_tensor_s(2, 1, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*61 downto INPUTS_WIDTH*61));
      input_tensor_s(2, 1, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*62 downto INPUTS_WIDTH*62));
      input_tensor_s(2, 1, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*63 downto INPUTS_WIDTH*63));
      input_tensor_s(2, 2, 0) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*64 downto INPUTS_WIDTH*64));
      input_tensor_s(2, 2, 1) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*65 downto INPUTS_WIDTH*65));
      input_tensor_s(2, 2, 2) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*66 downto INPUTS_WIDTH*66));
      input_tensor_s(2, 2, 3) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*67 downto INPUTS_WIDTH*67));
      input_tensor_s(2, 2, 4) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*68 downto INPUTS_WIDTH*68));
      input_tensor_s(2, 2, 5) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*69 downto INPUTS_WIDTH*69));
      input_tensor_s(2, 2, 6) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*70 downto INPUTS_WIDTH*70));
      input_tensor_s(2, 2, 7) <= unsigned(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*71 downto INPUTS_WIDTH*71));      
      
      data_rdy_in_s  <= data_rdy_in;
      rst_in_s       <= rst_in;
    end if;
  end process;
  
  -- map output signals to ports
  
  output_vector(POST_PROC_WIDTH-1+POST_PROC_WIDTH*0 downto POST_PROC_WIDTH*0) <= std_logic_vector(output_vector_s(0));  -- 32-bit
  output_vector(POST_PROC_WIDTH-1+POST_PROC_WIDTH*1 downto POST_PROC_WIDTH*1) <= std_logic_vector(output_vector_s(1));
  --output_vector(16-1+16*0 downto 16*0) <= std_logic_vector(output_vector_s(0));  -- 16-bit
  --output_vector(16-1+16*1 downto 16*1) <= std_logic_vector(output_vector_s(1));
  
  data_rdy_out  <= data_rdy_out_s;
  
  process(clk)  -- Statemachine
  begin
    if (rising_edge (clk)) then
    
      if(rst_in_s = '0') then
        statem_state <= IDLE;
        --output_index <= 0;
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
           --if (output_index > 0) then      -- or if already running
              --statem_state <= INIT_MAC;
            --end if;
          
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
            statem_state <= CONV_BIAS;
          
          when (CONV_BIAS) =>  -- add bias
            statem_state <= OUTPUT;
          
          when (OUTPUT) =>  -- execute rounding and write to output vector
            statem_state <= OUTPUT_LAYER_COUNTING;
          
          when (OUTPUT_LAYER_COUNTING) =>  -- compute 2 output features (output_index++)
            --if (output_index = 1) then
              statem_state <= WAIT_FOR_ACK;
              --output_index <= 0;
            --else
              --output_index <= output_index + 1;
              --statem_state <= IDLE;
            --end if;
            
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
          mac_sload_s <= '1';
          --mac1_sload_s <= '1';
          --mac2_sload_s <= '1';
          --mac3_sload_s <= '1';
          --mac4_sload_s <= '1';
          --mac5_sload_s <= '1';
          --mac6_sload_s <= '1';
          --mac7_sload_s <= '1';
        else
          mac_sload_s <= '0';
          --mac1_sload_s <= '0';
          --mac2_sload_s <= '0';
          --mac3_sload_s <= '0';
          --mac4_sload_s <= '0';
          --mac5_sload_s <= '0';
          --mac6_sload_s <= '0';
          --mac7_sload_s <= '0';
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
        mac_a_s(0, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(0, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(0, 2) <= input_tensor_s(frame_index_2, frame_index_1, 2);
        mac_a_s(0, 3) <= input_tensor_s(frame_index_2, frame_index_1, 3);
        mac_a_s(0, 4) <= input_tensor_s(frame_index_2, frame_index_1, 4);
        mac_a_s(0, 5) <= input_tensor_s(frame_index_2, frame_index_1, 5);
        mac_a_s(0, 6) <= input_tensor_s(frame_index_2, frame_index_1, 6);
        mac_a_s(0, 7) <= input_tensor_s(frame_index_2, frame_index_1, 7);
        mac_a_s(1, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(1, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(1, 2) <= input_tensor_s(frame_index_2, frame_index_1, 2);
        mac_a_s(1, 3) <= input_tensor_s(frame_index_2, frame_index_1, 3);
        mac_a_s(1, 4) <= input_tensor_s(frame_index_2, frame_index_1, 4);
        mac_a_s(1, 5) <= input_tensor_s(frame_index_2, frame_index_1, 5);
        mac_a_s(1, 6) <= input_tensor_s(frame_index_2, frame_index_1, 6);
        mac_a_s(1, 7) <= input_tensor_s(frame_index_2, frame_index_1, 7);
        mac_b_s(0, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 0);
        mac_b_s(0, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 0);
        mac_b_s(0, 2) <= weight_ram_s(frame_index_2, frame_index_1, 2, 0);
        mac_b_s(0, 3) <= weight_ram_s(frame_index_2, frame_index_1, 3, 0);
        mac_b_s(0, 4) <= weight_ram_s(frame_index_2, frame_index_1, 4, 0);
        mac_b_s(0, 5) <= weight_ram_s(frame_index_2, frame_index_1, 5, 0);
        mac_b_s(0, 6) <= weight_ram_s(frame_index_2, frame_index_1, 6, 0);
        mac_b_s(0, 7) <= weight_ram_s(frame_index_2, frame_index_1, 7, 0);
        mac_b_s(1, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 1);
        mac_b_s(1, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 1);
        mac_b_s(1, 2) <= weight_ram_s(frame_index_2, frame_index_1, 2, 1);
        mac_b_s(1, 3) <= weight_ram_s(frame_index_2, frame_index_1, 3, 1);
        mac_b_s(1, 4) <= weight_ram_s(frame_index_2, frame_index_1, 4, 1);
        mac_b_s(1, 5) <= weight_ram_s(frame_index_2, frame_index_1, 5, 1);
        mac_b_s(1, 6) <= weight_ram_s(frame_index_2, frame_index_1, 6, 1);
        mac_b_s(1, 7) <= weight_ram_s(frame_index_2, frame_index_1, 7, 1);
      else
        mac_a_s(0, 0) <= (others => '0');
        mac_b_s(0, 0) <= (others => '0');
        mac_a_s(0, 1) <= (others => '0');
        mac_b_s(0, 1) <= (others => '0');
        mac_a_s(0, 2) <= (others => '0');
        mac_b_s(0, 2) <= (others => '0');
        mac_a_s(0, 3) <= (others => '0');
        mac_b_s(0, 3) <= (others => '0');
        mac_a_s(0, 4) <= (others => '0');
        mac_b_s(0, 4) <= (others => '0');
        mac_a_s(0, 5) <= (others => '0');
        mac_b_s(0, 5) <= (others => '0');
        mac_a_s(0, 6) <= (others => '0');
        mac_b_s(0, 6) <= (others => '0');
        mac_a_s(0, 7) <= (others => '0');
        mac_b_s(0, 7) <= (others => '0');
        mac_a_s(0, 0) <= (others => '0');
        mac_b_s(0, 0) <= (others => '0');
        mac_a_s(0, 1) <= (others => '0');
        mac_b_s(0, 1) <= (others => '0');
        mac_a_s(0, 2) <= (others => '0');
        mac_b_s(0, 2) <= (others => '0');
        mac_a_s(0, 3) <= (others => '0');
        mac_b_s(0, 3) <= (others => '0');
        mac_a_s(0, 4) <= (others => '0');
        mac_b_s(0, 4) <= (others => '0');
        mac_a_s(0, 5) <= (others => '0');
        mac_b_s(0, 5) <= (others => '0');
        mac_a_s(0, 6) <= (others => '0');
        mac_b_s(0, 6) <= (others => '0');
        mac_a_s(0, 7) <= (others => '0');
        mac_b_s(0, 7) <= (others => '0');
        mac_a_s(0, 0) <= (others => '0');
        mac_b_s(0, 0) <= (others => '0');
        mac_a_s(0, 1) <= (others => '0');
        mac_b_s(0, 1) <= (others => '0');
        mac_a_s(0, 2) <= (others => '0');
        mac_b_s(0, 2) <= (others => '0');
        mac_a_s(0, 3) <= (others => '0');
        mac_b_s(0, 3) <= (others => '0');
        mac_a_s(0, 4) <= (others => '0');
        mac_b_s(0, 4) <= (others => '0');
        mac_a_s(0, 5) <= (others => '0');
        mac_b_s(0, 5) <= (others => '0');
        mac_a_s(0, 6) <= (others => '0');
        mac_b_s(0, 6) <= (others => '0');
        mac_a_s(0, 7) <= (others => '0');
        mac_b_s(0, 7) <= (others => '0');
        mac_a_s(0, 0) <= (others => '0');
        mac_b_s(0, 0) <= (others => '0');
        mac_a_s(0, 1) <= (others => '0');
        mac_b_s(0, 1) <= (others => '0');
        mac_a_s(0, 2) <= (others => '0');
        mac_b_s(0, 2) <= (others => '0');
        mac_a_s(0, 3) <= (others => '0');
        mac_b_s(0, 3) <= (others => '0');
        mac_a_s(0, 4) <= (others => '0');
        mac_b_s(0, 4) <= (others => '0');
        mac_a_s(0, 5) <= (others => '0');
        mac_b_s(0, 5) <= (others => '0');
        mac_a_s(0, 6) <= (others => '0');
        mac_b_s(0, 6) <= (others => '0');
        mac_a_s(0, 7) <= (others => '0');
        mac_b_s(0, 7) <= (others => '0');
        mac_a_s(0, 0) <= (others => '0');
        mac_b_s(0, 0) <= (others => '0');
        mac_a_s(0, 1) <= (others => '0');
        mac_b_s(0, 1) <= (others => '0');
        mac_a_s(0, 2) <= (others => '0');
        mac_b_s(0, 2) <= (others => '0');
        mac_a_s(0, 3) <= (others => '0');
        mac_b_s(0, 3) <= (others => '0');
        mac_a_s(0, 4) <= (others => '0');
        mac_b_s(0, 4) <= (others => '0');
        mac_a_s(0, 5) <= (others => '0');
        mac_b_s(0, 5) <= (others => '0');
        mac_a_s(0, 6) <= (others => '0');
        mac_b_s(0, 6) <= (others => '0');
        mac_a_s(0, 7) <= (others => '0');
        mac_b_s(0, 7) <= (others => '0');
        mac_a_s(0, 0) <= (others => '0');
        mac_b_s(0, 0) <= (others => '0');
        mac_a_s(0, 1) <= (others => '0');
        mac_b_s(0, 1) <= (others => '0');
        mac_a_s(0, 2) <= (others => '0');
        mac_b_s(0, 2) <= (others => '0');
        mac_a_s(0, 3) <= (others => '0');
        mac_b_s(0, 3) <= (others => '0');
        mac_a_s(0, 4) <= (others => '0');
        mac_b_s(0, 4) <= (others => '0');
        mac_a_s(0, 5) <= (others => '0');
        mac_b_s(0, 5) <= (others => '0');
        mac_a_s(0, 6) <= (others => '0');
        mac_b_s(0, 6) <= (others => '0');
        mac_a_s(0, 7) <= (others => '0');
        mac_b_s(0, 7) <= (others => '0');
        mac_a_s(0, 0) <= (others => '0');
        mac_b_s(0, 0) <= (others => '0');
        mac_a_s(0, 1) <= (others => '0');
        mac_b_s(0, 1) <= (others => '0');
        mac_a_s(0, 2) <= (others => '0');
        mac_b_s(0, 2) <= (others => '0');
        mac_a_s(0, 3) <= (others => '0');
        mac_b_s(0, 3) <= (others => '0');
        mac_a_s(0, 4) <= (others => '0');
        mac_b_s(0, 4) <= (others => '0');
        mac_a_s(0, 5) <= (others => '0');
        mac_b_s(0, 5) <= (others => '0');
        mac_a_s(0, 6) <= (others => '0');
        mac_b_s(0, 6) <= (others => '0');
        mac_a_s(0, 7) <= (others => '0');
        mac_b_s(0, 7) <= (others => '0');
        mac_a_s(0, 0) <= (others => '0');
        mac_b_s(0, 0) <= (others => '0');
        mac_a_s(0, 1) <= (others => '0');
        mac_b_s(0, 1) <= (others => '0');
        mac_a_s(0, 2) <= (others => '0');
        mac_b_s(0, 2) <= (others => '0');
        mac_a_s(0, 3) <= (others => '0');
        mac_b_s(0, 3) <= (others => '0');
        mac_a_s(0, 4) <= (others => '0');
        mac_b_s(0, 4) <= (others => '0');
        mac_a_s(0, 5) <= (others => '0');
        mac_b_s(0, 5) <= (others => '0');
        mac_a_s(0, 6) <= (others => '0');
        mac_b_s(0, 6) <= (others => '0');
        mac_a_s(0, 7) <= (others => '0');
        mac_b_s(0, 7) <= (others => '0');
        mac_a_s(1, 0) <= (others => '0');
        mac_b_s(1, 0) <= (others => '0');
        mac_a_s(1, 1) <= (others => '0');
        mac_b_s(1, 1) <= (others => '0');
        mac_a_s(1, 2) <= (others => '0');
        mac_b_s(1, 2) <= (others => '0');
        mac_a_s(1, 3) <= (others => '0');
        mac_b_s(1, 3) <= (others => '0');
        mac_a_s(1, 4) <= (others => '0');
        mac_b_s(1, 4) <= (others => '0');
        mac_a_s(1, 5) <= (others => '0');
        mac_b_s(1, 5) <= (others => '0');
        mac_a_s(1, 6) <= (others => '0');
        mac_b_s(1, 6) <= (others => '0');
        mac_a_s(1, 7) <= (others => '0');
        mac_b_s(1, 7) <= (others => '0');
        mac_a_s(1, 0) <= (others => '0');
        mac_b_s(1, 0) <= (others => '0');
        mac_a_s(1, 1) <= (others => '0');
        mac_b_s(1, 1) <= (others => '0');
        mac_a_s(1, 2) <= (others => '0');
        mac_b_s(1, 2) <= (others => '0');
        mac_a_s(1, 3) <= (others => '0');
        mac_b_s(1, 3) <= (others => '0');
        mac_a_s(1, 4) <= (others => '0');
        mac_b_s(1, 4) <= (others => '0');
        mac_a_s(1, 5) <= (others => '0');
        mac_b_s(1, 5) <= (others => '0');
        mac_a_s(1, 6) <= (others => '0');
        mac_b_s(1, 6) <= (others => '0');
        mac_a_s(1, 7) <= (others => '0');
        mac_b_s(1, 7) <= (others => '0');
        mac_a_s(1, 0) <= (others => '0');
        mac_b_s(1, 0) <= (others => '0');
        mac_a_s(1, 1) <= (others => '0');
        mac_b_s(1, 1) <= (others => '0');
        mac_a_s(1, 2) <= (others => '0');
        mac_b_s(1, 2) <= (others => '0');
        mac_a_s(1, 3) <= (others => '0');
        mac_b_s(1, 3) <= (others => '0');
        mac_a_s(1, 4) <= (others => '0');
        mac_b_s(1, 4) <= (others => '0');
        mac_a_s(1, 5) <= (others => '0');
        mac_b_s(1, 5) <= (others => '0');
        mac_a_s(1, 6) <= (others => '0');
        mac_b_s(1, 6) <= (others => '0');
        mac_a_s(1, 7) <= (others => '0');
        mac_b_s(1, 7) <= (others => '0');
        mac_a_s(1, 0) <= (others => '0');
        mac_b_s(1, 0) <= (others => '0');
        mac_a_s(1, 1) <= (others => '0');
        mac_b_s(1, 1) <= (others => '0');
        mac_a_s(1, 2) <= (others => '0');
        mac_b_s(1, 2) <= (others => '0');
        mac_a_s(1, 3) <= (others => '0');
        mac_b_s(1, 3) <= (others => '0');
        mac_a_s(1, 4) <= (others => '0');
        mac_b_s(1, 4) <= (others => '0');
        mac_a_s(1, 5) <= (others => '0');
        mac_b_s(1, 5) <= (others => '0');
        mac_a_s(1, 6) <= (others => '0');
        mac_b_s(1, 6) <= (others => '0');
        mac_a_s(1, 7) <= (others => '0');
        mac_b_s(1, 7) <= (others => '0');
        mac_a_s(1, 0) <= (others => '0');
        mac_b_s(1, 0) <= (others => '0');
        mac_a_s(1, 1) <= (others => '0');
        mac_b_s(1, 1) <= (others => '0');
        mac_a_s(1, 2) <= (others => '0');
        mac_b_s(1, 2) <= (others => '0');
        mac_a_s(1, 3) <= (others => '0');
        mac_b_s(1, 3) <= (others => '0');
        mac_a_s(1, 4) <= (others => '0');
        mac_b_s(1, 4) <= (others => '0');
        mac_a_s(1, 5) <= (others => '0');
        mac_b_s(1, 5) <= (others => '0');
        mac_a_s(1, 6) <= (others => '0');
        mac_b_s(1, 6) <= (others => '0');
        mac_a_s(1, 7) <= (others => '0');
        mac_b_s(1, 7) <= (others => '0');
        mac_a_s(1, 0) <= (others => '0');
        mac_b_s(1, 0) <= (others => '0');
        mac_a_s(1, 1) <= (others => '0');
        mac_b_s(1, 1) <= (others => '0');
        mac_a_s(1, 2) <= (others => '0');
        mac_b_s(1, 2) <= (others => '0');
        mac_a_s(1, 3) <= (others => '0');
        mac_b_s(1, 3) <= (others => '0');
        mac_a_s(1, 4) <= (others => '0');
        mac_b_s(1, 4) <= (others => '0');
        mac_a_s(1, 5) <= (others => '0');
        mac_b_s(1, 5) <= (others => '0');
        mac_a_s(1, 6) <= (others => '0');
        mac_b_s(1, 6) <= (others => '0');
        mac_a_s(1, 7) <= (others => '0');
        mac_b_s(1, 7) <= (others => '0');
        mac_a_s(1, 0) <= (others => '0');
        mac_b_s(1, 0) <= (others => '0');
        mac_a_s(1, 1) <= (others => '0');
        mac_b_s(1, 1) <= (others => '0');
        mac_a_s(1, 2) <= (others => '0');
        mac_b_s(1, 2) <= (others => '0');
        mac_a_s(1, 3) <= (others => '0');
        mac_b_s(1, 3) <= (others => '0');
        mac_a_s(1, 4) <= (others => '0');
        mac_b_s(1, 4) <= (others => '0');
        mac_a_s(1, 5) <= (others => '0');
        mac_b_s(1, 5) <= (others => '0');
        mac_a_s(1, 6) <= (others => '0');
        mac_b_s(1, 6) <= (others => '0');
        mac_a_s(1, 7) <= (others => '0');
        mac_b_s(1, 7) <= (others => '0');
        mac_a_s(1, 0) <= (others => '0');
        mac_b_s(1, 0) <= (others => '0');
        mac_a_s(1, 1) <= (others => '0');
        mac_b_s(1, 1) <= (others => '0');
        mac_a_s(1, 2) <= (others => '0');
        mac_b_s(1, 2) <= (others => '0');
        mac_a_s(1, 3) <= (others => '0');
        mac_b_s(1, 3) <= (others => '0');
        mac_a_s(1, 4) <= (others => '0');
        mac_b_s(1, 4) <= (others => '0');
        mac_a_s(1, 5) <= (others => '0');
        mac_b_s(1, 5) <= (others => '0');
        mac_a_s(1, 6) <= (others => '0');
        mac_b_s(1, 6) <= (others => '0');
        mac_a_s(1, 7) <= (others => '0');
        mac_b_s(1, 7) <= (others => '0');
      end if;
    end if;
  end process;

  process(clk)  -- fetch result from MAC(s) (no bitshifting because max. 24 bit)
  begin
    if (rising_edge (clk)) then
      if (statem_state = FETCH_MAC_RES) then
          post_proc_temp0(0) <= mac_result_s(0);
          post_proc_temp0(1) <= mac_result_s(1);
      end if;
    end if;
  end process;
  
  process(clk)  -- apply scaling factor
  begin
    if (rising_edge (clk)) then
      if (statem_state = SCALING) then
          post_proc_temp1(0) <= resize(shift_right(post_proc_temp0(0) * scale3_s, LAYER3_POST_SCAL_SHFT), POST_PROC_WIDTH);
          post_proc_temp1(1) <= resize(shift_right(post_proc_temp0(1) * scale3_s, LAYER3_POST_SCAL_SHFT), POST_PROC_WIDTH);
      end if;
    end if;
  end process;
  
  process(clk)  -- add bias
  begin
    if (rising_edge (clk)) then
      if (statem_state = CONV_BIAS) then
          post_proc_temp2(0) <= resize(shift_right(post_proc_temp1(0) + layer3_conv_bias_s(0), LAYER3_POST_BIAS_SHFT), POST_PROC_WIDTH);
          post_proc_temp2(1) <= resize(shift_right(post_proc_temp1(1) + layer3_conv_bias_s(1), LAYER3_POST_BIAS_SHFT), POST_PROC_WIDTH);
      end if;
    end if;
  end process;

  
  process(clk)  -- write to output_vector
  begin
    if (rising_edge (clk)) then
      if (statem_state = OUTPUT) then
        output_vector_s(0) <= post_proc_temp2(0);  --32-bit
        output_vector_s(1) <= post_proc_temp2(1);
        --output_vector_s(0) <= resize(shift_right(post_proc_temp2(0), 16), 16);  --16-bit
        --output_vector_s(1) <= resize(shift_right(post_proc_temp2(1), 16), 16);
      end if;
    end if;
  end process;

  MAC00_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(0, 0),
    b         => mac_b_s(0, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(0, 0));
  
  MAC01_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(0, 1),
    b         => mac_b_s(0, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(0, 1));
  
  MAC02_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(0, 2),
    b         => mac_b_s(0, 2),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(0, 2));
  
  MAC03_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(0, 3),
    b         => mac_b_s(0, 3),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(0, 3));
  
  MAC04_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(0, 4),
    b         => mac_b_s(0, 4),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(0, 4));
  
  MAC05_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(0, 5),
    b         => mac_b_s(0, 5),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(0, 5));
  
  MAC06_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(0, 6),
    b         => mac_b_s(0, 6),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(0, 6));
  
  MAC07_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(0, 7),
    b         => mac_b_s(0, 7),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(0, 7));
  
  MAC10_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(1, 0),
    b         => mac_b_s(1, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(1, 0));
  
  MAC11_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(1, 1),
    b         => mac_b_s(1, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(1, 1));
  
  MAC12_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(1, 2),
    b         => mac_b_s(1, 2),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(1, 2));
  
  MAC13_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(1, 3),
    b         => mac_b_s(1, 3),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(1, 3));
  
  MAC14_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(1, 4),
    b         => mac_b_s(1, 4),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(1, 4));
  
  MAC15_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(1, 5),
    b         => mac_b_s(1, 5),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(1, 5));
  
  MAC16_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(1, 6),
    b         => mac_b_s(1, 6),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(1, 6));
  
  MAC17_Instance : LG_MAC_layer3
  generic map (
    A_WIDTH   => MAC_LAYER3_A_WIDTH,
    B_WIDTH   => MAC_LAYER3_B_WIDTH,
    OUT_WIDTH => MAC_LAYER3_OUT_WIDTH)
  port map (
    a         => mac_a_s(1, 7),
    b         => mac_b_s(1, 7),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(1, 7));
    
  process (mac_accum_out_s(0, 0), mac_accum_out_s(0, 1), mac_accum_out_s(0, 2), mac_accum_out_s(0, 3), mac_accum_out_s(0, 4), mac_accum_out_s(0, 5), mac_accum_out_s(0, 6), mac_accum_out_s(0, 7), mac_accum_out_s(0, 0), mac_accum_out_s(0, 1), mac_accum_out_s(0, 2), mac_accum_out_s(0, 3), mac_accum_out_s(0, 4), mac_accum_out_s(0, 5), mac_accum_out_s(0, 6), mac_accum_out_s(0, 7), mac_accum_out_s(0, 0), mac_accum_out_s(0, 1), mac_accum_out_s(0, 2), mac_accum_out_s(0, 3), mac_accum_out_s(0, 4), mac_accum_out_s(0, 5), mac_accum_out_s(0, 6), mac_accum_out_s(0, 7), mac_accum_out_s(0, 0), mac_accum_out_s(0, 1), mac_accum_out_s(0, 2), mac_accum_out_s(0, 3), mac_accum_out_s(0, 4), mac_accum_out_s(0, 5), mac_accum_out_s(0, 6), mac_accum_out_s(0, 7), mac_accum_out_s(0, 0), mac_accum_out_s(0, 1), mac_accum_out_s(0, 2), mac_accum_out_s(0, 3), mac_accum_out_s(0, 4), mac_accum_out_s(0, 5), mac_accum_out_s(0, 6), mac_accum_out_s(0, 7), mac_accum_out_s(0, 0), mac_accum_out_s(0, 1), mac_accum_out_s(0, 2), mac_accum_out_s(0, 3), mac_accum_out_s(0, 4), mac_accum_out_s(0, 5), mac_accum_out_s(0, 6), mac_accum_out_s(0, 7), mac_accum_out_s(0, 0), mac_accum_out_s(0, 1), mac_accum_out_s(0, 2), mac_accum_out_s(0, 3), mac_accum_out_s(0, 4), mac_accum_out_s(0, 5), mac_accum_out_s(0, 6), mac_accum_out_s(0, 7), mac_accum_out_s(0, 0), mac_accum_out_s(0, 1), mac_accum_out_s(0, 2), mac_accum_out_s(0, 3), mac_accum_out_s(0, 4), mac_accum_out_s(0, 5), mac_accum_out_s(0, 6), mac_accum_out_s(0, 7), mac_accum_out_s(1, 0), mac_accum_out_s(1, 1), mac_accum_out_s(1, 2), mac_accum_out_s(1, 3), mac_accum_out_s(1, 4), mac_accum_out_s(1, 5), mac_accum_out_s(1, 6), mac_accum_out_s(1, 7), mac_accum_out_s(1, 0), mac_accum_out_s(1, 1), mac_accum_out_s(1, 2), mac_accum_out_s(1, 3), mac_accum_out_s(1, 4), mac_accum_out_s(1, 5), mac_accum_out_s(1, 6), mac_accum_out_s(1, 7), mac_accum_out_s(1, 0), mac_accum_out_s(1, 1), mac_accum_out_s(1, 2), mac_accum_out_s(1, 3), mac_accum_out_s(1, 4), mac_accum_out_s(1, 5), mac_accum_out_s(1, 6), mac_accum_out_s(1, 7), mac_accum_out_s(1, 0), mac_accum_out_s(1, 1), mac_accum_out_s(1, 2), mac_accum_out_s(1, 3), mac_accum_out_s(1, 4), mac_accum_out_s(1, 5), mac_accum_out_s(1, 6), mac_accum_out_s(1, 7), mac_accum_out_s(1, 0), mac_accum_out_s(1, 1), mac_accum_out_s(1, 2), mac_accum_out_s(1, 3), mac_accum_out_s(1, 4), mac_accum_out_s(1, 5), mac_accum_out_s(1, 6), mac_accum_out_s(1, 7), mac_accum_out_s(1, 0), mac_accum_out_s(1, 1), mac_accum_out_s(1, 2), mac_accum_out_s(1, 3), mac_accum_out_s(1, 4), mac_accum_out_s(1, 5), mac_accum_out_s(1, 6), mac_accum_out_s(1, 7), mac_accum_out_s(1, 0), mac_accum_out_s(1, 1), mac_accum_out_s(1, 2), mac_accum_out_s(1, 3), mac_accum_out_s(1, 4), mac_accum_out_s(1, 5), mac_accum_out_s(1, 6), mac_accum_out_s(1, 7), mac_accum_out_s(1, 0), mac_accum_out_s(1, 1), mac_accum_out_s(1, 2), mac_accum_out_s(1, 3), mac_accum_out_s(1, 4), mac_accum_out_s(1, 5), mac_accum_out_s(1, 6), mac_accum_out_s(1, 7))
  begin
    
    mac_result_s(0) <= mac_accum_out_s(0, 0) + mac_accum_out_s(0, 1) + mac_accum_out_s(0, 2) + mac_accum_out_s(0, 3) + mac_accum_out_s(0, 4) + mac_accum_out_s(0, 5) + mac_accum_out_s(0, 6) + mac_accum_out_s(0, 7);
    mac_result_s(0) <= mac_accum_out_s(0, 0) + mac_accum_out_s(0, 1) + mac_accum_out_s(0, 2) + mac_accum_out_s(0, 3) + mac_accum_out_s(0, 4) + mac_accum_out_s(0, 5) + mac_accum_out_s(0, 6) + mac_accum_out_s(0, 7);
    mac_result_s(0) <= mac_accum_out_s(0, 0) + mac_accum_out_s(0, 1) + mac_accum_out_s(0, 2) + mac_accum_out_s(0, 3) + mac_accum_out_s(0, 4) + mac_accum_out_s(0, 5) + mac_accum_out_s(0, 6) + mac_accum_out_s(0, 7);
    mac_result_s(0) <= mac_accum_out_s(0, 0) + mac_accum_out_s(0, 1) + mac_accum_out_s(0, 2) + mac_accum_out_s(0, 3) + mac_accum_out_s(0, 4) + mac_accum_out_s(0, 5) + mac_accum_out_s(0, 6) + mac_accum_out_s(0, 7);
    mac_result_s(0) <= mac_accum_out_s(0, 0) + mac_accum_out_s(0, 1) + mac_accum_out_s(0, 2) + mac_accum_out_s(0, 3) + mac_accum_out_s(0, 4) + mac_accum_out_s(0, 5) + mac_accum_out_s(0, 6) + mac_accum_out_s(0, 7);
    mac_result_s(0) <= mac_accum_out_s(0, 0) + mac_accum_out_s(0, 1) + mac_accum_out_s(0, 2) + mac_accum_out_s(0, 3) + mac_accum_out_s(0, 4) + mac_accum_out_s(0, 5) + mac_accum_out_s(0, 6) + mac_accum_out_s(0, 7);
    mac_result_s(0) <= mac_accum_out_s(0, 0) + mac_accum_out_s(0, 1) + mac_accum_out_s(0, 2) + mac_accum_out_s(0, 3) + mac_accum_out_s(0, 4) + mac_accum_out_s(0, 5) + mac_accum_out_s(0, 6) + mac_accum_out_s(0, 7);
    mac_result_s(0) <= mac_accum_out_s(0, 0) + mac_accum_out_s(0, 1) + mac_accum_out_s(0, 2) + mac_accum_out_s(0, 3) + mac_accum_out_s(0, 4) + mac_accum_out_s(0, 5) + mac_accum_out_s(0, 6) + mac_accum_out_s(0, 7);
    mac_result_s(1) <= mac_accum_out_s(1, 0) + mac_accum_out_s(1, 1) + mac_accum_out_s(1, 2) + mac_accum_out_s(1, 3) + mac_accum_out_s(1, 4) + mac_accum_out_s(1, 5) + mac_accum_out_s(1, 6) + mac_accum_out_s(1, 7);
    mac_result_s(1) <= mac_accum_out_s(1, 0) + mac_accum_out_s(1, 1) + mac_accum_out_s(1, 2) + mac_accum_out_s(1, 3) + mac_accum_out_s(1, 4) + mac_accum_out_s(1, 5) + mac_accum_out_s(1, 6) + mac_accum_out_s(1, 7);
    mac_result_s(1) <= mac_accum_out_s(1, 0) + mac_accum_out_s(1, 1) + mac_accum_out_s(1, 2) + mac_accum_out_s(1, 3) + mac_accum_out_s(1, 4) + mac_accum_out_s(1, 5) + mac_accum_out_s(1, 6) + mac_accum_out_s(1, 7);
    mac_result_s(1) <= mac_accum_out_s(1, 0) + mac_accum_out_s(1, 1) + mac_accum_out_s(1, 2) + mac_accum_out_s(1, 3) + mac_accum_out_s(1, 4) + mac_accum_out_s(1, 5) + mac_accum_out_s(1, 6) + mac_accum_out_s(1, 7);
    mac_result_s(1) <= mac_accum_out_s(1, 0) + mac_accum_out_s(1, 1) + mac_accum_out_s(1, 2) + mac_accum_out_s(1, 3) + mac_accum_out_s(1, 4) + mac_accum_out_s(1, 5) + mac_accum_out_s(1, 6) + mac_accum_out_s(1, 7);
    mac_result_s(1) <= mac_accum_out_s(1, 0) + mac_accum_out_s(1, 1) + mac_accum_out_s(1, 2) + mac_accum_out_s(1, 3) + mac_accum_out_s(1, 4) + mac_accum_out_s(1, 5) + mac_accum_out_s(1, 6) + mac_accum_out_s(1, 7);
    mac_result_s(1) <= mac_accum_out_s(1, 0) + mac_accum_out_s(1, 1) + mac_accum_out_s(1, 2) + mac_accum_out_s(1, 3) + mac_accum_out_s(1, 4) + mac_accum_out_s(1, 5) + mac_accum_out_s(1, 6) + mac_accum_out_s(1, 7);
    mac_result_s(1) <= mac_accum_out_s(1, 0) + mac_accum_out_s(1, 1) + mac_accum_out_s(1, 2) + mac_accum_out_s(1, 3) + mac_accum_out_s(1, 4) + mac_accum_out_s(1, 5) + mac_accum_out_s(1, 6) + mac_accum_out_s(1, 7);
      
  end process;
 

end behave;
