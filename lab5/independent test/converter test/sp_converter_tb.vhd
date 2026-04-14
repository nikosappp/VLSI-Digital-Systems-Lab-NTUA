library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_sp_converter is
end tb_sp_converter;

architecture sim of tb_sp_converter is

    component sp_converter
        generic (
            N : integer := 1024
        );
        port (
            clk     : in std_logic;
            rst_n   : in std_logic;
            pixel   : in std_logic_vector(7 downto 0);
            enable  : in std_logic;
            p11, p12, p13,
            p21, p22, p23,
            p31, p32, p33   : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Using N=8 for a small, readable 8x8 image simulation
    constant C_N : integer := 8;

    signal clk      : std_logic := '0';
    signal rst_n    : std_logic := '0';
    signal pixel    : std_logic_vector(7 downto 0) := (others => '0');
    signal enable   : std_logic := '0';
    
    signal p11, p12, p13 : std_logic_vector(7 downto 0);
    signal p21, p22, p23 : std_logic_vector(7 downto 0);
    signal p31, p32, p33 : std_logic_vector(7 downto 0);

    -- Simulation control flags
    signal sim_done   : boolean := false;
    signal error_flag : std_logic := '0';

    constant clk_period : time := 10 ns;

begin

    uut: sp_converter 
    generic map ( N => C_N )
    port map (
        clk => clk, rst_n => rst_n, pixel => pixel, enable => enable,
        p11 => p11, p12 => p12, p13 => p13,
        p21 => p21, p22 => p22, p23 => p23,
        p31 => p31, p32 => p32, p33 => p33
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

    -- 2. STIMULUS PROCESS (Feeds pixels 1 to 64)
    stim_proc: process
        variable pixel_val : integer := 1;
    begin		
        rst_n <= '0';
        enable <= '0';
        wait for 20 ns;	
        
        rst_n <= '1';
        wait for clk_period*2;

        -- Feed an 8x8 image (Values 1 through 64 sequentially)
        for i in 0 to (C_N * C_N) - 1 loop
            pixel <= std_logic_vector(to_unsigned(pixel_val, 8));
            enable <= '1';
            wait for clk_period;
            pixel_val := pixel_val + 1;
        end loop;

        -- Flush pipeline
        enable <= '0';
        pixel <= (others => '0');
        wait for clk_period * C_N * 4;
        
        -- End simulation (stops the clock process)
        sim_done <= true;
        wait;
    end process;

    -- 3. MONITOR & ERROR CHECK PROCESS
    monitor_proc: process(clk)
        variable l : line;
        variable v_p22 : integer;
    begin
        if rising_edge(clk) then
            if rst_n = '1' then
                
                v_p22 := to_integer(unsigned(p22));

                -- Only start checking/printing when the center pixel is populated
                if v_p22 > 0 then
                    
                    -- A. Print the 3x3 grid to the TCL Console
                    write(l, string'("--- Time: ")); write(l, now); writeline(output, l);
                    write(l, string'("[ ")); write(l, to_integer(unsigned(p11))); write(l, string'(", ")); write(l, to_integer(unsigned(p12))); write(l, string'(", ")); write(l, to_integer(unsigned(p13))); write(l, string'(" ]")); writeline(output, l);
                    write(l, string'("[ ")); write(l, to_integer(unsigned(p21))); write(l, string'(", ")); write(l, to_integer(unsigned(p22))); write(l, string'(", ")); write(l, to_integer(unsigned(p23))); write(l, string'(" ]")); writeline(output, l);
                    write(l, string'("[ ")); write(l, to_integer(unsigned(p31))); write(l, string'(", ")); write(l, to_integer(unsigned(p32))); write(l, string'(", ")); write(l, to_integer(unsigned(p33))); write(l, string'(" ]")); writeline(output, l);
                    writeline(output, l); -- Blank line

                    -- B. Error Checking Logic
                    -- In a perfect sequential image, the pixel to the right is +1, and the pixel below is +N
                    error_flag <= '0'; -- Default to no error
                    
                    if to_integer(unsigned(p23)) /= v_p22 + 1 then
                        error_flag <= '1';
                    elsif to_integer(unsigned(p21)) /= v_p22 - 1 then
                        error_flag <= '1';
                    elsif to_integer(unsigned(p32)) /= v_p22 + C_N then
                        error_flag <= '1';
                    elsif to_integer(unsigned(p12)) /= v_p22 - C_N then
                        error_flag <= '1';
                    end if;

                else
                    error_flag <= '0';
                end if;
            end if;
        end if;
    end process;

end sim;