library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_debayering_filter is
end tb_debayering_filter;

architecture tb of tb_debayering_filter is
    -- Component Declaration
    component debayering_filter
        port (
            clk            : in  std_logic;
            rst_n          : in  std_logic;
            new_image      : in  std_logic;
            valid_in       : in  std_logic;
            pixel          : in  std_logic_vector(7 downto 0);
            image_dim      : in  std_logic_vector(10 downto 0);
            image_dim_vld  : in  std_logic;
            valid_out      : out std_logic;
            image_finished : out std_logic;
            R, G, B        : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Constants
    constant CLK_PERIOD : time := 10 ns;

    -- Signals
    signal clk            : std_logic := '0';
    signal rst_n          : std_logic := '0';
    signal new_image      : std_logic := '0';
    signal valid_in       : std_logic := '0';
    signal pixel          : std_logic_vector(7 downto 0) := (others => '0');
    signal image_dim      : std_logic_vector(10 downto 0) := (others => '0');
    signal image_dim_vld  : std_logic := '0';
    signal R, G, B        : std_logic_vector(7 downto 0);
    signal valid_out      : std_logic;
    signal image_finished : std_logic;

    -- Verification Signals
    signal test_done      : std_logic := '0';
    signal error_flag     : std_logic := '0';
    signal error_counter  : integer   := 0;

begin

    UUT: debayering_filter
        port map (
            clk => clk, rst_n => rst_n, new_image => new_image,
            valid_in => valid_in, pixel => pixel,
            image_dim => image_dim, image_dim_vld => image_dim_vld,
            valid_out => valid_out, image_finished => image_finished,
            R => R, G => G, B => B
        );

    -- Clock Generation
    clk_process : process
    begin
        if test_done = '1' then wait; end if;
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    
    stim_proc : process
        file in_file     : text;
        variable in_line : line;
        variable pix_val : std_logic_vector(7 downto 0);
    begin
        -- initialization
        rst_n <= '0'; wait for CLK_PERIOD * 10; rst_n <= '1';
        wait for CLK_PERIOD * 2;

        -- --- IMAGE 1 ---
        image_dim <= std_logic_vector(to_unsigned(128, 11));
        wait for 1 ns; 
        image_dim_vld <= '1';
        wait for CLK_PERIOD * 5;
        image_dim_vld <= '0';
        wait for CLK_PERIOD * 5;

        file_open(in_file, "C:\VLSI\bonus\input_image_128.txt", read_mode);
        new_image <= '1';
        while not endfile(in_file) loop
            if new_image = '1' then new_image <= '0'; end if;
            readline(in_file, in_line);
            read(in_line, pix_val);
            pixel <= pix_val; valid_in <= '1';
            wait for CLK_PERIOD;
        end loop;
        valid_in <= '0';
        wait until rising_edge(clk) and image_finished = '1';
        file_close(in_file);
        wait for CLK_PERIOD * 20; -- stall between images

        -- --- IMAGE 2 ---
        image_dim <= std_logic_vector(to_unsigned(1024, 11));
        wait for 1 ns;
        image_dim_vld <= '1'; -- Soft Reset & Latch 
        wait for CLK_PERIOD * 5;
        image_dim_vld <= '0';
        wait for CLK_PERIOD * 5;

        file_open(in_file, "C:\VLSI\bonus\input_image_1024.txt", read_mode);
        new_image <= '1';
        while not endfile(in_file) loop
            if new_image = '1' then new_image <= '0'; end if;
            readline(in_file, in_line);
            read(in_line, pix_val);
            pixel <= pix_val; valid_in <= '1';
            wait for CLK_PERIOD;
        end loop;
        valid_in <= '0';
        wait until rising_edge(clk) and image_finished = '1';
        file_close(in_file);

        test_done <= '1';
        wait;
    end process;

    
    check_proc : process
        file exp_file     : text;
        variable exp_line : line;
        variable exp_R, exp_G, exp_B : std_logic_vector(7 downto 0);
        variable space1, space2      : character;
        variable current_dim : integer;
    begin
        while test_done = '0' loop
            -- wait for Configuration signal
            wait until rising_edge(clk) and image_dim_vld = '1';
            
            -- !!!!! wait 1ns before we read the new value of image_dim
            wait for 1 ns; 
            current_dim := to_integer(unsigned(image_dim));

            
            if current_dim = 128 then
                file_open(exp_file, "C:\VLSI\bonus\expected_output_128.txt", read_mode);
            elsif current_dim = 1024 then
                file_open(exp_file, "C:\VLSI\bonus\expected_output_1024.txt", read_mode);
            end if;

            wait until image_dim_vld = '0';

            
            while not endfile(exp_file) loop
                wait until rising_edge(clk);
                
                -- stop if a new configuration arrives
                if image_dim_vld = '1' then exit; end if;

                if valid_out = '1' then
                    readline(exp_file, exp_line);
                    read(exp_line, exp_R); read(exp_line, space1);
                    read(exp_line, exp_G); read(exp_line, space2);
                    read(exp_line, exp_B);

                    if (R /= exp_R) or (G /= exp_G) or (B /= exp_B) then
                        error_flag <= '1'; 
                        error_counter <= error_counter + 1;
                    else
                        error_flag <= '0';
                    end if;
                end if;
                if image_finished = '1' then exit; end if;
            end loop;

            file_close(exp_file);
            if test_done = '1' then wait; end if;
        end loop;
        wait;
    end process;

end tb;