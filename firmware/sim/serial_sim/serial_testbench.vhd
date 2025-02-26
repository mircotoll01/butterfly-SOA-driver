----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/04/2025 09:20:44 AM
-- Design Name: 
-- Module Name: serial_testbench - Behavioral
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

entity serial_testbench is
end serial_testbench;

architecture Behavioral of serial_testbench is
    constant BAUD_RATE      : integer := 9600;                                  -- Baud rate 
    constant CLOCK_FREQ     : integer := 10000000;                               -- System clock frequency (10 MHz)
    constant BAUD_DIVISOR   : integer := CLOCK_FREQ / BAUD_RATE;                -- This is the number of clock per bit
    constant input          : std_logic_vector(0 to 78) := "110" & "00001010" & -- P 
                                                           "110" & "11101010" & -- W
                                                           "110" & "10110010" & -- M
                                                           "110" & "00000100" & -- space
                                                           "110" & "10101100" & -- 5
                                                           "110" & "00001100" & -- 0
                                                           "110" & "01010000" & "11"; -- \n all characters are sent LSB first 
    
    signal baud_counter : integer range 0 to BAUD_DIVISOR - 1 := 0;
    signal counter : integer range 0 to 78 := 0;
    signal finished:std_logic := '0';
    signal clk:     std_logic := '0';
    signal reset:   std_logic := '0';
    signal rx:      std_logic := '1';
    signal dc:      integer;
    signal ctl:     integer;
    signal cth:     integer;
    signal tecv:    integer;
    signal stp:     integer;
    signal mode:    std_logic_vector(1 downto 0) := "00";

    component UART_decoder
        Port (
            clk          : in std_logic;
            reset        : in std_logic;
            rx           : in std_logic;
            duty_cycle   : out integer;  
            ctrl_l       : out integer;
            ctrl_h       : out integer;
            tec_maxv     : out integer;
            setpoint     : out integer;                                  
            mod_mode     : out std_logic_vector(1 downto 0)
        );
    end component;
begin
    decoder : UART_decoder
    Port map(
        clk         => clk,
        reset       => reset,
        rx          => rx,
        duty_cycle  => dc,
        ctrl_l      => ctl,
        ctrl_h      => cth,
        tec_maxv    => tecv,
        setpoint    => stp,
        mod_mode    => mode
    );
    
    process
    begin
        clk <= '0';
        wait for 500 ns;
        clk <= '1';
        wait for 500 ns;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if baud_counter = (BAUD_DIVISOR - 1) then 
                rx      <= input(counter);
                counter <= counter + 1;
                baud_counter <= 0;
            elsif counter = 78 then
                finished <= '1';
            elsif baud_counter < (BAUD_DIVISOR - 1) then
                baud_counter <= baud_counter + 1;
            end if;
        end if;
    end process;
    
end Behavioral;
