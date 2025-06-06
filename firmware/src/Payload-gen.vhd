library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MCP4728_payload_generator is
    Port ( 
        ctrl_h      : in integer;
        ctrl_l      : in integer;
        tec_maxv    : in integer;
        setpoint    : in integer;
        I2C_payload : out std_logic_vector(47 downto 0)
    );
end MCP4728_payload_generator;

architecture Behavioral of MCP4728_payload_generator is
    constant LSB_INT : integer := 5; -- Scaled LSB (e.g., 0.0005 * 10000)
    signal payload : std_logic_vector(47 downto 0) := (others => '0');
begin
    process(ctrl_h, ctrl_l, tec_maxv, setpoint)
        variable a0, a1, a2, a3 : integer := 0;
        variable refresh_counter: integer range 0 to 99999 := 0;
    begin
        -- Compute scaled values
        a0              := ctrl_l / LSB_INT; -- Integer division
        a1              := ctrl_h / LSB_INT;
        a2              := tec_maxv / LSB_INT;
        a3              := setpoint / LSB_INT;
        
        -- Concatenate the factors into the payload
        payload         <=  std_logic_vector(to_unsigned(a0, 12)) & 
                            std_logic_vector(to_unsigned(a1, 12)) & 
                            std_logic_vector(to_unsigned(a2, 12)) & 
                            std_logic_vector(to_unsigned(a3, 12));
    end process;
    I2C_payload <= payload;
end Behavioral;
