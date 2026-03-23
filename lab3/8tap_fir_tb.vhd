library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity tb_fir_8tap is
end tb_fir_8tap;

architecture behavioral of tb_fir_8tap is

    component fir_8tap is
        port (
            clk       : in std_logic;
            rst       : in std_logic;
            valid_in  : in std_logic;
            x         : in std_logic_vector(7 downto 0);
            valid_out : out std_logic;
            y         : out std_logic_vector(18 downto 0)
        );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal valid_in  : std_logic := '0';
    signal x         : std_logic_vector(7 downto 0) := (others => '0');
    signal valid_out : std_logic;
    signal y         : std_logic_vector(18 downto 0);

    signal error_flag         : std_logic := '0';

    -- for error checking
    type exp_fifo_type is array (0 to 63) of std_logic_vector(18 downto 0);
    signal exp_fifo : exp_fifo_type := (others => (others => '0'));
    signal wr_ptr   : integer := 0;
    signal rd_ptr   : integer := 0;

    type h_array is array (0 to 7) of integer;
    constant h_coeff : h_array := (1, 2, 3, 4, 5, 6, 7, 8);

    type x_array is array (0 to 7) of std_logic_vector(7 downto 0);

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

    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    stim_proc: process
        variable x_stim : std_logic_vector(7 downto 0) := x"00";
    begin
        rst      <= '1';
        valid_in <= '0';
        x        <= (others => '0');
        -- ΑΛΛΑΓΗ: 20 κύκλοι reset αντί για 5, για να περάσει το GSR
        wait for CLK_PERIOD * 20;
        rst <= '0';
        wait until falling_edge(clk);

        for i in 1 to 20 loop
            x_stim   := x_stim + 3;
            
            -- INJECT DELAY: If we are about to send the 20th input (x = 60)
            if i = 20 then
                report "Injecting an extra 15-cycle delay before sending 60..." severity note;
                wait for CLK_PERIOD * 15; 
            end if;

            x        <= x_stim;
            valid_in <= '1';
            wait for CLK_PERIOD;
            valid_in <= '0';
            wait for CLK_PERIOD * 7;
        end loop;

        wait for CLK_PERIOD * 10;

        report "Testing reset mid-operation..." severity note;
        x_stim   := x"AA";
        x        <= x_stim;
        valid_in <= '1';
        wait for CLK_PERIOD;
        valid_in <= '0';
        wait for CLK_PERIOD * 3;
        rst <= '1';
        -- ΑΛΛΑΓΗ: 20 κύκλοι reset και εδώ
        wait for CLK_PERIOD * 20;
        rst <= '0';
        wait until falling_edge(clk);

        for i in 1 to 10 loop
            x_stim   := x_stim + 5;
            x        <= x_stim;
            valid_in <= '1';
            wait for CLK_PERIOD;
            valid_in <= '0';
            wait for CLK_PERIOD * 7;
        end loop;

        wait for CLK_PERIOD * 20;
        report "Simulation Finished." severity note;
        wait;
    end process;

    calc_proc: process(clk, rst)
        variable v_x_hist : x_array := (others => (others => '0'));
        variable v_sum    : integer := 0;
    begin
        if rst = '1' then
            v_x_hist := (others => (others => '0'));
            wr_ptr   <= 0;
        elsif rising_edge(clk) then
            if valid_in = '1' then
                for i in 7 downto 1 loop
                    v_x_hist(i) := v_x_hist(i-1);
                end loop;
                v_x_hist(0) := x;

                v_sum := 0;
                for i in 0 to 7 loop
                    v_sum := v_sum + (conv_integer(v_x_hist(i)) * h_coeff(i));
                end loop;
                
                -- PUSH into FIFO and increment pointer (wrap around at 64)
                exp_fifo(wr_ptr) <= conv_std_logic_vector(v_sum, 19);
                wr_ptr <= (wr_ptr + 1) mod 64;
            end if;
        end if;
    end process;

    check_proc: process(clk, rst)
    begin
        if rst = '1' then
            error_flag <= '0';
            rd_ptr     <= 0;
        elsif rising_edge(clk) then
            if valid_out = '1' then
                -- POP from FIFO and compare
                if y /= exp_fifo(rd_ptr) then
                    error_flag <= '1';
                    assert false
                        report "MISMATCH! HW=" & integer'image(conv_integer(y)) &
                               " | EXP=" & integer'image(conv_integer(exp_fifo(rd_ptr)))
                        severity error;
                else
                    error_flag <= '0';
                    assert false
                        report "OK! y=" & integer'image(conv_integer(y))
                        severity note;
                end if;
                -- Increment pointer
                rd_ptr <= (rd_ptr + 1) mod 64;
            end if;
        end if;
    end process;

end behavioral;
