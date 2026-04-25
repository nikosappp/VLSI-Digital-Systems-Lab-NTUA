library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity systolic_pe is
    port (
        clk      : in  std_logic;
        i_a, i_b : in  std_logic;
        i_s, i_c : in  std_logic;
        o_a, o_b : out std_logic;
        o_s, o_c : out std_logic
    );
end entity systolic_pe;

architecture behav_sys_pe of systolic_pe is
    -- synchronous adder component declaration
    component sync_adder is
        port (
            clk       : in std_logic;
            a, b, cin : in std_logic;
            sum, cout : out std_logic
        );
    end component;

    signal pp   : std_logic;    -- partial product   

    -- D ff regs for pipelining
    signal a_reg1, a_reg2 : std_logic := '0';
    signal b_reg          : std_logic := '0';

begin
    -- compute partial product
    pp <= i_a and i_b;

    -- instantiate synchronous adder
    FA: sync_adder
        port map (
            clk  => clk,
            a    => pp,
            b    => i_s,
            cin  => i_c,
            sum  => o_s,    -- 1 cycle delay
            cout => o_c    -- 1 cycle delay
        );

    -- pipeline delays (D ffs)
    process(clk)
    begin
        if rising_edge(clk) then
            b_reg  <= i_b;      -- delay b by 1 clock cycle

            a_reg1 <= i_a;
            a_reg2 <= a_reg1;   -- delay a by 2 clock cycles
        end if;
    end process;

    -- feed delayed signals to out ports
    o_b <= b_reg;
    o_a <= a_reg2;

end architecture behav_sys_pe;