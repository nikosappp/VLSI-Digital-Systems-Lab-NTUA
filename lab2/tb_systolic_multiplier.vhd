-- 4-bit Systolic Multiplier (Testbench)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_systolic_multiplier is
end tb_systolic_multiplier;

architecture Behavioral of tb_systolic_multiplier is

    constant CLK_PERIOD : time := 10 ns;
    
    -- component declaration
    component systolic_multiplier is
        port (
            clk : in  std_logic;
            A   : in  std_logic_vector(4-1 downto 0);
            B   : in  std_logic_vector(4-1 downto 0);
            P   : out std_logic_vector(2*4-1 downto 0)
        );
    end component;

    -- signals connecting to the UUT
    signal clk : std_logic := '0';
    signal A   : std_logic_vector(4-1 downto 0) := (others => '0');
    signal B   : std_logic_vector(4-1 downto 0) := (others => '0');
    signal P   : std_logic_vector(2*4-1 downto 0);

    -- make an array of length 4+1 to delay mathematical result
    type delay_array is array (0 to 4) of std_logic_vector(2*4-1 downto 0);
    signal expected_pipe : delay_array := (others => (others => '0'));

    -- flags
    signal error_flag  : std_logic := '0';
    signal error_count : integer := 0;
    signal test_done   : std_logic := '0';

begin

    -- instantiate UUT
    uut: systolic_multiplier 
    port map (
        clk => clk, 
        A   => A, 
        B   => B, 
        P   => P
    );

    -- clock generation
    clk_proc: process
    begin
        while test_done = '0' loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- calculate A * B mathematically and delay by 4 clock cycles to match UUT
    ghost_pipeline_proc: process(clk)
        variable true_result : unsigned(2*4-1 downto 0);
    begin
        if rising_edge(clk) then
            -- calculate result
            true_result := unsigned(A) * unsigned(B);
            
            -- feed result to the start of the delay line
            expected_pipe(0) <= std_logic_vector(true_result);
            
            -- shift results down the line
            for i in 1 to 4 loop
                expected_pipe(i) <= expected_pipe(i-1);
            end loop;
        end if;
    end process;

    -- checker (runs on falling edge)
    checker_proc: process(clk)
        -- count how many clock cycles have passed
        variable startup_cycles : integer := 0;
    begin
        if falling_edge(clk) then
            -- ignore the first 7 clock cycles (flushing 'U's)
            if startup_cycles < 7 then
                startup_cycles := startup_cycles + 1;
            else
                -- pipeline ready, start checking
                if P /= expected_pipe(4) then       -- error detected
                    error_flag  <= '1';
                    error_count <= error_count + 1;
                    
                    report "MISMATCH CAUGHT! " & 
                           " Expected: " & integer'image(to_integer(unsigned(expected_pipe(4)))) & 
                           " Got: "      & integer'image(to_integer(unsigned(P))) 
                           severity error;
                else
                    error_flag <= '0'; 
                end if;
            end if;
        end if;
    end process;

    -- generate exhaustive stimulus
    stimulus_proc: process
    begin
        -- wait for a couple of cycles to let the pipeline initialize with zeros
        wait for CLK_PERIOD * 2;

        -- exhaustive nested loops (test for 0x0 through 15x15)
        for i in 0 to (2**4)-1 loop
            for j in 0 to (2**4)-1 loop
                
                A <= std_logic_vector(to_unsigned(i, 4));
                B <= std_logic_vector(to_unsigned(j, 4));
                
                -- wait one clock cycle before feeding the next input
                wait for CLK_PERIOD; 
                
            end loop;
        end loop;

        -- finished feeding inputs, wait for the final results to flush out of the pipeline\
        wait for CLK_PERIOD * (4+2);

        -- print final report
        if error_count = 0 then
            report "SUCCESS! All " & integer'image((2**4)*(2**4)) & " pipeline combinations passed perfectly." severity note;
        else
            report "FAILURE! Caught " & integer'image(error_count) & " errors during simulation." severity failure;
        end if;

        -- stop simulation
        test_done <= '1';
        wait;
    end process;

end Behavioral;