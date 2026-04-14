library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sp_converter is
    generic (
        N : integer := 1024
    );
    port (
        clk             : in std_logic;
        rst_n           : in std_logic;
        pixel           : in std_logic_vector(8-1 downto 0);
        enable          : in std_logic;
        -- 3x3 neighborhood outputs
        p11, p12, p13,
        p21, p22, p23,
        p31, p32, p33   : out std_logic_vector(8-1 downto 0)
    );
end sp_converter;

architecture behavioral of sp_converter is
    -- Declare Xilinx FIFO IP Component
    component fifo_generator_0
        port (
            clk   : in  std_logic;
            srst  : in  std_logic; 
            din   : in  std_logic_vector(8-1 downto 0);
            wr_en : in  std_logic;
            rd_en : in  std_logic;
            dout  : out std_logic_vector(8-1 downto 0)
        );
    end component;

    -- FIFO Data Outputs
    signal fifo1_out, fifo2_out : std_logic_vector(8-1 downto 0);
    -- FIFO Read Enables
    signal rd_en1, rd_en2 : std_logic := '0';
    -- FIFO Write Enables
    signal wr_en2 : std_logic := '0';
    -- wr_en1 is the "enable" from the port

    -- Fill Counters (track when N pixels have been buffered)
    signal cnt1, cnt2 : integer range 0 to N-1 := 0;
    
    -- Inverted reset for the FIFO IP
    signal rst : std_logic;
    
    -- 3x3 Register Array
    signal  r1c1, r1c2, r1c3,
            r2c1, r2c2, r2c3,
            r3c1, r3c2, r3c3    : std_logic_vector(8-1 downto 0) := (others => '0');

begin
    rst <= not rst_n;

    -- Instantiate FIFO 1 (Buffers Row 2)
    fifo_1 : fifo_generator_0
        port map(
            clk   => clk,
            srst  => rst,
            din   => pixel,
            wr_en => enable,
            rd_en => rd_en1,
            dout  => fifo1_out
        );

    -- Instantiate FIFO 2 (Buffers Row 3)
    fifo_2 : fifo_generator_0
        port map(
            clk   => clk,
            srst  => rst,
            din   => fifo1_out,
            wr_en => wr_en2,
            rd_en => rd_en2,
            dout  => fifo2_out
        );

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                cnt1 <= 0;
                cnt2 <= 0;
                wr_en2 <= '0';
                
                -- Clear 3x3 Register Array
                r1c1 <= (others => '0'); r1c2 <= (others => '0'); r1c3 <= (others => '0');
                r2c1 <= (others => '0'); r2c2 <= (others => '0'); r2c3 <= (others => '0');
                r3c1 <= (others => '0'); r3c2 <= (others => '0'); r3c3 <= (others => '0');
            else
                -- Track fifo_1 fill level
                if enable = '1' and cnt1 < N-1 then
                    cnt1 <= cnt1 + 1;
                end if;

                -- Pass data to fifo_2 and track its fill level
                wr_en2 <= rd_en1;
                if wr_en2 = '1' and cnt2 < N-1 then
                    cnt2 <= cnt2 + 1;
                end if;

                -- Shift the 3x3 Register Array only when data is flowing
                if enable = '1' or rd_en1 = '1' or rd_en2 = '1' then
                    -- Bottom Row (r1) gets the live incoming pixel stream
                    r1c3 <= r1c2; r1c2 <= r1c1; r1c1 <= pixel;
                    
                    -- Middle Row (r2) gets the stream delayed by 1 row (FIFO 1)
                    r2c3 <= r2c2; r2c2 <= r2c1; r2c1 <= fifo1_out;
                    
                    -- Top Row (r3) gets the stream delayed by 2 rows (FIFO 2)
                    r3c3 <= r3c2; r3c2 <= r3c1; r3c1 <= fifo2_out;
                end if;
            end if;
        end if;
    end process;

    -- Read only when the specific FIFO is full and new data is being pushed in
    rd_en1 <= '1' when (enable = '1' and cnt1 = N-1) else '0';
    rd_en2 <= '1' when (wr_en2 = '1' and cnt2 = N-1) else '0';

    -- Map registers to outputs (r3 is top row, r1 is bottom row)
    p11 <= r3c3; p12 <= r3c2; p13 <= r3c1;
    p21 <= r2c3; p22 <= r2c2; p23 <= r2c1;
    p31 <= r1c3; p32 <= r1c2; p33 <= r1c1;

end behavioral;