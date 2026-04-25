-- NO PIPELINE --


library ieee;
use ieee.std_logic_1164.all;

entity sync_adder is  
    port (
        clk       : in std_logic;
        a, b, cin : in std_logic;
        sum, cout : out std_logic
    );
end sync_adder;

architecture Behavioral of sync_adder is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            sum <= a xor b xor cin;
            cout <= (a and b) or (a and cin) or (b and cin);
        end if; 
    end process;
end Behavioral;
