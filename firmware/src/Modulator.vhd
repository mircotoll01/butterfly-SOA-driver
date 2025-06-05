library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity modulator is
    Port ( 
        clk             : in std_logic;
        overtemp_alarm  : in std_logic;
        undertemp_alarm : in std_logic;
        duty_cycle      : in integer;
        mod_sel         : in std_logic_vector(1 downto 0);      -- 00 = driver disabled, 01 = pwm mode, 10 = double threshold mode
        status          : out std_logic_vector(1 downto 0);     -- status bits indicate respectively SOA_EN and TEC_EN
        soa_en          : out std_logic;
        tec_en          : out std_logic;
        ctrl_sel        : out std_logic;
        pwm             : out std_logic
    );
end modulator;

architecture Behavioral of modulator is
    signal alarms           : std_logic_vector(1 downto 0) := "00";
    signal clk_div          : std_logic := '0';
    signal soa_en_reg       : std_logic := '0';
    signal tec_en_reg       : std_logic := '0';
    signal ctrl_sel_reg     : std_logic := '0';
    signal pwm_reg          : std_logic := '0';
begin
    process(clk)
    variable clock_divider : integer range 0 to 10000 := 0;
    begin
        if rising_edge(clk) then
            clock_divider := clock_divider + 1;
            if clock_divider = 10000 then
                clk_div <= not(clk_div);
            end if;
        end if;
    end process;
    
    process(clk_div)
    variable on_counter      : integer range 0 to 100 := 0;
    variable off_counter     : integer range 0 to 100 := 0;
    variable on_time         : integer range 0 to 100 := duty_cycle;
    variable off_time        : integer range 0 to 100 := 100 - on_time;
    begin
        if rising_edge(clk_div) then
            case alarms is
                when "10" => 
                    soa_en_reg          <= '0';  
                    tec_en_reg          <= '1';
                    ctrl_sel_reg        <= '0';
                    pwm_reg             <= '0';
                when "01" =>
                    soa_en_reg          <= '1';
                    tec_en_reg          <= '0';
                    ctrl_sel_reg        <= '0'; 
                    pwm_reg             <= '0';
                when "00" =>
                    tec_en_reg          <= '1';
                    case mod_sel is
                        when "00" =>
                            soa_en_reg          <= '0';
                            tec_en_reg          <= '1';
                            pwm_reg             <= '0';
                            ctrl_sel_reg        <= '0';
                        when "01" =>
                            soa_en_reg          <= '1';
                            tec_en_reg          <= '1';
                            ctrl_sel_reg        <= '0';
                            
                            if on_counter < on_time then
                                on_counter      := on_counter + 1;
                                pwm_reg         <= '1';
                            
                            elsif on_counter = on_time and off_counter < off_time then
                                off_counter     := off_counter + 1;
                                pwm_reg         <= '0';
    
                            elsif on_counter = on_time and off_counter = off_time then
                                on_counter      := 0;
                                off_counter     := 0;
                            end if;
                            
                        when "10" =>
                            soa_en_reg          <= '1';
                            tec_en_reg          <= '1';
                            pwm_reg             <= '0';
                            if on_counter < on_time then
                                on_counter      := on_counter + 1;
                                ctrl_sel_reg    <= '1';
                            elsif on_counter = on_time and off_counter < off_time then
                                off_counter     := off_counter + 1;
                                ctrl_sel_reg    <= '0';
                            elsif on_counter = on_time and off_counter = off_time then
                                on_counter      := 0;
                                off_counter     := 0;
                            end if;      
                        when others =>
                            soa_en_reg          <= '0';
                            pwm_reg             <= '0';
                            tec_en_reg          <= '0';
                            ctrl_sel_reg        <= '0';
                    end case;
                when others =>
                    soa_en_reg          <= '0';
                    pwm_reg             <= '0';
                    tec_en_reg          <= '0';
                    ctrl_sel_reg        <= '0';
            end case;
        end if;
    end process;
    
    alarms          <= overtemp_alarm & undertemp_alarm;
    soa_en          <= soa_en_reg;
    status          <= soa_en_reg & tec_en_reg;
    pwm             <= pwm_reg;
    tec_en          <= tec_en_reg;
    ctrl_sel        <= ctrl_sel_reg;
end Behavioral;