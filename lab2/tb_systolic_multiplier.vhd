library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_systolic_multiplier is
end tb_systolic_multiplier;

architecture Behavioral of tb_systolic_multiplier is

    constant CLK_PERIOD : time := 10 ns;
    
    -- Component Declaration
    component systolic_multiplier is
        port (
            clk : in  std_logic;
            A   : in  std_logic_vector(4-1 downto 0);
            B   : in  std_logic_vector(4-1 downto 0);
            P   : out std_logic_vector(2*4-1 downto 0)
        );
    end component;

    -- Signals connecting to the UUT (Unit Under Test)
    signal clk : std_logic := '0';
    signal A   : std_logic_vector(4-1 downto 0) := (others => '0');
    signal B   : std_logic_vector(4-1 downto 0) := (others => '0');
    signal P   : std_logic_vector(2*4-1 downto 0);

    -- The "Ghost Pipeline" for golden reference tracking
    -- We make an array of length 4+1 to delay our perfect mathematical result
    type delay_array is array (0 to 4) of std_logic_vector(2*4-1 downto 0);
    signal expected_pipe : delay_array := (others => (others => '0'));

    -- Verification Flags
    signal error_flag  : std_logic := '0';
    signal error_count : integer := 0;
    signal test_done   : std_logic := '0';

begin

    -- Instantiate the Unit Under Test
    uut: systolic_multiplier 
    port map (
        clk => clk, A => A, B => B, P => P
    );

    -- =========================================================================
    -- PROCESS 1: Clock Generation
    -- =========================================================================
    clk_proc: process
    begin
        while test_done = '0' loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait; -- Stop clock when tests are done
    end process;

    -- =========================================================================
    -- PROCESS 2: The Ghost Pipeline (Golden Reference)
    -- Calculates perfect A * B and delays it by N clock cycles to match the UUT
    -- =========================================================================
    ghost_pipeline_proc: process(clk)
        variable true_result : unsigned(2*4-1 downto 0);
    begin
        if rising_edge(clk) then
            -- 1. Calculate the perfect mathematical answer right now
            true_result := unsigned(A) * unsigned(B);
            
            -- 2. Feed it into the start of the delay line
            expected_pipe(0) <= std_logic_vector(true_result);
            
            -- 3. Shift everything down the line
            for i in 1 to 4 loop
                expected_pipe(i) <= expected_pipe(i-1);
            end loop;
        end if;
    end process;

    -- =========================================================================
    -- PROCESS 3: The Monitor / Checker (Runs on the Falling Edge)
    -- =========================================================================
    checker_proc: process(clk)
        -- Add a variable to count how many clock cycles have passed
        variable startup_cycles : integer := 0;
    begin
        if falling_edge(clk) then
            
            -- Ignore the first 7 clock cycles while the pipeline flushes the 'U's
            if startup_cycles < 7 then
                startup_cycles := startup_cycles + 1;
            else
                -- The pipeline is now full of real data! Start checking.
                if P /= expected_pipe(4) then
                    error_flag  <= '1'; -- Trip the flag!
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

    -- =========================================================================
    -- PROCESS 4: Exhaustive Stimulus Generation
    -- Feeds a new combination of A and B into the pipeline every single clock cycle
    -- =========================================================================
    stimulus_proc: process
    begin
        -- Wait for a couple of cycles to let the pipeline initialize with zeros
        wait for CLK_PERIOD * 2;

        -- Exhaustive nested loops: For N=4, this tests 0x0 through 15x15.
        for i in 0 to (2**4)-1 loop
            for j in 0 to (2**4)-1 loop
                
                A <= std_logic_vector(to_unsigned(i, 4));
                B <= std_logic_vector(to_unsigned(j, 4));
                
                -- Wait one clock cycle before feeding the next input
                wait for CLK_PERIOD; 
                
            end loop;
        end loop;

        -- We finished feeding inputs. Now we must wait N clock cycles for the 
        -- final few multiplications to flush out of the pipeline!
        wait for CLK_PERIOD * (4 + 2);

        -- Print final report
        if error_count = 0 then
            report "SUCCESS! All " & integer'image((2**4)*(2**4)) & " pipeline combinations passed perfectly." severity note;
        else
            report "FAILURE! Caught " & integer'image(error_count) & " errors during simulation." severity failure;
        end if;

        -- Stop the simulation
        test_done <= '1';
        wait;
    end process;

end Behavioral;