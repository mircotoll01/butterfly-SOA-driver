library IEEE;
library xil_defaultlib;
use IEEE.STD_LOGIC_1164.ALL;
use xil_defaultlib.utils_pkg.all;

entity UART_payload_gen is
    Port ( 
        command_parsed_in   : in std_logic_vector(23 downto 0);
        attribute_ASCII_in  : in std_logic_vector(31 downto 0);
        ctl_value_ASCII_in  : in std_logic_vector(31 downto 0);
        soa_current_dig_in  : in std_logic_vector(15 downto 0);
        adc_rdy             : in std_logic;
        ctrl_l              : in integer;
        ctrl_h              : in integer;
        tec_maxv            : in integer; 
        setpoint            : in integer; 
        duty_cycle          : in integer;
        mod_mode            : in std_logic_vector(1 downto 0); 
        
        payload_out         : out std_logic_vector(695 downto 0)   --display last command and measured current on the SOA  
    );
end UART_payload_gen;

architecture Behavioral of UART_payload_gen is
    signal ascii_ctrl_l    : std_logic_vector(31 downto 0);
    signal ascii_ctrl_h    : std_logic_vector(31 downto 0);
    signal ascii_tec_maxv  : std_logic_vector(31 downto 0);
    signal ascii_setpoint  : std_logic_vector(31 downto 0);
    signal ascii_duty      : std_logic_vector(31 downto 0);
    signal ascii_mode      : std_logic_vector(15 downto 0); -- two ASCII characters
    signal ascii_isoa      : std_logic_vector(39 downto 0);
begin

    process(all)
    begin
        -- Conversion of integers to ASCII
        ascii_ctrl_l   <= int_to_ascii(ctrl_l);
        ascii_ctrl_h   <= int_to_ascii(ctrl_h);
        ascii_tec_maxv <= int_to_ascii(tec_maxv);
        ascii_setpoint <= int_to_ascii(setpoint);
        ascii_duty     <= int_to_ascii(duty_cycle);
        
        -- conversion of adc ouput to ASCII
        ascii_isoa     <= adc_to_ascii(SOA_current_dig_in(12 downto 0)) when adc_rdy = '1' else ascii_isoa;

        -- Encoding modulation mode as two ASCII chars
        case mod_mode is
            when "00" => ascii_mode <= x"3030"; -- "00"
            when "01" => ascii_mode <= x"3031"; -- "01"
            when "10" => ascii_mode <= x"3130"; -- "10"
            when "11" => ascii_mode <= x"3131"; -- "11"
            when others => ascii_mode <= x"2D2D"; -- "--"
        end case;

        -- Assemble the final payload
        payload_out <=
            -- "LC: " + command (3 bytes) + space + attribute (4 bytes) + "\n"
            x"4C43" & x"3A20" & command_parsed_in & x"20" & attribute_ASCII_in & x"0A" &

            -- "ICTL: " + measured current (5 bytes) + "\n"
            x"4943544C" & x"3A20" & ascii_isoa & x"0A" &

            -- "CTLL: " + ctrl_l (5 bytes) + "\n"
            x"43544C4C" & x"3A20" & ascii_ctrl_l & x"0A" &

            -- "CTLH: " + ctrl_h (5 bytes) + "\n"
            x"43544C48" & x"3A20" & ascii_ctrl_h & x"0A" &

            -- "MODE: " + mode (2 bytes) + "\n"
            x"4D4F4445" & x"3A20" & ascii_mode & x"0A" &

            -- "TECV: " + tec_maxv (5 bytes) + "\n"
            x"54454356" & x"3A20" & ascii_tec_maxv & x"0A" &

            -- "DC: " + duty cycle (5 bytes) + "\n"
            x"44433A20" & ascii_duty & x"0A" &

            -- "SETP: " + setpoint (5 bytes) + "\n"
            x"53455450" & x"3A20" & ascii_setpoint & x"0A";
    end process;
end Behavioral;
