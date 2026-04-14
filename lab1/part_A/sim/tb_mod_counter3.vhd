-- 3-bit Up Counter with Parallel Modulo Input (upper bound) - TESTBENCH

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity tb_mod_counter3 is
end entity;

architecture tb of tb_mod_counter3 is 
    -- Component
    component mod_counter3 is 
        port (
            clk, resetn, count_en: in std_logic;
            bound : in std_logic_vector(3-1 downto 0);
            sum : out std_logic_vector(3-1 downto 0);
            cout : out std_logic
        );
    end component;

    -- Signals
    signal clk : std_logic;
    signal resetn : std_logic := '0';
    signal count_en : std_logic := '0';
    signal bound : std_logic_vector(3-1 downto 0) := "111";
    signal sum : std_logic_vector(3-1 downto 0);
    signal cout : std_logic;

    -- Constants
    constant CLOCK_PERIOD : time := 10 ns;

begin

    DUT : mod_counter3
        port map (
            clk => clk,
            resetn => resetn,
            count_en => count_en,
            bound => bound,
            sum => sum,
            cout => cout
        );
    
    STIMULUS : process
    begin
        -- Reset
        resetn <= '0';
        wait for (2 * CLOCK_PERIOD);
        resetn <= '1';
        wait for (1 * CLOCK_PERIOD);

        -- Test a Bound
        bound <= "101";
        count_en <= '1';
        wait for (10 * CLOCK_PERIOD);

        -- Hold Value
        count_en <= '0';
        wait for (2 * CLOCK_PERIOD);

        -- Test Another Bound
        bound <= "011";
        count_en <= '1';
        wait for (7 * CLOCK_PERIOD);

        -- Reset
        resetn <= '0';
        wait for (2 * CLOCK_PERIOD);
        resetn <= '1';
        count_en <= '0';
        wait for (1 * CLOCK_PERIOD);
        
        wait;
    end process;
    
    -- Clock Generation
    GEN_CLK : process
    begin
        clk <= '0';
        wait for (CLOCK_PERIOD / 2);
        clk <= '1';
        wait for (CLOCK_PERIOD / 2);
    end process;

end architecture;