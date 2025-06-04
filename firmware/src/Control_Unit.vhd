library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Control_Unit is
    Port (
        --Inputs
        reset               : in std_logic;
        clk                 : in std_logic;
        uart_rx             : in std_logic;
        overtemp_alarm      : in std_logic;
        undertemp_alarm     : in std_logic;
        
        --JXADC channel 15
        vauxp15             : in std_logic;
        vauxn15             : in std_logic;
                
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
        
        uart_tx             : out std_logic
    );
end Control_Unit;

architecture Structural of Control_Unit is

    -- signals to interconnect i2c master and paload generation
    signal payload          : std_logic_vector(47 downto 0);
    signal start_tx         : std_logic;
    signal clk_div          : std_logic;        
    
    -- signals for mudulation and controls
    signal mod_mode         : std_logic_vector(1 downto 0);
    signal status           : std_logic_vector(1 downto 0);
    signal ctrl_l           : integer;
    signal ctrl_h           : integer;
    signal setpoint         : integer;
    signal tec_maxv         : integer;
    signal duty_cycle       : integer;
    
    -- signals for the ADC
    signal SOA_current_dig  : std_logic_vector(15 downto 0);
    signal channel_out      : std_logic_vector(4 downto 0);
    signal adc_eoc          : std_logic;
    signal adc_rdy          : std_logic;
    signal adc_off          : std_logic;

    component clk_divider
        Port (
            clk             : in  std_logic;
            clk_div         : out std_logic
        );
    end component;
    
    -- components for I2C communication
    component MCP4728_payload_generator
        Port ( 
            ctrl_h          : in integer;  
            ctrl_l          : in integer;
            tec_maxv        : in integer;
            setpoint        : in integer;
            I2C_payload     : out std_logic_vector(47 downto 0)
        );
    end component;
    
    component I2C_Master
        Port (
            clk             : in std_logic;
            reset           : in  std_logic;
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
            overtemp_alarm  : in std_logic;
            undertemp_alarm : in std_logic;
            duty_cycle      : in integer;
            mod_sel         : in std_logic_vector(1 downto 0);
            status          : out std_logic_vector(1 downto 0);
            soa_en          : out std_logic;
            tec_en          : out std_logic;
            ctrl_sel        : out std_logic;
            pwm             : out std_logic
        );
    end component;
    
    component Display
        Port(
            clk             : in std_logic;
            mode            : in std_logic_vector(1 downto 0);
            status          : in std_logic_vector(1 downto 0);
            seg             : out std_logic_vector(5 downto 0);
            an              : out std_logic_vector(3 downto 0)
        );
    end component;
    
    -- component for UART communication
    component UART_transceiver
        Port (
            clk             : in std_logic;
            reset           : in std_logic;
            ADC_read        : in std_logic_vector(15 downto 0);
            uart_rx         : in std_logic;
            
            uart_tx         : out std_logic;
            duty_cycle      : out integer;  
            ctrl_l          : out integer; 
            ctrl_h          : out integer; 
            tec_maxv        : out integer;  
            setpoint        : out integer;                      
            mod_mode        : out std_logic_vector(1 downto 0)
        );               
    end component;
    
    component xadc_wiz_0
        Port(
            dclk_in         : in std_logic;                         
            reset_in        : in std_logic;   
            daddr_in        : in std_logic_vector(6 downto 0);     
            den_in          : in std_logic;                         
            di_in           : in std_logic_vector(15 downto 0);    
            dwe_in          : in std_logic;                                      
            vauxp15         : in std_logic;                       
            vauxn15         : in std_logic;
            vp_in           : in std_logic;                      
            vn_in           : in std_logic;
            
            busy_out        : out std_logic;                        
            drdy_out        : out std_logic;
            eoc_out         : out std_logic;                        
            eos_out         : out std_logic;                        
            alarm_out       : out std_logic;                        
            do_out          : out std_logic_vector(15 downto 0);   
            channel_out     : out std_logic_vector(4 downto 0)  
        );
    end component;
    
begin
    -- uart communication block
    transceiver : UART_transceiver
        Port map(
            clk             => clk,
            reset           => reset,
            ADC_read        => SOA_current_dig,
            uart_rx         => uart_rx,
            uart_tx         => uart_tx,
            duty_cycle      => duty_cycle,  
            ctrl_l          => ctrl_l,
            ctrl_h          => ctrl_h,
            tec_maxv        => tec_maxv,
            setpoint        => setpoint,                                  
            mod_mode        => mod_mode
        );
        
    -- modulation and control block
    modulator_block : modulator
        Port map (
            clk             => clk,
            overtemp_alarm  => overtemp_alarm,
            undertemp_alarm => undertemp_alarm,
            duty_cycle      => duty_cycle,
            mod_sel         => mod_mode,
            soa_en          => soa_en,
            tec_en          => tec_en,
            status          => status, 
            ctrl_sel        => ctrl_sel_pwm,
            pwm             => soa_pwm
        );

    display_block : Display
        Port map(
            clk             => clk,
            mode            => mod_mode,
            status          => status,
            seg             => seg,
            an              => an
        );
        
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
            I2C_payload     => payload,
            sda             => sda,
            scl             => scl,
            n_ldac          => n_ldac
        );
    
    ADC : xadc_wiz_0
        Port map(
            dclk_in         => clk,
            reset_in        => reset,
            daddr_in        => (others => '0'),
            den_in          => adc_eoc,
            di_in           => (others => '0'),
            dwe_in          => '0',
            vauxp15         => vauxp15,                      
            vauxn15         => vauxn15,
            vp_in           => '0',                
            vn_in           => '0',
            
            drdy_out        => adc_rdy,
            eoc_out         => adc_eoc,
            eos_out         => adc_off,
            busy_out        => adc_off,
            alarm_out       => adc_off,                    
            do_out          => SOA_current_dig,
            channel_out     => channel_out
        );
end Structural;
