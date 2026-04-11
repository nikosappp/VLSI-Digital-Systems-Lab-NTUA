library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity compute_unit is
    port (
        clk  : in std_logic;
        -- control signal (case)
        ctrl : in std_logic_vector(2-1 downto 0);
        -- 3x3 pixel neighborhood
        p11, p12, p13,
        p21, p22, p23,
        p31, p32, p33   : in std_logic_vector(8-1 downto 0);
        -- RGB pixel outputs
        R, G, B : out std_logic_vector(8-1 downto 0)
    );
end compute_unit;

architecture behavioral of compute_unit is

begin
    -- Calculate RGB values for current pixel
    process(clk)
        -- 10-bit variable to handle 4 pixel value addition
        variable sum : std_logic_vector(10-1 downto 0);
    begin
        if rising_edge(clk) then
            case ctrl is
                when "00" =>    -- Case (i)
                    sum := ("00" & p21) + ("00" & p23);
                    R   <= sum(8 downto 1);
                    G   <= p22;
                    sum := ("00" & p12) + ("00" & p32);
                    B   <= sum(8 downto 1);
                when "01" =>    -- Case (ii)
                    sum := ("00" & p12) + ("00" & p32);
                    R   <= sum(8 downto 1);
                    G   <= p22;
                    sum := ("00" & p21) + ("00" & p23);
                    B   <= sum(8 downto 1);
                when "10" =>    -- Case (iii)
                    R   <= p22;
                    sum := ("00" & p12) + ("00" & p21) + ("00" & p23) + ("00" & p32);
                    G   <= sum(9 downto 2);
                    sum := ("00" & p11) + ("00" & p13) + ("00" & p31) + ("00" & p33);
                    B   <= sum(9 downto 2);
                when "11" =>    -- Case (iv)
                    sum := ("00" & p11) + ("00" & p13) + ("00" & p31) + ("00" & p33);
                    R   <= sum(9 downto 2);
                    sum := ("00" & p12) + ("00" & p21) + ("00" & p23) + ("00" & p32);
                    G   <= sum(9 downto 2);
                    B   <= p22;
                when others =>  -- Safety Catch-All
                    R <= (others => '0');
                    G <= (others => '0');
                    B <= (others => '0');
            end case;
        end if;
    end process;

end behavioral;
