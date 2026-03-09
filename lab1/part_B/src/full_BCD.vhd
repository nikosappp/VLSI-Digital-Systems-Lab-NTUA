library ieee;
use ieee.std_logic_1164.all;

entity bcd_full_adder is
    port (
        num1_bcd, num2_bcd     : in  std_logic_vector(3 downto 0); 
        cin_bcd      : in  std_logic;                    
        sum_bcd  : out std_logic_vector(3 downto 0); 
        cout_bcd : out std_logic                     
    );
end bcd_full_adder;

architecture Structural of bcd_full_adder is

    component parallel_adder_4bit is
        port (
            num1, num2    : in  std_logic_vector(3 downto 0); 
            initial_carry : in  std_logic;
            sum_4bit      : out std_logic_vector(3 downto 0);
            final_carry   : out std_logic 
        );
    end component;

    signal temp_sum        : std_logic_vector(3 downto 0); -- Sum from the 1st adder
    signal temp_carry      : std_logic;                    -- Carry out from the 1st adder
    signal correction_flag : std_logic;                    -- Flag indicating correction is needed (+6)
    signal correction_num  : std_logic_vector(3 downto 0); -- The number to add (0000 or 0110)

begin 

    -- The first 4bit parallel adder performs normal binary addition
    ADDER_1: parallel_adder_4bit
        port map (
            num1          => num1_bcd,
            num2          => num2_bcd,
            initial_carry => cin_bcd,
            sum_4bit      => temp_sum,
            final_carry   => temp_carry
        );

    -- Correction Logic
    -- Check if the 1st addition resulted in a number > 9.
    -- If any of these 3 conditions are met, the correction_flag becomes '1':
    -- 1. temp_carry='1' => Sum is > 15.
    -- 2. temp_sum(3) and temp_sum(2) => Bit 8 + Bit 4 = 12 (catches 12, 13, 14, 15).
    -- 3. temp_sum(3) and temp_sum(1) => Bit 8 + Bit 2 = 10 (catches 10, 11).
    correction_flag <= temp_carry or (temp_sum(3) and temp_sum(2)) or (temp_sum(3) and temp_sum(1));

    -- Create the correction number 
    -- We build a 4-bit wire to add either "0000" (+0) or "0110" (+6) 
    -- Bits 3 and 0 are permanently grounded ('0').
    -- Bits 2 and 1 are wired directly to the correction_flag.
    correction_num(3) <= '0';             -- Leftmost bit is always '0'
    correction_num(2) <= correction_flag; -- Takes the value of the flag ('0' or '1')
    correction_num(1) <= correction_flag; -- Takes the value of the flag ('0' or '1')
    correction_num(0) <= '0';             -- Rightmost bit is always '0'

    -- The second adder performs the correction
    ADDER_2: parallel_adder_4bit
        port map (
            num1          => temp_sum,
            num2          => correction_num,
            initial_carry => '0',   -- No carry needed here
            sum_4bit      => sum_bcd,
            final_carry   => open   -- We dont need this carry out
        );

    -- Connect the flag to the final output port
    cout_bcd <= correction_flag;

end Structural;
