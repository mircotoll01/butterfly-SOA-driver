library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_transceiver is
    Port (
        clk          : in std_logic;
        reset        : in std_logic;
        ADC_read     : in std_logic_vector(15 downto 0);
        uart_rx      : in std_logic;
        
        uart_tx      : out std_logic;
        duty_cycle   : out integer;  
        ctrl_l       : out integer;  -- Scaled by 10000
        ctrl_h       : out integer;  -- Scaled by 10000
        tec_maxv     : out integer;  -- Scaled by 10000
        setpoint     : out integer;  -- Scaled by 10000                                
        mod_mode     : out std_logic_vector(1 downto 0)                 -- Commands that will be sent to the modulator block
    );
end UART_transceiver;

architecture Structural of UART_transceiver is
    signal reg_in               : integer;
    signal register_enable      : std_logic;
    signal reg_address          : std_logic_vector(2 downto 0);
    signal data_ready_signal    : std_logic;
    signal rx_data              : std_logic_vector(7 downto 0);
    signal mod_sel_reg          : std_logic_vector(1 downto 0);
    signal command_parsed_sig   : std_logic_vector(23 downto 0) := (others => '0');
    signal attribute_ASCII_sig  : std_logic_vector(31 downto 0) := (others => '0');
    signal ctl_value_ASCII_sig  : std_logic_vector(31 downto 0) := (others => '0');
    signal payload_sig          : std_logic_vector(335 downto 0) := (others => '0');
    
    
    component driver_reg is
        Port(
            clk                 : in std_logic;
            reset               : in std_logic;
            write_flag          : in std_logic;
            address             : in std_logic_vector(2 downto 0);
            mod_sel_in          : in std_logic_vector(1 downto 0);
            data_in             : in integer;  -- Scaled by 10000
            ctrl_l              : out integer; -- Scaled by 10000
            ctrl_h              : out integer; -- Scaled by 10000
            tec_maxv            : out integer; -- Scaled by 10000
            setpoint            : out integer; -- Scaled by 10000
            duty_cycle          : out integer;
            mod_mode            : out std_logic_vector(1 downto 0) 
        );
    end component;
    
    component UART_receiver is 
        Port(
            clk                 : in  std_logic;                       
            reset               : in  std_logic;                       
            rx_bit              : in  std_logic;                                    -- Incoming bit (RX)
            rx_data             : out std_logic_vector(7 downto 0);                 -- Received data
            data_ready          : out std_logic     
        );
    end component;
    
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
    
    component UART_transmitter
        Port (
            clk                 : in std_logic;
            enable              : in std_logic;
            uart_payload        : in std_logic_vector(335 downto 0);
            uart_tx             : out std_logic
        );
    end component;
    
    component UART_payload_gen is
        Port ( 
            command_parsed_in   : in std_logic_vector(23 downto 0);
            attribute_ASCII_in  : in std_logic_vector(31 downto 0);
            ctl_value_ASCII_in  : in std_logic_vector(31 downto 0);
            SOA_current_dig_in  : in std_logic_vector(15 downto 0);
            
            payload_out         : out std_logic_vector(335 downto 0)   --display last command and measured current on the SOA  
        );
    end component;
    
begin
    transmitter: UART_transmitter
        Port map(
            clk                 => clk,
            enable              => '1',
            uart_payload        => payload_sig,
            uart_tx             => uart_tx  
        );
    UART_pl : UART_payload_gen
        Port map(
            command_parsed_in   => command_parsed_sig,
            attribute_ASCII_in  => attribute_ASCII_sig,
            ctl_value_ASCII_in  => ctl_value_ASCII_sig,
            SOA_current_dig_in  => ADC_read,
            
            payload_out         => payload_sig
        );

    receiver: UART_receiver
        Port Map(
            clk                 => clk,
            reset               => reset,
            rx_bit              => uart_rx,
            rx_data             => rx_data,
            data_ready          => data_ready_signal
        );
        
    reg : driver_reg
        Port map(
            clk                 => clk,
            reset               => reset,
            write_flag          => register_enable,
            address             => reg_address,
            mod_sel_in          => mod_sel_reg,
            data_in             => reg_in,
            ctrl_l              => ctrl_l,
            ctrl_h              => ctrl_h,
            tec_maxv            => tec_maxv,
            setpoint            => setpoint,  
            duty_cycle          => duty_cycle,
            mod_mode            => mod_mode
        );
    
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
    
end Structural;
