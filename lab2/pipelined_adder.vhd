library ieee;
use ieee.std_logic_1164.all;

entity pipelined_adder is
    port (
        clk       : in std_logic;
        A         : in std_logic_vector(3 downto 0);
        B         : in std_logic_vector(3 downto 0);
        pipe_cin  : in std_logic;
        final_sum : out std_logic_vector(3 downto 0);
        final_cout : out std_logic
    );
end pipelined_adder;

architecture Mixed of pipelined_adder is    
    -- mixed architecture because we combine structural (port maps) and behavioral (process)  (name proposed by LLM)

    component sync_adder
        port (
            clk  : in std_logic;
            a    : in std_logic;
            b    : in std_logic;
            cin  : in std_logic;
            sum  : out std_logic;
            cout : out std_logic
        );
     end component;
     
    -- carry signals between adder stages
    signal c1, c2, c3 : std_logic;

    -- delay signals (shift registers) for inputs A and B
    signal a1_d1, b1_d1 : std_logic;                                  
    signal a2_d1, a2_d2, b2_d1, b2_d2 : std_logic;                    
    signal a3_d1, a3_d2, a3_d3, b3_d1, b3_d2, b3_d3 : std_logic;      

    -- temporary sum signals from the full adders
    signal s0_temp, s1_temp, s2_temp, s3_temp : std_logic;

    -- delay signals (shift registers) for output sums to synchronize them
    signal s0_d1, s0_d2, s0_d3 : std_logic; 
    signal s1_d1, s1_d2 : std_logic;
    signal s2_d1 : std_logic;
    
    
    -- the names above follow the format [name][bit]_d[cycles of delay]
    -- eg: a2_d1 = Bit 2 of input A, delayed by 1 clock cycle.
    -- s0_d3 : Sum of bit 0, delayed by 3 clock cycles.
    
    

begin

    FA0: sync_adder 
        port map (
            clk  => clk, 
            a    => A(0),  
            b    => B(0),  
            cin  => pipe_cin, 
            sum  => s0_temp, 
            cout => c1
        );

    FA1: sync_adder 
        port map (
            clk  => clk, 
            a    => a1_d1, 
            b    => b1_d1, 
            cin  => c1,       
            sum  => s1_temp, 
            cout => c2
        );

    FA2: sync_adder 
        port map (
            clk  => clk, 
            a    => a2_d2, 
            b    => b2_d2, 
            cin  => c2,       
            sum  => s2_temp, 
            cout => c3
        );

    FA3: sync_adder 
        port map (
            clk  => clk, 
            a    => a3_d3, 
            b    => b3_d3, 
            cin  => c3,       
            sum  => s3_temp, 
            cout => final_cout
        );

    process(clk)
    begin
        if rising_edge(clk) then
        
            -- stage 1: delay upper bits of inputs A and B by 1 clock cycle
            a1_d1 <= A(1); 
            b1_d1 <= B(1);
            
            a2_d1 <= A(2); 
            b2_d1 <= B(2);
            
            a3_d1 <= A(3); 
            b3_d1 <= B(3);
            
            -- stage 2: delay bits 2 and 3 by another cycle. Bit 1 goes to FA1.
            a2_d2 <= a2_d1; 
            b2_d2 <= b2_d1;
            
            a3_d2 <= a3_d1; 
            b3_d2 <= b3_d1;
            
            s0_d1 <= s0_temp; -- sum 0 is calculated, put it in delay line
            
            -- stage 3: delay bit 3 by another cycle. Bit 2 goes to FA2.
            a3_d3 <= a3_d2; 
            b3_d3 <= b3_d2;
            
            s0_d2 <= s0_d1;   -- sum 0 continues waiting
            s1_d1 <= s1_temp; -- sum 1 is calculated, put it in delay line
            
            -- stage 4: final synchronization for all sum outputs
            s0_d3 <= s0_d2;  
            s1_d2 <= s1_d1;
            s2_d1 <= s2_temp; -- sum 2 is calculated and delayed by 1 cycle
        end if;
    end process;

    final_sum(0) <= s0_d3;
    final_sum(1) <= s1_d2;
    final_sum(2) <= s2_d1;
    final_sum(3) <= s3_temp; -- sum 3 is calculated at cycle 4, no delay needed

end Mixed;