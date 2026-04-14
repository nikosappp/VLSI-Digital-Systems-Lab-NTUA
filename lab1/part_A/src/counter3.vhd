-- 3-bit Up/Down Counter

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ud_counter3 is 
    port (
        clk, resetn, count_en, up: in std_logic;
        sum : out std_logic_vector(3-1 downto 0);
        cout : out std_logic
    );
end ud_counter3;

architecture rtl_updown of ud_counter3 is
    signal count : std_logic_vector(3-1 downto 0);
begin
    process(clk, resetn)
    begin
        if resetn='0' then
            -- Reset (Active Low)
            count <= (others => '0');
        elsif clk'event and clk='1' then
            if count_en='1' then
                -- Count only if count_en = 1
                if up='1' then
                    count <= count + 1;
                elsif up='0' then
                    count <= count - 1;
                end if;
            end if;
        end if;
    end process;
    -- Assign values to output signals
    sum <= count;
    cout <= '1' when count=7 and count_en='1' else '0';
end rtl_updown;