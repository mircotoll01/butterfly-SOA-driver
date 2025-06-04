library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Utility package providing ASCII-integer conversion functions
package utils_pkg is
  -- Converts a 16-bit ADC sample (0..65535) to an ASCII representation of a voltage in format "d.ddd"
  function adc_to_ascii(sample : in std_logic_vector(15 downto 0)) return std_logic_vector;

  -- Converts a 3-byte ASCII vector to integer (e.g. "123" => 123)
  function ascii_to_integer(vect: std_logic_vector(23 downto 0)) return integer;

  -- Converts a 4-byte ASCII vector to integer (e.g. "0123" => 123)
  function four_bytes_ascii_to_integer(vect: std_logic_vector(31 downto 0)) return integer;

  -- Converts an integer (0..9999) to a 4-byte ASCII vector ("0000" to "9999")
  function int_to_ascii(input : integer) return std_logic_vector;
  
  -- Mirrors any bit vector
  function reverse_vector(input_vec : std_logic_vector) return std_logic_vector;

  -- Custom ASCII string type, 14-character fixed-length array
  type ASCII_string is array (0 to 13) of std_logic_vector(7 downto 0);
end package utils_pkg;

package body utils_pkg is
    
  -- Funzione generica che inverte un std_logic_vector
    -- (se il vettore è N downto 0, allora bit 0 diventa N, 1 diventa N-1, ecc.)
    function reverse_vector
        (input_vec : std_logic_vector)
        return std_logic_vector is
        variable result : std_logic_vector(input_vec'range);
    begin
        for i in input_vec'range loop
            result(i) := input_vec(input_vec'left - i);
        end loop;
        return result;
    end function reverse_vector;
    
  -- Converts a 16-bit ADC sample to ASCII string in format "d.ddd"
  function adc_to_ascii(sample : in std_logic_vector(15 downto 0)) return std_logic_vector is
        variable code_int    : integer;                              -- ADC input as integer
        variable scaled      : integer;                              -- Scaled value (0..1000)
        variable ipart       : integer;                              -- Integer part (0 or 1)
        variable frac        : integer;                              -- Fractional part (0..999)
        variable d100        : integer;                              -- Hundreds digit
        variable d10         : integer;                              -- Tens digit
        variable d1          : integer;                              -- Units digit
        variable b_ipart     : std_logic_vector(7 downto 0);         -- ASCII byte for integer part
        variable b_dot       : std_logic_vector(7 downto 0) := x"2E";-- ASCII for '.'
        variable b_hund      : std_logic_vector(7 downto 0);         -- ASCII byte for hundredths digit
        variable b_ten       : std_logic_vector(7 downto 0);         -- ASCII byte for tenths digit
        variable b_one       : std_logic_vector(7 downto 0);         -- ASCII byte for thousandths digit
        variable result      : std_logic_vector(39 downto 0);        -- 5-character ASCII result
    begin
        -- Convert input to integer
        code_int := to_integer(unsigned(sample));

        -- Scale the result to 0..1000 (represents 0.000 to 1.000 V)
        scaled := (code_int * 1000) / 65535;

        -- Extract parts for ASCII representation
        ipart := scaled / 1000;        -- Integer part (0 or 1)
        frac  := scaled mod 1000;      -- Decimal part (0 to 999)
        d100  := frac / 100;           -- First decimal digit
        d10   := (frac / 10) mod 10;   -- Second decimal digit
        d1    := frac mod 10;          -- Third decimal digit

        -- Convert each digit to ASCII
        b_ipart := std_logic_vector(to_unsigned(ipart + 48, 8)); -- '0' = 48
        b_hund  := std_logic_vector(to_unsigned(d100 + 48, 8));
        b_ten   := std_logic_vector(to_unsigned(d10 + 48, 8));
        b_one   := std_logic_vector(to_unsigned(d1 + 48, 8));

        -- Concatenate to produce "d.ddd"
        result := b_ipart & b_dot & b_hund & b_ten & b_one;

        return result;
    end function adc_to_ascii;

  -- Converts a 3-byte ASCII vector (e.g., "123") into an integer
  function ascii_to_integer(vect: std_logic_vector(23 downto 0)) return integer is 
        type parsedint is array (0 to 2) of integer;
        variable digits: parsedint;
        variable result: integer := 0;
    begin
        -- Extract digits from ASCII bytes, one byte per digit
        for i in 0 to 2 loop 
            case vect(23 - i*8 downto 16 - i*8) is 
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
                when others     => digits(i) := 0; -- Default to 0 if invalid
            end case;
        end loop;

        -- Combine digits into integer value
        result := digits(0)*100 + digits(1)*10 + digits(2);
        return result;
    end ascii_to_integer; 

  -- Converts a 4-byte ASCII vector (e.g., "0123") into an integer
  function four_bytes_ascii_to_integer(vect: std_logic_vector(31 downto 0)) return integer is
        type parsedint is array (0 to 3) of integer;
        variable digits: parsedint;
        variable result: integer := 0;
    begin
        -- Parse 4 ASCII digits
        for i in 0 to 3 loop 
            case vect(31 - i*8 downto 24 - i*8) is 
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
                when others     => digits(i) := 0; -- Fallback
            end case;
        end loop;

        -- Convert to integer (thousands + hundreds + tens + units)
        result := digits(0)*1000 + digits(1)*100 + digits(2)*10 + digits(3);
        return result;
    end four_bytes_ascii_to_integer;

  -- Converts an integer (0..9999) to a 4-digit ASCII string
  function int_to_ascii(input : integer) return std_logic_vector is
        variable result     : std_logic_vector(31 downto 0) := (others => '0'); -- Output vector (4 ASCII characters)
        variable temp       : integer := input;                                 -- Working copy
        variable digit      : integer;                                          -- Digit being processed
        variable ascii_char : std_logic_vector(7 downto 0);                     -- ASCII representation of the digit
    begin
        -- Thousands place
        digit := temp / 1000;
        ascii_char := std_logic_vector(to_unsigned(digit + 48, 8)); -- Add ASCII '0'
        result(31 downto 24) := ascii_char;
        temp := temp mod 1000;

        -- Hundreds place
        digit := temp / 100;
        ascii_char := std_logic_vector(to_unsigned(digit + 48, 8));
        result(23 downto 16) := ascii_char;
        temp := temp mod 100;

        -- Tens place
        digit := temp / 10;
        ascii_char := std_logic_vector(to_unsigned(digit + 48, 8));
        result(15 downto 8) := ascii_char;
        temp := temp mod 10;

        -- Units place
        digit := temp;
        ascii_char := std_logic_vector(to_unsigned(digit + 48, 8));
        result(7 downto 0) := ascii_char;

        return result;
    end function;

end package body utils_pkg;
