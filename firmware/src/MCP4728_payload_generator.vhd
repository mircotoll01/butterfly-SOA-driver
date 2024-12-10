----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/04/2024 09:40:08 AM
-- Design Name: 
-- Module Name: MCP4728_payload_generator - Behavioral
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

entity MCP4728_payload_generator is
    Port ( 
        CTRL_H      : in real;
        CTRL_L      : in real;
        TEC_MAXV    : in real;
        TEC_SET_T   : in real;
        I2C_payload : out std_logic_vector(81 downto 0)
    );
end MCP4728_payload_generator;

architecture Behavioral of MCP4728_payload_generator is
constant write_mode:            std_logic_vector (7 downto 0) := "11000000";
constant LSB:                   real := 0.0005;                                 -- DAC's least significant bit if internal voltage reference is used (2.048)  
signal first_byte_register:     std_logic_vector (7 downto 0);
signal second_byte_register:    std_logic_vector (7 downto 0);
begin
    process(CTRL_H, CTRL_L, TEC_MAXV, TEC_SET_T)
    variable mul_factor_A: unsigned;                                            -- V_out = LSB * a factor which has to be converted to binary and sent to the DAC
    variable mul_factor_B: unsigned;
    variable mul_factor_C: unsigned;
    variable mul_factor_D: unsigned;
    begin
        mul_factor_A := to_unsigned(integer(CTRL_H / LSB), 12);
        mul_factor_B := to_unsigned(integer(CTRL_L / LSB), 12);
        mul_factor_C := to_unsigned(integer(TEC_MAXV / LSB), 12);
        mul_factor_D := to_unsigned(integer(TEC_SET_T / LSB), 12);
        I2C_payload <= std_logic_vector (mul_factor_A) & 
                       std_logic_vector (mul_factor_B) &   
                       std_logic_vector (mul_factor_C) &
                       std_logic_vector (mul_factor_D);
    end process;
end Behavioral;
