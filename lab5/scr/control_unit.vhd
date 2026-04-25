library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity control_unit is
    generic (
        N : integer := 32
    );
    port (
        clk            : in  std_logic;
        rst_n          : in  std_logic;
        new_image      : in  std_logic;
        valid_in       : in  std_logic;
        -- Output to sp_converter
        datapath_en    : out std_logic; 
        -- Control signals to Compute Unit
        ctrl           : out std_logic_vector(1 downto 0);
        top_edge       : out std_logic;
        bottom_edge    : out std_logic;
        left_edge      : out std_logic;
        right_edge     : out std_logic;
        -- Top-Level Outputs
        valid_out      : out std_logic;
        image_finished : out std_logic
    );
end control_unit;

architecture behavioral of control_unit is
    -- FSM States
    type state_type is (IDLE, LOADING, RUNNING, DONE);
    signal state : state_type := IDLE;

    signal delay_cnt : integer range 0 to (2*N+1) := 0;
    signal col_cnt   : integer range 0 to N-1     := 0;
    signal row_cnt   : integer range 0 to N-1     := 0;

    -- Pipeline Drain Tracking
    signal pixels_in : integer range 0 to (N*N) := 0;
    signal active_en : std_logic;

begin
    -- active_en is high when reading valid data or processing data
    active_en <= '1' when (valid_in = '1') or (pixels_in = (N*N) and state /= DONE and state /= IDLE) else '0';
    -- Send active_en to sp_converter
    datapath_en <= active_en;

    process(clk)
    begin
        if rising_edge(clk) then
            -- Hard Reset
            if rst_n = '0' then
                state          <= IDLE;
                delay_cnt      <= 0;
                col_cnt        <= 0;
                row_cnt        <= 0;
                pixels_in      <= 0;
                valid_out      <= '0';
                image_finished <= '0';
            
            -- Start image processing
            elsif new_image = '1' then
                state          <= LOADING;
                delay_cnt      <= 0;
                col_cnt        <= 0;
                row_cnt        <= 0;
                pixels_in      <= 1;
                valid_out      <= '0';
                image_finished <= '0';

            -- Normal Operation
            else
                valid_out      <= '0';
                image_finished <= '0';

                -- Track pixels arriving from the input
                if valid_in = '1' and pixels_in < (N*N) then
                    pixels_in <= pixels_in + 1;
                end if;

                -- FSM driven by active_en
                if active_en = '1' then
                    case state is
                        -- Idle State: wait for new image 
                        when IDLE =>
                            null;

                        -- Loading State: wait until the first pixel is ready for processing
                        when LOADING =>
                            -- Loading done, start processing the image
                            if delay_cnt = (2*N+1) then
                                state     <= RUNNING;
                                valid_out <= '1';
                                col_cnt   <= 1; 
                            else
                                delay_cnt <= delay_cnt + 1;
                            end if;

                        -- Running State: Process Image
                        when RUNNING =>
                            valid_out <= '1';
                            
                            if col_cnt = N-1 then
                                -- reset column counter
                                col_cnt <= 0;
                                -- image processing finished
                                if row_cnt = N-1 then
                                    state <= DONE;
                                    image_finished <= '1';
                                else
                                    row_cnt <= row_cnt + 1;
                                end if;
                            else
                                col_cnt <= col_cnt + 1;
                            end if;

                        -- Done State: Go to Idle
                        when DONE =>
                            state <= IDLE;
                    end case;
                end if;
            end if;
        end if;
    end process;

    -- Compute Unit Flags
    -- Edge Flags
    top_edge    <= '1' when (row_cnt = 0)   else '0';
    bottom_edge <= '1' when (row_cnt = N-1) else '0';
    left_edge   <= '1' when (col_cnt = 0)   else '0';
    right_edge  <= '1' when (col_cnt = N-1) else '0';

    -- Neigborhood Flags
    process(row_cnt, col_cnt)
        variable row_lsb, col_lsb : std_logic;
    begin
        if (row_cnt mod 2) = 1 then row_lsb := '1'; else row_lsb := '0'; end if;
        if (col_cnt mod 2) = 1 then col_lsb := '1'; else col_lsb := '0'; end if;

        if row_lsb = '1' and col_lsb = '1' then
            ctrl <= "00"; -- Green (Red-Green row)
        elsif row_lsb = '0' and col_lsb = '0' then
            ctrl <= "01"; -- Green (Green-Blue row)
        elsif row_lsb = '1' and col_lsb = '0' then
            ctrl <= "10"; -- Red
        elsif row_lsb = '0' and col_lsb = '1' then
            ctrl <= "11"; -- Blue
        else
            ctrl <= "00"; 
        end if;
    end process;

end behavioral;