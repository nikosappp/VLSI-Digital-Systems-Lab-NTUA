-- 3 to 8 Binary Decoder (Behavioral) - TESTBENCH

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_dec3_8_behavioral is
end entity;

architecture tb of tb_dec3_8_behavioral is
    
    -- Component
    component dec3_8_behavioral is
        port (
            enc : in std_logic_vector(3-1 downto 0);
            dec : out std_logic_vector(8-1 downto 0)
        );
    end component;
    
    -- Signals
    signal enc : std_logic_vector(3-1 downto 0) := (others => '0');
    signal dec : std_logic_vector(8-1 downto 0);
    
    -- Constants
    constant TIME_DELAY : time := 10 ns;

begin
    
    DUT : dec3_8_behavioral
        port map (
            enc => enc,
            dec => dec
        );
    
    STIMULUS : process
    begin
        -- Initialize Signals
        enc <= (others => '0');
        wait for (1 * TIME_DELAY);
        
        -- Inputs
        for i in 1 to 7 loop
            enc <= std_logic_vector(to_unsigned(i, 3)); 
            wait for (1 * TIME_DELAY);
        end loop;
        
        enc <= (others => '0');
        wait for (1 * TIME_DELAY);

        wait;
    end process;

end architecture;
