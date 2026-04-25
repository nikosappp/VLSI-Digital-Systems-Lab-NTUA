library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity mac is
  port (
    clk      : in std_logic;
    rst      : in std_logic;
    en       : in std_logic;
    mac_init : in std_logic;
    ram_out  : in std_logic_vector(8-1 downto 0);
    rom_out  : in std_logic_vector(8-1 downto 0);
    acc      : out std_logic_vector(19-1 downto 0)
  );
end mac;

-- the reason we use 19 bits for the result is because by adding the highest 16bit number (65.025) 
-- eight times, the result will be 520.200 (max sum value) that can be represented with 19 bits

architecture Behavioral of mac is

  signal temp_acc : std_logic_vector(19-1 downto 0);

begin

  acc <= temp_acc;

  process (clk, rst)
    begin
      if rst = '1' then
        temp_acc <= (others => '0');
      elsif rising_edge(clk) then
        if en = '1' then
          if mac_init = '0' then
            temp_acc <= temp_acc + ("000" & (ram_out * rom_out));
          else
            temp_acc <= ("000" & (ram_out * rom_out));
          end if;
        end if;
      end if;
    end process;

end Behavioral;
