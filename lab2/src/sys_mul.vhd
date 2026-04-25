-- 4-bit Systolic Multiplier
library ieee;
use ieee.std_logic_1164.all;

entity sys_mul is 
    port (
        clk : in std_logic;
        A   : in std_logic_vector(4-1 downto 0);
        B   : in std_logic_vector(4-1 downto 0);
        P   : out std_logic_vector(2*4-1 downto 0)
    );
end sys_mul; 

architecture structural of sys_mul is
    -- processing element declaration
    component systolic_pe is
        port (
            clk      : in  std_logic;
            i_a, i_b : in  std_logic;
            i_s, i_c : in  std_logic;
            o_a, o_b : out std_logic;
            o_s, o_c : out std_logic
    );
    end component;

    -- define 2d grid type for interconnects
    type grid_t is array (0 to 4, 0 to 4) of std_logic;
    
    -- internal wiring nets
    signal a_net : grid_t := (others => (others => '0'));
    signal b_net : grid_t := (others => (others => '0'));
    signal c_net : grid_t := (others => (others => '0'));
    signal s_net : grid_t := (others => (others => '0'));

    -- shift register arrays for skewing/deskewing
    type a_skew_t is array (0 to 4-1)     of std_logic_vector(4-1 downto 0);
    type b_skew_t is array (0 to 2*(4-1)) of std_logic_vector(4-1 downto 0);
    type p_skew_t is array (0 to 2*4)     of std_logic_vector(2*4-1 downto 0);
    
    signal A_sr : a_skew_t := (others => (others => '0'));
    signal B_sr : b_skew_t := (others => (others => '0'));
    signal P_sr : p_skew_t := (others => (others => '0'));
    
    -- edge carry sreg
    signal edge_c : std_logic_vector(0 to 4-2) := (others => '0');

    -- raw output reg
    signal raw_P : std_logic_vector(7 downto 0);

begin
    -- input skewing
    in_skew: process(clk)
    begin
        if rising_edge(clk) then
            -- sregs for A and B
            A_sr(0) <= A;
            for i in 1 to 4-1 loop
                A_sr(i) <= A_sr(i-1);
            end loop;
            
            B_sr(0) <= B;
            for i in 1 to 2*(4-1) loop
               B_sr(i) <= B_sr(i-1); 
            end loop;
        end if;
    end process;

    -- feed delayed inputs to grid edges
    feed_in: for i in 0 to 4-1 generate
        a_net(0, i) <= A_sr(i)(i);
        b_net(i, 0) <= B_sr(2*i)(i);
    end generate feed_in;

    -- ground the undriven boundary inputs
    gnd_edges: for i in 0 to 3 generate
        c_net(i, 0)   <= '0';   -- ground the rightmost carry inputs
        s_net(0, i+1) <= '0';   -- ground the top row sum inputs
    end generate gnd_edges;

    -- generate the 4x4 systolic array
    gen_rows: for i in 0 to 4-1 generate
        gen_cols: for j in 0 to 4-1 generate
            PE: systolic_pe
            port map (
                clk => clk,
                -- inputs                
                i_a => a_net(i, j),     -- comes from above
                i_b => b_net(i, j),     -- comes from right
                i_c => c_net(i, j),     -- comes from right
                i_s => s_net(i, j+1),   -- comes from top-left (j+1 is left)
                -- outputs
                o_a => a_net(i+1, j),   -- goes down
                o_b => b_net(i, j+1),   -- goes left
                o_c => c_net(i, j+1),   -- goes left
                o_s => s_net(i+1, j)    -- goes down
            );
        end generate gen_cols;
    end generate gen_rows;
    
    -- delay edge carries
    del_c: process(clk)
    begin
        if rising_edge(clk) then
            for i in 0 to 4-2 loop
                edge_c(i) <= c_net(i, 4);
            end loop;
        end if;
    end process;

    -- drive delayed edge carry to next row edge i_s
    last_c: for i in 0 to 4-2 generate
        s_net(i+1, 4) <= edge_c(i);
    end generate last_c;

    -- drive last carry to s_net
    s_net(4, 4) <= c_net(4-1, 4);

    -- output deskewing
    -- extract raw product from grid edges
    raw_out: for i in 0 to 4-1 generate
        raw_P(i)   <= s_net(i+1, 0);    -- lower bits
        raw_P(4+i) <= s_net(4, i+1);    -- upper bits
    end generate raw_out;

    -- shiftreg to hold finished bits
    out_deskew: process(clk)
    begin
        if rising_edge(clk) then
            P_sr(0) <= raw_P;
            for i in 1 to 2*4 loop
                P_sr(i) <= P_sr(i-1);
            end loop;
        end if;
    end process;

    -- feed outputs at the correct delay 
    P(0) <= P_sr(8)(0);     -- needs 9 delays
    P(1) <= P_sr(6)(1);     -- needs 7 delays
    P(2) <= P_sr(4)(2);     -- needs 5 delays
    P(3) <= P_sr(2)(3);     -- needs 3 delays
    P(4) <= P_sr(1)(4);     -- needs 2 delays
    P(5) <= P_sr(0)(5);     -- needs 1 delay
    P(6) <= raw_P(6);       -- 0 delays (emerges at exactly 10 cycles)
    P(7) <= raw_P(7);       -- 0 delays (emerges at exactly 10 cycles)

end architecture structural;