library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_receiver is
    Port ( 
        clk                 : in  std_logic;                       
        reset               : in  std_logic;                       
        rx_bit              : in  std_logic;                                    -- Incoming bit (RX)
        rx_data             : out std_logic_vector(7 downto 0);                 -- Received data
        data_ready          : out std_logic                                     -- Flag for data ready to be read
    );
end UART_receiver;

architecture Behavioral of UART_receiver is
    constant BAUD_RATE      : integer := 9600;                                  -- Baud rate 
    constant CLOCK_FREQ     : integer := 100000000;                               -- System clock frequency (10 MHz)
    constant BAUD_DIVISOR   : integer := CLOCK_FREQ / BAUD_RATE;                -- This is the number of clock per bit

    signal rx_reg           : std_logic_vector(7 downto 0) := (others => '0');  -- received byte
    signal bit_index        : integer range 0 to 7 := 0;                        -- Indice dei bit (start, dati, stop)
    signal dr_reg           : std_logic := '0';

    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT, CLEANUP);
    signal state : state_type := CLEANUP;
begin 
    -- Receiver FSM
    process(clk)
        variable baud_counter     : integer range 0 to BAUD_DIVISOR - 1 := 0;
    begin
        if rising_edge(clk) then
        
            if reset = '1' then
                state                   <= IDLE;
                bit_index               <= 0;
                rx_reg                  <= (others => '0');
            end if;
            
            case state is
                when CLEANUP =>
                    rx_reg              <= (others => '0');
                    dr_reg              <= '0';
                    bit_index           <= 0;
                    baud_counter        := 0;
                    state               <= IDLE;  
                
                when IDLE =>
                    if rx_bit = '0' then                            -- Detect start bit 
                        state           <= START_BIT;
                    end if;
                    

                when START_BIT =>
                    if baud_counter = (BAUD_DIVISOR - 1)/2 then
                        if rx_bit = '0' then                       -- Is it really a start bit? check middle of start bit to verify it wasn't noise
                            state           <= DATA_BITS;
                        else
                            state           <= IDLE;               -- Turn back if it wasn't
                        end if;
                        baud_counter        := 0;
                    else 
                        baud_counter        := baud_counter + 1;
                        state               <= START_BIT;
                    end if;
                    
                when DATA_BITS =>
                    if baud_counter < BAUD_DIVISOR - 1 then
                        baud_counter        := baud_counter + 1;
                        state               <= DATA_BITS;
                    else
                        baud_counter        := 0;
                        rx_reg(bit_index)<= rx_bit;             -- Memorize bit in a buffer
                        
                        if bit_index = 7 then
                            state           <= STOP_BIT;           -- After eighth bit there's a stop
                            dr_reg          <= '1';
                            bit_index       <= 0;
                        else
                            bit_index       <= bit_index + 1;
                            state           <= DATA_BITS;
                        end if;
                    end if;
                    
                when STOP_BIT =>
                    if baud_counter < (BAUD_DIVISOR - 1)/2 then
                        baud_counter        := baud_counter + 1;
                        state               <= STOP_BIT;
                    else
                        baud_counter        := 0;
                        if rx_bit = '1' then                    -- Validate stop bit
                            state           <= CLEANUP;         -- clean up
                        end if;
                    end if;
                when others =>
                    state <= CLEANUP;
            end case;
        end if;
    end process;
    
    rx_data         <= rx_reg;
    data_ready      <= dr_reg;
end Behavioral;