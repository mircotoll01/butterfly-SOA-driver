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
        ctrl_l       : out real;
        ctrl_h       : out real;
        tec_maxv     : out real;
        setpoint     : out real;                                  
        command      : out std_logic_vector(1 downto 0)                 -- Commands that will be sent to the modulator block
    );
end UART_decoder;

architecture Behavioral of UART_decoder is
    signal command_buffer           : string(1 to 32);                                  -- Command parsing buffer
    signal char_index               : integer := 0;
    signal reg_in                   : real;
    signal write_flag               : std_logic;
    signal reg_address              : std_logic_vector(1 downto 0);
    signal data_ready               : std_logic;
    signal rx_data                  : std_logic_vector(7 downto 0);
    
    component driver_reg is
        Port(
            clk                     : in std_logic;
            write_flag              : in std_logic;
            address                 : in std_logic_vector(1 downto 0);
            data_in                 : in real;
            ctrl_l                  : out real;
            ctrl_h                  : out real;
            tec_maxv                : out real;
            setpoint                : out real
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
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                command_buffer <= (others => ' ');
                char_index <= 0;
                
            elsif data_ready = '1' then                                                         -- If data is ready convert byte to character and put it into the buffer
                command_buffer(char_index) <= character'val(to_integer(unsigned(rx_data)));
                char_index <= char_index + 1;
                
                if command_buffer(char_index - 1) = character'val(10) then                      -- When \n is given, analyze the command
                    case command_buffer(0 to 2) is
                        when "OFF" =>
                            command             <= "00";
                        when "PWM" =>                                                           -- This command expects an integer value for duty cycle
                            duty_cycle          <= integer'value(command_buffer(6 to char_index - 1));
                            command             <= "01";
                        when "DBL" =>                                                           -- Selects double threshold mode for SOA
                            command             <= "10";
                        when "SET" =>
                            case command_buffer(4 to 7) is 
                                when "CTLL" =>
                                    write_flag  <= '1';
                                    reg_address <= "00";
                                    reg_in      <= real'value(command_buffer(9 to char_index - 1));
                                when "CTLH" =>
                                    write_flag  <= '1';
                                    reg_address <= "01";
                                    reg_in      <= real'value(command_buffer(9 to char_index - 1));
                                when "MAXV" =>
                                    write_flag  <= '1';
                                    reg_address <= "10";
                                    reg_in      <= real'value(command_buffer(9 to char_index - 1));
                                when "TSET" =>
                                    write_flag  <= '1';
                                    reg_address <= "11";
                                    reg_in      <= real'value(command_buffer(9 to char_index - 1));
                                when others =>
                            write_flag      <= '0';
                            end case;
                    end case;
                    char_index <= 0;                                                            -- Clear buffer
                end if;
            end if;
        end if;
    end process;
end Behavioral;
