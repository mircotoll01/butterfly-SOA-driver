library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package utils_pkg is
  function ADC_to_ASCII( sample : in std_logic_vector(15 downto 0)) return std_logic_vector;
  function ASCII_to_integer (vect: std_logic_vector(23 downto 0)) return integer;
  function fourBytes_ASCII_to_integer (vect: std_logic_vector(31 downto 0)) return integer;
  type ASCII_string is array (0 to 13) of std_logic_vector(7 downto 0);
end package utils_pkg;

package body utils_pkg is
-- Function: Converts a 16-bit ADC code (0..65535) corresponding to 0..1 V
--           into a 5-character ASCII string "d.ddd" representing voltage 0.000..1.000.

  function ADC_to_ASCII(
        sample : in std_logic_vector(15 downto 0)
    ) return std_logic_vector is
        variable code_int    : integer;
        variable scaled      : integer;
        variable ipart       : integer;
        variable frac        : integer;
        variable d100        : integer;
        variable d10         : integer;
        variable d1          : integer;
        -- ASCII bytes
        variable b_ipart     : std_logic_vector(7 downto 0);
        variable b_dot       : std_logic_vector(7 downto 0) := x"2E";  -- '.'
        variable b_hund      : std_logic_vector(7 downto 0);
        variable b_ten       : std_logic_vector(7 downto 0);
        variable b_one       : std_logic_vector(7 downto 0);
        variable result      : std_logic_vector(39 downto 0);
    begin
        -- Convert sample to integer
        code_int := to_integer(unsigned(sample));

        -- Scale to 0..1000 (truncated)
        -- Avoid overflow: multiply then divide
        scaled := (code_int * 1000) / 65535;

        -- Extract integer and fractional parts
        ipart := scaled / 1000;        -- 0 or 1
        frac  := scaled mod 1000;       -- 0..999
        d100  := frac / 100;            -- hundreds digit
        d10   := (frac / 10) mod 10;    -- tens digit
        d1    := frac mod 10;           -- ones digit

        -- Build ASCII bytes (0x30 = '0')
        b_ipart := std_logic_vector(to_unsigned(ipart + 48, 8));
        b_hund  := std_logic_vector(to_unsigned(d100  + 48, 8));
        b_ten   := std_logic_vector(to_unsigned(d10   + 48, 8));
        b_one   := std_logic_vector(to_unsigned(d1    + 48, 8));

        -- Concatenate into 5-byte vector: [C0..C4]
        -- result(39 downto 32) = b_ipart, (31..24)=b_dot, (23..16)=b_hund, ...
        result := b_ipart & b_dot & b_hund & b_ten & b_one;
        return result;
    end function ADC_to_ASCII;
    
    function ASCII_to_integer (vect: std_logic_vector(23 downto 0)) return integer is 
        type parsedint is array (0 to 2) of integer;
        variable digits: parsedint;
        variable result: integer := 0;
    begin
        for i in 0 to 2 loop 
            case vect(23-i*8 downto 16-i*8) is 
                when "00110000" => digits(i) := 0;
                when "00110001" => digits(i) := 1;
                when "00110010" => digits(i) := 2;
                when "00110011" => digits(i) := 3;
                when "00110100" => digits(i) := 4;
                when "00110101" => digits(i) := 5;
                when "00110110" => digits(i) := 6;
                when "00110111" => digits(i) := 7;
                when "00111000" => digits(i) := 8;
                when "00111001" => digits(i) := 9;
                when others     => digits(i) := 0;
            end case;
        end loop;
        result := digits(0)*100 + digits(1)*10 + digits(2);
        return result;
    end ASCII_to_integer; 
    
    function fourBytes_ASCII_to_integer (vect: std_logic_vector(31 downto 0)) return integer is
        type parsedint is array (0 to 3) of integer;
        variable digits: parsedint;
        variable result: integer := 0;
    begin
        for i in 0 to 3 loop 
            case vect(31-i*8 downto 24-i*8) is 
                when "00110000" => digits(i) := 0;
                when "00110001" => digits(i) := 1;
                when "00110010" => digits(i) := 2;
                when "00110011" => digits(i) := 3;
                when "00110100" => digits(i) := 4;
                when "00110101" => digits(i) := 5;
                when "00110110" => digits(i) := 6;
                when "00110111" => digits(i) := 7;
                when "00111000" => digits(i) := 8;
                when "00111001" => digits(i) := 9;
                when others     => digits(i) := 0;
            end case;
        end loop;
        result := digits(0)*1000 + digits(1)*100 + digits(2)*10 + digits(3);
        return result;
    end fourBytes_ASCII_to_integer;
end package body utils_pkg;
