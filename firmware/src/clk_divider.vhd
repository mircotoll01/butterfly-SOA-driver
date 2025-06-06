library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- clk divider from 100 to 10 MHz
entity clk_divider is
    Port ( 
        clk             : in std_logic;
        clk_div         : out std_logic
    );
end clk_divider;

architecture Behavioral of clk_divider is
    signal tmp          : std_logic := '0';
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
