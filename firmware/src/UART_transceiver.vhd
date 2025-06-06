library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top-level entity for the UART transceiver system
entity UART_transceiver is
    Port (
        clk          : in std_logic;                               -- System clock
        reset        : in std_logic;                               -- System reset
        ADC_read     : in std_logic_vector(15 downto 0);           -- Input from ADC representing measured current
        uart_rx      : in std_logic;                               -- UART receive line
        
        uart_tx      : out std_logic;                              -- UART transmit line
        duty_cycle   : out integer;                                -- Output duty cycle value
        ctrl_l       : out integer;                                -- Lower control value (scaled by 1000)
        ctrl_h       : out integer;                                -- Upper control value (scaled by 1000)
        tec_maxv     : out integer;                                -- TEC max voltage (scaled by 1000)
        setpoint     : out integer;                                -- Temperature setpoint (scaled by 1000)
        mod_mode     : out std_logic_vector(1 downto 0)            -- Mode signal for modulator block
    );
end UART_transceiver;

-- Structural architecture to wire together various UART components
architecture Structural of UART_transceiver is

    -- Internal signals for interconnection between components
    signal reg_in               : integer;                         -- Value to be written to register
    signal register_enable      : std_logic;                       -- Flag to enable writing to registers
    signal reg_address          : std_logic_vector(2 downto 0);    -- Register address selector
    signal data_ready_signal    : std_logic;                       -- Signal indicating new UART byte received
    signal rx_data              : std_logic_vector(7 downto 0);    -- Received UART byte
    signal mod_sel_reg          : std_logic_vector(1 downto 0);    -- Selected modulation mode
    signal command_parsed_sig   : std_logic_vector(23 downto 0) := (others => '0');  -- Parsed command
    signal attribute_ASCII_sig  : std_logic_vector(31 downto 0) := (others => '0');  -- ASCII representation of attribute
    signal ctl_value_ASCII_sig  : std_logic_vector(31 downto 0) := (others => '0');  -- ASCII representation of value
    signal payload_sig          : std_logic_vector(695 downto 0) := (others => '0'); -- UART transmission payload
    signal ctrl_l_sig           : integer := 0;                    -- Internal signal for ctrl_l
    signal ctrl_h_sig           : integer := 0;                    -- Internal signal for ctrl_h
    signal tec_maxv_sig         : integer := 0;                    -- Internal signal for tec_maxv
    signal setpoint_sig         : integer := 0;                    -- Internal signal for setpoint
    signal duty_cycle_sig       : integer := 0;                    -- Internal signal for duty cycle
    signal mod_mode_sig         : std_logic_vector(1 downto 0);    -- Internal signal for modulation mode
    signal enable_sig           : std_logic := '0';

    -- Driver component: stores control values and generates system outputs
    component driver_reg is
        Port(
            clk                 : in std_logic;
            reset               : in std_logic;
            write_flag          : in std_logic;
            address             : in std_logic_vector(2 downto 0);
            mod_sel_in          : in std_logic_vector(1 downto 0);
            data_in             : in integer;                      -- Input value (scaled)
            ctrl_l              : out integer;
            ctrl_h              : out integer;
            tec_maxv            : out integer;
            setpoint            : out integer;
            duty_cycle          : out integer;
            mod_mode            : out std_logic_vector(1 downto 0)
        );
    end component;

    -- UART Receiver: receives serial data and indicates when a byte is ready
    component UART_receiver is 
        Port(
            clk                 : in std_logic;
            reset               : in std_logic;
            rx_bit              : in std_logic;
            rx_data             : out std_logic_vector(7 downto 0);
            data_ready          : out std_logic     
        );
    end component;

    -- UART Parser: decodes incoming UART data into control instructions
    component UART_parser is 
        Port(
            clk                 : in std_logic;
            reset               : in std_logic;
            data_ready_in       : in std_logic;
            uart_byte_in        : in std_logic_vector(7 downto 0);
            address_select      : out std_logic_vector(2 downto 0);
            register_enable     : out std_logic;
            data_out            : out integer;
            mod_select_out      : out std_logic_vector(1 downto 0);
            command_parsed_out  : out std_logic_vector(23 downto 0);
            attribute_ASCII_out : out std_logic_vector(31 downto 0);
            ctl_value_ASCII_out : out std_logic_vector(31 downto 0)
        );
    end component;

    -- UART Transmitter: serializes and sends payload over UART
    component UART_transmitter
        Port (
            clk                 : in std_logic;
            enable              : in std_logic;
            uart_payload        : in std_logic_vector(695 downto 0);
            uart_tx             : out std_logic
        );
    end component;

    -- Payload Generator: creates formatted UART message with system status
    component UART_payload_gen is
        Port ( 
            command_parsed_in   : in std_logic_vector(23 downto 0);
            attribute_ASCII_in  : in std_logic_vector(31 downto 0);
            ctl_value_ASCII_in  : in std_logic_vector(31 downto 0);
            SOA_current_dig_in  : in std_logic_vector(15 downto 0);
            ctrl_l              : in integer;
            ctrl_h              : in integer;
            tec_maxv            : in integer;
            setpoint            : in integer;
            duty_cycle          : in integer;
            mod_mode            : in std_logic_vector(1 downto 0);
            payload_out         : out std_logic_vector(695 downto 0)   -- Output payload for UART transmission
        );
    end component;

begin
    -- Instantiate UART Transmitter
    transmitter: UART_transmitter
        Port map(
            clk                 => clk,
            enable              => enable_sig,                 -- Always enabled for now
            uart_payload        => payload_sig,
            uart_tx             => uart_tx  
        );

    -- Instantiate Payload Generator
    UART_pl : UART_payload_gen
        Port map(
            command_parsed_in   => command_parsed_sig,
            attribute_ASCII_in  => attribute_ASCII_sig,
            ctl_value_ASCII_in  => ctl_value_ASCII_sig,
            SOA_current_dig_in  => ADC_read,
            ctrl_l              => ctrl_l_sig,
            ctrl_h              => ctrl_h_sig,
            tec_maxv            => tec_maxv_sig,
            setpoint            => setpoint_sig,
            duty_cycle          => duty_cycle_sig,
            mod_mode            => mod_mode_sig,
            payload_out         => payload_sig
        );

    -- Instantiate UART Receiver
    receiver: UART_receiver
        Port Map(
            clk                 => clk,
            reset               => reset,
            rx_bit              => uart_rx,
            rx_data             => rx_data,
            data_ready          => data_ready_signal
        );

    -- Instantiate Register Driver
    reg : driver_reg
        Port map(
            clk                 => clk,
            reset               => reset,
            write_flag          => register_enable,
            address             => reg_address,
            mod_sel_in          => mod_sel_reg,
            data_in             => reg_in,
            ctrl_l              => ctrl_l_sig,
            ctrl_h              => ctrl_h_sig,
            tec_maxv            => tec_maxv_sig,
            setpoint            => setpoint_sig,
            duty_cycle          => duty_cycle_sig,
            mod_mode            => mod_mode_sig
        );

    -- Instantiate UART Parser
    parser : UART_parser
        Port map(
            clk                 => clk,
            reset               => reset,
            data_ready_in       => data_ready_signal,
            uart_byte_in        => rx_data,
            address_select      => reg_address,
            register_enable     => register_enable,
            data_out            => reg_in,
            mod_select_out      => mod_sel_reg,
            command_parsed_out  => command_parsed_sig,
            attribute_ASCII_out => attribute_ASCII_sig,
            ctl_value_ASCII_out => ctl_value_ASCII_sig
        );

    -- Connect internal signals to top-level outputs
    ctrl_l      <= ctrl_l_sig;
    ctrl_h      <= ctrl_h_sig;
    tec_maxv    <= tec_maxv_sig;
    setpoint    <= setpoint_sig;
    duty_cycle  <= duty_cycle_sig;
    mod_mode    <= mod_mode_sig;
    
    process(clk)
        variable counter : integer range 0 to 100000 := 0;
    begin
        if rising_edge(clk) then
            counter := counter + 1;
            enable_sig <= '0';
            if counter = 100000 then
                enable_sig <= '1';
                counter := 0;
            end if;
        end if;
    end process;
        
end Structural;
