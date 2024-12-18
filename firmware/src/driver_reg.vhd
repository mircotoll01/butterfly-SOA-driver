----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/11/2024 08:50:31 PM
-- Design Name: 
-- Module Name: driver_reg - Behavioral
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

entity driver_reg is
    Port (
        clk         : in std_logic;
        reset       : in std_logic;
        write_flag  : in std_logic;
        address     : in std_logic_vector(2 downto 0);
        mod_sel_in  : in std_logic_vector(1 downto 0);
        data_in     : in integer;
        ctrl_l      : out integer;
        ctrl_h      : out integer;
        tec_maxv    : out integer;
        setpoint    : out integer;
        duty_cycle  : out integer;
        mod_mode    : out std_logic_vector(1 downto 0)
     );
end driver_reg;

architecture Behavioral of driver_reg is
    signal ctrl_l_reg      : integer;
    signal ctrl_h_reg      : integer;
    signal tec_maxv_reg    : integer;
    signal setpoint_reg    : integer;
    signal duty_cycle_reg  : integer;
    signal mod_mode_reg    : std_logic_vector(1 downto 0);
begin
    process(clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                ctrl_l_reg      <= 0;
                ctrl_h_reg      <= 0;
                tec_maxv_reg    <= 0; 
                setpoint_reg    <= 0;
                duty_cycle_reg  <= 0;
                mod_mode_reg    <= "00";
            else
                mod_mode_reg    <= mod_sel_in;
                case address is    
                    when "000" =>
                        if write_flag = '1' then
                            ctrl_l_reg      <= data_in;
                        end if;
                    when "001" =>
                        if write_flag = '1' then
                            ctrl_h_reg      <= data_in;
                        end if;
                    when "010" =>
                        if write_flag = '1' then
                            tec_maxv_reg    <= data_in;
                        end if;
                    when "011" =>
                        if write_flag = '1' then
                            setpoint_reg    <= data_in;
                        end if;
                    when "100" =>
                        if write_flag = '1' then
                            duty_cycle_reg  <= data_in;
                        end if;
                    when others =>
                        ctrl_l_reg      <= 0;
                        ctrl_h_reg      <= 0;
                        tec_maxv_reg    <= 0; 
                        setpoint_reg    <= 0;
                        duty_cycle_reg  <= 0;
                        mod_mode_reg    <= "00";
                end case; 
            end if;
        end if;
    end process;
    
    ctrl_l          <= ctrl_l_reg;
    ctrl_h          <= ctrl_h_reg;
    tec_maxv        <= tec_maxv_reg; 
    setpoint        <= setpoint_reg;
    duty_cycle      <= duty_cycle_reg; 
    mod_mode        <= mod_mode_reg;

end Behavioral;
