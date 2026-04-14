library ieee;
use ieee.std_logic_1164.all;

entity parallel_bcd_adder_4digit is
    port (
        num1_16bit, num2_16bit : in  std_logic_vector(15 downto 0); -- 4 BCD digits each (4x4=16 bits)
        initial_carry          : in  std_logic;                    -- Initial carry input
        sum_16bit              : out std_logic_vector(15 downto 0); -- 4-digit BCD sum output
        final_carry            : out std_logic                     -- Final carry output (overflow)
    );
end parallel_bcd_adder_4digit;

architecture Structural of parallel_bcd_adder_4digit is

    
    component bcd_full_adder is
        port (
            num1_bcd, num2_bcd : in  std_logic_vector(3 downto 0);
            cin_bcd            : in  std_logic;
            sum_bcd            : out std_logic_vector(3 downto 0);
            cout_bcd           : out std_logic
        );
    end component;

    signal c1, c2, c3 : std_logic;

begin 

    -- Digit 0: Addition of the 1st BCD digits (bits 0 to 3)
    BCD_FA0: bcd_full_adder
        port map (
            num1_bcd => num1_16bit(3 downto 0),
            num2_bcd => num2_16bit(3 downto 0),
            cin_bcd  => initial_carry,
            sum_bcd  => sum_16bit(3 downto 0),
            cout_bcd => c1
        );
        
    -- Digit 1: Addition of the 2nd BCD digits (bits 4 to 7)
    BCD_FA1: bcd_full_adder
        port map (
            num1_bcd => num1_16bit(7 downto 4),
            num2_bcd => num2_16bit(7 downto 4),
            cin_bcd  => c1,
            sum_bcd  => sum_16bit(7 downto 4),
            cout_bcd => c2
        );

    -- Digit 2: Addition of the 3rd BCD digits (bits 8 to 11)
    BCD_FA2: bcd_full_adder
        port map (
            num1_bcd => num1_16bit(11 downto 8),
            num2_bcd => num2_16bit(11 downto 8),
            cin_bcd  => c2,
            sum_bcd  => sum_16bit(11 downto 8),
            cout_bcd => c3
        );

    -- Digit 3: Addition of the 4th BCD digits (bits 12 to 15)
    BCD_FA3: bcd_full_adder
        port map (
            num1_bcd => num1_16bit(15 downto 12),
            num2_bcd => num2_16bit(15 downto 12),
            cin_bcd  => c3,
            sum_bcd  => sum_16bit(15 downto 12),
            cout_bcd => final_carry
        );

end Structural;