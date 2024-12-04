----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/27/2024 09:40:25 AM
-- Design Name: 
-- Module Name: Reader - Behavioral
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

entity Reader is
    Port (
        clk         : in std_logic;                      
        reset       : in std_logic;                      
        JXADC       : in std_logic_vector(1 downto 0);   -- Pin analogici VP e VN
        digital_out : out std_logic_vector(15 downto 0); -- Valore raw
        eoc         : out std_logic;                        
        eos         : out std_logic
    );
end Reader;

architecture Behavioral of Reader is
    signal xadc_data : std_logic_vector(15 downto 0); -- Dati grezzi dall'XADC
begin
    xadc_inst: entity work.xadc_wiz_0
        port map (
            -- Ingressi
            vp_in => JXADC(0),           -- Analogico VP
            vn_in => JXADC(1),           -- Analogico VN
            
            dclk_in  => clk,             -- Clock
            reset_in => reset,           -- Reset
            
            daddr_in => "0000000",       -- Seleziona canale
            di_in    => (others => '0'), -- Input dati non usato
            dwe_in   => '0',
            den_in   => '1',
            
            -- Uscite
            do_out   => xadc_data,       -- Valore raw
            drdy_out => open,            -- Segnale ready
            busy_out => open,            -- ADC busy
            eoc_out  => eoc,
            eos_out  => eos,
            alarm_out=> open,
            channel_out=> open
        );
        
    process(clk, reset)
    begin
        if reset = '1' then
            digital_out <= (others => '0');
        elsif rising_edge(clk) then
            -- Primi 12 bit del valore convertito
            digital_out <= xadc_data(15 downto 4);
        end if;
    end process;
end Behavioral;
