----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/29/2024 11:07:56 AM
-- Design Name: 
-- Module Name: I2C_master - Behavioral
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

entity I2C_Master is
    Port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        start_tx : in  std_logic;                       -- segnale di avvio della trasmissione
        data_in  : in  std_logic_vector(63 downto 0);   -- dati da inviare
        ack      : in std_logic;                       -- ack dal dispositivo
        sda      : inout std_logic;
        scl      : out std_logic
    );
end I2C_Master;

architecture Behavioral of I2C_master is
    -- Definisci stati
    type state_type is (Idle, Start, Address, Write, Waitack, Stop);
    signal state : state_type := Idle;

    -- Clock divider per generare SCL
    signal scl_div : integer := 0;
    signal scl_reg : std_logic := '1';

    -- Dati e controllo
    signal bit_counter : integer := 0;
    signal sda_out : std_logic := '1';
    
begin
    -- Clock divider per SCL
    process(clk)
    begin
        if rising_edge(clk) then
            if scl_div = 249 then  -- Divider per 100 kHz (assumendo un clock di 50 MHz)
                scl_div <= 0;
                scl_reg <= not scl_reg;
            else
                scl_div <= scl_div + 1;
            end if;
        end if;
    end process;

    scl <= scl_reg;

    -- FSM per gestire la trasmissione I2C
    process(clk, reset)
    begin
        if reset = '1' then
            state <= Idle;
            sda_out <= '1';
            bit_counter <= 0;
        elsif rising_edge(clk) then
            case state is
                when Idle =>
                    if start_tx = '1' then
                        state <= Start;
                    end if;

                when Start =>
                    sda_out <= '0';  -- Start condition: SDA va basso con SCL alto
                    state <= Address;

                when Address =>
                    if bit_counter < 8 then
                        sda_out <= data_in(63 - bit_counter);
                        bit_counter <= bit_counter + 1;
                    else
                        bit_counter <= 0;
                        state <= Waitack;
                    end if;

                when Waitack =>
                    sda_out <= 'Z';  -- Rilascia SDA per il bit di ACK
                    ack     <= sda;  -- Leggi l'ACK dallo slave
                    state <= Stop;

                when Stop =>
                    sda_out <= '0';  -- SDA va basso prima di SCL
                    if scl_reg = '1' then
                        sda_out <= '1';  -- Stop condition: SDA va alto con SCL alto
                        state <= Idle;
                    end if;

                when others =>
                    state <= Idle;
            end case;
        end if;
    end process;

    -- Collegamento SDA
    sda <= sda_out;

end Behavioral;