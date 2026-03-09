-- Addition of two 1-bit binary numbers

-- Inputs: a (1st 1-bit operand), 
--         b (2nd 1-bit operand)

-- Outputs: sum corresponds to an XOR gate (sum = a xor b),
--          carry corresponds to an AND gate ( carry = a AND b)
            
library ieee;
use ieee.std_logic_1164.all;


entity half_adder is
    port (
        a, b : in std_logic;
        sum, carry : out std_logic
    );    
end half_adder;

architecture Dataflow of half_adder is
begin

    sum <= a xor b;
    carry <= a and b;

end Dataflow;
