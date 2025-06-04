library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity I2C_Master is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        I2C_payload : in  std_logic_vector(47 downto 0);  
        sda         : inout std_logic;
        scl         : out std_logic;
        n_ldac      : out std_logic
    );
end I2C_Master;

architecture Behavioral of I2C_master is
    -- States definition
    type state_type is (IDLE, START, DATA_BITS, WAITACK, STOP);
    signal state        : state_type := IDLE;

    -- Clock divider to generate SCL
    signal scl_div      : integer range 0 to 49 := 0;

    -- controls and data
    signal bit_counter  : integer range 0 to 7 := 0;
    signal sda_reg      : std_logic := '1';
    signal ack          : std_logic := '0';
    signal scl_reg      : std_logic := '1';
    
begin
    -- Clock divider for SCL
    process(clk)
    begin
        if rising_edge(clk) then
            if scl_div = 49 then           -- 100 kHz divider (with a clock of 10 MHz)
                scl_div <= 0;
                scl_reg <= not scl_reg;
            else
                scl_div <= scl_div + 1;
            end if;
        end if;
    end process;

    scl <= scl_reg;

    -- FSM for I2C
    process(clk)      
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state       <= IDLE;
                sda_reg     <= '1';
                bit_counter <= 0;
                n_ldac      <= '1';
                ack         <= '0';
            end if;
            case state is
                when IDLE =>
                        state <= START;

                when START =>
                    sda_reg <= '0';             -- START condition: SDA goes low when SCL high
                    n_ldac  <= '0';
                    state   <= DATA_BITS;

                when DATA_BITS =>
                    if bit_counter < 7 then
                        sda_reg     <= I2C_payload(47 - bit_counter);
                        bit_counter <= bit_counter + 1;
                    else
                        bit_counter <= 0;
                        state       <= WAITACK;
                    end if;

                when WAITACK =>
                    sda_reg     <= 'Z';         -- Release SDA to let the slave give ACK
                    ack         <= sda_reg;     -- read ACK
                    if ack = '1' then
                        state   <= STOP; 
                        ack     <= '0';
                    end if;

                when STOP =>
                    sda_reg <= '0';             -- SDA goes low before SCL
                    if scl_reg = '1' then
                        sda_reg     <= '1';     -- STOP condition: SDA goes high with SCL high
                        state       <= IDLE;
                        n_ldac      <= '1';
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
    sda <= sda_reg;

end Behavioral;