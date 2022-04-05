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

entity Layer3_Debug is
    Generic (
    -- CNN value generics Layer 3
      SCALE3                  : integer := 1540923957;
      LAYER3_CONV_BIAS0       : integer := -1443;
      LAYER3_CONV_BIAS1       : integer := -196;
      -- MAC generics
      MAC_LAYER3_A_WIDTH      : integer := 8;
      MAC_LAYER3_B_WIDTH      : integer := 8;
      MAC_LAYER3_OUT_WIDTH    : integer := 23);
    Port ( clk                    : in STD_LOGIC;
           layer2_mem_wr_data     : in uint8;
           layer2_mem_rd_data     : out uint8;
           layer2_mem_address     : in integer range 0 to 96*96*8-1;
           layer2_mem_address_out : out integer range 0 to 96*96*8-1;
           layer2_mem_we          : in std_logic;
           layer2_mem_re          : in std_logic;
           layer3_mem_rd_data     : out int32;
           layer3_mem_address     : in integer range 0 to 96*96*2-1;
           layer3_mem_address_out : out integer range 0 to 96*96*2-1;
           layer3_mem_re          : in std_logic;
           layer3_INIT            : in std_logic;
           layer3_index_x         : out signed(7 downto 0);
           layer3_index_y         : out signed(7 downto 0);
           layer3_kernel_x        : out signed(2 downto 0);
           layer3_kernel_y        : out signed(2 downto 0);
           layer3_address_x       : out signed(7 downto 0);
           layer3_address_y       : out signed(7 downto 0);
           layer3_address         : out unsigned(15 downto 0);
           layer3_prev_output     : out signed(4 downto 0);
           layer3_data_rdy_in     : out std_logic;
           layer3_data_rdy_out    : out std_logic;
           layer3_input           : out input_matrix_layer3_uint8;
           layer3_output          : out output_vector_int32 (0 to 1);
           layer3_address_part1   : out unsigned(15 downto 0);
           layer3_address_part2   : out unsigned(15 downto 0);
           layer3_mem_we          : out std_logic;
           layer3_mem_wr_data     : out int32;
           reset                  : in std_logic);
end Layer3_Debug;

architecture Behavioral of Layer3_Debug is

  -- layer 2 RAM component
  component layer2_output_mem
    Port (
      clk           : in std_logic;
      block_address : in integer range 0 to 96*96*8-1;  -- pixels in one row
      we            : in std_logic;
      re            : in std_logic;
      data_i        : in uint8;
      data_o        : out uint8);
    end component;
  
  -- layer 3 RAM component
  component layer3_output_mem
    Port (
      clk           : in std_logic;
      block_address : in integer range 0 to 96*96*2-1;  -- pixels in one row
      we            : in std_logic;
      re            : in std_logic;
      data_i        : in int32;
      data_o        : out int32);
    end component;

  -- layer 3 component
  component LG_Layer3
    Generic (
      SCALE3                  : integer := 1540923957;
      LAYER3_CONV_BIAS0       : integer := -1443;
      LAYER3_CONV_BIAS1       : integer := -196;
      MAC_LAYER3_A_WIDTH      : integer := 8;
      MAC_LAYER3_B_WIDTH      : integer := 8;
      MAC_LAYER3_OUT_WIDTH    : integer := 23);
    Port (
      input_tensor            : in  input_matrix_layer3_uint8;     -- (3x3x8) (x,y,z)
      output_vector           : out output_vector_int32 (0 to 1);  -- (2)
      data_rdy_in             : in  std_logic;                     -- PS signal that it's done writing input_tensor
      data_rdy_out            : out std_logic;                     -- PL signal that it's done processing
      rst_in                  : in  std_logic;                     -- active low reset
      clk                     : in  std_logic);
    end component;
    
    -- layer 3 signals
    signal input_tensor_layer3_s     : input_matrix_layer3_uint8;        -- (3x3x8) (x,y,z)
    signal output_vector_layer3_s    : output_vector_int32 (0 to 1);     -- (2)
    signal data_rdy_in_layer3_s      : std_logic;                        -- PS signal that it's done writing input_tensor
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
    signal layer3_prev_output_s      : signed(4 downto 0) := (others => '0');
    signal layer3_prev_output_dld0_s : signed(4 downto 0) := (others => '0');
    signal layer3_prev_output_dld1_s : signed(4 downto 0) := (others => '0');
    signal layer3_prev_output_dld2_s : signed(4 downto 0) := (others => '0');
    signal layer3_prev_output_dld3_s : signed(4 downto 0) := (others => '0');
    signal layer3_prev_output_dld4_s : signed(4 downto 0) := (others => '0');
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
    signal layer3_address_part1_s    : unsigned(15 downto 0);
    signal layer3_address_part2_s    : unsigned(15 downto 0);

    signal layer3_address_s          : unsigned(15 downto 0);
    -- signals for all layers
    signal rst_in_s                  : std_logic;
    
    -- layer 2 ram signals
    signal layer2_mem_wr_data_s     : uint8 := (others => '0');
    signal layer2_mem_rd_data_s     : uint8 := (others => '0');
    signal layer2_mem_address_s     : integer range 0 to 96*96*8-1 := 0;
    signal layer2_mem_address_out_s : integer range 0 to 96*96*8-1;
    signal layer2_mem_we_s          : std_logic := '0';  -- write enable for the layer2 output ram
    signal layer2_mem_re_s          : std_logic := '0';  -- read enable for the layer2 output ram
    
    -- layer 3 ram signals
     signal layer3_mem_wr_data_s     : int32 := (others => '0');
     signal layer3_mem_rd_data_s     : int32 := (others => '0');
     signal layer3_mem_address_s     : integer range 0 to 96*96*2-1 := 0;
     signal layer3_mem_address_out_s : integer range 0 to 96*96*2-1;
     signal layer3_mem_we_s          : std_logic := '0';  -- write enable for the layer3 output ram
     signal layer3_mem_re_s          : std_logic := '0';  -- read enable for the layer3 output ram
     signal layer3_mem_shift_steps_s : integer range 0 to 2-1 := 0;  -- 2 steps are needed to store all outputs
     signal layer3_mem_wr_index_s    : integer range 0 to 96*96*2-1 := 0;  -- this is the running index in order to store values in ram

    
    type state is ( TEST,
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
                    DONE_LAYER3
                  );
    
    signal statem_state_s   : state := TEST;
    
begin

  layer2_mem_address_out   <= layer2_mem_address_out_s;
  layer2_mem_address_out_s <= layer2_mem_address_s;
  layer2_mem_we_s          <= layer2_mem_we;
  layer2_mem_re_s          <= layer2_mem_re;
  layer2_mem_wr_data_s     <= layer2_mem_wr_data;
  layer2_mem_rd_data       <= layer2_mem_rd_data_s;
  
  layer3_index_x      <= layer3_index_x_s;
  layer3_index_y      <= layer3_index_y_s;
  layer3_kernel_x     <= layer3_kernel_x_s;
  layer3_kernel_y     <= layer3_kernel_y_s;
  layer3_prev_output  <= layer3_prev_output_s;
  layer3_data_rdy_in  <= data_rdy_in_layer3_s;
  layer3_data_rdy_out <= data_rdy_out_layer3_s;
  layer3_address      <= layer3_address_s;
  layer3_address_x    <= layer3_address_x_s;
  layer3_address_y    <= layer3_address_y_s;
  layer3_input        <= input_tensor_layer3_s;
  layer3_output       <= output_vector_layer3_s;
  
  layer3_address_part1 <= layer3_address_part1_s;
  layer3_address_part2 <= layer3_address_part2_s;
  
  layer3_mem_rd_data  <= layer3_mem_rd_data_s;
  
  layer3_mem_we <= layer3_mem_we_s;
  
  layer3_mem_wr_data <= layer3_mem_wr_data_s;
  
  layer3_mem_address_out <= layer3_mem_address_s;
  
  
  
  -- logic for LOADING ADDRESSES in layer 2 RAM
  -- addresses are only taken from computation in states LOAD_LAYER3, PIPE_DELAY0_LAYER3, PIPE_DELAY1_LAYER3 and PIPE_DELAY2_LAYER3
  -- if the index is out of bounds, the address is set to 0.
  -- otherwise not changed
  process (clk)
    begin
      if rising_edge(clk) then
        if (statem_state_s = LOAD_LAYER3) or (statem_state_s = PIPE_DELAY0_LAYER3) or (statem_state_s = PIPE_DELAY1_LAYER3) or (statem_state_s = PIPE_DELAY2_LAYER3) or (statem_state_s = PIPE_DELAY3_LAYER3) then
          if (layer3_address_x_dld1_s >= 0) and (layer3_address_x_dld1_s < 96) and (layer3_address_y_dld1_s >= 0) and (layer3_address_y_dld1_s < 96) then
            layer2_mem_address_s <= to_integer(layer3_address_s);
          else
            layer2_mem_address_s <= 0;
          end if;
        else
          layer2_mem_address_s <= layer2_mem_address;
        end if;
      end if;
  end process;
  
  -- logic for READING DATA from layer 2 RAM
  -- data is only read from output of layer 2 RAM in states LOAD_LAYER3, PIPE_DELAY0_LAYER3, PIPE_DELAY1_LAYER3 and PIPE_DELAY2_LAYER3
  -- if the index is out of bounds, the data (for input of layer 3) is set to 0.
  -- otherwise, the input of layer 3 is not changed.
  process (clk)
    begin
      if rising_edge(clk) then
        if (statem_state_s = LOAD_LAYER3) or (statem_state_s = PIPE_DELAY0_LAYER3) or (statem_state_s = PIPE_DELAY1_LAYER3) or (statem_state_s = PIPE_DELAY2_LAYER3) or (statem_state_s = PIPE_DELAY3_LAYER3) or (statem_state_s = START_LAYER3) then
          if (layer3_address_x_dld3_s >= 0) and (layer3_address_x_dld3_s < 96) and (layer3_address_y_dld3_s >= 0) and (layer3_address_y_dld3_s < 96) then
            input_tensor_layer3_s(to_integer(layer3_kernel_x_dld4_s), to_integer(layer3_kernel_y_dld4_s), to_integer(layer3_prev_output_dld4_s)) <= layer2_mem_rd_data_s;
          else
            input_tensor_layer3_s(to_integer(layer3_kernel_x_dld4_s), to_integer(layer3_kernel_y_dld4_s), to_integer(layer3_prev_output_dld4_s)) <= to_unsigned(0, 8);
          end if;
        end if;
      end if;
  end process;
  
  -- pipeline logic
  process (clk)
    begin
      if rising_edge(clk) then
        layer3_kernel_x_dld0_s    <= layer3_kernel_x_s;
        layer3_kernel_y_dld0_s    <= layer3_kernel_y_s;
        layer3_prev_output_dld0_s <= layer3_prev_output_s;
        layer3_address_x_dld0_s   <= layer3_address_x_s;
        layer3_address_y_dld0_s   <= layer3_address_y_s;
        layer3_kernel_x_dld1_s    <= layer3_kernel_x_dld0_s;
        layer3_kernel_y_dld1_s    <= layer3_kernel_y_dld0_s;
        layer3_prev_output_dld1_s <= layer3_prev_output_dld0_s;
        layer3_address_x_dld1_s   <= layer3_address_x_dld0_s;
        layer3_address_y_dld1_s   <= layer3_address_y_dld0_s;
        layer3_kernel_x_dld2_s    <= layer3_kernel_x_dld1_s;
        layer3_kernel_y_dld2_s    <= layer3_kernel_y_dld1_s;
        layer3_prev_output_dld2_s <= layer3_prev_output_dld1_s;
        layer3_address_x_dld2_s   <= layer3_address_x_dld1_s;
        layer3_address_y_dld2_s   <= layer3_address_y_dld1_s;
        layer3_kernel_x_dld3_s    <= layer3_kernel_x_dld2_s;
        layer3_kernel_y_dld3_s    <= layer3_kernel_y_dld2_s;
        layer3_prev_output_dld3_s <= layer3_prev_output_dld2_s;
        layer3_address_x_dld3_s   <= layer3_address_x_dld2_s;
        layer3_address_y_dld3_s   <= layer3_address_y_dld2_s;
        layer3_kernel_x_dld4_s    <= layer3_kernel_x_dld3_s;
        layer3_kernel_y_dld4_s    <= layer3_kernel_y_dld3_s;
        layer3_prev_output_dld4_s <= layer3_prev_output_dld3_s;
        layer3_address_x_dld4_s   <= layer3_address_x_dld3_s;
        layer3_address_y_dld4_s   <= layer3_address_y_dld3_s;
      end if;
  end process;

  -- address computation for layer 1 RAM
  process (clk)
  begin
    if rising_edge(clk) then
      layer3_address_x_s     <= resize(layer3_index_x_s + layer3_kernel_x_s - 1, 8);
    end if;
  end process;
  
  process (clk)
  begin
    if rising_edge(clk) then
      layer3_address_y_s     <= resize(layer3_index_y_s + layer3_kernel_y_s - 1, 8);
    end if;
  end process;
  
  process (clk)
  begin
    if rising_edge(clk) then
      layer3_address_part1_s <= resize(resize(unsigned(layer3_address_x_s), 16) * 8, 16);
    end if;
  end process;
  
  process (clk)
  begin
    if rising_edge(clk) then
      layer3_address_part2_s <= resize(resize(unsigned(layer3_address_y_s), 16) * 768, 16);
    end if;
  end process;
  
  process (clk)
  begin
    if rising_edge(clk) then
      layer3_address_s       <= unsigned(resize(layer3_address_part1_s + layer3_address_part2_s + unsigned(layer3_prev_output_dld1_s), 16));
    end if;
  end process;
  
  -- writing results to layer 3 RAM
  -- If the statemachine is in the writing state (writing results of layer 3), the write enable bit is set and address as well as
  -- data are taken from the computational logic.
  -- Otherwise write enable bit is always 0 and data & address too.
  process( clk ) is
  begin
    if (rising_edge (clk)) then
      if (statem_state_s = WRITE_RAM_LAYER3) then
        layer3_mem_we_s <= '1';
        layer3_mem_address_s <= layer3_mem_wr_index_s;
        layer3_mem_wr_data_s <= output_vector_layer3_s(layer3_mem_shift_steps_s);
      else
        if (statem_state_s = DONE_LAYER3) then
          layer3_mem_we_s <= '0';
          layer3_mem_address_s <= layer3_mem_address;
          layer3_mem_wr_data_s <= (others => '0');
        else
          layer3_mem_we_s <= '0';
          layer3_mem_address_s <= 0;
          layer3_mem_wr_data_s <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  -- logic for layer 2 RAM read enable bit
  process( clk ) is
  begin
    if (rising_edge (clk)) then
      if reset = '0' then
        layer2_mem_re_s <= '0';
      else
        if (statem_state_s = INIT_LAYER3) or (statem_state_s = LOAD_LAYER3) or (statem_state_s = PIPE_DELAY0_LAYER3) or (statem_state_s = PIPE_DELAY1_LAYER3) or (statem_state_s = PIPE_DELAY2_LAYER3) or (statem_state_s = PIPE_DELAY3_LAYER3) then
          layer2_mem_re_s <= '1';
        else
          if (statem_state_s = CHECK_PROGRESS_LAYER3) and ((layer3_index_x_s < 95) and (layer3_index_y_s < 95)) then
            layer2_mem_re_s <= '1';
          else
            if (statem_state_s = DONE_LAYER3) then
              layer2_mem_re_s <= layer2_mem_re_s;
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
  process( clk ) is
  begin
    if (rising_edge (clk)) then
      if reset = '0' then
        layer3_mem_re_s <= '0';
      else
        if (statem_state_s = DONE_LAYER3) then
          layer3_mem_re_s <= layer3_mem_re;
        else
        end if;
      end if;
    end if;
  end process;
  
  -- logic for layer 3 data ready in flag
  process( clk ) is
  begin
    if (rising_edge (clk)) then
      if reset = '0' then
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
  
  
  rst_in_s <= reset;

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
  
  -- ram for results of layer3
  layer3_output_mem_instance0 : layer3_output_mem
    Port map (
      clk           => clk,
      block_address => layer3_mem_address_s,
      we            => layer3_mem_we_s,
      re            => layer3_mem_re_s,
      data_i        => layer3_mem_wr_data_s,
      data_o        => layer3_mem_rd_data_s
    );

  LG_Layer3_instance0 : LG_Layer3
    Generic map (
      SCALE3            => SCALE3,
      LAYER3_CONV_BIAS0 => LAYER3_CONV_BIAS0,
      LAYER3_CONV_BIAS1 => LAYER3_CONV_BIAS1,
      -- MAC generics
      MAC_LAYER3_A_WIDTH      => MAC_LAYER3_A_WIDTH,
      MAC_LAYER3_B_WIDTH      => MAC_LAYER3_B_WIDTH,
      MAC_LAYER3_OUT_WIDTH    => MAC_LAYER3_OUT_WIDTH)
    Port map (
      input_tensor  => input_tensor_layer3_s,
      output_vector => output_vector_layer3_s,
      data_rdy_in   => data_rdy_in_layer3_s,
      data_rdy_out  => data_rdy_out_layer3_s,
      rst_in        => rst_in_s,
      clk           => clk
    );
    
    process (clk)
    begin
      if rising_edge(clk) then
        if reset = '0' then
          statem_state_s        <= TEST;
          layer3_index_x_s      <= to_signed(0, 8);
          layer3_index_y_s      <= to_signed(0, 8);
          layer3_kernel_x_s     <= to_signed(0, 3);
          layer3_kernel_y_s     <= to_signed(0, 3);
          layer3_prev_output_s  <= to_signed(0, 5);
          layer3_mem_wr_index_s <= 0;
        else
          case (statem_state_s) is
            when (TEST) =>
              if (layer3_INIT = '1') then
                statem_state_s        <= INIT_LAYER3;
                layer3_mem_wr_index_s <= 0;
              end if;
              
            when (INIT_LAYER3) =>
              layer3_index_x_s      <= to_signed(0, 8);
              layer3_index_y_s      <= to_signed(0, 8);
              layer3_kernel_x_s     <= to_signed(0, 3);
              layer3_kernel_y_s     <= to_signed(0, 3);
              layer3_prev_output_s  <= to_signed(0, 5);
              layer3_mem_wr_index_s <= 0;
              statem_state_s        <= LOAD_LAYER3;

            when (LOAD_LAYER3) =>
              if (layer3_prev_output_s = 7) then
                layer3_prev_output_s  <= to_signed(0, 5);
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
              else
                layer3_prev_output_s <= layer3_prev_output_s + 1;
                statem_state_s        <= LOAD_LAYER3;
              end if;
            
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
              statem_state_s <= DONE_LAYER3;

            when others =>
              statem_state_s <= TEST;

          end case;
        end if;
      end if;
    end process;


end Behavioral;
