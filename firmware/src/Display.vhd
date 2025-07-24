library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Display is
    Port ( 
        clk     : in std_logic;
        mode    : in std_logic_vector(1 downto 0);
        status  : in std_logic_vector(1 downto 0);
        seg     : out std_logic_vector(5 downto 0);
        an      : out std_logic_vector(3 downto 0)
    );
end Display;

architecture Behavioral of Display is
    signal status_buffer      : std_logic_vector(1 downto 0) := "00";
    signal mode_buffer        : std_logic_vector(1 downto 0) := "00";
    signal activeDigit        : integer range 0 to 3;
    
begin
    process(clk)
    variable clk_counter        : integer range 0 to 999:= 0; 
    begin
        if rising_edge(clk) then
            clk_counter := clk_counter + 1;
            if clk_counter = 499 then  -- Cambia display attivo ogni tot cicli
                clk_counter         := 0;
                status_buffer       <= status;
                mode_buffer         <= mode;
                if activeDigit < 3 then
                    activeDigit     <= activeDigit + 1;
                else
                    activeDigit     <= 0;
                end if;
            end if;
        end if;
    end process;

    -- Multiplexing per i 7-segmenti
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
