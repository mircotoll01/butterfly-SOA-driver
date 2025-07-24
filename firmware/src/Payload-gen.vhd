library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MCP4728_payload_generator is
    Port ( 
        ctrl_h      : in integer;
        ctrl_l      : in integer;
        tec_maxv    : in integer;
        setpoint    : in integer;
        I2C_payload : out std_logic_vector(71 downto 0)
    );
end MCP4728_payload_generator;

architecture Behavioral of MCP4728_payload_generator is
    constant LSB_INT    : integer := 1; -- Scaled LSB (e.g., 0.001 * 1000)
    signal payload      : std_logic_vector(71 downto 0) := (others => '0');
begin
    process(ctrl_h, ctrl_l, tec_maxv, setpoint)
        variable a0, a1, a2, a3 : integer := 0;
    begin
        -- Compute scaled values
        a0              := (ctrl_h) / LSB_INT; 
        a1              := (ctrl_l) / LSB_INT;
        a2              := (tec_maxv) / (LSB_INT*4);
        a3              := (setpoint) / LSB_INT;
        
        -- Concatenate the factors into the payload
        payload         <=  "11000000" & -- addressing the MCP
                            "0000" & -- C1 C2 PD1 PD0 configuration for fast write mode
                            std_logic_vector(to_unsigned(a0, 12)) & "0000" &
                            std_logic_vector(to_unsigned(a1, 12)) & "0000" &
                            std_logic_vector(to_unsigned(a2, 12)) & "0000" &
                            std_logic_vector(to_unsigned(a3, 12));
    end process;
    I2C_payload <= payload;
end Behavioral;
