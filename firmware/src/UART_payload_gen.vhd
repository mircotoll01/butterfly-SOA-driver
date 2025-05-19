library IEEE;
library xil_defaultlib;
use IEEE.STD_LOGIC_1164.ALL;
use xil_defaultlib.utils_pkg.all;

entity UART_payload_gen is
    Port ( 
        command_parsed_in   : in std_logic_vector(23 downto 0);
        attribute_ASCII_in  : in std_logic_vector(31 downto 0);
        ctl_value_ASCII_in  : in std_logic_vector(31 downto 0);
        SOA_current_dig_in  : in std_logic_vector(15 downto 0);
        
        payload_out         : out std_logic_vector(335 downto 0)   --display last command and measured current on the SOA  
    );
end UART_payload_gen;

architecture Behavioral of UART_payload_gen is
begin
    process(command_parsed_in, attribute_ASCII_in, ctl_value_ASCII_in, SOA_current_dig_in)
    begin
        payload_out(111 downto 0)   <= "01001100" & "01000001" & "01010011" & "01010100" & "00100000" & "01000011" &
                                       "01001111" & "01001101" & "01001101" & "01000001" & "01001110" & "01000100" & 
                                       "00111010" & "00100000";  -- ASCII code for "LAST COMMAND: "
        payload_out(135 downto 112) <= command_parsed_in;
        payload_out(143 downto 136) <= "00100000";              -- ASCII code for space is 32
        payload_out(175 downto 144) <= attribute_ASCII_in;
        payload_out(287 downto 176) <= "00001010" & "01010011" & "01001111" & "01000001" & "00100000" & "01000011" & 
                                       "01010101" & "01010010" & "01010010" & "01000101" & "01001110" & "01010100" & 
                                       "00111010" & "00100000"; -- "\nSOA CURRENT: "
        payload_out(327 downto 288) <= ADC_to_ASCII(SOA_current_dig_in);
        payload_out(335 downto 328) <= "00001010"; -- 44 bytes total
    end process;
end Behavioral;
