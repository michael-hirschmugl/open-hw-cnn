library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity tb_Layer3_Debug is
Generic (
    -- CNN value generics Layer 3
        SCALE3                  : integer := 1540923957;
        LAYER3_CONV_BIAS0       : integer := -1443;
        LAYER3_CONV_BIAS1       : integer := -196;
        -- MAC generics
        MAC_LAYER3_A_WIDTH      : integer := 8;
        MAC_LAYER3_B_WIDTH      : integer := 8;
        MAC_LAYER3_OUT_WIDTH    : integer := 23);
end tb_Layer3_Debug;

architecture tb of tb_Layer3_Debug is

    component Layer3_Debug
      Generic (
      -- CNN value generics Layer 3
          SCALE3                  : integer := 1540923957;
          LAYER3_CONV_BIAS0       : integer := -1443;
          LAYER3_CONV_BIAS1       : integer := -196;
          -- MAC generics
          MAC_LAYER3_A_WIDTH      : integer := 8;
          MAC_LAYER3_B_WIDTH      : integer := 8;
          MAC_LAYER3_OUT_WIDTH    : integer := 23);
        port ( clk                    : in STD_LOGIC;
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
    end component;

    signal clk                  : std_logic;
    signal layer2_mem_wr_data   : uint8;
    signal layer2_mem_rd_data   : uint8;
    signal layer2_mem_address   : integer range 0 to 96*96*8-1;
    signal layer2_mem_address_out : integer range 0 to 96*96*8-1;
    signal layer2_mem_we        : std_logic;
    signal layer2_mem_re        : std_logic;
    signal layer3_mem_rd_data   : int32;
    signal layer3_mem_address   : integer range 0 to 96*96*2-1;
    signal layer3_mem_address_out : integer range 0 to 96*96*2-1;
    signal layer3_mem_re        : std_logic;
    signal layer3_INIT          : std_logic;
    signal layer3_index_x       : signed(7 downto 0);
    signal layer3_index_y       : signed(7 downto 0);
    signal layer3_kernel_x      : signed(2 downto 0);
    signal layer3_kernel_y      : signed(2 downto 0);
    signal layer3_address_x     : signed(7 downto 0);
    signal layer3_address_y     : signed(7 downto 0);
    signal layer3_address       : unsigned(15 downto 0);
    signal layer3_prev_output   : signed(4 downto 0);
    signal layer3_data_rdy_in   : std_logic;
    signal layer3_data_rdy_out  : std_logic;
    signal layer3_input         : input_matrix_layer3_uint8;
    signal layer3_output        : output_vector_int32 (0 to 1);
    signal layer3_address_part1 : unsigned(15 downto 0);
    signal layer3_address_part2 : unsigned(15 downto 0);
    signal layer3_mem_we        : std_logic;
    signal layer3_mem_wr_data   : int32;
    signal reset                : std_logic;

begin

    dut : Layer3_Debug
    port map (clk                  => clk,
              layer2_mem_wr_data   => layer2_mem_wr_data,
              layer2_mem_rd_data   => layer2_mem_rd_data,
              layer2_mem_address   => layer2_mem_address,
              layer2_mem_address_out => layer2_mem_address_out,
              layer2_mem_we        => layer2_mem_we,
              layer2_mem_re        => layer2_mem_re,
              layer3_mem_rd_data   => layer3_mem_rd_data,
              layer3_mem_address   => layer3_mem_address,
              layer3_mem_address_out => layer3_mem_address_out,
              layer3_mem_re        => layer3_mem_re,
              layer3_INIT          => layer3_INIT,
              layer3_index_x       => layer3_index_x,
              layer3_index_y       => layer3_index_y,
              layer3_kernel_x      => layer3_kernel_x,
              layer3_kernel_y      => layer3_kernel_y,
              layer3_address_x     => layer3_address_x,
              layer3_address_y     => layer3_address_y,
              layer3_address       => layer3_address,
              layer3_prev_output   => layer3_prev_output,
              layer3_data_rdy_in   => layer3_data_rdy_in,
              layer3_data_rdy_out  => layer3_data_rdy_out,
              layer3_input         => layer3_input,
              layer3_output        => layer3_output,
              layer3_address_part1 => layer3_address_part1,
              layer3_address_part2 => layer3_address_part2,
              layer3_mem_we        => layer3_mem_we,
              layer3_mem_wr_data   => layer3_mem_wr_data,
              reset                => reset);

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        clk <= '0';
        layer2_mem_wr_data <= to_unsigned(0, 8);
        layer2_mem_address <= 0;
        layer2_mem_we <= '0';
        layer2_mem_re <= '0';
        layer3_mem_re <= '0';
        layer3_INIT <= '0';
        reset <= '0';

        -- EDIT Add stimuli here
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        layer2_mem_we <= '1';
        reset <= '1';
        
        for h in 0 to 96*96-1 loop
          for g in 0 to 8-1 loop
              layer2_mem_address <= h*8+g;
              --layer1_mem_wr_data <= to_unsigned(g, 8);
              layer2_mem_wr_data <= to_unsigned(255, 8);
              wait for 5 ns;
              clk <= '0';
              wait for 5 ns;
              clk <= '1';
          end loop;
        end loop;
        
        layer2_mem_we <= '0';
        layer2_mem_re <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        layer2_mem_address <= 15;
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        layer3_INIT <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        layer3_INIT <= '0';
        
        for h in 0 to 10000000 loop
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
          clk <= '1';
        end loop;
        
        


        wait;
    end process;

end tb;
