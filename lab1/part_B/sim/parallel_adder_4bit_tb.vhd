library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity parallel_adder_4bit_tb is
end parallel_adder_4bit_tb;

architecture tb of parallel_adder_4bit_tb is

    
    component parallel_adder_4bit
        port (
            num1          : in  std_logic_vector(3 downto 0);
            num2          : in  std_logic_vector(3 downto 0);
            initial_carry : in  std_logic;
            sum_4bit      : out std_logic_vector(3 downto 0);
            final_carry   : out std_logic
        );
    end component;

    signal num1_tb          : std_logic_vector(3 downto 0) := (others => '0');
    signal num2_tb          : std_logic_vector(3 downto 0) := (others => '0');
    signal initial_carry_tb : std_logic := '0';
    signal sum_4bit_tb      : std_logic_vector(3 downto 0);
    signal final_carry_tb   : std_logic;

begin

    -- Instantiate the Unit Under Test (UUT) [cite: 14, 39]
    UUT: parallel_adder_4bit
    port map (
        num1          => num1_tb,
        num2          => num2_tb,
        initial_carry => initial_carry_tb,
        sum_4bit      => sum_4bit_tb,
        final_carry   => final_carry_tb
    );

    -- Stimulus process to apply test vectors
    STIMULUS : process
    begin
        -- Test Case 1: 0 + 0 + 0 = 0
        -- Inputting zeros to check basic reset/zero state
        num1_tb <= "0000"; num2_tb <= "0000"; initial_carry_tb <= '0';
        wait for 20 ns; 

        -- Test Case 2: 5 + 3 = 8
        -- (0101) + (0011) = 1000, Carry = 0
        num1_tb <= "0101"; num2_tb <= "0011"; initial_carry_tb <= '0';
        wait for 20 ns;

        -- Test Case 3: 10 + 2 = 12
        -- (1010) + (0010) = 1100, Carry = 0
        num1_tb <= "1010"; num2_tb <= "0010"; initial_carry_tb <= '0';
        wait for 20 ns;

        -- Test Case 4: 15 + 1 = 16 (Overflow check)
        -- (1111) + (0001) = 0000, Carry = 1
        -- This case verifies if the final_carry correctly indicates overflow
        num1_tb <= "1111"; num2_tb <= "0001"; initial_carry_tb <= '0';
        wait for 20 ns;

        -- Test Case 5: 7 + 7 + 1 (initial_carry) = 15
        -- (0111) + (0111) + 1 = 1111, Carry = 0
        -- Verifies the initial_carry input functionality
        num1_tb <= "0111"; num2_tb <= "0111"; initial_carry_tb <= '1';
        wait for 20 ns;

        -- Test Case 6: 15 + 15 + 1 = 31 (Maximum value)
        -- (1111) + (1111) + 1 = 1111, Carry = 1
        num1_tb <= "1111"; num2_tb <= "1111"; initial_carry_tb <= '1';
        wait for 20 ns;

        wait;
    end process;

end tb;