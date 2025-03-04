----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/04/2024 11:08:29 AM
-- Design Name: 
-- Module Name: modulator - Behavioral
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
    signal soa_en_reg       : std_logic := '0';
    signal tec_en_reg       : std_logic := '0';
    signal ctrl_sel_reg     : std_logic := '0';
    signal pwm_reg          : std_logic := '0';
    signal alarms           : std_logic_vector(1 downto 0) := "00";
begin 
    process(clk)
    variable refresh_counter    :integer range 0 to 999 := 0;
    begin
        if rising_edge(clk) then
            if refresh_counter = 999 then
                alarms          <= overtemp_alarm & undertemp_alarm;
                soa_en          <= soa_en_reg;
                status          <= soa_en_reg & tec_en_reg;
                pwm             <= pwm_reg;
                tec_en          <= tec_en_reg;
                ctrl_sel        <= ctrl_sel_reg;
                refresh_counter := 0;
            else
                refresh_counter := refresh_counter + 1;
            end if;
        end if;
    end process;
    
    process(clk)
    variable on_counter      : integer range 0 to 100 := 0;
    variable off_counter     : integer range 0 to 100 := 0;
    variable on_time         : integer range 0 to 100 := duty_cycle;
    variable off_time        : integer range 0 to 100 := 100 - on_time;
    begin
        if rising_edge(clk) then
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
    
    
end Behavioral;