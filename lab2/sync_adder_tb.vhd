library ieee;
use ieee.std_logic_1164.all;

entity sync_adder_tb is
end sync_adder_tb;

architecture tb of sync_adder_tb is

    component sync_adder
        port ( 
            clk       : in std_logic;
            a, b, cin : in std_logic;
            sum, cout : out std_logic
        );
    end component;
    
    signal clk  : std_logic := '0';
    signal a    : std_logic := '0';
    signal b    : std_logic := '0';
    signal cin  : std_logic := '0';
    
    signal sum  : std_logic;
    signal cout : std_logic;
    
    signal error_flag : std_logic := '0';
    
    constant CLOCK_PERIOD : time := 10 ns;

begin

    DUT : sync_adder port map (
        clk  => clk,
        a    => a,
        b    => b,
        cin  => cin,
        sum  => sum,
        cout => cout
    );
    
    clk_process : process
    begin
        clk <= '0';
        wait for CLOCK_PERIOD / 2;
        clk <= '1';
        wait for CLOCK_PERIOD / 2;
    end process;
    
    STIMULUS : process
    begin
        wait for CLOCK_PERIOD;

        -- Test Case 0: 0 + 0 + 0 = 0 (cout: 0)
        a <= '0'; b <= '0'; cin <= '0';
        wait for CLOCK_PERIOD; 
        if (sum /= '0' or cout /= '0') then error_flag <= '1'; else error_flag <= '0'; end if;

        -- Test Case 1: 0 + 0 + 1 = 1 (cout: 0)
        a <= '0'; b <= '0'; cin <= '1';
        wait for CLOCK_PERIOD;
        if (sum /= '1' or cout /= '0') then error_flag <= '1'; else error_flag <= '0'; end if;

        -- Test Case 2: 0 + 1 + 0 = 1 (cout: 0)
        a <= '0'; b <= '1'; cin <= '0';
        wait for CLOCK_PERIOD;
        if (sum /= '1' or cout /= '0') then error_flag <= '1'; else error_flag <= '0'; end if;

        -- Test Case 3: 0 + 1 + 1 = 0 (cout: 1)
        a <= '0'; b <= '1'; cin <= '1';
        wait for CLOCK_PERIOD;
        if (sum /= '0' or cout /= '1') then error_flag <= '1'; else error_flag <= '0'; end if;

        -- Test Case 4: 1 + 0 + 0 = 1 (cout: 0)
        a <= '1'; b <= '0'; cin <= '0';
        wait for CLOCK_PERIOD;
        if (sum /= '1' or cout /= '0') then error_flag <= '1'; else error_flag <= '0'; end if;

        -- Test Case 5: 1 + 0 + 1 = 0 (cout: 1)
        a <= '1'; b <= '0'; cin <= '1';
        wait for CLOCK_PERIOD;
        if (sum /= '0' or cout /= '1') then error_flag <= '1'; else error_flag <= '0'; end if;

        -- Test Case 6: 1 + 1 + 0 = 0 (cout: 1)
        a <= '1'; b <= '1'; cin <= '0';
        wait for CLOCK_PERIOD;
        if (sum /= '0' or cout /= '1') then error_flag <= '1'; else error_flag <= '0'; end if;

        -- Test Case 7: 1 + 1 + 1 = 1 (cout: 1)
        a <= '1'; b <= '1'; cin <= '1';
        wait for CLOCK_PERIOD;
        if (sum /= '1' or cout /= '1') then error_flag <= '1'; else error_flag <= '0'; end if;

        wait;
    end process;
    
end tb;