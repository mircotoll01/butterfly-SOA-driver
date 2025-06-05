library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library xil_defaultlib;
use xil_defaultlib.utils_pkg.all;

entity UART_transmitter is
    port (
        clk         : in std_logic;
        enable      : in std_logic;
        uart_payload: in std_logic_vector(695 downto 0);
        uart_tx     : out std_logic
    );
end UART_transmitter;


architecture Behavioral of UART_transmitter is
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT, CLEANUP);
    
    -- Constants
    constant BAUD_RATE      : integer := 9600;                                  -- Baud rate 
    constant CLOCK_FREQ     : integer := 10000000;                               -- System clock frequency (10 MHz)
    constant BAUD_DIVISOR   : integer := CLOCK_FREQ / BAUD_RATE;                 -- This is the number of clock per bit
    
    -- Signals
    signal state            : state_type := IDLE;
    signal tx_buffer        : std_logic_vector(7 downto 0) := (others => '0');   -- current byte to transmit
    signal ready            : std_logic := '1';                                  -- Indicates if the transmitter is ready for a new payload
    signal uart_payload_queued: std_logic_vector(695 downto 0) := (others => '0'); -- Stores the payload to be transmitted
begin

    -- Synchronous loading of uart_payload
    process(clk)
    begin
        if rising_edge(clk) and ready = '1' then
            -- Load new payload only when transmitter is ready AND enable is asserted
            uart_payload_queued <= uart_payload;
        end if;
    end process;
    
    process (clk)
        variable baud_counter       : integer range 0 to BAUD_DIVISOR - 1 := 0;
        variable byte_counter       : integer range 0 to 86 := 0;
        variable bit_index          : integer range 0 to 7 := 0;
    begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    uart_tx <= '1'; -- Drive Line High for Idle
                    
                    if enable = '1' and ready = '1' then -- If a payload is queued and not yet sent
                        -- Load the first byte for transmission
                        tx_buffer       <= uart_payload_queued(7 downto 0);
                        baud_counter    := 0; -- Reset baud counter for the start bit
                        byte_counter    := 0;   -- Reset byte counter for new payload
                        ready           <= '0';
                        state <= START_BIT;
                    elsif ready = '0' and byte_counter > 0 then
                        tx_buffer       <= uart_payload_queued((7+8*byte_counter) downto (0+8*byte_counter));
                        state <= START_BIT;
                    else
                        state <= IDLE; -- Stay in IDLE if no payload is ready to send
                    end if;
                
                when START_BIT =>
                    uart_tx <= '0'; -- Drive Line Low for Start Bit
                    
                    if baud_counter < BAUD_DIVISOR-1 then
                        baud_counter := baud_counter + 1;
                        state <= START_BIT;
                    else
                        baud_counter    := 0; -- Reset for data bits
                        bit_index       := 0;    -- Reset bit index for data bits
                        uart_tx <= tx_buffer(0); -- Drive the first data bit immediately
                        state <= DATA_BITS;
                    end if;
                
                when DATA_BITS =>
                    uart_tx <= tx_buffer(bit_index);
                    
                    if baud_counter < BAUD_DIVISOR-1 then
                        baud_counter    := baud_counter + 1;
                        state           <= DATA_BITS;
                    else
                        baud_counter    := 0;
                     
                        if bit_index < 7 then
                            bit_index   := bit_index + 1;
                            state       <= DATA_BITS;
                        else
                            bit_index   := 0;
                            state       <= STOP_BIT;
                        end if;
                    end if;
                    
                
                when STOP_BIT =>
                    uart_tx <= '1'; -- Drive Line High for Stop Bit
                    if baud_counter < BAUD_DIVISOR-1 then    
                        baud_counter := baud_counter + 1;
                        state <= STOP_BIT;
                    else
                        state <= CLEANUP;
                    end if;
            
                when CLEANUP =>
                    baud_counter := 0;
                    bit_index    := 0;
                    
                    if byte_counter = 86 then -- All bytes sent
                        ready <= '1'; -- Mark as ready for next payload
                    else
                        byte_counter := byte_counter + 1; -- Move to next byte
                    end if;
                    state <= IDLE; -- Go back to IDLE
                
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;    
end Behavioral;