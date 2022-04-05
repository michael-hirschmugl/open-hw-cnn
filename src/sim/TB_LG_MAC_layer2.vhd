library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity tb_LG_MAC_layer2 is
  generic (
    A_WIDTH : integer := 8;
    B_WIDTH : integer := 8;
    OUT_WIDTH : integer := 24);
end tb_LG_MAC_layer2;

architecture tb of tb_LG_MAC_layer2 is

    component LG_MAC_layer2
        generic (
              A_WIDTH : integer := 8;
              B_WIDTH : integer := 8;
              OUT_WIDTH : integer := 24);
        port (a         : in unsigned (a_width-1 downto 0);
              b         : in signed (b_width-1 downto 0);
              clk       : in std_logic;
              sload     : in std_logic;
              accum_out : out signed (out_width-1 downto 0));
    end component;

    signal a         : unsigned (a_width-1 downto 0);
    signal b         : signed (b_width-1 downto 0);
    signal clk       : std_logic;
    signal sload     : std_logic;
    signal accum_out : signed (out_width-1 downto 0);

begin

    dut : LG_MAC_layer2
    generic map (
              A_WIDTH   => A_WIDTH,
              B_WIDTH   => B_WIDTH,
              OUT_WIDTH => OUT_WIDTH)
    port map (a         => a,
              b         => b,
              clk       => clk,
              sload     => sload,
              accum_out => accum_out);

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        a <= (others => '0');
        b <= (others => '0');
        clk <= '0';
        sload <= '0';

        -- EDIT Add stimuli here
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        sload <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        sload <= '0';
        
        a <= to_unsigned(255, 8);
        b <= to_signed(127, 8);
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';

        wait;
    end process;

end tb;
