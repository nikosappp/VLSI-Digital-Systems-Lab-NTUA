library ieee;
use ieee.std_logic_1164.all;

entity parallel_bcd_adder_4digit_tb is
end parallel_bcd_adder_4digit_tb;

architecture tb of parallel_bcd_adder_4digit_tb is

    component parallel_bcd_adder_4digit
        port (
            num1_16bit, num2_16bit : in  std_logic_vector(15 downto 0);
            initial_carry          : in  std_logic;
            sum_16bit              : out std_logic_vector(15 downto 0);
            final_carry            : out std_logic
        );
    end component;

    signal num1_tb        : std_logic_vector(15 downto 0) := (others => '0');
    signal num2_tb        : std_logic_vector(15 downto 0) := (others => '0');
    signal cin_tb         : std_logic := '0';
    signal sum_tb         : std_logic_vector(15 downto 0);
    signal final_carry_tb : std_logic;

begin

    UUT: parallel_bcd_adder_4digit
    port map (
        num1_16bit    => num1_tb,
        num2_16bit    => num2_tb,
        initial_carry => cin_tb,
        sum_16bit      => sum_tb,
        final_carry    => final_carry_tb
    );

    STIMULUS : process
    begin
        -- Test Case 1: 0000 + 0000
        num1_tb <= x"0000"; num2_tb <= x"0000"; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 2: 1234 + 1111 = 2345 (No carries between digits)
        -- Hex notation x"..." is used for easier BCD reading
        num1_tb <= x"1234"; num2_tb <= x"1111"; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 3: 0009 + 0001 = 0010 (Carry from Digit 0 to Digit 1)
        -- (0000 0000 0000 1001) + (0000 0000 0000 0001)
        num1_tb <= x"0009"; num2_tb <= x"0001"; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 4: 9999 + 0001 = 0000 (with Final Carry = 1)
        -- This verifies the ripple carry across all 4 BCD digits
        num1_tb <= x"9999"; num2_tb <= x"0001"; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 5: 1234 + 5678 + 1 (initial carry) = 6913
        num1_tb <= x"1234"; num2_tb <= x"5678"; cin_tb <= '1';
        wait for 20 ns;

        wait;
    end process;

end tb;