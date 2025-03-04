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

entity UART_transmitter is
    port (
        clk         : in  std_logic;
        enable      : in  std_logic;
        input       : in  std_logic_vector(7 downto 0);
        uart_tx     : out std_logic
    );
end UART_transmitter;
 
 
architecture Behavioral of UART_transmitter is
    constant BAUD_RATE      : integer := 9600;                                  -- Baud rate 
    constant CLOCK_FREQ     : integer := 10000000;                              -- System clock frequency (10 MHz)
    constant BAUD_DIVISOR   : integer := CLOCK_FREQ / BAUD_RATE;                -- This is the number of clock per bit
    
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT, CLEANUP);
    signal state : state_type := IDLE;
 
    signal tx_buffer        : std_logic_vector(7 downto 0) := (others => '0');  -- received byte
    signal bit_index        : integer range 0 to 7 := 0;                        -- Indice dei bit (start, dati, stop)
    signal ready_buffer     : std_logic := '0';
   
begin
    process (clk)
        variable baud_counter     : integer range 0 to BAUD_DIVISOR - 1 := 0;
    begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    uart_tx             <= '1';         -- Drive Line High for Idle
                    if enable = '1' then 
                        tx_buffer       <= input;
                        state           <= START_BIT;
                    else
                        state           <= IDLE;
                    end if;
                
                when START_BIT =>
                    uart_tx             <= '0';
                    
                    if baud_counter < BAUD_DIVISOR-1 then
                        baud_counter    := baud_counter + 1;
                        state           <= START_BIT;
                    else
                        baud_counter    := 0;
                        state           <= DATA_BITS;
                    end if;
                    
                when DATA_BITS =>
                    uart_tx <= tx_buffer(bit_index);
                    
                    if baud_counter < BAUD_DIVISOR-1 then
                        baud_counter    := baud_counter + 1;
                        state           <= DATA_BITS;
                    else
                        baud_counter    := 0;
                     
                        if bit_index < 7 then
                            bit_index   <= bit_index + 1;
                            state       <= DATA_BITS;
                        else
                            bit_index   <= 0;
                            state       <= STOP_BIT;
                        end if;
                    end if;
                
                when STOP_BIT =>
                    uart_tx <= '1';
                    if baud_counter < BAUD_DIVISOR-1 then      
                        baud_counter    := baud_counter + 1;
                        state           <= STOP_BIT;
                    else
                        state           <= CLEANUP;
                    end if;
         
                when CLEANUP =>
                    baud_counter        := 0;
                    bit_index           <= 0;
                    state               <= IDLE;
                    
                when others =>
                    state               <= IDLE;
            end case;
        end if;
    end process;   
end Behavioral;