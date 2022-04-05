library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library hw_cnn_lib;
use hw_cnn_lib.Types.all;

entity LG_MAC_layer3 is
  generic (
    A_WIDTH : integer := 8;
    B_WIDTH : integer := 8;
    OUT_WIDTH : integer := 23);
  port (
    a : in unsigned (A_WIDTH-1 downto 0);
    b : in signed (B_WIDTH-1 downto 0);
    clk : in std_logic;
    sload : in std_logic;  -- reset signal
    accum_out : out signed (OUT_WIDTH-1 downto 0));
end LG_MAC_layer3;

architecture Behavioral of LG_MAC_layer3 is

  signal a_s : signed (A_WIDTH-1+1 downto 0);
  signal b_s : signed (B_WIDTH-1 downto 0);
  signal sload_s : std_logic;
  signal multi0_s : std_logic_vector (A_WIDTH+B_WIDTH-1+1 downto 0);
  signal multi1_s : signed (A_WIDTH+B_WIDTH-1 downto 0);
  signal adder_out_s : signed (OUT_WIDTH-1 downto 0);
  signal old_res_s : signed (OUT_WIDTH-1 downto 0);
  
begin

  multi0_s <= std_logic_vector(a_s * b_s);
  multi1_s <= signed(multi0_s(A_WIDTH+B_WIDTH-1 downto 0));
  
  process (adder_out_s, sload_s)
  begin
    if (sload_s = '1') then
      old_res_s <= (others => '0');
    else
      old_res_s <= adder_out_s;
    end if;
  end process;
  
  process (clk)
  begin
    if (rising_edge(clk)) then
      a_s <= signed('0'&std_logic_vector(a));
      b_s <= b;
      sload_s <= sload;
      adder_out_s <= multi1_s + old_res_s;
    end if;
  end process;

  accum_out <= adder_out_s;

end Behavioral;
