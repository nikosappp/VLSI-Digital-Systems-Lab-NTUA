-- 4-bit Systolic Multiplier
library ieee;
use ieee.std_logic_1164.all;

entity systolic_multiplier is 
    port (
        clk : in std_logic;
        A   : in std_logic_vector(4-1 downto 0);
        B   : in std_logic_vector(4-1 downto 0);
        P   : out std_logic_vector(2*4-1 downto 0)
    );
end systolic_multiplier; 

architecture structural_sys_mul of systolic_multiplier is
    component sync_adder is
        port (
            clk       : in std_logic;
            a, b, cin : in std_logic;
            sum, cout : out std_logic
        );
    end component;

    -- define custom array of logic vectors type in order to use for loops
    type logic_array is array (0 to 4-1) of std_logic_vector(4-1 downto 0);
    type delay_array is array (0 to 4-2) of std_logic_vector(4-2 downto 0);

    signal PP        : logic_array := (others => (others => '0'));    -- partial products
    signal S         : logic_array := (others => (others => '0'));    -- sums
    signal C         : logic_array := (others => (others => '0'));    -- carries
    signal A_del     : logic_array := (others => (others => '0'));    -- A input shiftreg
    signal B_del     : logic_array := (others => (others => '0'));    -- B input shiftreg
    signal P_del     : delay_array := (others => (others => '0'));    -- output lowest bits shiftreg
    signal vma_carry : std_logic_vector(4-1 downto 0);                -- final stage carries

begin
    -- delay inputs for pipeline
    in_del: process(clk)
    begin
        if rising_edge(clk) then
            -- first row gets undelayed inputs
            A_del(0) <= A;
            B_del(0) <= B;

            -- other rows get inputs delayed by a cycle
            for i in 1 to 4-1 loop
                A_del(i) <= A_del(i-1);
                B_del(i) <= B_del(i-1);
            end loop;
        end if;
    end process;

    -- 4x4 systolic grid generation using nested for loops
    row: for i in 0 to 4-1 generate
        col: for j in 0 to 4-1 generate
            signal fa_b   : std_logic;
            signal fa_cin : std_logic;
        begin
            -- calculate FA a input (partial product)
            PP(i)(j) <= A_del(i)(j) and B_del(i)(i);

            -- calculate FA b input (previous sum)
            fa_b <= '0' when i=0 else               -- first row: no previous sum
                    '0' when (i>0 and j=4-1) else   -- last column of row: no previous sum
                    S(i-1)(j+1);                    -- route previous sum diagonally
            
            -- calculate FA cin input (cout of previous row and column)
            fa_cin <= '0' when i=0 else             -- first row: no previous carry
                      C(i-1)(j);                    -- route carry downwards
            
            -- instantiate synchronous adder
            PE: sync_adder port map (
                clk  => clk,
                a    => PP(i)(j),
                b    => fa_b,
                cin  => fa_cin,
                sum  => S(i)(j),
                cout => C(i)(j)
            );
        end generate col;
    end generate row;
    
    -- align result
    result: process(clk)
    begin
        if rising_edge(clk) then
            -- get finished bits from the right edge
            for i in 0 to 4-2 loop
                P_del(i)(0) <= S(i)(0);
                -- shift finished bits down the registers
                for j in 1 to 4-2-i loop
                    P_del(i)(j) <= P_del(i)(j-1);
                end loop;
            end loop;
        end if;
    end process;

    -- assign output
    lower: for i in 0 to 4-2 generate   -- lower bits
        P(i) <= P_del(i)(4-2-i);
    end generate lower;

    P(4-1) <= S(4-1)(0);
    
    -- upper bits: Vector Merging Adder (VMA)
    vma_carry(0) <= '0';
    vma: for i in 0 to 4-2 generate
        -- calculate sum
        P(4+i) <= S(4-1)(i+1) xor C(4-1)(i) xor vma_carry(i);
        -- calculate cout for next bit
        vma_carry(i+1) <= (S(4-1)(i+1) and C(4-1)(i)) or (S(4-1)(i+1) and vma_carry(i)) or (C(4-1)(i) and vma_carry(i));
    end generate vma;
    
    P(2*4-1) <= C(4-1)(4-1) xor vma_carry(4-1);    -- msb

end structural_sys_mul;