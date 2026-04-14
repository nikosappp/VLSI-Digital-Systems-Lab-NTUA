-- CLANKER CODE

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fir_8tap is
end tb_fir_8tap;

architecture behavior of tb_fir_8tap is
    -- Component Declaration for the Unit Under Test (UUT)
    component fir_8tap
    port(
         clk       : in  std_logic;
         rst       : in  std_logic;
         valid_in  : in  std_logic;
         x         : in  std_logic_vector(7 downto 0);
         valid_out : out std_logic;
         y         : out std_logic_vector(18 downto 0)
        );
    end component;

    -- UUT Signals
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal valid_in  : std_logic := '0';
    signal x         : std_logic_vector(7 downto 0) := (others => '0');
    signal valid_out : std_logic;
    signal y         : std_logic_vector(18 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;

    -- Testbench Math Model Arrays & Signals
    type int_array is array(0 to 7) of integer;
    signal x_hist         : int_array := (others => 0);
    signal expected_y     : integer := 0;
    signal expected_y_reg : integer := 0;

    -- 20-Sample Test Stimulus Array
    type test_data_array is array (0 to 19) of integer;
    constant TEST_SAMPLES : test_data_array := (
        1, 2, 3, 4, 5, 6, 7, 8,
        9, 10, 11, 12, 13, 14, 15, 16,
        17, 18, 19, 20
    );

    -- Simulation Status Flags
    signal error_flag : std_logic := '0';
    signal test_done  : std_logic := '0';

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: fir_8tap port map (
          clk       => clk,
          rst       => rst,
          valid_in  => valid_in,
          x         => x,
          valid_out => valid_out,
          y         => y
        );

    -- ------------------------------------------------------------------------
    -- CLOCK GENERATION (Stops when test_done is '1')
    -- ------------------------------------------------------------------------
    clk_process :process
    begin
        while test_done = '0' loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait; -- Halts the clock process permanently
    end process;

    -- ------------------------------------------------------------------------
    -- MATHEMATICAL MODEL
    -- ------------------------------------------------------------------------
    expected_y <= x_hist(0)*1 + x_hist(1)*2 + x_hist(2)*3 + x_hist(3)*4 +
                  x_hist(4)*5 + x_hist(5)*6 + x_hist(6)*7 + x_hist(7)*8;

    math_model_proc: process(clk, rst)
    begin
        if rst = '1' then
            x_hist <= (others => 0);
            expected_y_reg <= 0;
        elsif rising_edge(clk) then
            if valid_in = '1' then
                -- Register the EXPECTED result for the CURRENT history.
                expected_y_reg <= expected_y;

                -- Update history array for the next sample (Shift Right)
                x_hist(0) <= to_integer(unsigned(x));
                for i in 1 to 7 loop
                    x_hist(i) <= x_hist(i-1);
                end loop;
            end if;
        end if;
    end process;

    -- ------------------------------------------------------------------------
    -- SELF-CHECKING ASSERTION & ERROR FLAG
    -- ------------------------------------------------------------------------
    check_proc: process(clk)
    begin
        if rising_edge(clk) then
            if valid_out = '1' then
                if to_integer(unsigned(y)) /= expected_y_reg then
                    error_flag <= '1'; -- Trip the error flag
                    report "Mismatch! Expected Y: " & integer'image(expected_y_reg) &
                           ", Actual Y: " & integer'image(to_integer(unsigned(y)))
                    severity error;
                end if;
            end if;
        end if;
    end process;

    -- ------------------------------------------------------------------------
    -- STIMULUS PROCESS
    -- ------------------------------------------------------------------------
    stim_proc: process
    begin
        -- Hold Reset
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for clk_period * 2;

        -- Feed 20 test samples one by one
        for i in 0 to 19 loop
            x <= std_logic_vector(to_unsigned(TEST_SAMPLES(i), 8));
            valid_in <= '1';
            wait until rising_edge(clk);

            valid_in <= '0';
            
            -- Wait for 7 clock cycles to let the control unit and MAC accumulate all 8 taps
            for j in 0 to 6 loop
                wait until rising_edge(clk);
            end loop;
        end loop;

        -- Feed one final dummy cycle to flush the pipeline for the 20th sample
        x <= (others => '0');
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';
        wait until rising_edge(clk);

        -- Wait a few extra cycles to ensure the final calculation propagates
        wait for clk_period * 5;

        -- End the simulation
        test_done <= '1'; 
        
        if error_flag = '0' then
            report "Simulation completed SUCCESSFULLY. No errors detected." severity note;
        else
            report "Simulation completed with ERRORS. Check waveform for error_flag." severity warning;
        end if;
        
        wait; -- Halts the stimulus process
    end process;

end behavior;