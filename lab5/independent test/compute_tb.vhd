library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_compute_unit is
end tb_compute_unit;

architecture sim of tb_compute_unit is

    -- Component Declaration
    component compute_unit
        port (
            clk         : in std_logic;
            ctrl        : in std_logic_vector(1 downto 0);
            top_edge    : in std_logic;
            bottom_edge : in std_logic;
            left_edge   : in std_logic;
            right_edge  : in std_logic;
            p11, p12, p13 : in std_logic_vector(7 downto 0);
            p21, p22, p23 : in std_logic_vector(7 downto 0);
            p31, p32, p33 : in std_logic_vector(7 downto 0);
            R, G, B       : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Signals
    signal clk          : std_logic := '0';
    signal ctrl         : std_logic_vector(1 downto 0) := "00";
    signal top_edge, bottom_edge, left_edge, right_edge : std_logic := '0';
    signal p11, p12, p13 : std_logic_vector(7 downto 0) := (others => '0');
    signal p21, p22, p23 : std_logic_vector(7 downto 0) := (others => '0');
    signal p31, p32, p33 : std_logic_vector(7 downto 0) := (others => '0');
    signal R, G, B      : std_logic_vector(7 downto 0);

    -- Simulation control flags
    signal sim_done   : boolean := false;
    signal error_flag : std_logic := '0';

    constant clk_period : time := 10 ns;

begin

    uut: compute_unit
        port map (
            clk => clk, ctrl => ctrl,
            top_edge => top_edge, bottom_edge => bottom_edge,
            left_edge => left_edge, right_edge => right_edge,
            p11 => p11, p12 => p12, p13 => p13,
            p21 => p21, p22 => p22, p23 => p23,
            p31 => p31, p32 => p32, p33 => p33,
            R => R, G => G, B => B
        );

    -- 1. CLOCK GENERATOR (Stops when sim_done is true)
    clk_process :process
    begin
        while not sim_done loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait; -- Stop forever
    end process;

    -- 2. STIMULUS AND CHECK PROCESS
    stim_proc: process
        variable l : line;
        
        -- Helper Procedure: Automatically waits 1 cycle and checks the math
        procedure check_math(exp_R, exp_G, exp_B : integer; test_name : string) is
        begin
            -- Wait 1 clock cycle for the compute_unit to process the inputs
            wait for clk_period;
            
            if to_integer(unsigned(R)) /= exp_R or
               to_integer(unsigned(G)) /= exp_G or
               to_integer(unsigned(B)) /= exp_B then
               
               error_flag <= '1';
               write(l, string'("--- [FAIL] --- ")); write(l, test_name); writeline(output, l);
               write(l, string'("  Expected RGB: [ ")); write(l, exp_R); write(l, string'(", ")); write(l, exp_G); write(l, string'(", ")); write(l, exp_B); write(l, string'(" ]")); writeline(output, l);
               write(l, string'("  Received RGB: [ ")); write(l, to_integer(unsigned(R))); write(l, string'(", ")); write(l, to_integer(unsigned(G))); write(l, string'(", ")); write(l, to_integer(unsigned(B))); write(l, string'(" ]")); writeline(output, l);
               writeline(output, l);
            else
               error_flag <= '0';
               write(l, string'("--- [PASS] --- ")); write(l, test_name); writeline(output, l);
               writeline(output, l);
            end if;
            
            -- Wait a bit before the next test so waveform pulses are clear
            wait for clk_period * 2;
        end procedure;

    begin
        -- Initial Wait
        wait for 20 ns;

        ------------------------------------------------------------------
        -- TEST 1: Case (i) Green center, NO edges
        ------------------------------------------------------------------
        ctrl <= "00";
        top_edge <= '0'; bottom_edge <= '0'; left_edge <= '0'; right_edge <= '0';
        p22 <= x"32"; -- G=50
        p21 <= x"64"; p23 <= x"C8"; -- R neighbors (100, 200). Avg = 150
        p12 <= x"28"; p32 <= x"3C"; -- B neighbors (40, 60).   Avg = 50
        check_math(150, 50, 50, "Test 1: Green Center (Case i), No Edges");

        ------------------------------------------------------------------
        -- TEST 2: Case (iii) Red center, TOP EDGE active
        ------------------------------------------------------------------
        ctrl <= "10";
        top_edge <= '1'; bottom_edge <= '0'; left_edge <= '0'; right_edge <= '0';
        p22 <= x"64"; -- R=100
        p12 <= x"FF"; -- Should be masked to 0 by top_edge
        p21 <= x"14"; p23 <= x"28"; p32 <= x"3C"; -- G neighbors (20, 40, 60). Avg = (0+20+40+60)/4 = 30
        p11 <= x"FF"; p13 <= x"FF"; -- Should be masked to 0 by top_edge
        p31 <= x"50"; p33 <= x"78"; -- B corners (80, 120). Avg = (0+0+80+120)/4 = 50
        check_math(100, 30, 50, "Test 2: Red Center (Case iii), Top Edge Padding");

        ------------------------------------------------------------------
        -- TEST 3: Case (iv) Blue center, LEFT EDGE active
        ------------------------------------------------------------------
        ctrl <= "11";
        top_edge <= '0'; bottom_edge <= '0'; left_edge <= '1'; right_edge <= '0';
        p22 <= x"C8"; -- B=200
        p21 <= x"FF"; -- Should be masked to 0 by left_edge
        p12 <= x"64"; p23 <= x"64"; p32 <= x"28"; -- G neighbors (100, 100, 40). Avg = (100+0+100+40)/4 = 60
        p11 <= x"FF"; p31 <= x"FF"; -- Should be masked to 0 by left_edge
        p13 <= x"64"; p33 <= x"3C"; -- R corners (100, 60). Avg = (0+100+0+60)/4 = 40
        check_math(40, 60, 200, "Test 3: Blue Center (Case iv), Left Edge Padding");

        ------------------------------------------------------------------
        -- END SIMULATION
        ------------------------------------------------------------------
        sim_done <= true;
        wait;
    end process;

end sim;