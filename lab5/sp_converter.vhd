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
        valid_in        : in std_logic;
        -- 3x3 neighborhood outputs
        p11, p12, p13,
        p21, p22, p23,
        p31, p32, p33   : out std_logic_vector(8-1 downto 0)
    );
end sp_converter;

architecture sp_converter_arch of sp_converter is
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
    signal fifo1_out, fifo2_out, fifo3_out : std_logic_vector(8-1 downto 0);
    -- FIFO Read Enables
    signal rd_en1, rd_en2, rd_en3 : std_logic := '0';
    -- FIFO Write Enables
    signal wr_en2, wr_en3 : std_logic := '0';
    -- Fill Counters (track when N pixels have been buffered)
    signal cnt1, cnt2, cnt3 : integer range 0 to N := 0;
    -- Inverted reset for the FIFO IP
    signal rst : std_logic;

    -- 3x3 Register Array
    signal  r1c1, r1c2, r1c3,
            r2c1, r2c2, r2c3,
            r3c1, r3c2, r3c3    : std_logic_vector(8-1 downto 0) := (others => '0');

begin
    rst <= not rst_n;

    -- Instantiate FIFOs
    fifo_1 : fifo_generator_0
        port map(
            clk   => clk,
            srst  => rst,
            din   => pixel,
            wr_en => valid_in,
            rd_en => rd_en1,
            dout  => fifo1_out
        );
    fifo_2 : fifo_generator_0
        port map(
            clk   => clk,
            srst  => rst,
            din   => fifo1_out,
            wr_en => wr_en2,
            rd_en => rd_en2,
            dout  => fifo2_out
        );
    fifo_3 : fifo_generator_0
        port map(
            clk   => clk,
            srst  => rst,
            din   => fifo2_out,
            wr_en => wr_en3,
            rd_en => rd_en3,
            dout  => fifo3_out
        );
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                cnt1 <= 0;cnt2 <= 0; cnt3 <= 0;
                wr_en2 <= '0'; wr_en3 <= '0';
                -- Clear 3x3 Register Array
                r1c1 <= (others => '0'); r1c2 <= (others => '0'); r1c3 <= (others => '0');
                r2c1 <= (others => '0'); r2c2 <= (others => '0'); r2c3 <= (others => '0');
                r3c1 <= (others => '0'); r3c2 <= (others => '0'); r3c3 <= (others => '0');
            else
                -- Track fifo_1 fill level
                if valid_in = '1' and cnt1 < N then
                    cnt1 <= cnt1 + 1;
                end if;

                -- Pass data to fifo_2 and track its fill level
                wr_en2 <= rd_en1;
                if wr_en2 = '1' and cnt2 < N then
                    cnt2 <= cnt2 + 1;
                end if;

                -- Pass data to fifo_3 and track its fill level
                wr_en3 <= rd_en2;
                if wr_en3 = '1' and cnt3 < N then
                    cnt3 <= cnt3 + 1;
                end if;

                -- Shift the 3x3 Register Array only when data is flowing
                if valid_in = '1' or rd_en1 = '1' or rd_en2 = '1' or rd_en3 = '1' then
                    r1c3 <= r1c2; r1c2 <= r1c1; r1c1 <= fifo1_out;
                    r2c3 <= r2c2; r2c2 <= r2c1; r2c1 <= fifo2_out;
                    r3c3 <= r3c2; r3c2 <= r3c1; r3c1 <= fifo3_out;
                end if;
            end if;
        end if;
    end process;
    
    -- Read only when the specific FIFO is full and new data is being pushed in
    rd_en1 <= '1' when (valid_in = '1' and cnt1 = N) else '0';
    rd_en2 <= '1' when (wr_en2 = '1'   and cnt2 = N) else '0';
    rd_en3 <= '1' when (wr_en3 = '1'   and cnt3 = N) else '0';

    -- Map registers to outputs
    p11 <= r3c3; p12 <= r3c2; p13 <= r3c1;
    p21 <= r2c3; p22 <= r2c2; p23 <= r2c1;
    p31 <= r1c3; p32 <= r1c2; p33 <= r1c1;

end sp_converter_arch;
