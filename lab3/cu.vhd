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

    -- After reset, when the valid_out will be set at cnt=001 the circuit has trash in the acc.
    -- The output at this point is not valid, we have to wait 8 cylces. When this signal is set
    -- it means that these 8 cycles have passed.
    signal has_run : std_logic := '0';

begin

    control : process(clk, rst)
    begin
        if (rst = '1') then     
            cnt <= (others => '0');
            has_run <= '0';
            
        elsif rising_edge(clk) then

            -- This is the point where mac gets the final data.
            -- During the next cycle (cnt=000) it computes the complete sum, so we must tell
            -- the circuit that the result is valid this time
            if (cnt = "111") then
                has_run <= '1';
            end if;

            if (cnt = "000") then
                if (valid_in = '1') then
                    cnt <= cnt + 1;
                end if;
            else
                cnt <= cnt + 1;
            end if;
        end if;
    end process;

    rom_en      <= '1';
    ram_en      <= '1';
    rom_address <= cnt;
    ram_address <= cnt;

    -- disable MAC to stop it from accumulating garbage
    mac_en <= '0' when (cnt = "000" and valid_in = '0') else '1';

    -- write new x to RAM during the cycle valid_in is high
    ram_we <= '1' when (cnt = "000" and valid_in = '1') else '0';

    -- initialize MAC and trip valid_out flag during state 001
    mac_init  <= '1' when (cnt = "001") else '0';
    
    -- set valid_out during state 001 BUT ONLY IF we have completed the first 8 cycles of operating
    valid_out <= '1' when (cnt = "001" and has_run = '1') else '0';

end behavioral;