----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/04/2024 11:08:29 AM
-- Design Name: 
-- Module Name: modulation_type_selector - Behavioral
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

entity modulation_type_selector is
    Port ( 
        clk             : in std_logic;
        duty_cycle      : in integer;
        mod_select      : in std_logic_vector(1 downto 0);      -- 00 = driver disabled, 01 = PWM mode, 10 = double threshold mode
        driver_enable   : out std_logic;
        CTRL_SEL        : buffer std_logic;
        PWM             : buffer std_logic
    );
end modulation_type_selector;

architecture Behavioral of modulation_type_selector is
signal clk_divider: integer := 0; 
signal dc_counter:  integer := 0;
begin
    PWM         <= '0';
    CTRL_SEL    <= '0';
    process(clk)
    begin
        if not mod_select = "00" then
            driver_enable <= '1';
            if clk_divider < 499 and rising_edge(clk) then      -- Assuming the clock is 100 MHz
                clk_divider <= clk_divider + 1;
            else
                if mod_select = "01" and dc_counter < duty_cycle then
                    dc_counter <= dc_counter +1;
                    PWM <= not PWM;
                elsif mod_select = "10" and dc_counter < duty_cycle then
                    dc_counter <= dc_counter + 1;
                    CTRL_SEL <= not CTRL_SEL;
                else dc_counter <= 0;
                end if; 
            end if; 
        else driver_enable <= '0';          
        end if;
    end process;
end Behavioral;
