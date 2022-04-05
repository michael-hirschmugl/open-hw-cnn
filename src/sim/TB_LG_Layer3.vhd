library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity tb_LG_Layer3 is
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
end tb_LG_Layer3;

architecture tb of tb_LG_Layer3 is

    component LG_Layer3
        generic (
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
        port (input_tensor  : in std_logic_vector (3*3*8*inputs_width-1 downto 0);
              output_vector : out std_logic_vector (2*post_proc_width-1 downto 0);
              data_rdy_in   : in std_logic;
              data_rdy_out  : out std_logic;
              rst_in        : in std_logic;
              clk           : in std_logic);
    end component;

    signal input_tensor  : std_logic_vector (3*3*8*inputs_width-1 downto 0);
    signal output_vector : std_logic_vector (2*post_proc_width-1 downto 0);
    signal data_rdy_in   : std_logic;
    signal data_rdy_out  : std_logic;
    signal rst_in        : std_logic;
    signal clk           : std_logic;

begin

    dut : LG_Layer3
    generic map (
              INPUTS_WIDTH          => INPUTS_WIDTH,
              SCALE3                => SCALE3,
              LAYER3_CONV_BIAS0     => LAYER3_CONV_BIAS0,
              LAYER3_CONV_BIAS1     => LAYER3_CONV_BIAS1,
              SCALE3_WIDTH          => SCALE3_WIDTH,
              POST_PROC_WIDTH       => POST_PROC_WIDTH,
              LAYER3_POST_SCAL_SHFT => LAYER3_POST_SCAL_SHFT,
              LAYER3_POST_BIAS_SHFT => LAYER3_POST_BIAS_SHFT,
              WEIGHTS_WIDTH         => WEIGHTS_WIDTH,
              MAC_LAYER3_A_WIDTH    => MAC_LAYER3_A_WIDTH,
              MAC_LAYER3_B_WIDTH    => MAC_LAYER3_B_WIDTH,
              MAC_LAYER3_OUT_WIDTH  => MAC_LAYER3_OUT_WIDTH)
    port map (input_tensor  => input_tensor,
              output_vector => output_vector,
              data_rdy_in   => data_rdy_in,
              data_rdy_out  => data_rdy_out,
              rst_in        => rst_in,
              clk           => clk);

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        input_tensor <= (others => '0');
        clk <= '0';
        rst_in <= '0';
        data_rdy_in <= '0';
        
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        
        rst_in <= '1';

        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        
        data_rdy_in <= '1';
        
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        
        data_rdy_in <= '0';
        
        for i in 0 to 10000 loop
          wait for 5 ns;
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
        end loop;
        wait;
    end process;

end tb;
