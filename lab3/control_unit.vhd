library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity control_unit is
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        valid_in    : in std_logic;
        mac_en      : out std_logic;
        mac_init    : out std_logic;
        valid_out   : out std_logic;        
        rom_address : out std_logic_vector(3-1 downto 0);
        rom_en      : out std_logic;
        ram_address : out std_logic_vector(3-1 downto 0);
        ram_en      : out std_logic;
        ram_we      : out std_logic
    );
end control_unit;

architecture behavioral of control_unit is

    signal cnt : std_logic_vector(3-1 downto 0) := (others => '0'); 

<<<<<<< Updated upstream:lab3/control_unit.vhd
=======
    -- tracks the final accumulation cycle
    signal calc_finish : std_logic := '0';

>>>>>>> Stashed changes:lab3/cu.vhd
begin

    control : process(clk, rst)
    begin
        if (rst = '1') then     
            cnt <= (others => '0');
<<<<<<< Updated upstream:lab3/control_unit.vhd
            
        elsif rising_edge(clk) then
=======
            valid_out <= '0';
            calc_finish <= '0';
            
        elsif rising_edge(clk) then

            valid_out <= calc_finish;

            -- This is the point where mac gets the final data.
            -- During the next cycle (cnt=000) it computes the complete sum, so we must tell
            -- the circuit that the result is valid this time
            if (cnt = "111") then
                calc_finish <= '1';
            else
                calc_finish <= '0';
            end if;

>>>>>>> Stashed changes:lab3/cu.vhd
            if (cnt = "000") then
                if (valid_in = '1') then
                    cnt <= cnt + 1;
                end if;
            else
                cnt <= cnt + 1;
            end if;
<<<<<<< Updated upstream:lab3/control_unit.vhd
=======

>>>>>>> Stashed changes:lab3/cu.vhd
        end if;
    end process;

    rom_en      <= '1';
    ram_en      <= '1';
    rom_address <= cnt;
    ram_address <= cnt;

    -- disable MAC to stop it from accumulating garbage
<<<<<<< Updated upstream:lab3/control_unit.vhd
    mac_en <= '0' when (cnt = "000" and valid_in = '0') else '1';
=======
    -- force mac_en high during the finishing cycle
    mac_en <= '1' when calc_finish = '1' else
              '0' when (cnt = "000" and valid_in = '0') else 
              '1';
>>>>>>> Stashed changes:lab3/cu.vhd

    -- write new x to RAM during the cycle valid_in is high
    ram_we <= '1' when (cnt = "000" and valid_in = '1') else '0';

    -- initialize MAC and trip valid_out flag during state 001
    mac_init  <= '1' when (cnt = "001") else '0';
    valid_out <= '1' when (cnt = "001") else '0';

end behavioral;