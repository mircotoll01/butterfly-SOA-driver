----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2024 05:10:32 PM
-- Design Name: 
-- Module Name: Selector - Behavioral
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

entity Selector is
    Port ( 
        clk  : in std_logic; 
        BtnL : in std_logic;
        BtnR : in std_logic;
        BtnD : in std_logic;
        BtnU : in std_logic;
        BtnC : in std_logic
    );
end Selector;

architecture Behavioral of Selector is
    signal voltage      : real := 0.00;
    signal current      : real := 0.00;
    signal selection    : string := "voltage";
    signal i            : real := 0.00;
    
    component Display
        Port (
            input   : in real := 0.00;
            seg     : out bit_vector(7 downto 0)
        );
    end component;
    
begin
    display_instance : Display
        Port map(
            input   => i
        );
        
    process(clk, BtnL, BtnR, BtnD, BtnU, BtnC)
    begin
        if falling_edge(BtnU) then
            if selection = "voltage" then 
                voltage <= voltage + 0.01;
            elsif selection = "current" then
                current <= current + 0.01;
            end if;
            
        elsif falling_edge(BtnD) then
            if selection = "voltage" and voltage > 0.0 then 
                voltage <= voltage - 0.01;
            elsif selection = "current" and current > 0.0 then
                current <= current - 0.01;
            end if;
            
        elsif falling_edge(BtnL) then
            if selection = "voltage" then 
                selection <= "current";
            elsif selection = "current" then
                selection <= "voltage";
            end if;
            
        elsif falling_edge(BtnR) then
            if selection = "voltage" then 
                selection <= "current";
            elsif selection = "current" then
                selection <= "voltage";
            end if;
            
        elsif falling_edge(BtnC) then
            if selection = "voltage" then 
                i <= voltage;
            elsif selection = "current" then
                i <= current;
            end if;
        end if;
    end process;
end Behavioral;
