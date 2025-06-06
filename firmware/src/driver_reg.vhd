library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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
    signal ctrl_l_reg      : integer := 0;
    signal ctrl_h_reg      : integer := 0;
    signal tec_maxv_reg    : integer := 0;
    signal setpoint_reg    : integer := 0;
    signal duty_cycle_reg  : integer := 0;
    signal mod_mode_reg    : std_logic_vector(1 downto 0);
begin
    process(clk,reset)
    begin
        if reset = '1' then
                ctrl_l_reg      <= 0;
                ctrl_h_reg      <= 0;
                tec_maxv_reg    <= 0; 
                setpoint_reg    <= 0;
                duty_cycle_reg  <= 0;
                mod_mode_reg    <= "00";
        end if;
        
        if rising_edge(clk) then
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
                        mod_mode_reg    <= mod_sel_in;
                    end if;
                when "111" =>
                    mod_mode_reg    <= "00";
                when others =>
            end case; 
        end if;
    end process;
    
    ctrl_l          <= ctrl_l_reg;
    ctrl_h          <= ctrl_h_reg;
    tec_maxv        <= tec_maxv_reg; 
    setpoint        <= setpoint_reg;
    duty_cycle      <= duty_cycle_reg; 
    mod_mode        <= mod_mode_reg;

end Behavioral;
