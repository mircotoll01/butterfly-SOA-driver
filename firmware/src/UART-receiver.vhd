----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/11/2024 03:01:23 PM
-- Design Name: 
-- Module Name: Serial - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_receiver is
    Port ( 
        clk                 : in  std_logic;                       
        reset               : in  std_logic;                       
        rx                  : in  std_logic;                                    -- Incoming bit (RX)
        rx_data             : out std_logic_vector(7 downto 0);                 -- Received data
        data_ready          : out std_logic                                     -- Flag for data ready to be read
    );
end UART_receiver;

architecture Behavioral of UART_receiver is
    constant BAUD_RATE      : integer := 9600;                                  -- Baud rate 
    constant CLOCK_FREQ     : integer := 50000000;                              -- System clock frequency (50 MHz)
    constant BAUD_DIVISOR   : integer := CLOCK_FREQ / BAUD_RATE;                -- Clock divider

    signal baud_tick        : std_logic;                                        -- Baud rate tick
    signal baud_counter     : integer range 0 to BAUD_DIVISOR - 1 := 0;

    signal rx_buffer        : std_logic_vector(7 downto 0) := (others => '0');  -- received byte
    signal bit_index        : integer range 0 to 9 := 0;                        -- Indice dei bit (start, dati, stop)
    signal receiving        : std_logic := '0';                                 -- Stato di ricezione attiva

    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;
begin
    -- Clovk divider for baud rate
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                baud_counter <= 0;
                baud_tick <= '0';
            else
                if baud_counter = BAUD_DIVISOR - 1 then
                    baud_counter <= 0;
                    baud_tick <= '1';
                else
                    baud_counter <= baud_counter + 1;
                    baud_tick <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Receiver FSM
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state       <= IDLE;
                bit_index   <= 0;
                rx_buffer   <= (others => '0');
                data_ready  <= '0';
                receiving   <= '0';
            elsif baud_tick = '1' then
                case state is
                    when IDLE =>
                        data_ready <= '0';                      -- Reset data ready flag
                        if rx = '0' then                        -- Detect start bit 
                            state       <= START_BIT;
                            receiving   <= '1';
                            bit_index   <= 0;
                        end if;

                    when START_BIT =>
                        if rx = '0' then                        -- Is it really a start bit?
                            state <= DATA_BITS;
                        else
                            state <= IDLE;                      -- Turn back if it wasn't
                        end if;

                    when DATA_BITS =>
                        rx_buffer(bit_index) <= rx;             -- Memorize bit in a buffer
                        if bit_index = 7 then
                            state <= STOP_BIT;                  -- After eighth bit there's a stop
                        else
                            bit_index <= bit_index + 1;
                        end if;

                    when STOP_BIT =>
                        if rx = '1' then                        -- Validate stop bit
                            rx_data     <= rx_buffer;
                            data_ready  <= '1';                 -- Set data ready flag
                        end if;
                        state <= IDLE;                          -- Go back to idle
                        receiving <= '0';

                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
