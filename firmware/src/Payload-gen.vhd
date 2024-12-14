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
        ctrl_h      : in integer;
        ctrl_l      : in integer;
        tec_maxv    : in integer;
        setpoint    : in integer;
        I2C_payload : out std_logic_vector(47 downto 0)
    );
end MCP4728_payload_generator;

architecture Behavioral of MCP4728_payload_generator is
        constant LSB_INT : integer := 5; -- Scaled LSB (e.g., 0.0005 * 10000)
        signal mul_factor_A: unsigned(11 downto 0);
        signal mul_factor_B: unsigned(11 downto 0);
        signal mul_factor_C: unsigned(11 downto 0);
        signal mul_factor_D: unsigned(11 downto 0);
        
    begin
        process(ctrl_h, ctrl_l, tec_maxv, setpoint)
            variable a0, a1, a2, a3 : integer;
        begin
            -- Compute scaled values
            a0 := ctrl_l / LSB_INT; -- Integer division
            a1 := ctrl_h / LSB_INT;
            a2 := tec_maxv / LSB_INT;
            a3 := setpoint / LSB_INT;
    
            -- Convert to unsigned
            mul_factor_A <= to_unsigned(a0, 12);
            mul_factor_B <= to_unsigned(a1, 12);
            mul_factor_C <= to_unsigned(a2, 12);
            mul_factor_D <= to_unsigned(a3, 12);
    
            -- Concatenate the factors into the payload
            I2C_payload <= std_logic_vector(mul_factor_A) & 
                           std_logic_vector(mul_factor_B) & 
                           std_logic_vector(mul_factor_C) & 
                           std_logic_vector(mul_factor_D);
        end process;
end Behavioral;
