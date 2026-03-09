library ieee;
use ieee.std_logic_1164.all;

entity full_adder is
    port (
        fa, fb, cin : in std_logic;
        full_sum, carry_out : out std_logic
    );
end full_adder;

architecture Structural of full_adder is

    -- Declaration of half adder that we designed before
    component half_adder is
        port (
            a, b : in std_logic;
            sum, carry : out std_logic
        );
    end component;

    signal s1, c1, c2 : std_logic; 
    -- s1 = partial sum without cin, 
    -- c1 = first carry, 
    -- c2 = second carry
    
begin
    
    -- Adds inputs a and b
    HA1: half_adder
        port map (
            a     => fa,  -- Connects component's pin 'a' to Full Adder input 'fa'
            b     => fb,  -- Connects component's pin 'b' to Full Adder input 'fb'
            sum   => s1,  -- Connects HA1 sum to internal wire s1
            carry => c1   -- Connects HA1 carry to internal wire c1
        );

    
    -- Adds the partial sum s1 and cin
    HA2: half_adder
        port map (
            a     => s1,        -- Connects component's pin 'a' to the wire 's1' (from HA1)
            b     => cin,       -- Connects component's pin 'b' to Full Adder input 'cin'
            sum   => full_sum,  -- Connects directly to the final Sum output
            carry => c2         -- Connects HA2 carry to internal wire c2
        );

    -- If either HA1 or HA2 generated a carry the final Cout is 1
    carry_out <= c1 or c2;

end Structural;