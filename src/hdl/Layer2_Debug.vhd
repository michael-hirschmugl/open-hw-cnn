library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Layer2_Debug is
    Generic (
    -- CNN value generics Layer 2
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
        -- MAC generics
        MAC_LAYER2_A_WIDTH        : integer := 8;
        MAC_LAYER2_B_WIDTH        : integer := 8;
        MAC_LAYER2_OUT_WIDTH      : integer := 24);
    Port ( clk                    : in STD_LOGIC;
           layer1_mem_wr_data     : in std_logic_vector(127 downto 0);
           layer1_mem_rd_data     : out std_logic_vector(127 downto 0);
           layer1_mem_address     : in integer range 0 to 96*96-1;
           layer1_mem_address_out : out integer range 0 to 96*96-1;
           layer1_mem_we          : in std_logic;
           layer1_mem_re          : in std_logic;
           layer2_mem_rd_data     : out std_logic_vector(63 downto 0);
           layer2_mem_address     : in integer range 0 to 96*96-1;
           layer2_mem_address_out : out integer range 0 to 96*96-1;
           layer2_mem_re          : in std_logic;
           layer2_INIT            : in std_logic;
           layer2_index_x         : out signed(7 downto 0);
           layer2_index_y         : out signed(7 downto 0);
           layer2_kernel_x        : out signed(2 downto 0);
           layer2_kernel_y        : out signed(2 downto 0);
           layer2_address_x       : out signed(7 downto 0);
           layer2_address_y       : out signed(7 downto 0);
           layer2_address         : out unsigned(17 downto 0);
           --layer2_prev_output     : out signed(4 downto 0);
           layer2_data_rdy_in     : out std_logic;
           layer2_data_rdy_out    : out std_logic;
           layer2_input           : out input_matrix_layer2_uint8;
           layer2_output          : out output_vector_uint8 (0 to 7);
           layer2_address_part1   : out unsigned(17 downto 0);
           layer2_address_part2   : out unsigned(17 downto 0);
           layer2_mem_we          : out std_logic;
           layer2_mem_wr_data     : out std_logic_vector(63 downto 0);
           reset                  : in std_logic);
end Layer2_Debug;

architecture Behavioral of Layer2_Debug is

  -- layer 1 RAM component
  component layer1_output_mem
    Port (
      clk           : in std_logic;
      block_address : in integer range 0 to 96*96-1;  -- pixels in one row
      we            : in std_logic;
      re            : in std_logic;
      data_i        : in std_logic_vector(127 downto 0);
      data_o        : out std_logic_vector(127 downto 0));
    end component;
  
  -- layer 2 RAM component
  component layer2_output_mem
    Port (
      clk           : in std_logic;
      block_address : in integer range 0 to 96*96-1;  -- pixels in one row
      we            : in std_logic;
      re            : in std_logic;
      data_i        : in std_logic_vector(63 downto 0);
      data_o        : out std_logic_vector(63 downto 0));
    end component;

  -- layer 2 component
  component LG_Layer2
    Generic (
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
      MAC_LAYER2_A_WIDTH      : integer := 8;
      MAC_LAYER2_B_WIDTH      : integer := 8;
      MAC_LAYER2_OUT_WIDTH    : integer := 24);
    Port (
      input_tensor            : in  input_matrix_layer2_uint8;     -- (3x3x16) (x,y,z)
      output_vector           : out output_vector_uint8 (0 to 7);  -- (8)
      data_rdy_in             : in  std_logic;                     -- PS signal that it's done writing input_tensor
      data_rdy_out            : out std_logic;                     -- PL signal that it's done processing
      rst_in                  : in  std_logic;                     -- active low reset
      clk                     : in  std_logic);
    end component;
    
    -- layer 2 signals
    signal input_tensor_layer2_s     : input_matrix_layer2_uint8;        -- (3x3x16) (x,y,z)
    signal output_vector_layer2_s    : output_vector_uint8 (0 to 7);     -- (8)
    signal data_rdy_in_layer2_s      : std_logic;                        -- PS signal that it's done writing input_tensor
    signal data_rdy_out_layer2_s     : std_logic;
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
    -- signals for all layers
    signal rst_in_s                  : std_logic;
    
    -- layer 1 ram signals
    signal layer1_mem_wr_data_s     : std_logic_vector(127 downto 0) := (others => '0');
    signal layer1_mem_rd_data_s     : std_logic_vector(127 downto 0) := (others => '0');
    signal layer1_mem_address_s     : integer range 0 to 96*96-1 := 0;
    signal layer1_mem_address_out_s : integer range 0 to 96*96-1;
    signal layer1_mem_we_s          : std_logic := '0';  -- write enable for the layer1 output ram
    signal layer1_mem_re_s          : std_logic := '0';  -- read enable for the layer1 output ram
    
    -- layer 2 ram signals
     signal layer2_mem_wr_data_s     : std_logic_vector(63 downto 0) := (others => '0');
     signal layer2_mem_rd_data_s     : std_logic_vector(63 downto 0) := (others => '0');
     signal layer2_mem_address_s     : integer range 0 to 96*96-1 := 0;
     signal layer2_mem_address_out_s : integer range 0 to 96*96-1;
     signal layer2_mem_we_s          : std_logic := '0';  -- write enable for the layer2 output ram
     signal layer2_mem_re_s          : std_logic := '0';  -- read enable for the layer2 output ram
     --signal layer2_mem_shift_steps_s : integer range 0 to 8-1 := 0;  -- 8 steps are needed to store all outputs
     signal layer2_mem_wr_index_s    : integer range 0 to 96*96-1 := 0;  -- this is the running index in order to store values in ram

    
    type state is ( TEST,
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
                    DONE_LAYER2
                  );
    
    signal statem_state_s   : state := TEST;
    
begin

  layer1_mem_address_out   <= layer1_mem_address_out_s;
  layer1_mem_address_out_s <= layer1_mem_address_s;
  layer1_mem_we_s          <= layer1_mem_we;
  layer1_mem_re_s          <= layer1_mem_re;
  layer1_mem_wr_data_s     <= layer1_mem_wr_data;
  layer1_mem_rd_data       <= layer1_mem_rd_data_s;
  
  layer2_index_x      <= layer2_index_x_s;
  layer2_index_y      <= layer2_index_y_s;
  layer2_kernel_x     <= layer2_kernel_x_s;
  layer2_kernel_y     <= layer2_kernel_y_s;
  --layer2_prev_output  <= layer2_prev_output_s;
  layer2_data_rdy_in  <= data_rdy_in_layer2_s;
  layer2_data_rdy_out <= data_rdy_out_layer2_s;
  layer2_address      <= layer2_address_s;
  layer2_address_x    <= layer2_address_x_s;
  layer2_address_y    <= layer2_address_y_s;
  layer2_input        <= input_tensor_layer2_s;
  layer2_output       <= output_vector_layer2_s;
  
  layer2_address_part1 <= layer2_address_part1_s;
  layer2_address_part2 <= layer2_address_part2_s;
  
  layer2_mem_rd_data  <= layer2_mem_rd_data_s;
  
  layer2_mem_we <= layer2_mem_we_s;
  
  layer2_mem_wr_data <= layer2_mem_wr_data_s;
  
  layer2_mem_address_out <= layer2_mem_address_s;
  
  
  
  -- logic for LOADING ADDRESSES in layer 1 RAM
  -- addresses are only taken from computation in states LOAD_LAYER2, PIPE_DELAY0_LAYER2, PIPE_DELAY1_LAYER2 and PIPE_DELAY2_LAYER2
  -- if the index is out of bounds, the address is set to 0.
  -- otherwise not changed
  process (clk)
    begin
      if rising_edge(clk) then
        if (statem_state_s = LOAD_LAYER2) or (statem_state_s = PIPE_DELAY0_LAYER2) or (statem_state_s = PIPE_DELAY1_LAYER2) or (statem_state_s = PIPE_DELAY2_LAYER2) or (statem_state_s = PIPE_DELAY3_LAYER2) then
          if (layer2_address_x_dld1_s >= 0) and (layer2_address_x_dld1_s < 96) and (layer2_address_y_dld1_s >= 0) and (layer2_address_y_dld1_s < 96) then
            layer1_mem_address_s <= to_integer(layer2_address_s);
          else
            layer1_mem_address_s <= 0;
          end if;
        else
          layer1_mem_address_s <= layer1_mem_address;
        end if;
      end if;
  end process;
  
  -- logic for READING DATA from layer 1 RAM
  -- data is only read from output of layer 1 RAM in states LOAD_LAYER2, PIPE_DELAY0_LAYER2, PIPE_DELAY1_LAYER2 and PIPE_DELAY2_LAYER2
  -- if the index is out of bounds, the data (for input of layer 2) is set to 0.
  -- otherwise, the input of layer 2 is not changed.
  process (clk)
    begin
      if rising_edge(clk) then
        if (statem_state_s = LOAD_LAYER2) or (statem_state_s = PIPE_DELAY0_LAYER2) or (statem_state_s = PIPE_DELAY1_LAYER2) or (statem_state_s = PIPE_DELAY2_LAYER2) or (statem_state_s = PIPE_DELAY3_LAYER2) or (statem_state_s = START_LAYER2) then
          if (layer2_address_x_dld3_s >= 0) and (layer2_address_x_dld3_s < 96) and (layer2_address_y_dld3_s >= 0) and (layer2_address_y_dld3_s < 96) then
             for g in 0 to 16-1 loop
              input_tensor_layer2_s(to_integer(layer2_kernel_x_dld4_s), to_integer(layer2_kernel_y_dld4_s), g) <= unsigned(layer1_mem_rd_data_s(7+8*g downto 8*g));
            end loop;
          else
            for g in 0 to 16-1 loop
              input_tensor_layer2_s(to_integer(layer2_kernel_x_dld4_s), to_integer(layer2_kernel_y_dld4_s), g) <= (others => '0');
            end loop;
          end if;
        end if;
      end if;
  end process;
  
  -- pipeline logic
  process (clk)
    begin
      if rising_edge(clk) then
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
      end if;
  end process;

  -- address computation for layer 1 RAM
  process (clk)
  begin
    if rising_edge(clk) then
      layer2_address_x_s     <= resize(layer2_index_x_s + layer2_kernel_x_s - 1, 8);
    end if;
  end process;
  
  process (clk)
  begin
    if rising_edge(clk) then
      layer2_address_y_s     <= resize(layer2_index_y_s + layer2_kernel_y_s - 1, 8);
    end if;
  end process;
  
  process (clk)
  begin
    if rising_edge(clk) then
      layer2_address_part1_s <= resize(resize(unsigned(layer2_address_x_s), 18) * 1, 18);
    end if;
  end process;
  
  process (clk)
  begin
    if rising_edge(clk) then
      layer2_address_part2_s <= resize(resize(unsigned(layer2_address_y_s), 18) * 96, 18);
    end if;
  end process;
  
  process (clk)
  begin
    if rising_edge(clk) then
      --layer2_address_s       <= unsigned(resize(layer2_address_part1_s + layer2_address_part2_s + unsigned(layer2_prev_output_dld1_s), 18));
      layer2_address_s       <= unsigned(resize(layer2_address_part1_s + layer2_address_part2_s, 18));
    end if;
  end process;
  
  -- writing results to layer 2 RAM
  -- If the statemachine is in the writing state (writing results of layer 2), the write enable bit is set and address as well as
  -- data are taken from the computational logic.
  -- Otherwise write enable bit is always 0 and data & address too.
  process( clk ) is
  begin
    if (rising_edge (clk)) then
      if (statem_state_s = WRITE_RAM_LAYER2) then
        layer2_mem_we_s <= '1';
        layer2_mem_address_s <= layer2_mem_wr_index_s;
        for g in 0 to 8-1 loop
          layer2_mem_wr_data_s(7+8*g downto 8*g) <= std_logic_vector(output_vector_layer2_s(g));
        end loop;
      else
        if (statem_state_s = DONE_LAYER2) then
          layer2_mem_we_s <= '0';
          layer2_mem_address_s <= layer2_mem_address;
          layer2_mem_wr_data_s <= (others => '0');
        else
          layer2_mem_we_s <= '0';
          layer2_mem_address_s <= 0;
          layer2_mem_wr_data_s <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  -- logic for layer 1 RAM read enable bit
  process( clk ) is
  begin
    if (rising_edge (clk)) then
      if reset = '0' then
        layer1_mem_re_s <= '0';
      else
        if (statem_state_s = INIT_LAYER2) or (statem_state_s = LOAD_LAYER2) or (statem_state_s = PIPE_DELAY0_LAYER2) or (statem_state_s = PIPE_DELAY1_LAYER2) or (statem_state_s = PIPE_DELAY2_LAYER2) or (statem_state_s = PIPE_DELAY3_LAYER2) then
          layer1_mem_re_s <= '1';
        else
          if (statem_state_s = CHECK_PROGRESS_LAYER2) and ((layer2_index_x_s < 95) and (layer2_index_y_s < 95)) then
            layer1_mem_re_s <= '1';
          else
            if (statem_state_s = DONE_LAYER2) then
              layer1_mem_re_s <= layer1_mem_re_s;
            else
              layer1_mem_re_s <= '0';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- logic for layer 2 RAM read enable bit
  -- not important in this simulation
  process( clk ) is
  begin
    if (rising_edge (clk)) then
      if reset = '0' then
        layer2_mem_re_s <= '0';
      else
        if (statem_state_s = DONE_LAYER2) then
          layer2_mem_re_s <= layer2_mem_re;
        else
        end if;
      end if;
    end if;
  end process;
  
  -- logic for layer 2 data ready in flag
  process( clk ) is
  begin
    if (rising_edge (clk)) then
      if reset = '0' then
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
  
  
  rst_in_s <= reset;

  -- ram for results of layer1
  layer1_output_mem_instance0 : layer1_output_mem
    Port map (
      clk           => clk,
      block_address => layer1_mem_address_s,
      we            => layer1_mem_we_s,
      re            => layer1_mem_re_s,
      data_i        => layer1_mem_wr_data_s,
      data_o        => layer1_mem_rd_data_s
    );
  
  -- ram for results of layer2
  layer2_output_mem_instance0 : layer2_output_mem
    Port map (
      clk           => clk,
      block_address => layer2_mem_address_s,
      we            => layer2_mem_we_s,
      re            => layer2_mem_re_s,
      data_i        => layer2_mem_wr_data_s,
      data_o        => layer2_mem_rd_data_s
    );

  LG_Layer2_instance0 : LG_Layer2
    Generic map (
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
      -- MAC generics
      MAC_LAYER2_A_WIDTH      => MAC_LAYER2_A_WIDTH,
      MAC_LAYER2_B_WIDTH      => MAC_LAYER2_B_WIDTH,
      MAC_LAYER2_OUT_WIDTH    => MAC_LAYER2_OUT_WIDTH)
    Port map (
      input_tensor  => input_tensor_layer2_s,
      output_vector => output_vector_layer2_s,
      data_rdy_in   => data_rdy_in_layer2_s,
      data_rdy_out  => data_rdy_out_layer2_s,
      rst_in        => rst_in_s,
      clk           => clk
    );
    
    process (clk)
    begin
      if rising_edge(clk) then
        if reset = '0' then
          statem_state_s        <= TEST;
          layer2_index_x_s      <= to_signed(0, 8);
          layer2_index_y_s      <= to_signed(0, 8);
          layer2_kernel_x_s     <= to_signed(0, 3);
          layer2_kernel_y_s     <= to_signed(0, 3);
          --layer2_prev_output_s  <= to_signed(0, 5);
          layer2_mem_wr_index_s <= 0;
        else
          case (statem_state_s) is
            when (TEST) =>
              if (layer2_INIT = '1') then
                statem_state_s        <= INIT_LAYER2;
                layer2_mem_wr_index_s <= 0;
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
                  statem_state_s   <= DONE_LAYER2;
                else
                  layer2_index_y_s <= layer2_index_y_s + 1;
                  statem_state_s   <= LOAD_LAYER2;
                end if;
              else
                layer2_index_x_s   <= layer2_index_x_s + 1;
                statem_state_s     <= LOAD_LAYER2;
              end if;
            
            when (DONE_LAYER2) =>
              statem_state_s <= DONE_LAYER2;

            when others =>
              statem_state_s <= TEST;

          end case;
        end if;
      end if;
    end process;


end Behavioral;
