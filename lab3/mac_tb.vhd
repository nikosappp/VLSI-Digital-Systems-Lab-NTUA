library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity mac_tb is
-- Τα testbenches δεν έχουν ports
end mac_tb;

architecture sim of mac_tb is

    -- Σήματα για τη διασύνδεση με το Component
    signal clk      : std_logic := '0';
    signal mac_init : std_logic := '0';
    signal ram_out  : std_logic_vector(7 downto 0) := (others => '0');
    signal rom_out  : std_logic_vector(7 downto 0) := (others => '0');
    signal acc      : std_logic_vector(18 downto 0); -- L=19 bits για αποφυγή υπερχείλισης [cite: 68, 69]

    -- Σήμα ελέγχου τερματισμού προσομοίωσης
    signal test_done : std_logic := '0';

    -- Ορισμός περιόδου ρολογιού
    constant clk_period : time := 10 ns;

begin

    -- Unit Under Test (UUT) Instantiation
    uut: entity work.mac
        port map (
            clk      => clk,
            mac_init => mac_init,
            ram_out  => ram_out,
            rom_out  => rom_out,
            acc      => acc
        );

    -- Clock generation process - Σταματάει όταν το test_done γίνει '1'
    clk_process : process
    begin
        while test_done = '0' loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait; -- Παύση ρολογιού για πάντα
    end process;

    -- Stimulus process
    stim_proc: process
    begin		
        -- Αναμονή για σταθεροποίηση
        wait for 20 ns;

        -----------------------------------------------------------
        -- ΚΥΚΛΟΣ 1: Αρχικοποίηση και 1ο Γινόμενο (mac_init = '1')
        -----------------------------------------------------------
        mac_init <= '1'; -- [cite: 46]
        ram_out  <= x"02"; 
        rom_out  <= x"03"; 
        wait for clk_period;
        
        -----------------------------------------------------------
        -- ΚΥΚΛΟΙ 2-8: Συσσώρευση (mac_init = '0') [cite: 19]
        -----------------------------------------------------------
        mac_init <= '0';
        
        ram_out <= x"04"; rom_out <= x"05"; wait for clk_period; -- Cycle 2
        ram_out <= x"0A"; rom_out <= x"02"; wait for clk_period; -- Cycle 3
        ram_out <= x"01"; rom_out <= x"01"; wait for clk_period; -- Cycle 4
        ram_out <= x"64"; rom_out <= x"02"; wait for clk_period; -- Cycle 5
        ram_out <= x"05"; rom_out <= x"02"; wait for clk_period; -- Cycle 6
        ram_out <= x"03"; rom_out <= x"03"; wait for clk_period; -- Cycle 7
        ram_out <= x"02"; rom_out <= x"02"; wait for clk_period; -- Cycle 8 (Τελικό: 270)

        -----------------------------------------------------------
        -- Έλεγχος Υπερχείλισης (8-tap με Max values) [cite: 19, 21]
        -----------------------------------------------------------
        mac_init <= '1';
        ram_out  <= x"FF"; -- 255
        rom_out  <= x"FF"; -- 255
        wait for clk_period; -- Φόρτωση 65025
        
        mac_init <= '0';
        for i in 1 to 7 loop
            ram_out <= x"FF"; rom_out <= x"FF";
            wait for clk_period;
        end loop;
        -- Στο σημείο αυτό (8ος κύκλος), το acc πρέπει να είναι 520200 [cite: 68]

        -- Ολοκλήρωση προσομοίωσης
        wait for clk_period;
        test_done <= '1'; -- Ενεργοποίηση του kill-switch
        wait;
    end process;

end sim;