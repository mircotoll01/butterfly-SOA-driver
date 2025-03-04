----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/12/2024 02:53:00 PM
-- Design Name: 
-- Module Name: UART_parser - Behavioral
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

entity UART_parser is
    Port ( 
        clk             : in std_logic;
        reset           : in std_logic;
        data_ready_in   : in std_logic;
        uart_byte_in    : in std_logic_vector(7 downto 0);
        address_select  : out std_logic_vector(2 downto 0);
        register_enable : out std_logic;
        data_out        : out integer;                           
        mod_select_out  : out std_logic_vector(1 downto 0)   
    );
end UART_parser;

architecture Behavioral of UART_parser is  
    type ASCII_string is array (0 to 13) of std_logic_vector(7 downto 0);
    signal command_reg          : ASCII_string := (others => (others => '0'));
    signal command_buffer       : ASCII_string := (others => (others => '0'));
    signal command_parsed       : std_logic_vector(23 downto 0) := (others => '0');
    signal attribute_ASCII      : std_logic_vector(31 downto 0) := (others => '0');
    signal pwm_value_ASCII      : std_logic_vector(15 downto 0) := (others => '0');
    signal ctl_value_ASCII      : std_logic_vector(31 downto 0) := (others => '0');
        
    signal char_index           : integer range 0 to 13 := 0;
    signal data_out_buffer      : integer := 0;
    signal address_sel_buffer   : std_logic_vector(2 downto 0):= (others => '1');
    signal mod_select_buffer    : std_logic_vector(1 downto 0):= (others => '0');
    signal register_en_buffer   : std_logic := '0';
    signal data_ready_prev      : std_logic := '0';
    
    function twobytes_ASCII_to_integer (vect: std_logic_vector(15 downto 0)) return integer is 
        type parsedint is array (0 to 1) of integer;
        variable digits: parsedint;
        variable result: integer := 0;
    begin
        for i in 0 to 1 loop 
            case vect(15-i*8 downto 8-i*8) is 
                when "00110000" => digits(i) := 0;
                when "00110001" => digits(i) := 1;
                when "00110010" => digits(i) := 2;
                when "00110011" => digits(i) := 3;
                when "00110100" => digits(i) := 4;
                when "00110101" => digits(i) := 5;
                when "00110110" => digits(i) := 6;
                when "00110111" => digits(i) := 7;
                when "00111000" => digits(i) := 8;
                when "00111001" => digits(i) := 9;
                when others     => digits(i) := 0;
            end case;
        end loop;
        result := digits(0)*10 + digits(1);
        return result;
    end twobytes_ASCII_to_integer; 
    
    function fourBytes_ASCII_to_integer (vect: std_logic_vector(31 downto 0)) return integer is
        type parsedint is array (0 to 3) of integer;
        variable digits: parsedint;
        variable result: integer := 0;
    begin
        for i in 0 to 3 loop 
            case vect(31-i*8 downto 24-i*8) is 
                when "00110000" => digits(i) := 0;
                when "00110001" => digits(i) := 1;
                when "00110010" => digits(i) := 2;
                when "00110011" => digits(i) := 3;
                when "00110100" => digits(i) := 4;
                when "00110101" => digits(i) := 5;
                when "00110110" => digits(i) := 6;
                when "00110111" => digits(i) := 7;
                when "00111000" => digits(i) := 8;
                when "00111001" => digits(i) := 9;
                when others     => digits(i) := 0;
            end case;
        end loop;
        result := digits(0)*1000 + digits(1)*100 + digits(2)*10 + digits(3);
        return result;
    end fourBytes_ASCII_to_integer;
    
begin
    process(clk)
    begin
        if reset = '1' then 
            register_en_buffer  <= '0';
            address_sel_buffer  <= "111";
            mod_select_buffer   <= "00";
            data_out_buffer     <= 0;
            command_buffer      <= (others => (others => '0'));
        end if;
            
        if rising_edge(clk) then
            data_ready_prev <= data_ready_in;
            
            if (data_ready_in = '1' and data_ready_prev = '0') then                     -- If data is ready convert byte to character and put it into the buffer
                command_buffer(char_index)      <= uart_byte_in;
                char_index                      <= char_index + 1;
                if uart_byte_in = "00001010" then                                       -- When \n is given (line feed is number 10 in ascii code), analyze the command 
                    command_reg                 <= command_buffer;
                    command_buffer              <= (others => (others => '0'));
                    char_index                  <= 0;
                end if;
            end if;
            
            case command_parsed is
                when "01001111" & "01000110" & "01000110" =>                                      -- ASCII code for OFF (Every code is LSB first)
                    mod_select_buffer          <= "00";
                when "01010000" & "01010111" & "01001101" =>                                      -- ASCII coded for PWM This command expects an integer value for duty cycle from 0 to 99
                    register_en_buffer         <= '1';
                    address_sel_buffer         <= "100";
                    data_out_buffer            <= twobytes_ASCII_to_integer(pwm_value_ASCII);
                    mod_select_buffer          <= "01";
                when "01000100" & "01000010" & "01001100" =>                                      -- ASCII coded for DBL This command expects two integer values for dac from 0 to 2048
                    mod_select_buffer          <= "10";
                when "01010011" & "01000101" & "01010100" =>                                      -- ASCII coded for SET
                    case attribute_ASCII is 
                        when "01000011" & "01010100" & "01001100" & "01001100" =>                 -- CTLL changes CTRL_L
                            register_en_buffer      <= '1';
                            address_sel_buffer      <= "000";                           
                            data_out_buffer         <= fourBytes_ASCII_to_integer(ctl_value_ASCII);
                        when "01000011" & "01010100" & "01001100" & "01001000" =>                      -- CTLH changes CTRL_H
                            register_en_buffer      <= '1';
                        address_sel_buffer          <= "001";
                            data_out_buffer         <= fourBytes_ASCII_to_integer(ctl_value_ASCII);
                        when "01001101" & "01000001" & "01011000" & "01010110" =>                      -- MAXV changes maximum tec voltage
                            register_en_buffer      <= '1';
                            address_sel_buffer      <= "010";
                            data_out_buffer         <= fourBytes_ASCII_to_integer(ctl_value_ASCII);
                        when "01010100" & "01000100" & "01000101" & "01010100" =>                      -- TSET changes temperature setpoint for TEC controller
                            register_en_buffer      <= '1';
                            address_sel_buffer      <= "011";
                            data_out_buffer         <= fourBytes_ASCII_to_integer(ctl_value_ASCII);
                        when others =>
                            register_en_buffer      <= '0';
                            address_sel_buffer      <= "111";
                            mod_select_buffer       <= "00";
                            data_out_buffer         <= 0;
                    end case;
                when others =>
                    register_en_buffer  <= '0';
                    address_sel_buffer  <= "111";
                    mod_select_buffer   <= "00";
                    data_out_buffer     <= 0;
            end case;
        end if;
    end process;
    
    command_parsed          <= command_reg(0) & 
                               command_reg(1) &
                               command_reg(2);
                       
    pwm_value_ASCII         <= command_reg(4) &
                               command_reg(5);   
                               
    attribute_ASCII         <= command_reg(4) &
                               command_reg(5) &
                               command_reg(6) &
                               command_reg(7);  
                               
    ctl_value_ASCII         <= command_reg(9) &
                               command_reg(10) &
                               command_reg(11) &
                               command_reg(12);  
                               
    address_select          <= address_sel_buffer;
    register_enable         <= register_en_buffer;
    data_out                <= data_out_buffer;
    mod_select_out          <= mod_select_buffer;
      
end Behavioral;
