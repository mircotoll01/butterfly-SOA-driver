library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity I2C_Master is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        I2C_payload : in  std_logic_vector(71 downto 0);  
        sda         : inout std_logic;
        scl         : inout std_logic;
        n_ldac      : out std_logic
    );
end I2C_Master;

architecture Behavioral of I2C_Master is
    constant CLK_FREQ       : integer := 10000000; -- 10MHz
    constant SCL_FREQ       : integer := 100000;
    constant CLK_DIVIDER    : integer := (CLK_FREQ/SCL_FREQ)/4;
    
    -- States
    type state_type is (IDLE, ACK_RECEIVED, WAIT_CLOCK_CYCLE, START, DATA_BITS, WAIT_ACK, STOP);
    signal state : state_type := IDLE;

    -- SCL generation
    signal scl_counter : integer range 1 to CLK_DIVIDER*4 := 1;
    signal scl_reg     : std_logic := '1';
    signal scl_enable  : std_logic := '1';
    signal scl_pull    : std_logic := '0'; 

    -- Internal data handling
    signal bit_index   : integer range 0 to 71 := 0;
    signal payload_buf : std_logic_vector(71 downto 0) := (others => '0');
    signal sda_out     : std_logic := '1';
    signal sda_enable  : std_logic := '0';  -- 1 = drive SDA, 0 = release SDA
    signal ack         : std_logic := '0';
    signal ready       : std_logic := '1';
    signal stretch     : std_logic := '0';  -- if slave holds the clock
    signal sda_tick    : std_logic := '0';  -- when to prepare the output bit
    signal sda_tick_prv: std_logic := '0';
begin
  
    process(clk) -- SCL clock generation (100kHz from 10MHz clock)
    begin
        if rising_edge(clk) then
            sda_tick_prv <= sda_tick;                       --store previous value of data clock
            if(scl_counter = CLK_DIVIDER*4) then            --end of timing cycle
                scl_counter <= 1;                       
            elsif(stretch = '0') then                       --clock stretching from slave not detected
                scl_counter <= scl_counter + 1;             --continue clock generation timing
            end if;
            case scl_counter is
                when 1 to CLK_DIVIDER-1 =>                    --first 1/4 cycle of clocking
                    scl_reg     <= '0';
                    sda_tick    <= '0';
                when CLK_DIVIDER to CLK_DIVIDER*2-1 =>        --second 1/4 cycle of clocking
                    scl_reg     <= '0';
                    sda_tick    <= '1';
                when CLK_DIVIDER*2 TO CLK_DIVIDER*3 =>      --third 1/4 cycle of clocking
                    scl_reg     <= '1';                     --release scl
                    if scl = '0' and scl_enable = '1' and scl_pull = '0' then                       --detect if slave is stretching clock
                        stretch     <= '1';
                    else
                        stretch     <= '0';
                    end if;
                    sda_tick    <= '1';
                when others =>                              --last 1/4 cycle of clocking
                    scl_reg     <= '1';
                    sda_tick    <= '0';
            end case;
        end if;
    end process;
    
    -- I2C FSM
    process(clk)
    begin
        if rising_edge(clk) then
            if sda_tick_prv = '1' and sda_tick = '0' then
                case state is
    
                    when IDLE =>
                        if ready = '1' then
                            n_ldac      <= '0';
                            state       <= START;
                            ready       <= '0';
                        end if;
    
                    when START =>  --at the 3/4 of clock cycle, when SCL is high pull SDA low
                        sda_out     <= '0';
                        scl_enable  <= '1';
                        state       <= DATA_BITS;
                        
                    when ACK_RECEIVED =>
                        sda_out     <= '0';
                        state       <= DATA_BITS;
                        
                    when DATA_BITS =>
                        if bit_index mod 8 = 7 then
                            state       <= WAIT_ACK;
                        end if;
                        bit_index   <= bit_index + 1;
    
                    when WAIT_ACK =>
                        if sda = '0' then
                            if bit_index < 71 then
                                state       <= ACK_RECEIVED;
                                sda_enable  <= '1';
                            else
                                sda_enable  <= '1';
                                bit_index   <= 0;
                                state       <= STOP;
                            end if;
                        else
                            bit_index   <= 0;
                            sda_enable  <= '1';
                            state       <= STOP;
                        end if;
                        
                    when STOP =>
                        scl_enable  <= '0';
                        sda_out     <= '1'; -- SDA goes high while SCL high (STOP) 
                        n_ldac      <= '1';
                        state       <= IDLE;
    
                    when others =>
                        state <= IDLE;
    
                end case;
            elsif sda_tick_prv = '0' and sda_tick = '1' then
                case state is
    
                    when IDLE =>
                        sda_out     <= '1';
                        payload_buf <= I2C_payload;
                        ready       <= '1';
                        
                    when START =>
                        
                    when ACK_RECEIVED =>
                        sda_out     <= '1';
                        scl_pull    <= '1';
                            
                    when DATA_BITS =>
                        scl_pull    <= '0';
                        sda_out     <= payload_buf(71 - bit_index);
                        
                        
                    when WAIT_ACK =>
                        sda_enable  <= '0'; -- Release SDA
                        
                    when STOP =>
                        state       <= STOP;
    
                    when others =>
                        state <= IDLE;
    
                end case;
            end if;
        end if;
    end process;
    
    sda <= sda_out when sda_enable = '1' else 'Z';
    scl <= scl_reg when scl_enable = '1' and scl_pull = '0'
            else '1' when state = STOP or state = IDLE or state = START
            else '0' when scl_pull = '1' 
            else 'Z';
    
end Behavioral;
