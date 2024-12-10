----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/04/2024 11:08:29 AM
-- Design Name: 
-- Module Name: modulator - Behavioral
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

entity modulator is
    Port ( 
        clk             : in std_logic;
        duty_cycle      : in integer;
        mod_sel         : in std_logic_vector(1 downto 0);      -- 00 = driver disabled, 01 = pwm mode, 10 = double threshold mode
        soa_en          : out std_logic;
        ctrl_sel        : buffer std_logic;
        pwm             : buffer std_logic
    );
end modulator;

architecture Behavioral of modulator is
signal clk_divider: integer := 0; 
signal dc_counter:  integer := 0;
begin
    pwm         <= '0';
    ctrl_sel    <= '0';
    process(clk)
    begin
        if not mod_sel = "00" then
            soa_en <= '1';
            if clk_divider < 499 and rising_edge(clk) then      -- Assuming the clock is 100 MHz
                clk_divider <= clk_divider + 1;
            else
                if mod_sel = "01" and dc_counter < duty_cycle then
                    dc_counter <= dc_counter +1;
                    pwm <= not pwm;
                elsif mod_sel = "10" and dc_counter < duty_cycle then
                    dc_counter <= dc_counter + 1;
                    ctrl_sel <= not ctrl_sel;
                else dc_counter <= 0;
                end if; 
            end if; 
        else soa_en <= '0';          
        end if;
    end process;
end Behavioral;
