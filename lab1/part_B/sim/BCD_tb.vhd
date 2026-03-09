library ieee;
use ieee.std_logic_1164.all;

entity bcd_full_adder_tb is
end bcd_full_adder_tb;

architecture tb of bcd_full_adder_tb is

    component bcd_full_adder
        port (
            num1_bcd, num2_bcd : in  std_logic_vector(3 downto 0); 
            cin_bcd            : in  std_logic;                    
            sum_bcd            : out std_logic_vector(3 downto 0); 
            cout_bcd           : out std_logic                     
        );
    end component;

    -- Testbench signals
    signal num1_tb : std_logic_vector(3 downto 0) := "0000";
    signal num2_tb : std_logic_vector(3 downto 0) := "0000";
    signal cin_tb  : std_logic := '0';
    signal sum_tb  : std_logic_vector(3 downto 0);
    signal cout_tb : std_logic;

begin

    UUT: bcd_full_adder
    port map (
        num1_bcd => num1_tb,
        num2_bcd => num2_tb,
        cin_bcd  => cin_tb,
        sum_bcd  => sum_tb,
        cout_bcd => cout_tb
    );

    STIMULUS : process
    begin
        -- Test Case 1: 0 + 0 + 0 = 0 (Basic reset state)
        -- Expected: sum = "0000" (0), cout = '0'
        num1_tb <= "0000"; num2_tb <= "0000"; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 2: 5 + 3 = 8 (No correction needed)
        -- Expected: sum = "1000" (8), cout = '0'
        num1_tb <= "0101"; num2_tb <= "0011"; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 3: 8 + 7 = 15 (Correction needed! Sum > 9)
        -- Expected: sum = "0101" (5), cout = '1'
        num1_tb <= "1000"; num2_tb <= "0111"; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 4: 6 + 4 = 10 (Correction needed! Edge case exactly 10)
        -- Expected: sum = "0000" (0), cout = '1'
        num1_tb <= "0110"; num2_tb <= "0100"; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 5: 9 + 9 = 18 (Correction needed! Max digits without carry in)
        -- Expected: sum = "1000" (8), cout = '1'
        num1_tb <= "1001"; num2_tb <= "1001"; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 6: 9 + 9 + 1 = 19 (Correction needed! Absolute max value)
        -- Expected: sum = "1001" (9), cout = '1'
        num1_tb <= "1001"; num2_tb <= "1001"; cin_tb <= '1';
        wait for 20 ns;

        wait;
    end process;

end tb;