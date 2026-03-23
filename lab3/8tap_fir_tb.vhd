library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity tb_fir_8tap is
end tb_fir_8tap;

architecture tb of tb_fir_8tap is

    component fir_8tap is
        port (
            clk       : in std_logic;
            rst       : in std_logic;
            valid_in  : in std_logic;
            x         : in std_logic_vector(8-1 downto 0);
            valid_out : out std_logic;
            y         : out std_logic_vector(19-1 downto 0)
        );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    -- Standard Signals
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal valid_in  : std_logic := '0';
    signal x         : std_logic_vector(8-1 downto 0) := (others => '0');
    signal valid_out : std_logic;
    signal y         : std_logic_vector(19-1 downto 0);
    signal error_flag: std_logic := '0';

    -- Expected output delay registers
    type out_array is array (0 to 3-1) of std_logic_vector(19-1 downto 0);
    signal exp_y_del : out_array := (others => (others => '0'));

    -- Simulation Control Flag
    signal test_done  : std_logic := '0';

    -- Filter coefficients
    type h_array is array (0 to 8-1) of integer;
    constant h_coeff : h_array := (1, 2, 3, 4, 5, 6, 7, 8);

    -- Input sequences
    type in_sequence is array (0 to 20-1) of integer;
    constant x_seq1 : in_sequence := (23, 145, 8, 201, 56, 178, 92, 12, 233, 45, 110, 77, 199, 3, 167, 88, 215, 61, 134, 250);
    constant x_seq2 : in_sequence := (233, 56, 178, 12, 201, 88, 145, 9, 212, 167, 34, 199, 100, 77, 241, 15, 132, 60, 225, 42);

    -- Input memory - holds values of x needed for convolution calculation
    type x_array is array (0 to 8-1) of std_logic_vector(8-1 downto 0);

begin

    uut: fir_8tap
    port map (
        clk       => clk,
        rst       => rst,
        valid_in  => valid_in,
        x         => x,
        valid_out => valid_out,
        y         => y
    );

    -- Clock Process: Halts automatically when test_done is '1'
    clk_process : process
    begin
        while test_done = '0' loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
        wait; -- Permanently stop this process
    end process;

    -- Stimulus Process: Apply Inputs
    stim_proc: process
        variable x_stim : std_logic_vector(7 downto 0) := x"00";
    begin
        -- Initialization
        rst       <= '1';
        valid_in  <= '0';
        x         <= (others => '0');
        test_done <= '0';

        -- Wait out GSR
        wait for CLK_PERIOD * 20;
        rst <= '0';
        
        -- DRIVE ON FALLING EDGE for timing safety
        wait until falling_edge(clk);

        -- First Loop: Normal operation with injected delay
        for i in 0 to 19 loop
            x_stim := conv_std_logic_vector(x_seq1(i), 8);
            
            -- Inject a delay before the last input sequence sample
            if i = 19 then
                report "Injecting an extra 15-cycle delay before sending the last sample..." severity note;
                wait for CLK_PERIOD * 15; 
            end if;

            x        <= x_stim;
            valid_in <= '1';
            wait for CLK_PERIOD;
            valid_in <= '0';
            wait for CLK_PERIOD * 7;
        end loop;

        wait for CLK_PERIOD * 10;

        -- Mid-operation reset test
        report "Testing reset mid-operation..." severity note;
        x_stim   := x"AA";
        x        <= x_stim;
        valid_in <= '1';
        wait for CLK_PERIOD;
        valid_in <= '0';
        wait for CLK_PERIOD * 3;
        rst <= '1';
        
        wait for CLK_PERIOD * 20;
        rst <= '0';
        wait until falling_edge(clk);

        -- Second Loop: Post-reset operation
        for i in 0 to 19 loop
            x_stim := conv_std_logic_vector(x_seq2(i), 8);
            x        <= x_stim;
            valid_in <= '1';
            wait for CLK_PERIOD;
            valid_in <= '0';
            wait for CLK_PERIOD * 7;
        end loop;

        wait for CLK_PERIOD * 20;
        
        -- End Simulation gracefully
        report "Simulation Finished successfully." severity note;
        test_done <= '1'; 
        wait;
    end process;

    -- CALCULATION PROCESS: Computes expected result
    calc_proc: process(clk, rst)
        variable v_x_hist : x_array := (others => (others => '0'));
        variable v_sum    : integer := 0;
    begin
        if rst = '1' then
            v_x_hist  := (others => (others => '0'));
            exp_y_del <= (others => (others => '0'));
            
        -- SAMPLE ON RISING EDGE for output timing safety
        elsif rising_edge(clk) then
            if valid_in = '1' then
                -- Shift history
                for i in 7 downto 1 loop
                    v_x_hist(i) := v_x_hist(i-1);
                end loop;
                v_x_hist(0) := x;

                -- Calculate sum
                v_sum := 0;
                for i in 0 to 7 loop
                    v_sum := v_sum + (conv_integer(v_x_hist(i)) * h_coeff(i));
                end loop;
                
                -- Store result in the first position of expected result delay array
                exp_y_del(0) <= conv_std_logic_vector(v_sum, 19);
            end if;

            -- Shift expected result
            exp_y_del(1) <= exp_y_del(0);
            exp_y_del(2) <= exp_y_del(1);
        end if;
    end process;

    -- CHECK PROCESS: Compares hardware output to expected result
    check_proc: process(clk, rst)
    begin
        if rst = '1' then
            error_flag <= '0';
            
        -- SAMPLE ON RISING EDGE for output timing safety
        elsif rising_edge(clk) then
            if valid_out = '1' then
                -- Compare hardware 'y' against 'exp_y_del'
                if y /= exp_y_del(2) then
                    error_flag <= '1';
                    assert false
                        report "MISMATCH! HW=" & integer'image(conv_integer(y)) &
                               " | EXP=" & integer'image(conv_integer(exp_y_del(2)))
                        severity error;
                else
                    error_flag <= '0';
                    assert false
                        report "OK! y=" & integer'image(conv_integer(y))
                        severity note;
                end if;
            end if;
        end if;
    end process;

end tb;