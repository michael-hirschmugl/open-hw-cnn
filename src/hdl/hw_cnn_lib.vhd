library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package Types is

  subtype uint8 is unsigned (7 downto 0);
  subtype int8 is signed (7 downto 0);
  subtype int45 is signed (44 downto 0);
  subtype int32 is signed (31 downto 0);
  subtype int40 is signed (39 downto 0);
  
  type int32_array is array (integer range <>) of int32;
  --type output_vector_uint8 is array (0 to 15) of uint8;
  --type output_vector_uint8 is array (integer range <>) of uint8;
  --type output_vector_int32 is array (integer range <>) of int32;
  
  --type weight_matrix_layer1_int8 is array (0 to 2, 0 to 2, 0 to 1, 0 to 15) of int8;
  --type weight_matrix_layer2_int8 is array (0 to 2, 0 to 2, 0 to 15, 0 to 7) of int8;
  --type weight_matrix_layer3_int8 is array (0 to 2, 0 to 2, 0 to 7, 0 to 1) of int8;
  
  --type input_matrix_layer1_int32 is array (0 to 2, 0 to 2, 0 to 1) of int32;
  --type input_matrix_layer2_uint8 is array (0 to 2, 0 to 2, 0 to 15) of uint8;
  --type input_matrix_layer3_uint8 is array (0 to 2, 0 to 2, 0 to 7) of uint8;

  type temp_product_matrix_int40 is array (0 to 1, 0 to 2, 0 to 2) of int40;
  
end package Types;

package body Types is

end package body Types;