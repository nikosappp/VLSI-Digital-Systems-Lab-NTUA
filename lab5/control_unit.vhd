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
        -- Handshaking and input control
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

    -- FSM State Definitions
    type state_type is (IDLE, LOADING, RUNNING, DONE);
    signal state : state_type := IDLE;

    -- Internal Signal Declarations
    
    -- Counters for timing, columns, and rows
    signal delay_cnt    : integer range 0 to (2*N+4) := 0;
    signal col_cnt      : integer range 0 to N       := 0;
    signal row_cnt      : integer range 0 to N       := 0;

    -- Pipeline Drain Tracking
    signal pixels_in    : integer range 0 to (N*N)   := 0;
    
    -- Enable signals

    -- Immediate enable flag: High when valid data is streaming in, or when the 
    -- pipeline is draining at the end of the image. Drops to '0' instantly on a stall.
    signal active_en    : std_logic;
    -- Delayed enable flag: A 1-clock-cycle delayed version of 'active_en'.
    -- WHY IT EXISTS: The Xilinx FIFOs in the sp_converter have a 1-cycle read latency. 
    -- We use this delayed signal to drive the FSM so our column/row counters wait
    -- exactly 1 cycle before incrementing, perfectly aligning the control logic with 
    -- the physical arrival of the data during stalls and restarts.
    signal active_en_d1 : std_logic := '0'; -- 1-cycle delay to match FIFO read latency

begin

    
    -- active_en is high when reading valid data OR when draining the pipeline at the end
    active_en   <= '1' when (valid_in = '1') or (pixels_in = (N*N) and state /= DONE and state /= IDLE) else '0';
    
    -- Send immediate active_en to sp_converter (so fifos can register writes)
    datapath_en <= active_en;


    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                
                -- Reset all states, counters, and outputs
                state          <= IDLE;
                delay_cnt      <= 0;
                col_cnt        <= 0;
                row_cnt        <= 0;
                pixels_in      <= 0;
                valid_out      <= '0';
                image_finished <= '0';
                active_en_d1   <= '0';
                
            elsif new_image = '1' then
                
                -- Initialize FSM for a new frame
                state          <= LOADING;
                delay_cnt      <= 0;
                col_cnt        <= 0;
                row_cnt        <= 0;
                pixels_in      <= 1;
                valid_out      <= '0';
                image_finished <= '0';
                active_en_d1   <= '0';
                
            else
                -- Delay the enable by 1 cycle to keep FSM perfectly synced with sp_converter
                active_en_d1 <= active_en;

                -- Increment total pixel tracker if receiving valid data
                if valid_in = '1' and pixels_in < (N*N) then
                    pixels_in <= pixels_in + 1;
                end if;

                -- The FSM is strictly dependent from the delayed enable (active_en_d1).
                -- If this signal is '1', the data coming from the sp_converter 
                -- is valid, and the FSM is allowed to advance its state and counters.
                if active_en_d1 = '1' then
                    
                    case state is
                        when IDLE =>
                            valid_out <= '0';
                            
                        when LOADING =>
                            -- Wait 2*N + 1 cycles for the first two rows and 3 pixels to buffer
                            if delay_cnt = (2*N+1) then
                                state     <= RUNNING;
                                valid_out <= '1';
                                col_cnt   <= 1; 
                            else
                                delay_cnt <= delay_cnt + 1;
                                valid_out <= '0';
                            end if;
                            
                        when RUNNING =>
                            valid_out <= '1';
                            
                            -- Manage Column and Row counters
                            if col_cnt = N-1 then
                                col_cnt <= 0;
                                
                                if row_cnt = N-1 then
                                    state          <= DONE;
                                    image_finished <= '1';
                                else
                                    row_cnt        <= row_cnt + 1;
                                end if;
                            else
                                col_cnt <= col_cnt + 1;
                            end if;
                            
                        when DONE =>
                            state          <= IDLE;
                            valid_out      <= '0';
                            image_finished <= '0';
                            
                    end case;
                
                -- =============
                -- STALL HANDLER 
                -- =============
                else
                    -- During a stall, the compute unit is recalculating the same (stale) 
                    -- pixel. We must explicitly pull 'valid_out' low so the downstream 
                    -- module (or testbench) ignores the data bus on this clock cycle.
                    valid_out      <= '0';
                    -- We also hold image_finished low to prevent falsely signaling 
                    -- the end of a frame if a stall happens exactly at the last pixel.
                    image_finished <= '0';
                end if;
            end if;
        end if;
    end process;


    -- Edge Detection Flags 
    top_edge    <= '1' when (row_cnt = 0)   else '0';
    bottom_edge <= '1' when (row_cnt = N-1) else '0';
    left_edge   <= '1' when (col_cnt = 0)   else '0';
    right_edge  <= '1' when (col_cnt = N-1) else '0';


    -- Neighborhood Color Flags 
    process(row_cnt, col_cnt)
        variable row_lsb, col_lsb : std_logic;
    begin
        
        -- Determine if current row is Even (0) or Odd (1)
        if (row_cnt mod 2) = 1 then 
            row_lsb := '1'; 
        else 
            row_lsb := '0'; 
        end if;
        
        -- Determine if current column is Even (0) or Odd (1)
        if (col_cnt mod 2) = 1 then 
            col_lsb := '1'; 
        else 
            col_lsb := '0'; 
        end if;

        -- Map to the correct Bayer CFA Case
        if row_lsb = '1' and col_lsb = '1' then
            ctrl <= "00"; -- Green (Red-Green row)
            
        elsif row_lsb = '0' and col_lsb = '0' then
            ctrl <= "01"; -- Green (Green-Blue row)
            
        elsif row_lsb = '1' and col_lsb = '0' then
            ctrl <= "10"; -- Red center
            
        elsif row_lsb = '0' and col_lsb = '1' then
            ctrl <= "11"; -- Blue center
            
        else
            ctrl <= "00"; -- Default safety catch
            
        end if;
        
    end process;

end behavioral;