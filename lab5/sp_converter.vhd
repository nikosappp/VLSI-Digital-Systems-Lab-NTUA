library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sp_converter is
    generic (
        N : integer := 32 
    );
    port (
        clk             : in  std_logic; 
        rst_n           : in  std_logic; 
        pixel           : in  std_logic_vector(8-1 downto 0); 
        enable          : in  std_logic; 
        -- 3x3 neighborhood outputs (formatted as p_row_col)
        p11, p12, p13   : out std_logic_vector(8-1 downto 0);
        p21, p22, p23   : out std_logic_vector(8-1 downto 0);
        p31, p32, p33   : out std_logic_vector(8-1 downto 0) 
    );
end sp_converter;

architecture behavioral of sp_converter is
    
    -- Xilinx fifo ip Generator
    component fifo_generator_0
        port (
            clk   : in  std_logic; 
            srst  : in  std_logic; 
            din   : in  std_logic_vector(7 downto 0);
            wr_en : in  std_logic; 
            rd_en : in  std_logic; 
            dout  : out std_logic_vector(7 downto 0)
        );
    end component;

    
    -- Internal Signal Declarations
    
    -- Data outputs from the three FIFOs
    signal fifo1_out   : std_logic_vector(7 downto 0);
    signal fifo2_out   : std_logic_vector(7 downto 0);
    signal fifo3_out   : std_logic_vector(7 downto 0);
    
    -- Read and write enables for cascading the fifos
    signal rd_en1      : std_logic := '0';
    signal rd_en2      : std_logic := '0';
    signal rd_en3      : std_logic := '0';
    signal wr_en2      : std_logic := '0';
    signal wr_en3      : std_logic := '0';
    
    -- Dependent write signals for cascading the line buffers (controlled by the global enable signal)
    signal fifo2_wr_en : std_logic;
    signal fifo3_wr_en : std_logic;
    
    -- Counters to track when a full row (N pixels) has been buffered
    signal cnt1        : integer range 0 to N-1 := 0;
    signal cnt2        : integer range 0 to N-1 := 0;
    signal cnt3        : integer range 0 to N-1 := 0;
    
    -- Active-high reset for the fifo ip
    signal rst         : std_logic;
    
    -- 3x3 internal shift register array
    signal r1c1, r1c2, r1c3 : std_logic_vector(7 downto 0) := (others => '0');
    signal r2c1, r2c2, r2c3 : std_logic_vector(7 downto 0) := (others => '0');
    signal r3c1, r3c2, r3c3 : std_logic_vector(7 downto 0) := (others => '0');

begin

    rst <= not rst_n;

    --=================================
    -- LOGIC FOR THE VALID_IN DROP TO 0
    --=================================

    fifo2_wr_en <= wr_en2 and enable;
    fifo3_wr_en <= wr_en3 and enable;

    --==================================
    --==================================

    
    fifo_1 : fifo_generator_0 
        port map (
            clk   => clk, 
            srst  => rst, 
            din   => pixel,         -- Takes new incoming pixel
            wr_en => enable,        -- Writes whenever input is valid
            rd_en => rd_en1, 
            dout  => fifo1_out
        );

    --=====================================================================================

    -- We use teh dependent write signals because the internal signals like wr_en2 
    -- are updated inside a process(clk). When a stall happens ( enable drops to '0'),
    -- a registered signal stays '1' for exactly one more clock cycle before it can update.

    --======================================================================================
        
    -- FIFO 2: Stores the second row
    fifo_2 : fifo_generator_0 
        port map (
            clk   => clk, 
            srst  => rst, 
            din   => fifo1_out,     -- Takes output from fifo 1
            wr_en => fifo2_wr_en,   -- Uses the gated write enable
            rd_en => rd_en2, 
            dout  => fifo2_out
        );
        
    -- FIFO 3: Stores the third row
    fifo_3 : fifo_generator_0 
        port map (
            clk   => clk, 
            srst  => rst, 
            din   => fifo2_out,     -- Takes output from fifo 2
            wr_en => fifo3_wr_en,   -- Uses the gated write enable
            rd_en => rd_en3, 
            dout  => fifo3_out
        );

    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                -- Reset all counters and enables
                cnt1   <= 0; 
                cnt2   <= 0; 
                cnt3   <= 0;
                wr_en2 <= '0'; 
                wr_en3 <= '0';
                
                -- and clear the 3x3 shift register array
                r1c1 <= (others => '0'); r1c2 <= (others => '0'); r1c3 <= (others => '0');
                r2c1 <= (others => '0'); r2c2 <= (others => '0'); r2c3 <= (others => '0');
                r3c1 <= (others => '0'); r3c2 <= (others => '0'); r3c3 <= (others => '0');
            else
                -- Only advance state when the pipeline is enabled (not stalled)
                if enable = '1' then
                    
                    if cnt1 < N-1 then 
                        cnt1 <= cnt1 + 1; 
                    end if;
                    
                    wr_en2 <= rd_en1;
                    if wr_en2 = '1' and cnt2 < N-1 then 
                        cnt2 <= cnt2 + 1; 
                    end if;
                    
                    wr_en3 <= rd_en2;
                    if wr_en3 = '1' and cnt3 < N-1 then 
                        cnt3 <= cnt3 + 1; 
                    end if;

                    -- older pixels move to higher column indices
                    r1c3 <= r1c2;  r1c2 <= r1c1;  r1c1 <= fifo1_out;
                    r2c3 <= r2c2;  r2c2 <= r2c1;  r2c1 <= fifo2_out;
                    r3c3 <= r3c2;  r3c2 <= r3c1;  r3c1 <= fifo3_out;
                    
                end if;
            end if;
        end if;
    end process;

    
    -- Read from a fifo only when it is full AND the pipeline is running
    rd_en1 <= '1' when (enable = '1' and cnt1 = N-1)                  else '0';
    rd_en2 <= '1' when (enable = '1' and wr_en2 = '1' and cnt2 = N-1) else '0';
    rd_en3 <= '1' when (enable = '1' and wr_en3 = '1' and cnt3 = N-1) else '0';

    -- Map internal shift registers to the component's output ports
    -- Note: Row 3 is the top of the image (oldest), Row 1 is the bottom (newest)
    p11 <= r3c3; p12 <= r3c2; p13 <= r3c1;
    p21 <= r2c3; p22 <= r2c2; p23 <= r2c1;
    p31 <= r1c3; p32 <= r1c2; p33 <= r1c1;

end behavioral;