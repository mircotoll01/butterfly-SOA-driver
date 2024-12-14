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
        write_flag  : in std_logic;
        address     : in std_logic_vector(2 downto 0);
        data_in     : in integer;
        ctrl_l      : out integer;
        ctrl_h      : out integer;
        tec_maxv    : out integer;
        setpoint    : out integer;
        duty_cycle  : out integer
     );
end driver_reg;

architecture Behavioral of driver_reg is

begin
    process(clk)
    begin
        if rising_edge(clk) then
            case address is
                when "000" =>
                    if write_flag = '1' then
                        ctrl_l <= data_in;
                    end if;
                when "001" =>
                    if write_flag = '1' then
                        ctrl_h <= data_in;
                    end if;
                when "010" =>
                    if write_flag = '1' then
                        tec_maxv <= data_in;
                    end if;
                when "011" =>
                    if write_flag = '1' then
                        setpoint <= data_in;
                    end if;
                when "100" =>
                    if write_flag = '1' then
                        duty_cycle <= data_in;
                    end if;
                when others =>
                    if write_flag = '1' then
                        setpoint <= data_in;
                    end if;
            end case; 
        end if;
    end process;
end Behavioral;
