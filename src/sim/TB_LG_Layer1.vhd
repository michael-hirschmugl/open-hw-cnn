library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity tb_LG_Layer1 is
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
end tb_LG_Layer1;

architecture tb of tb_LG_Layer1 is

    component LG_Layer1
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
        port (input_tensor  : in std_logic_vector (3*3*2*inputs_width-1 downto 0);
              output_vector : out std_logic_vector (16*act_width-1 downto 0);
              data_rdy_in   : in std_logic;
              data_rdy_out  : out std_logic;
              rst_in        : in std_logic;
              clk           : in std_logic);
    end component;

    signal input_tensor  : std_logic_vector (3*3*2*INPUTS_WIDTH-1 downto 0);
    signal output_vector : std_logic_vector (16*ACT_WIDTH-1 downto 0);
    signal data_rdy_in   : std_logic;
    signal data_rdy_out  : std_logic;
    signal rst_in        : std_logic;
    signal clk           : std_logic;

begin

    dut : LG_Layer1
    generic map (
              INPUTS_WIDTH     => INPUTS_WIDTH,
              SCALE1           => SCALE1,
              SCALE1_WIDTH     => SCALE1_WIDTH,
              POST_PROC_WIDTH  => POST_PROC_WIDTH,
              ACT_WIDTH        => ACT_WIDTH,
              WEIGHTS_WIDTH    => WEIGHTS_WIDTH,
              ROUNDING_MASK    => ROUNDING_MASK,
              DTA_RDY_DLY_CLKS => DTA_RDY_DLY_CLKS,
              MAC_A_WIDTH      => MAC_A_WIDTH,
              MAC_B_WIDTH      => MAC_B_WIDTH,
              MAC_OUT_WIDTH    => MAC_OUT_WIDTH)
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
