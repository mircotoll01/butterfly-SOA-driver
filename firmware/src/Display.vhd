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
        reset   : in std_logic;
        mode    : in std_logic_vector(1 downto 0);
        status  : in std_logic_vector(1 downto 0);
        seg     : out std_logic_vector(5 downto 0);
        an      : out std_logic_vector(3 downto 0)
    );
end Display;

architecture Behavioral of Display is
    signal activeDigit        : integer range 0 to 3 := 0;     -- Display attivo
    signal status_buffer      : std_logic_vector(1 downto 0);
    signal mode_buffer        : std_logic_vector(1 downto 0);
begin
    -- Multiplexing per i 7-segmenti
    process(clk, reset)
        variable clk_counter        : integer := 0; 
    begin
        if reset = '1' then
            clk_counter := 0;
        end if;

        if rising_edge(clk) then
            clk_counter := clk_counter + 1;
            if clk_counter = 100000 then  -- Cambia display attivo ogni tot cicli
                clk_counter := 0;
                activeDigit <= activeDigit + 1; 
                status_buffer <= status;
                mode_buffer   <= mode;
            end if;
        end if;
    end process; 
    
        -- Mappare le cifre sui display
    process(activeDigit)
    begin
        case activeDigit is
            when 0 =>
                an <= "1110";           -- Attiva primo display
                if mode_buffer(0) = '0' then
                    seg <= "000000";
                else
                    seg <= "111001";
                end if;
            when 1 =>
                an <= "1101";           -- Attiva secondo display
                if mode_buffer(1) = '0' then
                    seg <= "000000";
                else
                    seg <= "111001";
                end if;
            when 2 =>
                an <= "1011";           -- Attiva secondo display
                if status_buffer(0) = '0' then
                    seg <= "000000";
                else
                    seg <= "111001";
                end if;
            when 3 =>
                an <= "0111";           -- Attiva secondo display
                if status_buffer(1) = '0' then
                    seg <= "000000";
                else
                    seg <= "111001";
                end if;
            when others =>
                seg <= "000110";       -- Tutti i segmenti spenti
                an <= "0000";
        end case;
    end process;  
    
end Behavioral;
