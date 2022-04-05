library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity TB_LG_Layer2 is
  Generic (
    --
    START_OUTPUT            : integer := 0;
    STOP_OUTPUT             : integer := 7;
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
end TB_LG_Layer2;

architecture tb of TB_LG_Layer2 is

    component LG_Layer2
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
              input_tensor  : in  std_logic_vector(3*3*16*INPUTS_WIDTH-1 downto 0);  -- (3x3x16) (x,y,z)
              output_vector : out std_logic_vector((STOP_OUTPUT-START_OUTPUT+1)*ACT_WIDTH-1 downto 0);          -- (?)
              data_rdy_in   : in  std_logic;               -- PS signal that it's done writing input_tensor
              data_rdy_out  : out std_logic;               -- PL signal that it's done processing
              rst_in        : in  std_logic;               -- active low reset
              --DBG_MAC_OUT   : out signed (44 downto 0);
              clk           : in  std_logic);
    end component;

    signal input_tensor     : std_logic_vector(3*3*16*INPUTS_WIDTH-1 downto 0);
    signal output_vector    : std_logic_vector((STOP_OUTPUT-START_OUTPUT+1)*ACT_WIDTH-1 downto 0);
    signal data_rdy_in      : std_logic;
    signal data_rdy_out     : std_logic;
    --signal data_ack_in   : std_logic;
    signal rst_in           : std_logic;
    --signal DBG_MAC_OUT      : signed (44 downto 0);
    signal clk              : std_logic;

begin

    dut : LG_Layer2
    generic map (--
              START_OUTPUT => START_OUTPUT,
              STOP_OUTPUT => STOP_OUTPUT,
              INPUTS_WIDTH => INPUTS_WIDTH,
              SCALE2_0 => SCALE2_0,
              SCALE2_1 => SCALE2_1,
              SCALE2_2 => SCALE2_2,
              SCALE2_3 => SCALE2_3,
              SCALE2_4 => SCALE2_4,
              SCALE2_5 => SCALE2_5,
              SCALE2_6 => SCALE2_6,
              SCALE2_7 => SCALE2_7,
              LAYER2_BATCH_NORM_BIAS0 => LAYER2_BATCH_NORM_BIAS0,
              LAYER2_BATCH_NORM_BIAS1 => LAYER2_BATCH_NORM_BIAS1,
              LAYER2_BATCH_NORM_BIAS2 => LAYER2_BATCH_NORM_BIAS2,
              LAYER2_BATCH_NORM_BIAS3 => LAYER2_BATCH_NORM_BIAS3,
              LAYER2_BATCH_NORM_BIAS4 => LAYER2_BATCH_NORM_BIAS4,
              LAYER2_BATCH_NORM_BIAS5 => LAYER2_BATCH_NORM_BIAS5,
              LAYER2_BATCH_NORM_BIAS6 => LAYER2_BATCH_NORM_BIAS6,
              LAYER2_BATCH_NORM_BIAS7 => LAYER2_BATCH_NORM_BIAS7,
              SCALE2_WIDTH => SCALE2_WIDTH,
              LAYER2_POST_SCAL_SHFT => LAYER2_POST_SCAL_SHFT,
              LAYER2_POST_BIAS_SHFT => LAYER2_POST_BIAS_SHFT,
              LAYER2_POST_RNDG_SHFT => LAYER2_POST_RNDG_SHFT,
              POST_PROC_WIDTH => POST_PROC_WIDTH,
              ACT_WIDTH => ACT_WIDTH,
              WEIGHTS_WIDTH => WEIGHTS_WIDTH,
              ROUNDING_MASK => ROUNDING_MASK,
              MAC_LAYER2_A_WIDTH => MAC_LAYER2_A_WIDTH,
              MAC_LAYER2_B_WIDTH => MAC_LAYER2_B_WIDTH,
              MAC_LAYER2_OUT_WIDTH => MAC_LAYER2_OUT_WIDTH)
    port map (input_tensor     => input_tensor,
              output_vector    => output_vector,
              data_rdy_in      => data_rdy_in,
              data_rdy_out     => data_rdy_out,
              rst_in           => rst_in,
              --data_ack_in => data_ack_in,
              --DBG_MAC_OUT      => DBG_MAC_OUT,
              clk              => clk);

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        input_tensor <= (others => '0');
        clk <= '0';
        rst_in <= '0';
        --data_ack_in <= '0';
        data_rdy_in <= '0';
        
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        
        rst_in <= '1';
        
        --for h in 0 to 16-1 loop
        --  for g in 0 to 3-1 loop
            --for f in 0 to 3-1 loop
              --input_tensor(f, g, h) <= to_unsigned(100, 8);
              --input_tensor(f, g, h) <= to_signed(1, 32);
            --end loop;
          --end loop;
        --end loop;

        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';

        -- EDIT Add stimuli here
        data_rdy_in <= '1';
        
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        
        data_rdy_in <= '0';
        
        for i in 0 to 1000 loop
        
          --if (data_rdy_out = '1') then
            --data_ack_in <= '1';
          --else
            --data_ack_in <= '0';
          --end if;
        
          wait for 5 ns;
          clk <= '1';
          wait for 5 ns;
          clk <= '0';

        end loop;
        
        --for h in 0 to 16-1 loop
          --for g in 0 to 3-1 loop
            --for f in 0 to 3-1 loop
              --input_tensor(f, g, h) <= to_unsigned(2, 8);
              --input_tensor(f, g, h) <= to_signed(1, 32);
            --end loop;
          --end loop;
        --end loop;

        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';

        -- EDIT Add stimuli here
        data_rdy_in <= '1';
        
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        
        data_rdy_in <= '0';
        
        for i in 0 to 1000 loop
        
          --if (data_rdy_out = '1') then
            --data_ack_in <= '1';
          --else
            --data_ack_in <= '0';
          --end if;
        
          wait for 5 ns;
          clk <= '1';
          wait for 5 ns;
          clk <= '0';

        end loop;
        
        --for h in 0 to 16-1 loop
          --for g in 0 to 3-1 loop
            --for f in 0 to 3-1 loop
              --input_tensor(f, g, h) <= to_unsigned(1, 8);
              --input_tensor(f, g, h) <= to_signed(1, 32);
            --end loop;
          --end loop;
        --end loop;

        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';

        -- EDIT Add stimuli here
        data_rdy_in <= '1';
        
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        
        data_rdy_in <= '0';
        
        for i in 0 to 1000 loop
        
          --if (data_rdy_out = '1') then
            --data_ack_in <= '1';
          --else
            --data_ack_in <= '0';
          --end if;
        
          wait for 5 ns;
          clk <= '1';
          wait for 5 ns;
          clk <= '0';

        end loop;
       


        wait;
    end process;

end tb;
