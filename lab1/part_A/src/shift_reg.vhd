-- 4-bit Shift Register with Parallel Load

library ieee;
use ieee.std_logic_1164.all;

entity shift_reg is
    port (
        clk, rst, si, en, ls, pl : in std_logic;
        din : in std_logic_vector(4-1 downto 0);
        so : out std_logic
    );
end shift_reg;

-- architecture rtl of shift_reg is
--     signal dff : std_logic_vector(4-1 downto 0);
-- begin
--     edge : process(clk, rst)
--     begin
--         if rst='0' then
--             dff <= (others => '0');
--         elsif clk'event and clk='1' then
--             if pl='1' then
--                 dff <= din;
--             elsif en='1' then
--                 case ls is
--                     when '0' =>
--                         dff <= si & dff(4-1 downto 1);
--                     when '1' =>
--                         dff <= dff(4-2 downto 0) & si;
--                     when others =>
--                         dff <= dff;
--                 end case;
--             end if;
--         end if;
--     end process;
--    so <= dff(0) when ls='0' else dff(4-1);
-- end rtl;

-- Alternative Implementation using if
architecture rtl of shift_reg is
    signal dff : std_logic_vector(4-1 downto 0);
begin
    edge : process(clk, rst)
    begin
        if rst='0' then
            dff <= (others => '0');
        elsif clk'event and clk='1' then
            if pl='1' then
                dff <= din;
            elsif en='1' then
                if ls='0' then
                    dff <= si & dff(4-1 downto 1);
                elsif ls='1' then
                    dff <= dff(4-2 downto 0) & si;
                end if;
            end if;
        end if;
    end process;
    so <= dff(0) when ls='0' else dff(4-1);
end rtl;