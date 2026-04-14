-- 3-bit Up Counter with Parallel Modulo Input (upper bound)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity mod_counter3 is 
    port (
        clk, resetn, count_en: in std_logic;
        bound : in std_logic_vector(3-1 downto 0);
        sum : out std_logic_vector(3-1 downto 0);
        cout : out std_logic
    );
end mod_counter3;

architecture rtl_limit of mod_counter3 is
    signal count : std_logic_vector(3-1 downto 0);
begin
    process(clk, resetn)
    begin
        if resetn='0' then
            -- Asynchronous Reset
            count <= (others => '0');
        elsif clk'event and clk='1' then
            if count_en='1' then
                -- Count only if count_en = 1
                if count<bound then
                    -- Increase counter only if it is less than the upper bound
                    count <= count + 1;
                else
                    -- Else, reset counter
                    count <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    sum <= count;
    cout <= '1' when count=bound and count_en='1' else '0';
end rtl_limit;

