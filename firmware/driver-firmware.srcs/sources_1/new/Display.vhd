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
        input   : in real;
        seg     : out std_logic_vector(7 downto 0);
        an      : out std_logic_vector(3 downto 0)
    );
end Display;

architecture Behavioral of Display is
    signal intPart      : integer; -- parte intera del numero in ingresso
    signal floatPart    : integer; -- parte decimale del numero in ingresso
    signal digit1, digit2, digit3, digit4 : integer := 0; -- Cifre da visualizzare
    signal activeDigit  : integer range 0 to 3 := 0;     -- Display attivo
    signal clk_div       : integer := 0; 
    
    type segment_map is array (0 to 9) of std_logic_vector(6 downto 0);
    constant seg_map : segment_map := (
        "1000000", -- 0
        "1111001", -- 1
        "0100100", -- 2
        "0110000", -- 3
        "0011001", -- 4
        "0010010", -- 5
        "0000010", -- 6
        "1111000", -- 7
        "0000000", -- 8
        "0010000"  -- 9
    );
    
   
begin
    process(clk, input)
        variable temp_number : real := 0.0;
    begin
        intPart     <= integer(input);                      -- Ricava la parte intera
        floatPart   <= integer(input * 100.0) - intPart;      -- Ricava la parte decimale
        
        digit1 <= intPart / 10;         -- Prima cifra (decine)
        digit2 <= intPart mod 10;       -- Seconda cifra (unità)

        digit3 <= floatPart / 10;        -- Terza cifra (decimi)
        digit4 <= floatPart mod 10;      -- Quarta cifra (centesimi)
    end process;

    -- Multiplexing per i 7-segmenti
    process(clk)
    begin
        if rising_edge(clk) then
            clk_div <= clk_div + 1;
            if clk_div = 100000 then  -- Cambia display attivo ogni tot cicli
                clk_div <= 0;
                activeDigit <= (activeDigit + 1) mod 4;
            end if;
        end if;
    end process; 
    
        -- Mappare le cifre sui display
    process(activeDigit, digit1, digit2, digit3, digit4)
    begin
        case activeDigit is
            when 0 =>
                seg <= seg_map(digit1); -- Prima cifra
                an <= "1110";           -- Attiva primo display
            when 1 =>
                seg <= seg_map(digit2); -- Seconda cifra
                an <= "1101";           -- Attiva secondo display
            when 2 =>
                seg <= seg_map(digit3); -- Terza cifra
                an <= "1011";           -- Attiva terzo display
            when 3 =>
                seg <= seg_map(digit4); -- Quarta cifra
                an <= "0111";           -- Attiva quarto display
            when others =>
                seg <= "1111111";       -- Tutti i segmenti spenti
                an <= "1111";
        end case;
    end process;  
    
end Behavioral;
