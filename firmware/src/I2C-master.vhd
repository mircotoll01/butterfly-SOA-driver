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
        clk         : in  std_logic;
        reset       : in  std_logic;
        start_tx    : in  std_logic;                       -- external blocks will start transmission
        I2C_payload : in  std_logic_vector(47 downto 0);  
        sda         : inout std_logic;
        scl         : out std_logic;
        n_ldac      : out std_logic
    );
end I2C_Master;

architecture Behavioral of I2C_master is
    -- States definition
    type state_type is (Idle, Start, Address, Write, Waitack, Stop);
    signal state : state_type := Idle;

    -- Clock divider to generate SCL
    signal scl_div : integer := 0;

    -- controls and data
    signal bit_counter  : integer := 0;
    signal sda_out      : std_logic := '1';
    signal ack          : std_logic;
    signal scl_reg      : std_logic := '1';
    
begin
    -- Clock divider for SCL
    process(clk)
    begin
        if rising_edge(clk) then
            if scl_div = 499 then           -- Divider per 100 kHz (a clock of clock 100 MHz)
                scl_div <= 0;
                scl_reg <= not scl_reg;
            else
                scl_div <= scl_div + 1;
            end if;
        end if;
    end process;

    scl <= scl_reg;

    -- FSM for I2C
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
                    sda_out <= '0';             -- Start condition: SDA goes low when SCL high
                    n_ldac  <= '0';
                    state   <= Address;

                when Address =>
                    if bit_counter < 8 then
                        sda_out     <= I2C_payload(47 - bit_counter);
                        bit_counter <= bit_counter + 1;
                    else
                        bit_counter <= 0;
                        state       <= Waitack;
                    end if;

                when Waitack =>
                    sda_out     <= 'Z';         -- Release SDA to let the slave give ACK
                    ack         <= sda;         -- read ACK
                    state       <= Stop;

                when Stop =>
                    sda_out <= '0';             -- SDA goes low before SCL
                    if scl_reg = '1' then
                        sda_out     <= '1';     -- Stop condition: SDA goes high with SCL high
                        state       <= Idle;
                        n_ldac  <= '1';
                    end if;

                when others =>
                    state <= Idle;
            end case;
        end if;
    end process;
    sda <= sda_out;

end Behavioral;