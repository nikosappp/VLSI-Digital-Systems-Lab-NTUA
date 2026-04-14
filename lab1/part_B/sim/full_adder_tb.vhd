library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder_tb is
end full_adder_tb;

architecture tb of full_adder_tb is

    component full_adder
        port (
            fa, fb, cin : in std_logic;
            full_sum, carry_out : out std_logic
        );
    end component;

    signal fa_tb        : std_logic := '0';
    signal fb_tb        : std_logic := '0';
    signal cin_tb       : std_logic := '0';
    signal full_sum_tb  : std_logic;
    signal carry_out_tb : std_logic;

begin

    UUT: full_adder 
    port map (
        fa        => fa_tb,
        fb        => fb_tb,
        cin       => cin_tb,
        full_sum  => full_sum_tb,
        carry_out => carry_out_tb
    );

    -- Applying all 8 possible input combinations
    STIMULUS : process
    begin
        -- Test Case 1: 0 + 0 + 0 = 0 (Sum=0, Carry=0)
        fa_tb <= '0'; fb_tb <= '0'; cin_tb <= '0';
        wait for 20 ns;
        
        -- Test Case 2: 0 + 0 + 1 = 1 (Sum=1, Carry=0)
        fa_tb <= '0'; fb_tb <= '0'; cin_tb <= '1';
        wait for 20 ns;

        -- Test Case 3: 0 + 1 + 0 = 1 (Sum=1, Carry=0)
        fa_tb <= '0'; fb_tb <= '1'; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 4: 0 + 1 + 1 = 2 (Sum=0, Carry=1)
        fa_tb <= '0'; fb_tb <= '1'; cin_tb <= '1';
        wait for 20 ns;

        -- Test Case 5: 1 + 0 + 0 = 1 (Sum=1, Carry=0)
        fa_tb <= '1'; fb_tb <= '0'; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 6: 1 + 0 + 1 = 2 (Sum=0, Carry=1)
        fa_tb <= '1'; fb_tb <= '0'; cin_tb <= '1';
        wait for 20 ns;

        -- Test Case 7: 1 + 1 + 0 = 2 (Sum=0, Carry=1)
        fa_tb <= '1'; fb_tb <= '1'; cin_tb <= '0';
        wait for 20 ns;

        -- Test Case 8: 1 + 1 + 1 = 3 (Sum=1, Carry=1)
        fa_tb <= '1'; fb_tb <= '1'; cin_tb <= '1';
        wait for 20 ns;

        -- Stop the simulation
        wait;
    end process;

end tb;