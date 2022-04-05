library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity LG_Layer1 is
  Generic (
    -- CNN value generics
    INPUTS_WIDTH     : integer := 32;
    SCALE1           : integer := 1970659685;
    SCALE1_WIDTH     : integer := 32;
    POST_PROC_WIDTH  : integer := 32;
    ACT_WIDTH        : integer := 8;
    WEIGHTS_WIDTH    : integer := 8;
    ROUNDING_MASK    : integer := -8192;
    -- CNN control generics
    DTA_RDY_DLY_CLKS : integer := 20;
    -- MAC generics
    MAC_A_WIDTH      : integer := 32;
    MAC_B_WIDTH      : integer := 8;
    MAC_OUT_WIDTH    : integer := 45);
  Port (
    input_tensor     : in  std_logic_vector(3*3*2*INPUTS_WIDTH-1 downto 0);  -- (3x3x2) (x,y,z)
    output_vector    : out std_logic_vector(16*ACT_WIDTH-1 downto 0);        -- (16)
    data_rdy_in      : in  std_logic;                                        -- PS signal that it's done writing input_tensor
    data_rdy_out     : out std_logic;                                        -- PL signal that it's done processing
    rst_in           : in  std_logic;                                        -- active low reset
    clk              : in  std_logic);
end LG_Layer1;

architecture behave of LG_Layer1 is

  component LG_MAC_layer1
    generic (
      A_WIDTH   : integer := 32;
      B_WIDTH   : integer := 8;
      OUT_WIDTH : integer := 45);
    port (
      a         : in signed (MAC_A_WIDTH-1 downto 0);
      b         : in signed (MAC_B_WIDTH-1 downto 0);
      clk       : in std_logic;
      sload     : in std_logic;
      accum_out : out signed (MAC_OUT_WIDTH-1 downto 0));
  end component;
  
  -- definition of MAC A vector
  subtype gen_int_0 is signed (MAC_A_WIDTH-1 downto 0);
  type mac_a_matrix is array (0 to 15, 0 to 1) of gen_int_0;
  
  -- definition of MAC B vector
  subtype gen_int_1 is signed (MAC_B_WIDTH-1 downto 0);
  type mac_b_matrix is array (0 to 15, 0 to 1) of gen_int_1;
  
  -- definition of MAC OUT vector
  subtype gen_int_2 is signed (MAC_OUT_WIDTH-1 downto 0);
  type mac_out_matrix is array (0 to 15, 0 to 1) of gen_int_2;
  
  -- definition of MAC RESULT vector
  subtype gen_int_3 is signed (MAC_OUT_WIDTH-1 downto 0);
  type mac_result_matrix is array (0 to 15) of gen_int_3;
  
  -- MAC signals
  signal mac_a_s           : mac_a_matrix;
  signal mac_b_s           : mac_b_matrix;
  signal mac_sload_s       : std_logic;
  signal mac_accum_out_s   : mac_out_matrix;
  signal mac_result_s      : mac_result_matrix;

  -- definition of weights ram
  subtype gen_int_4 is signed (WEIGHTS_WIDTH-1 downto 0);
  type weight_matrix_layer1 is array (0 to 2, 0 to 2, 0 to 1, 0 to 15) of gen_int_4;
  
  signal weight_ram_s : weight_matrix_layer1;  -- Weight RAM (3x3x2x16)
  
  -- definition of input tensor
  subtype gen_int_5 is signed (INPUTS_WIDTH-1 downto 0);
  type input_matrix_layer1 is array (0 to 2, 0 to 2, 0 to 1) of gen_int_5;
  
  -- definition of output tensor
  subtype gen_int_6 is unsigned (ACT_WIDTH-1 downto 0);
  type output_vector_layer1 is array (0 to 15) of gen_int_6;

  -- signals for entity inputs and outputs
  signal input_tensor_s  : input_matrix_layer1 := (others => (others => (others => (others => '0'))));
  signal output_vector_s : output_vector_layer1 := (others => (others => '0'));
  signal scale1_s        : signed (SCALE1_WIDTH-1 downto 0) := (others => '0');
  signal data_rdy_in_s   : std_logic;
  signal data_rdy_out_s  : std_logic;
  signal data_ack_in_s   : std_logic;
  signal rst_in_s        : std_logic;
  
  type state is ( IDLE,                  -- idle state (reset frame index and MACs)
                  INIT_MAC,              -- One cycle for MAC to reset
                  EXEC_MAC,              -- CNN Layer 1 (Multiply-And-Add)
                  WAIT_MAC_0,
                  WAIT_MAC_1,
                  FETCH_MAC_RES,         -- fetch result and shift bits in range
                  RELU,                  -- apply relu activation function
                  SCALING,               -- apply scaling factor
                  INIT_ROUNDING,         -- prepare values for rounding
                  ROUNDING_0,            -- rounding
                  ROUNDING_1,            -- rounding
                  OUTPUT_LAYER_COUNTING, -- Increase output layer index (and repeat from INIT (or stop))
                  WAIT_FOR_ACK);         -- issue ready flag and wait for ACK from PS
                  
  signal statem_state : state := IDLE; -- stores state of state machine
  
  -- definition of post processing data
  subtype gen_int_7 is signed (POST_PROC_WIDTH-1 downto 0);
  type post_proc_vector is array (0 to 15) of gen_int_7;
  
  subtype gen_int_8 is signed (POST_PROC_WIDTH-1 downto 0); -- 32-bit
  --subtype gen_int_8 is signed (29-1 downto 0); -- 16-bit
  --subtype gen_int_8 is signed (21-1 downto 0); -- 8-bit
  type post_proc_vector_small is array (0 to 15) of gen_int_8;
  
  --signal output_index         : integer range 0 to 16-1;                -- running output index
  signal frame_index_1        : integer range 0 to 3-1;                 -- running frame index (y)
  signal frame_index_2        : integer range 0 to 3-1;                 -- running frame index (x)
  signal rdy_flag_count       : integer range 0 to DTA_RDY_DLY_CLKS-1;  -- leaves the output data ready flag for some cycles
  --signal mac_result_s         : signed (MAC_OUT_WIDTH-1 downto 0);      -- result of all MACs
  signal post_proc_temp0      : post_proc_vector_small;    -- bit-shifted MAC result
  signal post_proc_temp1      : post_proc_vector;    -- post Relu
  signal post_proc_temp2      : post_proc_vector;    -- post Scaling
  signal rounding_natural_num : post_proc_vector;    -- result without part behind comma
  signal rounding_fract_num   : post_proc_vector;    -- only the fractional part

begin

  -- CNN kernel weights (3,3,2,16)
  weight_ram_s(0, 0, 0, 0) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 0) <= to_signed(84, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 0) <= to_signed(27, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 0) <= to_signed(-57, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 0) <= to_signed(56, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 0) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 0) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 0) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 0) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 0) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 0) <= to_signed(-33, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 0) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 0) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 0) <= to_signed(63, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 0) <= to_signed(30, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 0) <= to_signed(-65, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 0) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 0) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 1) <= to_signed(39, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 1) <= to_signed(20, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 1) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 1) <= to_signed(88, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 1) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 1) <= to_signed(-36, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 1) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 1) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 1) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 1) <= to_signed(-62, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 1) <= to_signed(39, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 1) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 1) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 1) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 1) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 1) <= to_signed(78, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 1) <= to_signed(-33, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 1) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 2) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 2) <= to_signed(79, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 2) <= to_signed(39, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 2) <= to_signed(-77, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 2) <= to_signed(-94, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 2) <= to_signed(-28, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 2) <= to_signed(44, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 2) <= to_signed(-56, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 2) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 2) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 2) <= to_signed(68, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 2) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 2) <= to_signed(-115, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 2) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 2) <= to_signed(-14, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 2) <= to_signed(-44, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 2) <= to_signed(10, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 2) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 3) <= to_signed(84, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 3) <= to_signed(-64, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 3) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 3) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 3) <= to_signed(-46, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 3) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 3) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 3) <= to_signed(68, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 3) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 3) <= to_signed(57, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 3) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 3) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 3) <= to_signed(127, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 3) <= to_signed(-103, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 3) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 3) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 3) <= to_signed(-57, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 3) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 4) <= to_signed(34, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 4) <= to_signed(71, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 4) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 4) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 4) <= to_signed(-106, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 4) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 4) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 4) <= to_signed(38, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 4) <= to_signed(-32, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 4) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 4) <= to_signed(42, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 4) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 4) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 4) <= to_signed(41, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 4) <= to_signed(-34, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 4) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 4) <= to_signed(37, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 4) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 5) <= to_signed(-63, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 5) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 5) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 5) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 5) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 5) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 5) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 5) <= to_signed(52, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 5) <= to_signed(7, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 5) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 5) <= to_signed(-49, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 5) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 5) <= to_signed(31, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 5) <= to_signed(75, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 5) <= to_signed(26, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 5) <= to_signed(-44, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 5) <= to_signed(-66, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 5) <= to_signed(9, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 6) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 6) <= to_signed(-28, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 6) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 6) <= to_signed(25, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 6) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 6) <= to_signed(18, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 6) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 6) <= to_signed(-52, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 6) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 6) <= to_signed(-33, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 6) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 6) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 6) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 6) <= to_signed(-78, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 6) <= to_signed(-20, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 6) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 6) <= to_signed(42, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 6) <= to_signed(22, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 7) <= to_signed(-47, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 7) <= to_signed(86, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 7) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 7) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 7) <= to_signed(61, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 7) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 7) <= to_signed(-38, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 7) <= to_signed(-31, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 7) <= to_signed(-12, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 7) <= to_signed(29, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 7) <= to_signed(19, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 7) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 7) <= to_signed(32, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 7) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 7) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 7) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 7) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 7) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 8) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 8) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 8) <= to_signed(-19, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 8) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 8) <= to_signed(-60, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 8) <= to_signed(-29, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 8) <= to_signed(47, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 8) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 8) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 8) <= to_signed(60, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 8) <= to_signed(-31, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 8) <= to_signed(-17, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 8) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 8) <= to_signed(53, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 8) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 8) <= to_signed(38, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 8) <= to_signed(-38, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 8) <= to_signed(-30, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 9) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 9) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 9) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 9) <= to_signed(66, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 9) <= to_signed(21, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 9) <= to_signed(-11, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 9) <= to_signed(-63, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 9) <= to_signed(62, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 9) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 9) <= to_signed(-26, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 9) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 9) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 9) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 9) <= to_signed(71, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 9) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 9) <= to_signed(-51, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 9) <= to_signed(40, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 9) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 10) <= to_signed(-5, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 10) <= to_signed(48, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 10) <= to_signed(24, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 10) <= to_signed(5, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 10) <= to_signed(-26, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 10) <= to_signed(15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 10) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 10) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 10) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 10) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 10) <= to_signed(-103, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 10) <= to_signed(-29, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 10) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 10) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 10) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 10) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 10) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 10) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 11) <= to_signed(-25, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 11) <= to_signed(56, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 11) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 11) <= to_signed(-106, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 11) <= to_signed(98, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 11) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 11) <= to_signed(-35, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 11) <= to_signed(73, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 11) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 11) <= to_signed(76, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 11) <= to_signed(-32, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 11) <= to_signed(21, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 11) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 11) <= to_signed(-40, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 11) <= to_signed(1, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 11) <= to_signed(-70, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 11) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 11) <= to_signed(-8, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 12) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 12) <= to_signed(8, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 12) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 12) <= to_signed(-39, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 12) <= to_signed(59, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 12) <= to_signed(98, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 12) <= to_signed(-3, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 12) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 12) <= to_signed(49, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 12) <= to_signed(3, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 12) <= to_signed(-43, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 12) <= to_signed(-88, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 12) <= to_signed(-9, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 12) <= to_signed(33, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 12) <= to_signed(-49, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 12) <= to_signed(-36, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 12) <= to_signed(78, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 12) <= to_signed(45, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 13) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 13) <= to_signed(-20, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 13) <= to_signed(-2, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 13) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 13) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 13) <= to_signed(2, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 13) <= to_signed(35, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 13) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 13) <= to_signed(11, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 13) <= to_signed(-1, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 13) <= to_signed(-22, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 13) <= to_signed(-7, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 13) <= to_signed(54, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 13) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 13) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 13) <= to_signed(-31, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 13) <= to_signed(62, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 13) <= to_signed(-10, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 14) <= to_signed(-49, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 14) <= to_signed(-76, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 14) <= to_signed(-6, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 14) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 14) <= to_signed(40, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 14) <= to_signed(38, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 14) <= to_signed(47, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 14) <= to_signed(75, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 14) <= to_signed(13, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 14) <= to_signed(12, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 14) <= to_signed(-20, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 14) <= to_signed(4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 14) <= to_signed(-47, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 14) <= to_signed(-104, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 14) <= to_signed(6, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 14) <= to_signed(41, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 14) <= to_signed(49, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 14) <= to_signed(63, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 0, 15) <= to_signed(31, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 0, 15) <= to_signed(-62, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 0, 15) <= to_signed(-4, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 0, 15) <= to_signed(-50, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 0, 15) <= to_signed(-59, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 0, 15) <= to_signed(-27, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 0, 15) <= to_signed(54, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 0, 15) <= to_signed(70, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 0, 15) <= to_signed(23, WEIGHTS_WIDTH);
  weight_ram_s(0, 0, 1, 15) <= to_signed(-27, WEIGHTS_WIDTH);
  weight_ram_s(1, 0, 1, 15) <= to_signed(-15, WEIGHTS_WIDTH);
  weight_ram_s(2, 0, 1, 15) <= to_signed(0, WEIGHTS_WIDTH);
  weight_ram_s(0, 1, 1, 15) <= to_signed(-41, WEIGHTS_WIDTH);
  weight_ram_s(1, 1, 1, 15) <= to_signed(14, WEIGHTS_WIDTH);
  weight_ram_s(2, 1, 1, 15) <= to_signed(-18, WEIGHTS_WIDTH);
  weight_ram_s(0, 2, 1, 15) <= to_signed(-16, WEIGHTS_WIDTH);
  weight_ram_s(1, 2, 1, 15) <= to_signed(-13, WEIGHTS_WIDTH);
  weight_ram_s(2, 2, 1, 15) <= to_signed(-12, WEIGHTS_WIDTH);
  
  scale1_s                  <= to_signed(SCALE1, SCALE1_WIDTH);

  process(clk)  -- fetch inputs at rising clock (=Flip Flop)
  begin
    if (rising_edge (clk)) then
      
      input_tensor_s(0, 0, 0) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*0 downto INPUTS_WIDTH*0));
      input_tensor_s(0, 0, 1) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*1 downto INPUTS_WIDTH*1));
      input_tensor_s(0, 1, 0) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*2 downto INPUTS_WIDTH*2));
      input_tensor_s(0, 1, 1) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*3 downto INPUTS_WIDTH*3));
      input_tensor_s(0, 2, 0) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*4 downto INPUTS_WIDTH*4));
      input_tensor_s(0, 2, 1) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*5 downto INPUTS_WIDTH*5));
      input_tensor_s(1, 0, 0) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*6 downto INPUTS_WIDTH*6));
      input_tensor_s(1, 0, 1) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*7 downto INPUTS_WIDTH*7));
      input_tensor_s(1, 1, 0) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*8 downto INPUTS_WIDTH*8));
      input_tensor_s(1, 1, 1) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*9 downto INPUTS_WIDTH*9));
      input_tensor_s(1, 2, 0) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*10 downto INPUTS_WIDTH*10));
      input_tensor_s(1, 2, 1) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*11 downto INPUTS_WIDTH*11));
      input_tensor_s(2, 0, 0) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*12 downto INPUTS_WIDTH*12));
      input_tensor_s(2, 0, 1) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*13 downto INPUTS_WIDTH*13));
      input_tensor_s(2, 1, 0) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*14 downto INPUTS_WIDTH*14));
      input_tensor_s(2, 1, 1) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*15 downto INPUTS_WIDTH*15));
      input_tensor_s(2, 2, 0) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*16 downto INPUTS_WIDTH*16));
      input_tensor_s(2, 2, 1) <= signed(input_tensor(INPUTS_WIDTH-1+INPUTS_WIDTH*17 downto INPUTS_WIDTH*17));

      data_rdy_in_s  <= data_rdy_in;
      rst_in_s       <= rst_in;
    end if;
  end process;
  
  -- map output signals to ports
  output_vector(ACT_WIDTH-1+ACT_WIDTH*0 downto ACT_WIDTH*0) <= std_logic_vector(output_vector_s(0));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*1 downto ACT_WIDTH*1) <= std_logic_vector(output_vector_s(1));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*2 downto ACT_WIDTH*2) <= std_logic_vector(output_vector_s(2));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*3 downto ACT_WIDTH*3) <= std_logic_vector(output_vector_s(3));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*4 downto ACT_WIDTH*4) <= std_logic_vector(output_vector_s(4));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*5 downto ACT_WIDTH*5) <= std_logic_vector(output_vector_s(5));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*6 downto ACT_WIDTH*6) <= std_logic_vector(output_vector_s(6));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*7 downto ACT_WIDTH*7) <= std_logic_vector(output_vector_s(7));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*8 downto ACT_WIDTH*8) <= std_logic_vector(output_vector_s(8));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*9 downto ACT_WIDTH*9) <= std_logic_vector(output_vector_s(9));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*10 downto ACT_WIDTH*10) <= std_logic_vector(output_vector_s(10));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*11 downto ACT_WIDTH*11) <= std_logic_vector(output_vector_s(11));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*12 downto ACT_WIDTH*12) <= std_logic_vector(output_vector_s(12));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*13 downto ACT_WIDTH*13) <= std_logic_vector(output_vector_s(13));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*14 downto ACT_WIDTH*14) <= std_logic_vector(output_vector_s(14));
  output_vector(ACT_WIDTH-1+ACT_WIDTH*15 downto ACT_WIDTH*15) <= std_logic_vector(output_vector_s(15));
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
            if (frame_index_2 = 2) then             -- (frame_index_2++)
              frame_index_2 <= 0;
              if (frame_index_1 = 2) then           -- (frame_index_1++)
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
            statem_state <= RELU;
          
          when (RELU) =>  -- apply activation function
            statem_state <= SCALING;
            
          when (SCALING) =>  -- apply scaling factor
            statem_state <= INIT_ROUNDING;
          
          when (INIT_ROUNDING) =>  -- preperations for rounding
            statem_state <= ROUNDING_0;
          
          when (ROUNDING_0) =>  -- execute rounding
            statem_state <= ROUNDING_1;
          
          when (ROUNDING_1) =>  -- execute rounding and write to output vector
            statem_state <= OUTPUT_LAYER_COUNTING;
          
          when (OUTPUT_LAYER_COUNTING) =>  -- compute 16 output features (output_index++)
            --if (output_index = 15) then
              statem_state <= WAIT_FOR_ACK;
              --output_index <= 0;
            --else
              --output_index <= output_index + 1;
              --statem_state <= IDLE;
            --end if;
            
          when (WAIT_FOR_ACK) =>  -- wait for PS to receive data
            if (rdy_flag_count = DTA_RDY_DLY_CLKS-1) then
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
        else
          mac_sload_s <= '0';
          --mac1_sload_s <= '0';
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
        mac_a_s(1, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(1, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(2, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(2, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(3, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(3, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(4, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(4, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(5, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(5, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(6, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(6, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(7, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(7, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(8, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(8, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(9, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(9, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(10, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(10, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(11, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(11, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(12, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(12, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(13, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(13, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(14, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(14, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_a_s(15, 0) <= input_tensor_s(frame_index_2, frame_index_1, 0);
        mac_a_s(15, 1) <= input_tensor_s(frame_index_2, frame_index_1, 1);
        mac_b_s(0, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 0);
        mac_b_s(0, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 0);
        mac_b_s(1, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 1);
        mac_b_s(1, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 1);
        mac_b_s(2, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 2);
        mac_b_s(2, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 2);
        mac_b_s(3, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 3);
        mac_b_s(3, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 3);
        mac_b_s(4, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 4);
        mac_b_s(4, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 4);
        mac_b_s(5, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 5);
        mac_b_s(5, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 5);
        mac_b_s(6, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 6);
        mac_b_s(6, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 6);
        mac_b_s(7, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 7);
        mac_b_s(7, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 7);
        mac_b_s(8, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 8);
        mac_b_s(8, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 8);
        mac_b_s(9, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 9);
        mac_b_s(9, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 9);
        mac_b_s(10, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 10);
        mac_b_s(10, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 10);
        mac_b_s(11, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 11);
        mac_b_s(11, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 11);
        mac_b_s(12, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 12);
        mac_b_s(12, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 12);
        mac_b_s(13, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 13);
        mac_b_s(13, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 13);
        mac_b_s(14, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 14);
        mac_b_s(14, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 14);
        mac_b_s(15, 0) <= weight_ram_s(frame_index_2, frame_index_1, 0, 15);
        mac_b_s(15, 1) <= weight_ram_s(frame_index_2, frame_index_1, 1, 15);
      else
        mac_a_s(0, 0) <= (others => '0');
        mac_b_s(0, 0) <= (others => '0');
        mac_a_s(0, 1) <= (others => '0');
        mac_b_s(0, 1) <= (others => '0');
        mac_a_s(1, 0) <= (others => '0');
        mac_b_s(1, 0) <= (others => '0');
        mac_a_s(1, 1) <= (others => '0');
        mac_b_s(1, 1) <= (others => '0');
        mac_a_s(2, 0) <= (others => '0');
        mac_b_s(2, 0) <= (others => '0');
        mac_a_s(2, 1) <= (others => '0');
        mac_b_s(2, 1) <= (others => '0');
        mac_a_s(3, 0) <= (others => '0');
        mac_b_s(3, 0) <= (others => '0');
        mac_a_s(3, 1) <= (others => '0');
        mac_b_s(3, 1) <= (others => '0');
        mac_a_s(4, 0) <= (others => '0');
        mac_b_s(4, 0) <= (others => '0');
        mac_a_s(4, 1) <= (others => '0');
        mac_b_s(4, 1) <= (others => '0');
        mac_a_s(5, 0) <= (others => '0');
        mac_b_s(5, 0) <= (others => '0');
        mac_a_s(5, 1) <= (others => '0');
        mac_b_s(5, 1) <= (others => '0');
        mac_a_s(6, 0) <= (others => '0');
        mac_b_s(6, 0) <= (others => '0');
        mac_a_s(6, 1) <= (others => '0');
        mac_b_s(6, 1) <= (others => '0');
        mac_a_s(7, 0) <= (others => '0');
        mac_b_s(7, 0) <= (others => '0');
        mac_a_s(7, 1) <= (others => '0');
        mac_b_s(7, 1) <= (others => '0');
        mac_a_s(8, 0) <= (others => '0');
        mac_b_s(8, 0) <= (others => '0');
        mac_a_s(8, 1) <= (others => '0');
        mac_b_s(8, 1) <= (others => '0');
        mac_a_s(9, 0) <= (others => '0');
        mac_b_s(9, 0) <= (others => '0');
        mac_a_s(9, 1) <= (others => '0');
        mac_b_s(9, 1) <= (others => '0');
        mac_a_s(10, 0) <= (others => '0');
        mac_b_s(10, 0) <= (others => '0');
        mac_a_s(10, 1) <= (others => '0');
        mac_b_s(10, 1) <= (others => '0');
        mac_a_s(11, 0) <= (others => '0');
        mac_b_s(11, 0) <= (others => '0');
        mac_a_s(11, 1) <= (others => '0');
        mac_b_s(11, 1) <= (others => '0');
        mac_a_s(12, 0) <= (others => '0');
        mac_b_s(12, 0) <= (others => '0');
        mac_a_s(12, 1) <= (others => '0');
        mac_b_s(12, 1) <= (others => '0');
        mac_a_s(13, 0) <= (others => '0');
        mac_b_s(13, 0) <= (others => '0');
        mac_a_s(13, 1) <= (others => '0');
        mac_b_s(13, 1) <= (others => '0');
        mac_a_s(14, 0) <= (others => '0');
        mac_b_s(14, 0) <= (others => '0');
        mac_a_s(14, 1) <= (others => '0');
        mac_b_s(14, 1) <= (others => '0');
        mac_a_s(15, 0) <= (others => '0');
        mac_b_s(15, 0) <= (others => '0');
        mac_a_s(15, 1) <= (others => '0');
        mac_b_s(15, 1) <= (others => '0');
      end if;
    end if;
  end process;

  process(clk)  -- fetch result from MAC(s) (and bitshifting)
  begin
    if (rising_edge (clk)) then
      if (statem_state = FETCH_MAC_RES) then
          post_proc_temp0(0) <= resize(shift_right(mac_result_s(0), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13  -- 32-bit
          post_proc_temp0(1) <= resize(shift_right(mac_result_s(1), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(2) <= resize(shift_right(mac_result_s(2), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(3) <= resize(shift_right(mac_result_s(3), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(4) <= resize(shift_right(mac_result_s(4), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(5) <= resize(shift_right(mac_result_s(5), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(6) <= resize(shift_right(mac_result_s(6), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(7) <= resize(shift_right(mac_result_s(7), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(8) <= resize(shift_right(mac_result_s(8), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(9) <= resize(shift_right(mac_result_s(9), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(10) <= resize(shift_right(mac_result_s(10), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(11) <= resize(shift_right(mac_result_s(11), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(12) <= resize(shift_right(mac_result_s(12), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(13) <= resize(shift_right(mac_result_s(13), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(14) <= resize(shift_right(mac_result_s(14), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          post_proc_temp0(15) <= resize(shift_right(mac_result_s(15), MAC_OUT_WIDTH-POST_PROC_WIDTH), POST_PROC_WIDTH);  -- shift right 13
          --post_proc_temp0(0) <= resize(shift_right(mac_result_s(0), 0-0), 29);  -- shift right 13  -- 16-bit
          --post_proc_temp0(1) <= resize(shift_right(mac_result_s(1), 0-0), 29);  -- shift right 13
          --post_proc_temp0(2) <= resize(shift_right(mac_result_s(2), 0-0), 29);  -- shift right 13
          --post_proc_temp0(3) <= resize(shift_right(mac_result_s(3), 0-0), 29);  -- shift right 13
          --post_proc_temp0(4) <= resize(shift_right(mac_result_s(4), 0-0), 29);  -- shift right 13
          --post_proc_temp0(5) <= resize(shift_right(mac_result_s(5), 0-0), 29);  -- shift right 13
          --post_proc_temp0(6) <= resize(shift_right(mac_result_s(6), 0-0), 29);  -- shift right 13
          --post_proc_temp0(7) <= resize(shift_right(mac_result_s(7), 0-0), 29);  -- shift right 13
          --post_proc_temp0(8) <= resize(shift_right(mac_result_s(8), 0-0), 29);  -- shift right 13
          --post_proc_temp0(9) <= resize(shift_right(mac_result_s(9), 0-0), 29);  -- shift right 13
          --post_proc_temp0(10) <= resize(shift_right(mac_result_s(10), 0-0), 29);  -- shift right 13
          --post_proc_temp0(11) <= resize(shift_right(mac_result_s(11), 0-0), 29);  -- shift right 13
          --post_proc_temp0(12) <= resize(shift_right(mac_result_s(12), 0-0), 29);  -- shift right 13
          --post_proc_temp0(13) <= resize(shift_right(mac_result_s(13), 0-0), 29);  -- shift right 13
          --post_proc_temp0(14) <= resize(shift_right(mac_result_s(14), 0-0), 29);  -- shift right 13
          --post_proc_temp0(15) <= resize(shift_right(mac_result_s(15), 0-0), 29);  -- shift right 13
          --post_proc_temp0(0) <= resize(shift_right(mac_result_s(0), 0-0), 21);  -- shift right 13  -- 8-bit
          --post_proc_temp0(1) <= resize(shift_right(mac_result_s(1), 0-0), 21);  -- shift right 13
          --post_proc_temp0(2) <= resize(shift_right(mac_result_s(2), 0-0), 21);  -- shift right 13
          --post_proc_temp0(3) <= resize(shift_right(mac_result_s(3), 0-0), 21);  -- shift right 13
          --post_proc_temp0(4) <= resize(shift_right(mac_result_s(4), 0-0), 21);  -- shift right 13
          --post_proc_temp0(5) <= resize(shift_right(mac_result_s(5), 0-0), 21);  -- shift right 13
          --post_proc_temp0(6) <= resize(shift_right(mac_result_s(6), 0-0), 21);  -- shift right 13
          --post_proc_temp0(7) <= resize(shift_right(mac_result_s(7), 0-0), 21);  -- shift right 13
          --post_proc_temp0(8) <= resize(shift_right(mac_result_s(8), 0-0), 21);  -- shift right 13
          --post_proc_temp0(9) <= resize(shift_right(mac_result_s(9), 0-0), 21);  -- shift right 13
          --post_proc_temp0(10) <= resize(shift_right(mac_result_s(10), 0-0), 21);  -- shift right 13
          --post_proc_temp0(11) <= resize(shift_right(mac_result_s(11), 0-0), 21);  -- shift right 13
          --post_proc_temp0(12) <= resize(shift_right(mac_result_s(12), 0-0), 21);  -- shift right 13
          --post_proc_temp0(13) <= resize(shift_right(mac_result_s(13), 0-0), 21);  -- shift right 13
          --post_proc_temp0(14) <= resize(shift_right(mac_result_s(14), 0-0), 21);  -- shift right 13
          --post_proc_temp0(15) <= resize(shift_right(mac_result_s(15), 0-0), 21);  -- shift right 13
      end if;
    end if;
  end process;

  process(clk)  -- apply Relu activation function
  begin
    if (rising_edge (clk)) then
      if (statem_state = RELU) then
        if (post_proc_temp0(0) > 0) then
          post_proc_temp1(0) <= resize(post_proc_temp0(0), POST_PROC_WIDTH);
        else
          post_proc_temp1(0) <= (others => '0');
        end if;
        if (post_proc_temp0(1) > 0) then
          post_proc_temp1(1) <= resize(post_proc_temp0(1), POST_PROC_WIDTH);
        else
          post_proc_temp1(1) <= (others => '0');
        end if;
        if (post_proc_temp0(2) > 0) then
          post_proc_temp1(2) <= resize(post_proc_temp0(2), POST_PROC_WIDTH);
        else
          post_proc_temp1(2) <= (others => '0');
        end if;
        if (post_proc_temp0(3) > 0) then
          post_proc_temp1(3) <= resize(post_proc_temp0(3), POST_PROC_WIDTH);
        else
          post_proc_temp1(3) <= (others => '0');
        end if;
        if (post_proc_temp0(4) > 0) then
          post_proc_temp1(4) <= resize(post_proc_temp0(4), POST_PROC_WIDTH);
        else
          post_proc_temp1(4) <= (others => '0');
        end if;
        if (post_proc_temp0(5) > 0) then
          post_proc_temp1(5) <= resize(post_proc_temp0(5), POST_PROC_WIDTH);
        else
          post_proc_temp1(5) <= (others => '0');
        end if;
        if (post_proc_temp0(6) > 0) then
          post_proc_temp1(6) <= resize(post_proc_temp0(6), POST_PROC_WIDTH);
        else
          post_proc_temp1(6) <= (others => '0');
        end if;
        if (post_proc_temp0(7) > 0) then
          post_proc_temp1(7) <= resize(post_proc_temp0(7), POST_PROC_WIDTH);
        else
          post_proc_temp1(7) <= (others => '0');
        end if;
        if (post_proc_temp0(8) > 0) then
          post_proc_temp1(8) <= resize(post_proc_temp0(8), POST_PROC_WIDTH);
        else
          post_proc_temp1(8) <= (others => '0');
        end if;
        if (post_proc_temp0(9) > 0) then
          post_proc_temp1(9) <= resize(post_proc_temp0(9), POST_PROC_WIDTH);
        else
          post_proc_temp1(9) <= (others => '0');
        end if;
        if (post_proc_temp0(10) > 0) then
          post_proc_temp1(10) <= resize(post_proc_temp0(10), POST_PROC_WIDTH);
        else
          post_proc_temp1(10) <= (others => '0');
        end if;
        if (post_proc_temp0(11) > 0) then
          post_proc_temp1(11) <= resize(post_proc_temp0(11), POST_PROC_WIDTH);
        else
          post_proc_temp1(11) <= (others => '0');
        end if;
        if (post_proc_temp0(12) > 0) then
          post_proc_temp1(12) <= resize(post_proc_temp0(12), POST_PROC_WIDTH);
        else
          post_proc_temp1(12) <= (others => '0');
        end if;
        if (post_proc_temp0(13) > 0) then
          post_proc_temp1(13) <= resize(post_proc_temp0(13), POST_PROC_WIDTH);
        else
          post_proc_temp1(13) <= (others => '0');
        end if;
        if (post_proc_temp0(14) > 0) then
          post_proc_temp1(14) <= resize(post_proc_temp0(14), POST_PROC_WIDTH);
        else
          post_proc_temp1(14) <= (others => '0');
        end if;
        if (post_proc_temp0(15) > 0) then
          post_proc_temp1(15) <= resize(post_proc_temp0(15), POST_PROC_WIDTH);
        else
          post_proc_temp1(15) <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  process(clk)  -- apply scaling factor
  begin
    if (rising_edge (clk)) then
      if (statem_state = SCALING) then
          post_proc_temp2(0) <= resize(shift_right(post_proc_temp1(0) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(1) <= resize(shift_right(post_proc_temp1(1) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(2) <= resize(shift_right(post_proc_temp1(2) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(3) <= resize(shift_right(post_proc_temp1(3) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(4) <= resize(shift_right(post_proc_temp1(4) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(5) <= resize(shift_right(post_proc_temp1(5) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(6) <= resize(shift_right(post_proc_temp1(6) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(7) <= resize(shift_right(post_proc_temp1(7) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(8) <= resize(shift_right(post_proc_temp1(8) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(9) <= resize(shift_right(post_proc_temp1(9) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(10) <= resize(shift_right(post_proc_temp1(10) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(11) <= resize(shift_right(post_proc_temp1(11) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(12) <= resize(shift_right(post_proc_temp1(12) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(13) <= resize(shift_right(post_proc_temp1(13) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(14) <= resize(shift_right(post_proc_temp1(14) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
          post_proc_temp2(15) <= resize(shift_right(post_proc_temp1(15) * scale1_s, SCALE1_WIDTH), POST_PROC_WIDTH);
      end if;
    end if;
  end process;
  
  process(clk)  -- prepare values for rounding
  begin
    if (rising_edge (clk)) then
      if (statem_state = INIT_ROUNDING) then
        rounding_natural_num(0) <= post_proc_temp2(0) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(1) <= post_proc_temp2(1) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(2) <= post_proc_temp2(2) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(3) <= post_proc_temp2(3) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(4) <= post_proc_temp2(4) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(5) <= post_proc_temp2(5) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(6) <= post_proc_temp2(6) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(7) <= post_proc_temp2(7) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(8) <= post_proc_temp2(8) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(9) <= post_proc_temp2(9) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(10) <= post_proc_temp2(10) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(11) <= post_proc_temp2(11) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(12) <= post_proc_temp2(12) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(13) <= post_proc_temp2(13) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(14) <= post_proc_temp2(14) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
        rounding_natural_num(15) <= post_proc_temp2(15) AND to_signed(ROUNDING_MASK, POST_PROC_WIDTH);  -- 32/19:13
      end if;
    end if;
  end process;

  process(clk)  -- execute rounding
  begin
    if (rising_edge (clk)) then
      if (statem_state = ROUNDING_0) then
        rounding_fract_num(0) <= post_proc_temp2(0) - rounding_natural_num(0);
        rounding_fract_num(1) <= post_proc_temp2(1) - rounding_natural_num(1);
        rounding_fract_num(2) <= post_proc_temp2(2) - rounding_natural_num(2);
        rounding_fract_num(3) <= post_proc_temp2(3) - rounding_natural_num(3);
        rounding_fract_num(4) <= post_proc_temp2(4) - rounding_natural_num(4);
        rounding_fract_num(5) <= post_proc_temp2(5) - rounding_natural_num(5);
        rounding_fract_num(6) <= post_proc_temp2(6) - rounding_natural_num(6);
        rounding_fract_num(7) <= post_proc_temp2(7) - rounding_natural_num(7);
        rounding_fract_num(8) <= post_proc_temp2(8) - rounding_natural_num(8);
        rounding_fract_num(9) <= post_proc_temp2(9) - rounding_natural_num(9);
        rounding_fract_num(10) <= post_proc_temp2(10) - rounding_natural_num(10);
        rounding_fract_num(11) <= post_proc_temp2(11) - rounding_natural_num(11);
        rounding_fract_num(12) <= post_proc_temp2(12) - rounding_natural_num(12);
        rounding_fract_num(13) <= post_proc_temp2(13) - rounding_natural_num(13);
        rounding_fract_num(14) <= post_proc_temp2(14) - rounding_natural_num(14);
        rounding_fract_num(15) <= post_proc_temp2(15) - rounding_natural_num(15);
      end if;
    end if;
  end process;
  
  process(clk)  -- execute rounding and write to output_vector
  begin
    if (rising_edge (clk)) then
      if (statem_state = ROUNDING_1) then
        output_vector_s(0) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(0)) + unsigned(rounding_fract_num(0)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));  -- 32-bit
        output_vector_s(1) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(1)) + unsigned(rounding_fract_num(1)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(2) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(2)) + unsigned(rounding_fract_num(2)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(3) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(3)) + unsigned(rounding_fract_num(3)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(4) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(4)) + unsigned(rounding_fract_num(4)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(5) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(5)) + unsigned(rounding_fract_num(5)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(6) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(6)) + unsigned(rounding_fract_num(6)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(7) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(7)) + unsigned(rounding_fract_num(7)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(8) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(8)) + unsigned(rounding_fract_num(8)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(9) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(9)) + unsigned(rounding_fract_num(9)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(10) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(10)) + unsigned(rounding_fract_num(10)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(11) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(11)) + unsigned(rounding_fract_num(11)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(12) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(12)) + unsigned(rounding_fract_num(12)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(13) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(13)) + unsigned(rounding_fract_num(13)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(14) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(14)) + unsigned(rounding_fract_num(14)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        output_vector_s(15) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(15)) + unsigned(rounding_fract_num(15)), MAC_OUT_WIDTH-POST_PROC_WIDTH), ACT_WIDTH));
        --output_vector_s(0) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(0)) + unsigned(rounding_fract_num(0)), 13), ACT_WIDTH));  -- 16-bit
        --output_vector_s(1) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(1)) + unsigned(rounding_fract_num(1)), 13), ACT_WIDTH));
        --output_vector_s(2) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(2)) + unsigned(rounding_fract_num(2)), 13), ACT_WIDTH));
        --output_vector_s(3) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(3)) + unsigned(rounding_fract_num(3)), 13), ACT_WIDTH));
        --output_vector_s(4) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(4)) + unsigned(rounding_fract_num(4)), 13), ACT_WIDTH));
        --output_vector_s(5) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(5)) + unsigned(rounding_fract_num(5)), 13), ACT_WIDTH));
        --output_vector_s(6) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(6)) + unsigned(rounding_fract_num(6)), 13), ACT_WIDTH));
        --output_vector_s(7) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(7)) + unsigned(rounding_fract_num(7)), 13), ACT_WIDTH));
        --output_vector_s(8) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(8)) + unsigned(rounding_fract_num(8)), 13), ACT_WIDTH));
        --output_vector_s(9) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(9)) + unsigned(rounding_fract_num(9)), 13), ACT_WIDTH));
        --output_vector_s(10) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(10)) + unsigned(rounding_fract_num(10)), 13), ACT_WIDTH));
        --output_vector_s(11) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(11)) + unsigned(rounding_fract_num(11)), 13), ACT_WIDTH));
        --output_vector_s(12) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(12)) + unsigned(rounding_fract_num(12)), 13), ACT_WIDTH));
        --output_vector_s(13) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(13)) + unsigned(rounding_fract_num(13)), 13), ACT_WIDTH));
        --output_vector_s(14) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(14)) + unsigned(rounding_fract_num(14)), 13), ACT_WIDTH));
        --output_vector_s(15) <= unsigned(resize(shift_right(unsigned(post_proc_temp2(15)) + unsigned(rounding_fract_num(15)), 13), ACT_WIDTH));
      end if;
    end if;
  end process;

  MAC00_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(0, 0),
    b         => mac_b_s(0, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(0, 0));
  
  MAC01_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(0, 1),
    b         => mac_b_s(0, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(0, 1));
  
  MAC10_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(1, 0),
    b         => mac_b_s(1, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(1, 0));
  
  MAC11_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(1, 1),
    b         => mac_b_s(1, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(1, 1));
  
  MAC20_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(2, 0),
    b         => mac_b_s(2, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(2, 0));
  
  MAC21_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(2, 1),
    b         => mac_b_s(2, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(2, 1));
  
  MAC30_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(3, 0),
    b         => mac_b_s(3, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(3, 0));
  
  MAC31_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(3, 1),
    b         => mac_b_s(3, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(3, 1));
  
  MAC40_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(4, 0),
    b         => mac_b_s(4, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(4, 0));
  
  MAC41_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(4, 1),
    b         => mac_b_s(4, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(4, 1));
  
  MAC50_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(5, 0),
    b         => mac_b_s(5, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(5, 0));
  
  MAC51_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(5, 1),
    b         => mac_b_s(5, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(5, 1));
  
  MAC60_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(6, 0),
    b         => mac_b_s(6, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(6, 0));
  
  MAC61_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(6, 1),
    b         => mac_b_s(6, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(6, 1));
  
  MAC70_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(7, 0),
    b         => mac_b_s(7, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(7, 0));
  
  MAC71_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(7, 1),
    b         => mac_b_s(7, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(7, 1));
  
  MAC80_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(8, 0),
    b         => mac_b_s(8, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(8, 0));
  
  MAC81_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(8, 1),
    b         => mac_b_s(8, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(8, 1));
  
  MAC90_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(9, 0),
    b         => mac_b_s(9, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(9, 0));
  
  MAC91_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(9, 1),
    b         => mac_b_s(9, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(9, 1));
  
  MAC100_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(10, 0),
    b         => mac_b_s(10, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(10, 0));
  
  MAC101_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(10, 1),
    b         => mac_b_s(10, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(10, 1));
  
  MAC110_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(11, 0),
    b         => mac_b_s(11, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(11, 0));
  
  MAC111_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(11, 1),
    b         => mac_b_s(11, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(11, 1));
  
  MAC120_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(12, 0),
    b         => mac_b_s(12, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(12, 0));
  
  MAC121_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(12, 1),
    b         => mac_b_s(12, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(12, 1));
  
  MAC130_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(13, 0),
    b         => mac_b_s(13, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(13, 0));
  
  MAC131_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(13, 1),
    b         => mac_b_s(13, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(13, 1));
  
  MAC140_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(14, 0),
    b         => mac_b_s(14, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(14, 0));
  
  MAC141_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(14, 1),
    b         => mac_b_s(14, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(14, 1));
  
  MAC150_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(15, 0),
    b         => mac_b_s(15, 0),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(15, 0));
  
  MAC151_Instance : LG_MAC_layer1
  generic map (
    A_WIDTH   => MAC_A_WIDTH,
    B_WIDTH   => MAC_B_WIDTH,
    OUT_WIDTH => MAC_OUT_WIDTH)
  port map (
    a         => mac_a_s(15, 1),
    b         => mac_b_s(15, 1),
    clk       => clk,
    sload     => mac_sload_s,
    accum_out => mac_accum_out_s(15, 1));
    
  process (mac_accum_out_s(0, 0), mac_accum_out_s(0, 1), mac_accum_out_s(1, 0), mac_accum_out_s(1, 1), mac_accum_out_s(2, 0), mac_accum_out_s(2, 1), mac_accum_out_s(3, 0), mac_accum_out_s(3, 1), mac_accum_out_s(4, 0), mac_accum_out_s(4, 1), mac_accum_out_s(5, 0), mac_accum_out_s(5, 1), mac_accum_out_s(6, 0), mac_accum_out_s(6, 1), mac_accum_out_s(7, 0), mac_accum_out_s(7, 1), mac_accum_out_s(8, 0), mac_accum_out_s(8, 1), mac_accum_out_s(9, 0), mac_accum_out_s(9, 1), mac_accum_out_s(10, 0), mac_accum_out_s(10, 1), mac_accum_out_s(11, 0), mac_accum_out_s(11, 1), mac_accum_out_s(12, 0), mac_accum_out_s(12, 1), mac_accum_out_s(13, 0), mac_accum_out_s(13, 1), mac_accum_out_s(14, 0), mac_accum_out_s(14, 1), mac_accum_out_s(15, 0), mac_accum_out_s(15, 1)) 
  begin
    
    mac_result_s(0) <= mac_accum_out_s(0, 0) + mac_accum_out_s(0, 1);
    mac_result_s(1) <= mac_accum_out_s(1, 0) + mac_accum_out_s(1, 1);
    mac_result_s(2) <= mac_accum_out_s(2, 0) + mac_accum_out_s(2, 1);
    mac_result_s(3) <= mac_accum_out_s(3, 0) + mac_accum_out_s(3, 1);
    mac_result_s(4) <= mac_accum_out_s(4, 0) + mac_accum_out_s(4, 1);
    mac_result_s(5) <= mac_accum_out_s(5, 0) + mac_accum_out_s(5, 1);
    mac_result_s(6) <= mac_accum_out_s(6, 0) + mac_accum_out_s(6, 1);
    mac_result_s(7) <= mac_accum_out_s(7, 0) + mac_accum_out_s(7, 1);
    mac_result_s(8) <= mac_accum_out_s(8, 0) + mac_accum_out_s(8, 1);
    mac_result_s(9) <= mac_accum_out_s(9, 0) + mac_accum_out_s(9, 1);
    mac_result_s(10) <= mac_accum_out_s(10, 0) + mac_accum_out_s(10, 1);
    mac_result_s(11) <= mac_accum_out_s(11, 0) + mac_accum_out_s(11, 1);
    mac_result_s(12) <= mac_accum_out_s(12, 0) + mac_accum_out_s(12, 1);
    mac_result_s(13) <= mac_accum_out_s(13, 0) + mac_accum_out_s(13, 1);
    mac_result_s(14) <= mac_accum_out_s(14, 0) + mac_accum_out_s(14, 1);
    mac_result_s(15) <= mac_accum_out_s(15, 0) + mac_accum_out_s(15, 1);
      
  end process;
 

end behave;
