library ieee;
use ieee.std_logic_1164.all;

entity parallel_adder_4bit is
    port (
        num1, num2 : in std_logic_vector (3 downto 0); 
        initial_carry : in std_logic;
        sum_4bit : out std_logic_vector(3 downto 0);
        final_carry : out std_logic 
     );
end parallel_adder_4bit;


architecture Structural of parallel_adder_4bit is

    -- Declaraton of full adder
    component full_adder is
        port (
            fa, fb, cin : in std_logic;
            full_sum, carry_out : out std_logic
        );
    end component;
    
    signal c0, c1, c2 : std_logic;
  
begin 

    FA0: full_adder
        port map (
            fa => num1(0),
            fb => num2(0),
            cin => initial_carry,
            full_sum => sum_4bit(0),
            carry_out => c0
        );
        
    FA1: full_adder
        port map (
            fa => num1(1),
            fb => num2(1),
            cin => c0,
            full_sum => sum_4bit(1),
            carry_out => c1
        );
        
    FA2: full_adder
        port map (
            fa => num1(2),
            fb => num2(2),
            cin => c1,
            full_sum => sum_4bit(2),
            carry_out => c2
        );
        
     FA3: full_adder
        port map (
            fa => num1(3),
            fb => num2(3),
            cin => c2,
            full_sum => sum_4bit(3),
            carry_out => final_carry
        );
        
end Structural;
            
    


         