----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/30/2024 02:07:02 PM
-- Design Name: 
-- Module Name: dac_testbench - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity dac_controller_tb is
end dac_controller_tb;

architecture Behavioral of dac_controller_tb is
    -- Componenti
    component dac_controller
        Port (
            clk       : in  std_logic;
            reset     : in  std_logic;
            sda       : inout std_logic;
            scl       : out std_logic;
            dac_start : in  std_logic;
            dac_data  : in  std_logic_vector(7 downto 0);
            ack_out   : out std_logic
        );
    end component;

    -- Segnali interni per la simulazione
    signal clk       : std_logic := '0';
    signal reset     : std_logic := '1';
    signal sda       : std_logic := 'Z';
    signal scl       : std_logic;
    signal dac_start : std_logic := '0';
    signal dac_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal ack_out   : std_logic;

    -- Clock di simulazione
    constant CLK_PERIOD : time := 20 ns;

begin
    -- Istanza del componente dac_controller
    uut: dac_controller
        Port map (
            clk       => clk,
            reset     => reset,
            sda       => sda,
            scl       => scl,
            dac_start => dac_start,
            dac_data  => dac_data,
            ack_out   => ack_out
        );

    -- Generazione del clock
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimoli per la simulazione
    stimulus_process : process
    begin
        -- Reset iniziale
        reset <= '1';
        wait for 50 ns;
        reset <= '0';

        -- Inizio della trasmissione con dati per il DAC
        dac_start <= '1';
        dac_data <= "10101010";  -- Dato di esempio da inviare al DAC
        wait for CLK_PERIOD;
        dac_start <= '0';  -- Fine del segnale di start

        -- Aspetta un po' di tempo per completare la trasmissione
        wait for 500 ns;

        -- Termina la simulazione
        wait;
    end process;

end Behavioral;

