library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity compute_unit is
    port (
        clk             : in std_logic;
        -- neighborhood control signal (keeps the case of the bayer filter)
        ctrl            : in std_logic_vector(2-1 downto 0);
        -- edge case control signals
        top_edge        : in std_logic;
        bottom_edge     : in std_logic;
        left_edge       : in std_logic;
        right_edge      : in std_logic;
        -- 3x3 pixel neighborhood
        p11, p12, p13,
        p21, p22, p23,
        p31, p32, p33   : in std_logic_vector(8-1 downto 0);
        -- RGB pixel outputs
        R, G, B         : out std_logic_vector(8-1 downto 0)
    );
end compute_unit;

architecture behavioral of compute_unit is

begin
    -- Calculate RGB values for current pixel
    process(clk)
        -- masked pixel variables to handle edge cases
        variable m11, m12, m13,
                 m21, m22, m23,
                 m31, m32, m33  : std_logic_vector(8-1 downto 0);
        -- 10-bit variable to handle 4 pixel value addition
        variable sum : std_logic_vector(10-1 downto 0);
    begin
        if rising_edge(clk) then
            -- Load masked pixel variables with default pixels
            m11 := p11; m12 := p12; m13 := p13;
            m21 := p21; m22 := p22; m23 := p23;
            m31 := p31; m32 := p32; m33 := p33;

            -- Handle edge cases by applying zero-padding masks
            if top_edge = '1' then
                m11 := (others => '0'); m12 := (others => '0'); m13 := (others => '0');
            end if;
            if bottom_edge = '1' then
                m31 := (others => '0'); m32 := (others => '0'); m33 := (others => '0');
            end if;
            if left_edge = '1' then
                m11 := (others => '0'); m21 := (others => '0'); m31 := (others => '0');
            end if;
            if right_edge = '1' then
                m13 := (others => '0'); m23 := (others => '0'); m33 := (others => '0');
            end if;

            -- Calculate RGB values according to the current neighborhood
            -- Note: Division is performed using bit slicing (right shift).
            --       sum(8 downto 1) = sum / 2 (right shift by 1 bit)
            --       sum(9 downto 2) = sum / 4 (right shift by 2 bits)
            case ctrl is
                when "00" =>    -- Case (i)
                    sum := ("00" & m21) + ("00" & m23);
                    R   <= sum(8 downto 1);
                    G   <= m22;
                    sum := ("00" & m12) + ("00" & m32);
                    B   <= sum(8 downto 1);
                when "01" =>    -- Case (ii)
                    sum := ("00" & m12) + ("00" & m32);
                    R   <= sum(8 downto 1);
                    G   <= m22;
                    sum := ("00" & m21) + ("00" & m23);
                    B   <= sum(8 downto 1);
                when "10" =>    -- Case (iii)
                    R   <= m22;
                    sum := ("00" & m12) + ("00" & m21) + ("00" & m23) + ("00" & m32);
                    G   <= sum(9 downto 2);
                    sum := ("00" & m11) + ("00" & m13) + ("00" & m31) + ("00" & m33);
                    B   <= sum(9 downto 2);
                when "11" =>    -- Case (iv)
                    sum := ("00" & m11) + ("00" & m13) + ("00" & m31) + ("00" & m33);
                    R   <= sum(9 downto 2);
                    sum := ("00" & m12) + ("00" & m21) + ("00" & m23) + ("00" & m32);
                    G   <= sum(9 downto 2);
                    B   <= m22;
                when others =>  -- Safety Catch-All
                    R <= (others => '0');
                    G <= (others => '0');
                    B <= (others => '0');
            end case;
        end if;
    end process;

end behavioral;
