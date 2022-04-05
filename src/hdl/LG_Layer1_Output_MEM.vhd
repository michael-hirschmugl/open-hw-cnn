library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity layer1_output_mem is
generic (
        WORD_SIZE     : integer := 128;
        RAM_SIZE      : integer := 96*96
        );
port (  clk           : in std_logic;
        block_address : in integer range 0 to RAM_SIZE-1;  -- pixels in one row
        we            : in std_logic;
        re            : in std_logic;
        data_i        : in std_logic_vector(WORD_SIZE-1 downto 0);
        data_o        : out std_logic_vector(WORD_SIZE-1 downto 0)
     );
end layer1_output_mem;

architecture behave of layer1_output_mem is

  type ram_array is array (0 to RAM_SIZE-1) of std_logic_vector(WORD_SIZE-1 downto 0);
  signal ram : ram_array := (others => (others => '0'));
  attribute ram_style: string;
  attribute ram_style of ram : signal is "block";

  signal output_buf : std_logic_vector(WORD_SIZE-1 downto 0) := (others => '0');

begin

  process(output_buf)
  begin
    data_o <= output_buf;
  end process;

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(we='1') then
        ram(block_address) <= data_i;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(re='1') then
        output_buf <= ram(block_address);
      end if;
    end if;
  end process;

end behave;