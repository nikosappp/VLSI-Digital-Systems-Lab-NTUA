library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- Required libraries for file I/O
library std;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_debayering_filter is
end tb_debayering_filter;

architecture tb of tb_debayering_filter is
    -- Component Declaration for the Unit Under Test (UUT)
    component debayering_filter
        generic (
            N : integer
        );
        port (
            clk            : in  std_logic;
            rst_n          : in  std_logic;
            new_image      : in  std_logic;
            valid_in       : in  std_logic;
            pixel          : in  std_logic_vector(8-1 downto 0);
            valid_out      : out std_logic;
            image_finished : out std_logic;
            R, G, B        : out std_logic_vector(8-1 downto 0)
        );
    end component;

    -- Generic configuration
    constant N : integer := 1024; -- Set this to match your test image width
    constant CLK_PERIOD : time := 10 ns;

    -- UUT Signals
    signal clk            : std_logic := '0';
    signal rst_n          : std_logic := '0';
    signal new_image      : std_logic := '0';
    signal valid_in       : std_logic := '0';
    signal pixel          : std_logic_vector(8-1 downto 0) := (others => '0');
    signal R, G, B        : std_logic_vector(8-1 downto 0);
    signal valid_out      : std_logic;
    signal image_finished : std_logic;

    -- Verification Signals
    signal error_flag     : std_logic := '0';
    signal error_counter  : integer := 0;
    signal test_done      : std_logic := '0';

begin

    -- Instantiate the Unit Under Test
    UUT: debayering_filter
        generic map ( N => N )
        port map (
            clk            => clk,
            rst_n          => rst_n,
            new_image      => new_image,
            valid_in       => valid_in,
            pixel          => pixel,
            R              => R,
            G              => G,
            B              => B,
            valid_out      => valid_out,
            image_finished => image_finished
        );

    -- Clock Generation Process
    -- Halts completely when test_done is raised
    clk_process : process
    begin
        if test_done = '1' then
            wait; -- Stop the clock, halting simulation
        end if;
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus Process: Reads input.txt and drives UUT
    stim_proc : process
        file in_file     : text open read_mode is "input_image.txt";
        variable in_line : line;
        variable pix_val : std_logic_vector(8-1 downto 0);
    begin
        -- Initial State
        valid_in <= '0';
        pixel    <= (others => '0');
        
        -- Apply System Reset
        rst_n <= '0';
        wait for CLK_PERIOD * 5;
        rst_n <= '1';
        wait for CLK_PERIOD * 2;

        -- Pulse new_image to wake up the Control Unit
        new_image <= '1';

        -- Stream the file data into the pipeline
        while not endfile(in_file) loop
            if (new_image = '1') then
                new_image <= '0';
            end if;
            
            readline(in_file, in_line);
            read(in_line, pix_val); 
            
            -- Apply to bus
            pixel <= pix_val;
            valid_in <= '1';
            
            -- Wait for next clock edge
            wait for CLK_PERIOD;
        end loop;

        -- End of file reached, stop feeding valid data
        valid_in <= '0';
        
        -- Wait for the pipeline to flush naturally
        wait until image_finished = '1';
        
        -- Hold for a few cycles before flagging done
        wait for CLK_PERIOD * 5;
        test_done <= '1';
        wait;
    end process;

    -- =========================================================
    -- Checker Process: Reads expected.txt and compares outputs
    -- =========================================================
    check_proc : process
        file exp_file    : text open read_mode is "expected_output.txt";
        variable exp_line: line;
        variable exp_R   : std_logic_vector(7 downto 0);
        variable exp_G   : std_logic_vector(7 downto 0);
        variable exp_B   : std_logic_vector(7 downto 0);
        variable space1  : character; -- Used to consume the space between binary strings
        variable space2  : character;
    begin
        -- Wait until reset is released before checking
        wait until rst_n = '1';

        while not endfile(exp_file) loop
            -- Only check on the rising edge when output is declared valid
            wait until rising_edge(clk);
            
            if valid_out = '1' then
                readline(exp_file, exp_line);
                
                -- Read the three expected RGB values (assuming space-separated binary)
                read(exp_line, exp_R);
                read(exp_line, space1);
                read(exp_line, exp_G);
                read(exp_line, space2);
                read(exp_line, exp_B);

                -- Compare Expected vs Actual
                if (R /= exp_R) or (G /= exp_G) or (B /= exp_B) then
                    error_flag <= '1';
                    error_counter <= error_counter + 1;
                    report "Mismatch detected at output pixel!" severity warning;
                else
                    error_flag <= '0';
                end if;
            end if;

            -- Safety exit if the pipeline finishes before the file runs out
            if image_finished = '1' then
                exit;
            end if;
        end loop;
        
        wait;
    end process;

end tb;