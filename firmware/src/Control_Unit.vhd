----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/27/2024 10:03:21 AM
-- Design Name: 
-- Module Name: Control_Unit - Behavioral
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

entity Control_Unit is
    Port (
        --Inputs
        reset               : in std_logic;
        clk                 : in std_logic;
        overtemp_alarm      : in std_logic;
        undertemp_alarm     : in std_logic;
        CTRL_L              : in std_logic;
        CTRL_H              : in std_logic;
        PWM_DC              : in std_logic;
        Modulation_type     : in std_logic;
        
        --Outputs
        CTRL_SEL_PWM        : out std_logic;
        SOA_PWM             : out std_logic;
        SOA_EN              : out std_logic;
        TEC_EN              : out std_logic
    );
end Control_Unit;

architecture Structural of Control_Unit is
    signal start_tx: std_logic;
    signal I2C_package: std_logic_vector(31 downto 0);
    signal I2C_ack: std_logic;
    signal ISOA_raw: std_logic_vector(15 downto 0);
    signal eoc: std_logic;
    signal eos: std_logic;
    
    component I2C_Master
        Port (
            clk      : in  std_logic;
            reset    : in  std_logic;
            sda      : inout std_logic;
            scl      : out std_logic;
            start_tx : in  std_logic;
            data_in  : in  std_logic_vector(7 downto 0);
            ack_out  : out std_logic
        );
    end component;
    
    component Reader
        Port (
            clk         : in std_logic;                      
            reset       : in std_logic;                      
            JXADC       : in std_logic_vector(1 downto 0);   -- Pin analogici VP e VN
            digital_out : out std_logic_vector(15 downto 0); -- Valore raw
            eoc         : out std_logic;                        
            eos         : out std_logic
        );
    end component;
begin
    adc_inst : Reader
        Port map (
            clk     => clk,
            reset   => reset,
            digital_out => ISOA_raw,
            eoc     => eoc,
            eos     => eos
        );
    -- Istanza del componente I2C_Master
    i2c_inst : I2C_Master
        Port map (
            clk      => clk,
            reset    => reset,
            start_tx => start_tx,
            data_in  => I2C_package,
            ack_out  => I2C_ack
        );
     process(clk, reset, overtemp_alarm, undertemp_alarm)
     begin
        if reset <= '1' then
            
        end if;
     
     
     end process;
end Structural;
