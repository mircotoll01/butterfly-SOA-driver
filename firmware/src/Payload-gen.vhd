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
        clk         : in std_logic;
        ctrl_h      : in integer;
        ctrl_l      : in integer;
        tec_maxv    : in integer;
        setpoint    : in integer;
        start_tx    : out std_logic;
        I2C_payload : out std_logic_vector(47 downto 0)
    );
end MCP4728_payload_generator;

architecture Behavioral of MCP4728_payload_generator is
        constant LSB_INT : integer := 5; -- Scaled LSB (e.g., 0.0005 * 10000)
        signal payload : std_logic_vector(47 downto 0);
    begin
        process(clk)
            variable a0, a1, a2, a3 : integer;
        begin
            if rising_edge(clk) then
                start_tx    <= '0';
                -- Compute scaled values
                a0 := ctrl_l / LSB_INT; -- Integer division
                a1 := ctrl_h / LSB_INT;
                a2 := tec_maxv / LSB_INT;
                a3 := setpoint / LSB_INT;
                
                -- Concatenate the factors into the payload
                payload     <= std_logic_vector(to_unsigned(a0, 12)) & 
                               std_logic_vector(to_unsigned(a1, 12)) & 
                               std_logic_vector(to_unsigned(a2, 12)) & 
                               std_logic_vector(to_unsigned(a3, 12));
                start_tx    <= '1';
           end if;
        end process;
        I2C_payload <= payload;
end Behavioral;
