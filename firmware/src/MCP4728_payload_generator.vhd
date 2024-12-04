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
        N_LDAC      : out std_logic;
        start_tx    : out std_logic;
        I2C_payload : out std_logic_vector(81 downto 0)
    );
end MCP4728_payload_generator;

architecture Behavioral of MCP4728_payload_generator is

begin
    process(CTRL_H, CTRL_L, TEC_MAXV, TEC_SET_T)
    begin
        
    end process;
end Behavioral;
