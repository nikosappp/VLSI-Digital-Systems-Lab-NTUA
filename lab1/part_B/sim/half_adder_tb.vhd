library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity half_adder_tb is
end half_adder_tb;

architecture tb of half_adder_tb is

    component half_adder
        port (
            a, b : in std_logic;
            sum, carry : out std_logic
        );
    end component;

    signal a_tb     : std_logic := '0';
    signal b_tb     : std_logic := '0';
    signal sum_tb   : std_logic;
    signal carry_tb : std_logic;

begin

    UUT: half_adder 
    port map (
        a     => a_tb,
        b     => b_tb,
        sum   => sum_tb,
        carry => carry_tb
    );

    STIMULUS : process
    begin
        -- Test Case 1: 0 + 0
        a_tb <= '0'; b_tb <= '0';
        wait for 20 ns;
        
        -- Test Case 2: 0 + 1
        a_tb <= '0'; b_tb <= '1';
        wait for 20 ns;

        -- Test Case 3: 1 + 0
        a_tb <= '1'; b_tb <= '0';
        wait for 20 ns;

        -- Test Case 4: 1 + 1
        a_tb <= '1'; b_tb <= '1';
        wait for 20 ns;

        -- Stop the simulation
        wait;
    end process;

end tb;