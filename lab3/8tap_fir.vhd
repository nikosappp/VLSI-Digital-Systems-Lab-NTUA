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
            clk : in std_logic;
            en  : in std_logic;
            mac_init: in std_logic;
            ram_out : in std_logic_vector(8-1 downto 0);
            rom_out : in std_logic_vector(8-1 downto 0);
            acc : out std_logic_vector(19-1 downto 0)
        );
    end component;

    component ram is
     	generic (
		    data_width : integer :=8  				--- width of data (bits)
	    );
        port (
            clk  : in std_logic;
            we   : in std_logic;						            -- memory write enable
		    en   : in std_logic;				                    -- operation enable
            rst  : in std_logic;                                    -- asynchronous reset
            addr : in std_logic_vector(2 downto 0);			        -- memory address
            di   : in std_logic_vector(data_width-1 downto 0);		-- input data
            do   : out std_logic_vector(data_width-1 downto 0)      -- output data
        );
    end component;

    component rom is
        generic (
		    coeff_width : integer :=8  				-- width of coefficients (bits)
	    );
        port ( 
            clk : in  STD_LOGIC;
	        en : in  STD_LOGIC;				                            -- operation enable
            addr : in  STD_LOGIC_VECTOR (2 downto 0);			        -- memory address
            rom_out : out  STD_LOGIC_VECTOR (coeff_width-1 downto 0)    -- output data
        );
    end component;

    -- wires
    signal mac_init, rom_en, ram_en, ram_we, mac_en : std_logic;
    signal rom_address, ram_address : std_logic_vector(3-1 downto 0);
    signal rom_out, ram_out : std_logic_vector(8-1 downto 0);

begin
    -- map ports
    control_unit_inst: control_unit
    port map(
        clk => clk,
        rst => rst,
        valid_in => valid_in,
        mac_en => mac_en,
        mac_init => mac_init,
        valid_out => valid_out,
        rom_address => rom_address,
        rom_en => rom_en,
        ram_address => ram_address,
        ram_en => ram_en,
        ram_we => ram_we
    );

    mac_inst: mac
    port map(
        clk => clk,
        mac_init => mac_init,
        ram_out => ram_out,
        rom_out => rom_out,
        acc => y,
        en => mac_en
    );

    ram_inst: ram
    generic map(
        data_width => 8
    )
    port map(
        clk => clk,
        we => ram_we,
        en => ram_en,
        rst => rst,
        addr => ram_address,
        di => x,
        do => ram_out
    );

    rom_inst: rom
    generic map(
        coeff_width => 8
    )
    port map(
        clk => clk,
        en => rom_en,
        addr => rom_address,
        rom_out => rom_out
    );

end structural;