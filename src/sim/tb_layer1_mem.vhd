library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity tb_layer1_output_mem is
end tb_layer1_output_mem;

architecture tb of tb_layer1_output_mem is

    component layer1_output_mem
        port (clk           : in std_logic;
              block_address : in integer;
              we            : in std_logic;
              re            : in std_logic;
              data_i        : in uint8;
              data_o        : out uint8);
    end component;

    signal clk           : std_logic;
    signal block_address : integer;
    signal we            : std_logic;
    signal re            : std_logic;
    signal data_i        : uint8;
    signal data_o        : uint8;

begin

    dut : layer1_output_mem
    port map (clk           => clk,
              block_address => block_address,
              we            => we,
              re            => re,
              data_i        => data_i,
              data_o        => data_o);

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        clk <= '0';
        block_address <= 0;
        we <= '0';
        re <= '0';
        data_i <= (others => '0');
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        we <= '1';
        
        block_address <= 0;
        data_i <= to_unsigned(50, 8);
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        block_address <= 1;
        data_i <= to_unsigned(51, 8);
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        block_address <= 2;
        data_i <= to_unsigned(52, 8);
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        we <= '0';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        block_address <= 0;
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        re <= '1';
        
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        
        re <= '0';
        
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

        -- EDIT Add stimuli here

        wait;
    end process;

end tb;
