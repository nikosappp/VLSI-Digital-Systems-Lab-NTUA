library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity mac is
  port (
    clk : in std_logic;
    mac_init: in std_logic;
    ram_out : in std_logic_vector(8-1 downto 0);
    rom_out : in std_logic_vector(8-1 downto 0);
    acc : out std_logic_vector(19-1 downto 0)
  );
end mac;

-- the reason we use 19 bits for the result is because by adding the highest 16bit number (65.025) 
-- eight times, the result will be 520.200 (max sum value) that can be represented with 19 bits


architecture Behavioral of mac is

  signal temp_acc : std_logic_vector(19-1 downto 0) := (others => '0');

begin

  acc <= temp_acc;

  process (clk)

    begin 
      if rising_edge(clk) then
        if mac_init = '0' then
          temp_acc <=  temp_acc + ("000" & (ram_out * rom_out));
        else
          temp_acc <= ("000" & (ram_out * rom_out));             -- we put the first product here because if we put '0' it will take 9 cycles to calculate y
        end if;
      end if;
    end process;

  end Behavioral;
