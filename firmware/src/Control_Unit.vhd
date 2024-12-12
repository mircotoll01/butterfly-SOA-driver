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
        uart_rx             : in std_logic;
        overtemp_alarm      : in std_logic;
        undertemp_alarm     : in std_logic;
        JXADC               : in std_logic_vector(1 downto 0);
                
        --Outputs
        ctrl_sel_pwm        : buffer std_logic;
        soa_pwm             : buffer std_logic;
        tec_en              : out std_logic
    );
end Control_Unit;

architecture Structural of Control_Unit is

    -- signals to interconnect i2c master and paload generation
    signal payload          : std_logic_vector(47 downto 0);
    signal start_tx         : std_logic;
    
    -- signals for mudulation and controls
    signal mod_sel          : std_logic_vector(1 downto 0);
    signal soa_en           : std_logic;
    signal ctrl_l           : real;
    signal ctrl_h           : real;
    signal setpoint         : real;
    signal tec_maxv         : real;
    signal duty_cycle       : integer;
    
    -- signals for the ADC
    signal ISOA_raw         : std_logic_vector(15 downto 0);
    signal eoc              : std_logic;
    signal eos              : std_logic;
    
    -- components for I2C communication
    component MCP4728_payload_generator
        Port ( 
            ctrl_h          : in real;
            ctrl_l          : in real;
            tec_maxv        : in real;
            setpoint        : in real;
            I2C_payload     : out std_logic_vector(47 downto 0)
        );
    end component;
    
    component I2C_Master
        Port (
            clk             : in  std_logic;
            reset           : in  std_logic;
            start_tx        : in  std_logic;                       
            I2C_payload     : in  std_logic_vector(47 downto 0);  
            sda             : inout std_logic;
            scl             : out std_logic;
            n_ldac          : out std_logic
        );
    end component;
    
    -- components for current monitoring
    component Reader
        Port (
            clk             : in std_logic;                      
            reset           : in std_logic;                      
            JXADC           : in std_logic_vector(1 downto 0);   
            digital_out     : out std_logic_vector(15 downto 0); 
            eoc             : out std_logic;                        
            eos             : out std_logic
        );
    end component;
    
    -- components for SOA drive
    component modulator
        Port (
            clk             : in std_logic;
            duty_cycle      : in integer;
            mod_sel         : in std_logic_vector(1 downto 0); 
            soa_en          : out std_logic;
            ctrl_sel        : buffer std_logic;
            pwm             : buffer std_logic
        );
    end component;
    
    -- component for UART communication
    component UART_decoder
        Port (
            clk          : in std_logic;
            reset        : in std_logic;
            rx           : in std_logic;
            duty_cycle   : out integer;  
            ctrl_l       : out real;
            ctrl_h       : out real;
            tec_maxv     : out real;
            setpoint     : out real;                                  
            command      : out std_logic_vector(1 downto 0)
        );
    end component;

begin
    -- i2c blocks
    i2c_gen: MCP4728_payload_generator
        Port map (
            ctrl_l          => ctrl_l,
            ctrl_h          => ctrl_h,
            tec_maxv        => tec_maxv,
            setpoint        => setpoint,
            I2C_payload     => payload  
        );
        
    i2cmaster : I2C_Master
        Port map (
            clk             => clk,
            reset           => reset,
            start_tx        => start_tx,
            I2C_payload     => payload
        );
    
    -- modulation and control block
    modulator_block : modulator
        Port map (
            clk             => clk,
            duty_cycle      => duty_cycle, 
            mod_sel         => mod_sel,
            soa_en          => soa_en,
            ctrl_sel        => ctrl_sel_pwm,
            pwm             => soa_pwm
        );
        
    -- other blocks
    adc_reader : Reader
        Port map (
            clk             => clk,
            reset           => reset,
            JXADC           => JXADC,
            digital_out     => ISOA_raw,
            eoc             => eoc,
            eos             => eos
        );
    
    -- uart communication block
    decoder : UART_decoder
        Port map(
            clk             => clk,
            reset           => reset,
            rx              => uart_rx,
            duty_cycle      => duty_cycle,  
            ctrl_l          => ctrl_l,
            ctrl_h          => ctrl_h,
            tec_maxv        => tec_maxv,
            setpoint        => setpoint,                                  
            command         => mod_sel
        );
    -- over/under-temperature response for butterfly SOA
     process(overtemp_alarm, undertemp_alarm)
     begin
        if overtemp_alarm = '1' then
            soa_en <= '0';
        elsif undertemp_alarm = '1' then
            tec_en <= '0';
        end if;
     end process;
     
end Structural;
