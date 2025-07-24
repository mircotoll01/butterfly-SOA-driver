library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library xil_defaultlib;
use xil_defaultlib.utils_pkg.all;

entity UART_parser is
    Port ( 
        clk                 : in std_logic;
        reset               : in std_logic;
        data_ready_in       : in std_logic;
        uart_byte_in        : in std_logic_vector(7 downto 0);
        address_select      : out std_logic_vector(2 downto 0);
        register_enable     : out std_logic;
        data_out            : out integer;                           
        tec_status_out      : out std_logic;
        soa_status_out      : out std_logic;
        mode_status_out     : out std_logic_vector(1 downto 0);
        command_parsed_out  : out std_logic_vector(23 downto 0);
        attribute_ASCII_out : out std_logic_vector(31 downto 0);
        ctl_value_ASCII_out : out std_logic_vector(31 downto 0)
    );
end UART_parser;

architecture Behavioral of UART_parser is
    signal char_index           : integer range 0 to 13 := 0;
    signal command_reg          : ASCII_string := (others => (others => '0'));
    signal command_buffer       : ASCII_string := (others => (others => '0'));
    signal command_parsed       : std_logic_vector(23 downto 0) := (others => '0');
    signal attribute_ASCII      : std_logic_vector(31 downto 0) := (others => '0');
    signal pwm_value_ASCII      : std_logic_vector(23 downto 0) := (others => '0');
    signal ctl_value_ASCII      : std_logic_vector(31 downto 0) := (others => '0');
    signal data_ready_prev      : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            data_ready_prev     <= data_ready_in;
            if (data_ready_in = '1' and data_ready_prev = '0') then
                command_buffer(char_index)      <= uart_byte_in;
                char_index                      <= char_index + 1;
                if uart_byte_in = x"0A" then                                       -- When \n is given (line feed is number 10 in ascii code), analyze the command
                    char_index                      <= 0;
                    command_parsed                  <= command_buffer(0) & 
                                                        command_buffer(1) &
                                                        command_buffer(2); 
                                               
                    attribute_ASCII                 <= command_buffer(4) &
                                                        command_buffer(5) &
                                                        command_buffer(6) &
                                                        command_buffer(7);  
                                               
                    ctl_value_ASCII                 <= command_buffer(9) &
                                                        command_buffer(10) &
                                                        command_buffer(11) &
                                                        command_buffer(12);
                                                        
                    command_buffer                  <= (others => (others => '0'));
                end if;
            end if;
        end if;
    end process;
    
    process(command_parsed)
    begin        
        mode_status_out          <= "00";
        register_enable         <= '1';
        case command_parsed is
            when x"4F4646" | x"6F6666" => -- ASCII code for OFF
                register_enable         <= '0';
                address_select          <= "111";
                data_out                <= 0;
            when x"50574D" | x"70776D" => -- ASCII coded for PWM This command expects an integer value for duty cycle from 0 to 99
                address_select          <= "100";
                mode_status_out         <= "01";
                if ascii_to_integer(attribute_ASCII(31 downto 8)) > 100 then
                    data_out            <= 100;
                else
                    data_out            <= ascii_to_integer(attribute_ASCII(31 downto 8));
                end if;
            when x"44424C" | x"64626C" => -- ASCII coded for DBL This command expects two integer values for dac from 0 to 2048
                mode_status_out         <= "10";
                address_select          <= "100";
                if ascii_to_integer(attribute_ASCII(31 downto 8)) > 100 then
                    data_out            <= 100;
                else
                    data_out            <= ascii_to_integer(attribute_ASCII(31 downto 8));
                end if;
            when x"544543" | x"746563" => -- ASCII code for TEC
                if attribute_ASCII(31 downto 16) = x"4F4E" or attribute_ASCII(31 downto 16) = x"6F6E" then -- ON
                    address_select      <= "101";
                    tec_status_out      <= '1';
                elsif attribute_ASCII(31 downto 8) = x"4F4646"  or attribute_ASCII(31 downto 8) = x"6F6666" then -- OFF
                    address_select      <= "101";
                    tec_status_out      <= '0';
                end if;
                
            when x"534F41" | x"736F61" => -- ASCII code for SOA
                if attribute_ASCII(31 downto 16) = x"4F4E" or attribute_ASCII(31 downto 16) = x"6F6E" then -- ON
                    address_select      <= "110";
                    soa_status_out      <= '1';
                elsif attribute_ASCII(31 downto 8) = x"4F4646"  or attribute_ASCII(31 downto 8) = x"6F6666" then -- OFF
                    address_select      <= "110";
                    soa_status_out      <= '0';
                end if;
                
            when x"534554" | x"736574" => -- ASCII coded for SET
                case attribute_ASCII is 
                    when x"43544C4C" | x"63746C6C" => -- CTLL changes CTRL_L
                        address_select          <= "000";                           
                        if four_bytes_ascii_to_integer(ctl_value_ASCII) >= 1500 then -- CTRL range 0 to 1.5V
                            data_out            <= 1500;
                        else
                            data_out            <= four_bytes_ascii_to_integer(ctl_value_ASCII);
                        end if;
                    when x"43544C48" | x"63746C68" => -- CTLH changes CTRL_H
                        address_select          <= "001";
                        if four_bytes_ascii_to_integer(ctl_value_ASCII) > 1500 then
                            data_out            <= 1500;
                        else
                            data_out            <= four_bytes_ascii_to_integer(ctl_value_ASCII);
                        end if;
                    when x"4D415856" | x"6D617876" => -- MAXV changes maximum tec voltage
                        address_select          <= "010";
                        if four_bytes_ascii_to_integer(ctl_value_ASCII) > 5000 then   -- TEC voltage is 4*VMAXV, hence maximum voltage has to be 1,25V to achieve 0-5V range
                            data_out            <= 5000;                              -- for this reason the value will be divided by 4 later
                        else
                            data_out            <= four_bytes_ascii_to_integer(ctl_value_ASCII);
                        end if;
                    when x"54534554" | x"74736574" => -- TSET changes temperature setpoint for TEC controller
                        address_select          <= "011";
                        if four_bytes_ascii_to_integer(ctl_value_ASCII) > 1500 then -- NTC is in a 1.5V VCC voltage divider
                            data_out            <= 1500;
                        else
                            data_out            <= four_bytes_ascii_to_integer(ctl_value_ASCII);
                        end if;
                    when others =>
                        register_enable         <= '0';
                end case;
            when others =>
                register_enable         <= '0';
        end case;
    end process;
                   
    command_parsed_out      <= command_parsed;
    attribute_ASCII_out     <= attribute_ASCII;
    ctl_value_ASCII_out     <= ctl_value_ASCII;
end Behavioral;
