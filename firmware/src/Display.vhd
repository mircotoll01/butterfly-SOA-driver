----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2024 05:15:33 PM
-- Design Name: 
-- Module Name: Display - Equation
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

entity Display is
    Port ( 
        clk     : in std_logic;
        input   : in std_logic_vector(1 downto 0);
        seg     : out std_logic_vector(6 downto 0);
        an      : out std_logic_vector(3 downto 0)
    );
end Display;

architecture Behavioral of Display is
    signal activeDigit        : integer range 0 to 1 := 0;     -- Display attivo
    signal clk_div            : integer := 0; 
       
begin
    -- Multiplexing per i 7-segmenti
    process(clk)
    begin
        if rising_edge(clk) then
            clk_div <= clk_div + 1;
            if clk_div = 100000 then  -- Cambia display attivo ogni tot cicli
                clk_div <= 0;
                activeDigit <= (activeDigit + 1) mod 2;
            end if;
        end if;
    end process; 
    
        -- Mappare le cifre sui display
    process(activeDigit)
    begin
        case activeDigit is
            when 0 =>
                an <= "1110";           -- Attiva primo display
                if input(0) = '0' then
                    seg <= "1000000";
                else
                    seg <= "1111001";
                end if;
            when 1 =>
                an <= "1101";           -- Attiva secondo display
                if input(1) = '0' then
                    seg <= "1000000";
                else
                    seg <= "1111001";
                end if;
            when others =>
                seg <= "1111111";       -- Tutti i segmenti spenti
                an <= "1111";
        end case;
    end process;  
    
end Behavioral;
