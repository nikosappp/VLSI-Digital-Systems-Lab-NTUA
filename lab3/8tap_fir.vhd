library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;  

entity fir_8tap is
    port (
        clk       : in std_logic;
        rst       : in std_logic;
        valid_in  : in std_logic;
        x         : in std_logic_vector(8-1 downto 0);
        valid_out : out std_logic;
        y         : out std_logic_vector(19-1 downto 0)  
    );
end fir_8tap;

architecture structural of fir_8tap is
    -- module declarations
    component control_unit is
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
    end component;

    component mac is
        port (
            clk      : in std_logic;
            en       : in std_logic;
            mac_init : in std_logic;
            ram_out  : in std_logic_vector(8-1 downto 0);
            rom_out  : in std_logic_vector(8-1 downto 0);
            acc      : out std_logic_vector(19-1 downto 0)
        );
    end component;

    component ram is
        generic (
            data_width : integer := 8               --- width of data (bits)
        );
        port (
            clk  : in std_logic;
            we   : in std_logic;                    -- memory write enable
            en   : in std_logic;                    -- operation enable
            rst  : in std_logic;                    -- asynchronous reset
            addr : in std_logic_vector(2 downto 0); -- memory address
            di   : in std_logic_vector(data_width-1 downto 0);  -- input data
            do   : out std_logic_vector(data_width-1 downto 0)  -- output data
        );
    end component;

    component rom is
        generic (
            coeff_width : integer := 8              -- width of coefficients (bits)
        );
        port ( 
            clk     : in  STD_LOGIC;
            en      : in  STD_LOGIC;                -- operation enable
            addr    : in  STD_LOGIC_VECTOR (2 downto 0);        -- memory address
            rom_out : out STD_LOGIC_VECTOR (coeff_width-1 downto 0) -- output data
        );
    end component;

    -- internal signals (wires) with s_ prefix
    signal s_mac_init, s_rom_en, s_ram_en, s_ram_we, s_mac_en : std_logic;
    signal s_rom_address, s_ram_address : std_logic_vector(3-1 downto 0);
    signal s_rom_out, s_ram_out : std_logic_vector(8-1 downto 0);

begin
    -- map ports
    control_unit_inst: control_unit
    port map(
        clk         => clk,
        rst         => rst,
        valid_in    => valid_in,
        mac_en      => s_mac_en,
        mac_init    => s_mac_init,
        valid_out   => valid_out,
        rom_address => s_rom_address,
        rom_en      => s_rom_en,
        ram_address => s_ram_address,
        ram_en      => s_ram_en,
        ram_we      => s_ram_we
    );

    mac_inst: mac
    port map(
        clk      => clk,
        mac_init => s_mac_init,
        ram_out  => s_ram_out,
        rom_out  => s_rom_out,
        acc      => y,
        en       => s_mac_en
    );

    ram_inst: ram
    generic map(
        data_width => 8
    )
    port map(
        clk  => clk,
        we   => s_ram_we,
        en   => s_ram_en,
        rst  => rst,
        addr => s_ram_address,
        di   => x,
        do   => s_ram_out
    );

    rom_inst: rom
    generic map(
        coeff_width => 8
    )
    port map(
        clk     => clk,
        en      => s_rom_en,
        addr    => s_rom_address,
        rom_out => s_rom_out
    );

end structural;