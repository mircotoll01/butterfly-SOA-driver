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
    constant on_time       : integer := duty_cycle;
    signal soa_en_buffer   : std_logic;
    signal tec_en_buffer   : std_logic;
    signal ctrl_sel_buffer : std_logic;
    signal pwm_buffer      : std_logic;
    signal on_counter      : integer range 0 to 99 := 0;
    signal off_counter     : integer range 0 to 99 := 0;
    signal alarms          : std_logic_vector(1 downto 0) := "00";
begin 
    process(clk)        
    begin
        if rising_edge(clk) then
            case alarms is
                when "10" => 
                    soa_en_buffer      <= '0';  
                    tec_en_buffer      <= '1';
                    ctrl_sel_buffer    <= '0';
                    pwm_buffer         <= '0';
                when "01" =>
                    soa_en_buffer      <= '1';
                    tec_en_buffer      <= '0';
                    ctrl_sel_buffer    <= '0'; 
                    pwm_buffer         <= '0';
                when "00" =>
                    tec_en_buffer      <= '1';
                    case mod_sel is
                        when "00" =>
                            soa_en_buffer      <= '0';
                            tec_en_buffer      <= '1';
                            pwm_buffer         <= '0';
                            ctrl_sel_buffer    <= '0';
                        when "01" =>
                            soa_en_buffer      <= '1';
                            tec_en_buffer      <= '1';
                            ctrl_sel_buffer    <= '0';
                            
                            if on_counter < on_time then
                                on_counter     <= on_counter + 1;
                                pwm_buffer     <= '1';
                            end if;
                            
                            if off_counter < 99 - on_time then
                                off_counter    <= off_counter + 1;
                                pwm_buffer     <= '0';
                            end if;
                            
                            if on_counter + off_counter = 99 then
                                on_counter     <= 0;
                                off_counter    <= 0;
                            end if;
                        when "10" =>
                            soa_en_buffer      <= '1';
                            tec_en_buffer      <= '1';
                            pwm_buffer         <= '0';
                            if on_counter < 49 then
                                on_counter     <= on_counter + 1;
                                ctrl_sel_buffer<= '1';
                            elsif on_counter = 49 and off_counter < 49 then
                                off_counter    <= off_counter + 1;
                                ctrl_sel_buffer    <= '0';
                            elsif on_counter = 49 and off_counter = 49 then
                                on_counter     <= 0;
                                off_counter    <= 0;
                            end if;      
                        when others =>
                            soa_en_buffer      <= '0';
                            pwm_buffer         <= '0';
                            tec_en_buffer      <= '0';
                            ctrl_sel_buffer    <= '0';
                    end case;
                when others =>
                    soa_en_buffer      <= '0';
                    pwm_buffer         <= '0';
                    tec_en_buffer      <= '0';
                    ctrl_sel_buffer    <= '0';
            end case;
        end if;
    end process;
    alarms            <= overtemp_alarm & undertemp_alarm;
    soa_en            <= soa_en_buffer;
    status            <= soa_en_buffer & tec_en_buffer;
    pwm               <= pwm_buffer;
    tec_en            <= tec_en_buffer;
    ctrl_sel          <= ctrl_sel_buffer;
end Behavioral;
