library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Used specifically for to_integer(unsigned()) in print statements
use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_debayering_filter is
end tb_debayering_filter;

architecture sim of tb_debayering_filter is
    constant N : integer := 1024;
    constant CLK_PERIOD : time := 10 ns;

    -- Component Signals
    signal clk            : std_logic := '0';
    signal rst_n          : std_logic := '0';
    signal new_image      : std_logic := '0';
    signal valid_in       : std_logic := '0';
    signal pixel          : std_logic_vector(7 downto 0) := (others => '0');
    signal valid_out      : std_logic;
    signal image_finished : std_logic;
    signal R, G, B        : std_logic_vector(7 downto 0);

    -- Debug & Verification Signals
    signal error_flag     : std_logic := '0';
    signal pixel_count    : integer := 0;

begin
    -- Instantiate the Top-Level Filter
    UUT: entity work.debayering_filter
        generic map ( N => N )
        port map (
            clk => clk, rst_n => rst_n, new_image => new_image,
            valid_in => valid_in, pixel => pixel,
            valid_out => valid_out, image_finished => image_finished,
            R => R, G => G, B => B
        );

    -- Clock Generation
    clk <= not clk after CLK_PERIOD / 2;

    -- Stimulus Process: Feeds the hardware and cleanly stops the simulation
    stimulus_proc: process
        file input_file : text open read_mode is "C:/VLSI/lab5-6/input_image.txt";
        variable row    : line;
        variable v_pixel : std_logic_vector(7 downto 0);
    begin
        -- Initial Reset
        rst_n <= '0';
        wait for 20 ns;
        rst_n <= '1';
        wait for CLK_PERIOD;

        -- Trigger New Image
        new_image <= '1';
        valid_in  <= '1';

        -- Read pixels and push them into the pipeline
        while not endfile(input_file) loop
            readline(input_file, row);
            read(row, v_pixel);
            pixel <= v_pixel;
            wait for CLK_PERIOD;
            new_image <= '0'; -- new_image is only a 1-cycle pulse
        end loop;

        -- Image fully read, stop valid_in and wait for pipeline to drain
        valid_in <= '0';
        
        -- Wait for the hardware to signal it is done
        wait until image_finished = '1';
        
        -- Give it a few extra cycles to settle, then aggressively stop Vivado
        wait for 100 ns;
        report "====== SIMULATION COMPLETED ======" severity note;
        assert false report "Simulation stopped intentionally." severity failure;
    end process;

    -- Verification Process: Checks hardware output against expected output
    checker_proc: process(clk)
        file expected_file : text open read_mode is "C:/VLSI/lab5-6/expected_output.txt";
        variable exp_row   : line;
        variable exp_R, exp_G, exp_B : std_logic_vector(7 downto 0);
    begin
        if rising_edge(clk) then
            -- We only check when the hardware says the output is valid
            if valid_out = '1' then
                if not endfile(expected_file) then
                    -- Read the expected values (TextIO handles the spaces automatically)
                    readline(expected_file, exp_row);
                    read(exp_row, exp_R);
                    read(exp_row, exp_G);
                    read(exp_row, exp_B);

                    pixel_count <= pixel_count + 1;

                    -- Compare Hardware vs Software
                    if (R /= exp_R) or (G /= exp_G) or (B /= exp_B) then
                        error_flag <= '1';
                        
                        report "MISMATCH at Valid Pixel #" & integer'image(pixel_count) & 
                               " | COMPUTED (R,G,B): (" & integer'image(to_integer(unsigned(R))) & "," & 
                                                          integer'image(to_integer(unsigned(G))) & "," & 
                                                          integer'image(to_integer(unsigned(B))) & ")" &
                               " | EXPECTED (R,G,B): (" & integer'image(to_integer(unsigned(exp_R))) & "," & 
                                                          integer'image(to_integer(unsigned(exp_G))) & "," & 
                                                          integer'image(to_integer(unsigned(exp_B))) & ")"
                               severity warning;
                               
                        -- ADD THIS LINE: Instantly kills the simulation on the first error
                        assert false report "STOPPING ON FIRST MISMATCH" severity failure; 
                    end if;
                end if;
            end if;
        end if;
    end process;

end sim;