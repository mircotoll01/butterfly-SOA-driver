----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/25/2025 12:56:33 PM
-- Design Name: 
-- Module Name: control_unit_testbench - Behavioral
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

entity control_unit_testbench is
--  Port ( );
end control_unit_testbench;

architecture Behavioral of control_unit_testbench is
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
    
    signal sda:     std_logic := '1';
    signal scl:     std_logic := '1';
    signal n_ldac:  std_logic := '0';
    signal ctrl_sel_pwm: std_logic := '0';
    signal soa_pwm: std_logic := '0';
    signal soa_en:  std_logic := '0';
    signal tec_en:  std_logic := '0';
    signal seg:     std_logic_vector(5 downto 0) := "000000";
    signal an:      std_logic_vector(3 downto 0) := "0000"; 
    
    signal o_TX_Active: std_logic;
    signal uart_tx: std_logic;
    signal o_TX_Done:   std_logic;
                                                           
    component Control_Unit is
        Port (
            --Inputs
            reset               : in std_logic;
            clk                 : in std_logic;
            uart_rx             : in std_logic;
            overtemp_alarm      : in std_logic;
            undertemp_alarm     : in std_logic;
    --        JXADC               : in std_logic_vector(1 downto 0);
                    
            --Outputs
            sda                 : inout std_logic;
            scl                 : out std_logic;
            n_ldac              : out std_logic;
            ctrl_sel_pwm        : out std_logic;
            soa_pwm             : out std_logic;
            soa_en              : out std_logic;
            tec_en              : out std_logic;
            seg                 : out std_logic_vector(5 downto 0);
            an                  : out std_logic_vector(3 downto 0);
            
            o_TX_Active  : out std_logic;
            o_TX_Serial  : out std_logic;
            o_TX_Done    : out std_logic
        );
    end component;
begin
    CU: Control_Unit
    port map(
        reset           => reset,
        clk             => clk,
        uart_rx         => rx,
        overtemp_alarm  => reset,
        undertemp_alarm => reset,
                
        sda             => sda,
        scl             => scl,
        n_ldac          => n_ldac,   
        ctrl_sel_pwm    => ctrl_sel_pwm,
        soa_pwm         => soa_pwm,
        soa_en          => soa_en,
        tec_en          => tec_en,
        seg             => seg,
        an              => an,
        
        o_TX_Active     => o_TX_Active,
        uart_tx         => uart_tx,
        o_TX_Done       => o_TX_Done
    );
    
    process
    begin
        clk <= '0';
        wait for 50 ns;
        clk <= '1';
        wait for 50 ns;
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
