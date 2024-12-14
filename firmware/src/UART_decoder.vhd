----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/11/2024 05:00:23 PM
-- Design Name: 
-- Module Name: UART_decoder - Behavioral
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

entity UART_decoder is
    Port (
        clk          : in std_logic;
        reset        : in std_logic;
        rx           : in std_logic;
        duty_cycle   : out integer;  
        ctrl_l       : out integer;  -- Scaled by 10000
        ctrl_h       : out integer;  -- Scaled by 10000
        tec_maxv     : out integer;  -- Scaled by 10000
        setpoint     : out integer;  -- Scaled by 10000                                
        mod_command  : out std_logic_vector(1 downto 0)                 -- Commands that will be sent to the modulator block
    );
end UART_decoder;

architecture Structural of UART_decoder is
    signal char_index               : integer := 0;
    signal reg_in                   : integer;
    signal write_flag               : std_logic;
    signal reg_address              : std_logic_vector(2 downto 0);
    signal data_ready               : std_logic;
    signal rx_data                  : std_logic_vector(7 downto 0);
    
    component driver_reg is
        Port(
            clk                     : in std_logic;
            write_flag              : in std_logic;
            address                 : in std_logic_vector(2 downto 0);
            data_in                 : in integer;  -- Scaled by 10000
            ctrl_l                  : out integer; -- Scaled by 10000
            ctrl_h                  : out integer; -- Scaled by 10000
            tec_maxv                : out integer; -- Scaled by 10000
            setpoint                : out integer  -- Scaled by 10000
        );
    end component;
    
    component UART_receiver is 
        Port(
            clk                     : in  std_logic;                       
            reset                   : in  std_logic;                       
            rx                      : in  std_logic;                                    -- Incoming bit (RX)
            rx_data                 : out std_logic_vector(7 downto 0);                 -- Received data
            data_ready              : out std_logic     
        );
    end component;
    
    component UART_parser is 
        Port(
            clk          : in std_logic;
            reset        : in std_logic;
            data_ready_in: in std_logic;
            uart_byte_in : in std_logic_vector(7 downto 0);
            reg_address  : out std_logic_vector(2 downto 0);
            write_out_reg: out std_logic;
            data_out_reg : out integer;                           
            mod_command  : out std_logic_vector(1 downto 0)  
        );
    end component;
    
begin

    receiver: UART_receiver
        Port Map(
            clk             => clk,
            reset           => reset,
            rx              => rx,
            rx_data         => rx_data,
            data_ready      => data_ready
        );
        
    reg : driver_reg
        Port map(
            clk             => clk,
            write_flag      => write_flag,
            address         => reg_address,
            data_in         => reg_in,
            ctrl_l          => ctrl_l,
            ctrl_h          => ctrl_h,
            tec_maxv        => tec_maxv,
            setpoint        => setpoint
        );
    
    parser : UART_parser
        Port map(
            clk             => clk,
            reset           => reset,
            data_ready_in   => data_ready,
            uart_byte_in    => rx_data,
            reg_address     => reg_address,
            write_out_reg   => write_flag,
            data_out_reg    => reg_in,
            mod_command     => mod_command
        );
    
end Structural;
