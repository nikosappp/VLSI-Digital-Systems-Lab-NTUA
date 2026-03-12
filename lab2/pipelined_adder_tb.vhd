library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipelined_adder_tb is
end pipelined_adder_tb;

architecture behavior of pipelined_adder_tb is

    -- 1. Component Declaration for the DUT (Device Under Test)
    component pipelined_adder
        port (
            clk       : in std_logic;
            A         : in std_logic_vector(3 downto 0);
            B         : in std_logic_vector(3 downto 0);
            pipe_cin  : in std_logic;
            final_sum : out std_logic_vector(3 downto 0);
            final_cout : out std_logic
        );
    end component;

    -- Input and Output Signals
    signal clk       : std_logic := '0';
    signal A         : std_logic_vector(3 downto 0) := (others => '0');
    signal B         : std_logic_vector(3 downto 0) := (others => '0');
    signal pipe_cin  : std_logic := '0';
    
    signal final_sum : std_logic_vector(3 downto 0);
    signal final_cout : std_logic;

    -------------------------------------------------------
    -- === Verification Signals (Self-Checking Logic) ===--
    -------------------------------------------------------
    
    signal error_flag        : std_logic := '0';
    -- it becomes '1' only if a mismatch is detected between the actual output and the expected result
    signal cin_ext           : unsigned(4 downto 0);
    -- Since pipe_cin is a 1-bit std_logic, 
    -- we extend it to 5 bits ("00000" or "00001") so we can mathematically add it directly with vectors A and B
    signal expected_sum_comb : unsigned(4 downto 0);
    -- The expected result. The testbench calculates the correct sum here (A + B + cin_ext)
    -- It is 5 bits wide to hold both the 4-bit sum and the final carry-out
    signal exp_d1, exp_d2, exp_d3, exp_d4 : unsigned(4 downto 0) := (others => '0'); 
    -- Testbench delay line. Because our pipeline needs 3 intermediate 
    -- clock cycles to produce the result, we intentionally delay the result by 3 cycles (d1, d2, d3, d4). 
    -- This allows us to compare the correct data at the correct time
    signal actual_out        : unsigned(4 downto 0);
    -- The total actual output of our circuit
    
    -- Clock period definition
    constant CLK_PERIOD : time := 10 ns;

begin

    DUT: pipelined_adder port map (
        clk       => clk,
        A         => A,
        B         => B,
        pipe_cin  => pipe_cin,
        final_sum => final_sum,
        final_cout => final_cout
    );

    -- Clock Generation Process
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    
    
    -- Note : The lines below are OUTSIDE of any process.
    -- In VHDL, this means they act as physical wires and pure combinational logic.
    -- They do NOT wait for a clock edge. They are continuously active and 
    -- will update their outputs instantly (in 0 simulation time) the moment 
    -- any signal on the right side of the assignment (<=) changes its value.
    
    -- For example: As soon as the STIMULUS loop changes 'A', 'B', or 'pipe_cin', 
    -- 'expected_sum_comb' and 'cin_ext' are recalculated immediately.
    
    -- Convert pipe_cin to a 5-bit unsigned vector for mathematical addition
    cin_ext <= "00001" when pipe_cin = '1' else "00000";

    -- Calculate the expected result combinationally (5-bit to include carry out)
    expected_sum_comb <= resize(unsigned(A), 5) + resize(unsigned(B), 5) + cin_ext;

    -- Concatenate actual outputs into a single 5-bit vector for easy comparison
    actual_out <= unsigned(final_cout & final_sum);

    -- Delay line for the expected result to match the pipeline's 3-cycle latency
    DELAY_EXPECTED_PROCESS : process(clk)
    begin
        if rising_edge(clk) then
            exp_d1 <= expected_sum_comb;
            exp_d2 <= exp_d1;
            exp_d3 <= exp_d2;
            exp_d4 <= exp_d3; -- Η "χαμένη" 4η καθυστέρηση που μας έλειπε!
        end if;
    end process;

    -- Compare actual output with the delayed expected output
    CHECKER_PROCESS : process(clk)
        variable cycle_count : integer := 0;
    begin
        -- We check on the falling edge to ensure all output signals are completely stable
        if falling_edge(clk) then
            -- Wait 4 clock cycles for the pipeline to fill up before checking for errors
            if cycle_count >= 5 then 
                if actual_out /= exp_d4 then
                    error_flag <= '1'; -- ERROR DETECTED!
                else
                    error_flag <= '0'; -- Output is correct
                end if;
            end if;
            cycle_count := cycle_count + 1;
        end if;
    end process;

    
    STIMULUS : process
    begin
        -- Wait for 1 clock cycle before applying the first inputs
        wait for CLK_PERIOD;

        -- Exhaustive testing: Iterate through all 512 possible combinations
        for i in 0 to 15 loop         -- A values: 0 to 15
            for j in 0 to 15 loop     -- B values: 0 to 15
                for k in 0 to 1 loop  -- Cin values: 0 or 1
                    
                    A <= std_logic_vector(to_unsigned(i, 4));  -- Παίρνει τον ακέραιο i και τον κάνει έναν καθαρό 4-bit αριθμό.
                    B <= std_logic_vector(to_unsigned(j, 4));  -- Τον μετατρέπει σε std_logic_vactor για να τον συνδέσουμε στο κύκλωμα 
                    
                    if k = 1 then
                        pipe_cin <= '1';
                    else
                        pipe_cin <= '0';
                    end if;

                    -- Wait for 1 clock cycle to feed the NEXT input into the pipeline
                    wait for CLK_PERIOD;
                    
                end loop;
            end loop;
        end loop;

        -- Wait a few extra clock cycles to flush the final results out of the pipeline
        wait for 5 * CLK_PERIOD;

        -- Stop simulation
        wait;
    end process;

end behavior;