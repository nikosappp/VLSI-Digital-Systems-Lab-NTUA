library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity debayering_filter is
    generic (
        N : integer := 1024
    );
    port (
        clk            : in std_logic;
        rst_n          : in std_logic;
        new_image      : in std_logic;
        valid_in       : in std_logic;
        pixel          : in std_logic_vector(8-1 downto 0);
        valid_out      : out std_logic;
        image_finished : out std_logic;
        R, G, B        : out std_logic_vector(8-1 downto 0)
    );
end debayering_filter;

architecture structural of debayering_filter is
    -- Component Declarations
    component control_unit
        generic (
            N : integer
        );
        port (
            clk            : in  std_logic;
            rst_n          : in  std_logic;
            new_image      : in  std_logic;
            valid_in       : in  std_logic;
            -- Output to sp_converter
            datapath_en    : out std_logic; 
            -- Control signals to Compute Unit
            ctrl           : out std_logic_vector(1 downto 0);
            top_edge       : out std_logic;
            bottom_edge    : out std_logic;
            left_edge      : out std_logic;
            right_edge     : out std_logic;
            -- Top-Level Outputs
            valid_out      : out std_logic;
            image_finished : out std_logic
        );
    end component;

    component compute_unit
        port (
            clk             : in std_logic;
            -- neighborhood control signal
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
    end component;

    component sp_converter
        generic (
            N : integer
        );
        port (
            clk             : in std_logic;
            rst_n           : in std_logic;
            pixel           : in std_logic_vector(8-1 downto 0);
            enable          : in std_logic;
            -- 3x3 neighborhood outputs
            p11, p12, p13,
            p21, p22, p23,
            p31, p32, p33   : out std_logic_vector(8-1 downto 0)
        );
    end component;

    -- Internal Signal Declarations
    -- Pixel Array Wires
    signal  s_p11, s_p12, s_p13,
            s_p21, s_p22, s_p23,
            s_p31, s_p32, s_p33 : std_logic_vector(8-1 downto 0);

    -- Control Signal Wires
    signal s_ctrl        : std_logic_vector(2-1 downto 0);
    signal s_top_edge    : std_logic; 
    signal s_bottom_edge : std_logic;
    signal s_left_edge   : std_logic;
    signal s_right_edge  : std_logic;
    signal s_datapath_en : std_logic;

    signal s_valid_out, s_image_finished : std_logic;

begin
    -- Control Unit Instantiation
    u_control_unit : control_unit
        generic map (
            N => N
        )
        port map (
            clk            => clk,
            rst_n          => rst_n,
            new_image      => new_image,
            valid_in       => valid_in,
            datapath_en    => s_datapath_en,
            ctrl           => s_ctrl,
            top_edge       => s_top_edge,
            bottom_edge    => s_bottom_edge,
            left_edge      => s_left_edge,
            right_edge     => s_right_edge,
            -- Map to the internal signals instead of the direct entity outputs
            valid_out      => s_valid_out,
            image_finished => s_image_finished
        );

    -- Compute Unit Instantation
    u_compute_unit : compute_unit
        port map (
            clk         => clk,
            ctrl        => s_ctrl,
            top_edge    => s_top_edge,
            bottom_edge => s_bottom_edge,
            left_edge   => s_left_edge,
            right_edge  => s_right_edge,
            
            p11 => s_p11, p12 => s_p12, p13 => s_p13,
            p21 => s_p21, p22 => s_p22, p23 => s_p23,
            p31 => s_p31, p32 => s_p32, p33 => s_p33,
            
            R => R, G => G, B => B
        );

    -- Serial to Parallel Unit Instantation
    u_sp_converter : sp_converter
        generic map(
            N => N
        )
        port map(
            clk    => clk,
            rst_n  => rst_n,
            pixel  => pixel,
            enable => s_datapath_en,

            p11 => s_p11, p12 => s_p12, p13 => s_p13,
            p21 => s_p21, p22 => s_p22, p23 => s_p23,
            p31 => s_p31, p32 => s_p32, p33 => s_p33
        );

        process(clk)
        begin
            if rising_edge(clk) then
                if rst_n = '0' then
                    valid_out <= '0';
                    image_finished <= '0';
                else
                    -- Delays the control flags by 1 cycle to match Compute Unit latency
                    -- Since valid_out is only driven here now, there are no multiple driver conflicts.
                    valid_out <= s_valid_out; 
                    image_finished <= s_image_finished;
                end if;
            end if;
        end process;

end structural;