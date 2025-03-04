----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/04/2025 09:34:16 AM
-- Design Name: 
-- Module Name: clk_divider - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clk_divider is
    Port ( 
        clk         : in std_logic;
        clk_div     : out std_logic
    );
end clk_divider;

architecture Behavioral of clk_divider is
    signal tmp      : std_logic := '0';
begin
    process(clk)
    variable counter    : integer range 0 to 4 := 0;
    begin
        if rising_edge(clk) then
            if counter = 4 then
                tmp     <= not tmp;
                counter := 0;
            else 
                counter := counter + 1;
            end if;
        end if;
    end process;
    
    clk_div     <= tmp;

end Behavioral;
