library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package ram_wb8_init is

constant ADDRLEN : integer := 12; -- bits for number of 8 bit words in memory
type store_t is array(0 to (2**ADDRLEN)-1) of std_logic_vector(7 downto 0);

constant RAM_INIT : store_t := (

-- slow binary LED counter loop.s


X"b3",
X"62",
X"00",
X"00",
X"23",
X"20",
X"50",
X"20",
X"13",
X"03",
X"10",
X"00",
X"b7",
X"03",
X"00",
X"10",
X"83",
X"22",
X"00",
X"20",
X"b3",
X"82",
X"62",
X"00",
X"23",
X"20",
X"50",
X"20",
X"93",
X"d2",
X"02",
X"01",
X"23",
X"a0",
X"53",
X"00",
X"93",
X"02",
X"50",
X"00",
X"b3",
X"82",
X"62",
X"40",
X"e3",
X"de",
X"02",
X"fe",
X"6f",
X"f0",
X"1f",
X"fe",




others => X"00"
);

end package ram_wb8_init;
