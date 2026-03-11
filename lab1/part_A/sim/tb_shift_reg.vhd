-- 4-bit Shift Register with Parallel Load - TESTBENCH

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_shift_reg is
end entity;

architecture tb of tb_shift_reg is 
    -- Component
    component shift_reg is 
        port (
            clk, rst, si, en, ls, pl : in std_logic;
            din : in std_logic_vector(4-1 downto 0);
            so : out std_logic
        );
    end component;

    -- Signals
    signal clk : std_logic;
    signal rst : std_logic := '0';
    signal si : std_logic := '0';
    signal en : std_logic := '0';
    signal ls : std_logic := '0';
    signal pl : std_logic := '0';
    signal din : std_logic_vector(4-1 downto 0) := (others => '0');
    signal so : std_logic;

    -- Constants
    constant CLOCK_PERIOD : time := 10 ns;

begin

    DUT : shift_reg
        port map (
            clk => clk,
            rst => rst,
            si => si,
            en => en,
            ls => ls,
            pl => pl,
            din => din,
            so => so
        );
    
    STIMULUS : process
    begin
        -- Reset
        rst <= '0';
        wait for (2 * CLOCK_PERIOD);
        rst <= '1';
        wait for (1 * CLOCK_PERIOD);

        -- Test Right Shift
        pl <= '1';
        din <= "1001";      -- load "1001"
        wait for (1 * CLOCK_PERIOD);
        pl <= '0';
        en <= '1';
        ls <= '0';
        si <= '0';                      -- feed zeros from the left
        wait for (4 * CLOCK_PERIOD);    -- shift 4 times
        en <= '0';                      -- stop shifting
        wait for (1 * CLOCK_PERIOD);

        -- Test Left Shift
        pl <= '1';
        din <= "1010";      -- load "1010"
        wait for (1 * CLOCK_PERIOD);
        pl <= '0';
        en <= '1';
        ls <= '1';
        si <= '1';                      -- feed ones from the right
        wait for (4 * CLOCK_PERIOD);    -- shift 4 times
        en <= '0';                      -- stop shifting
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