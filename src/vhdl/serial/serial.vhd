library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity serial is
	Port(
		I_clk: in std_logic;
		I_en: in std_logic;
		I_addr: in std_logic_vector(31 downto 0);
		I_data: in std_logic_vector(31 downto 0);
		I_rx: in std_logic;
		I_write: in std_logic;
		O_tx: out std_logic;
		O_busy: out std_logic;
		O_data: out std_logic_vector(31 downto 0)
	);
end serial;


architecture Behavioral of serial is
	constant clock_freq: integer := 50 * 1000000;
	constant baud: integer := 9600;
	constant baudclocks: integer := clock_freq/baud;
	
	type read_states is (READ_IDLE, READING);
	signal readstate: read_states := READ_IDLE;
	
	type write_states is (WRITE_IDLE, WRITING);
	signal writestate: write_states := WRITE_IDLE;
	
	signal dowrite: boolean := false;
	signal writebuf: std_logic_vector(7 downto 0) := X"00";
	signal readbuf: std_logic_vector(7 downto 0) := X"00";
	signal read_ready: boolean := false;
begin

	O_busy <= '0';

process(I_clk)
		variable readclkcnt: integer range 0 to baudclocks;
		variable readbitcnt: integer range 0 to 9;
		variable input: std_logic_vector(7 downto 0);
		variable edge_filter: std_logic_vector(3 downto 0);
		
		variable writeclkcnt: integer range 0 to baudclocks;
		variable writebitcnt: integer range 0 to 8;

	begin
		if rising_edge(I_clk) then
	
			-- reading
			case readstate is
				when READ_IDLE =>
					edge_filter := I_rx & edge_filter(3 downto 1);
					if edge_filter = "0000" then
						readstate <= READING;
						readclkcnt := 0;
						readbitcnt := 0;
						edge_filter := "1111";
					end if;
				
				when READING =>
					if readclkcnt = baudclocks/2 then -- sample mid-baud
						if readbitcnt /= 9 then
							input := I_rx & input(7 downto 1);
						else
							readbuf <= input;
							read_ready <= true;
							readstate <= READ_IDLE;
						end if;
						readbitcnt := readbitcnt + 1;
					end if;
					readclkcnt := readclkcnt + 1;
					if readclkcnt = baudclocks then
						readclkcnt := 0;
					end if;
					
			end case;

			-- writing
			case writestate is
				when WRITE_IDLE =>
					O_tx <= '1'; -- idle, high logic level
					if dowrite then
						writestate <= WRITING;
						writeclkcnt := 0;
						writebitcnt := 0;
						O_tx <= '0'; -- start bit: zero
					end if;
				
				when WRITING =>
					writeclkcnt := writeclkcnt + 1;
					if writeclkcnt = baudclocks then -- write next bit after one baud period
						writeclkcnt := 0;
						O_tx <= writebuf(0);
						if writebitcnt = 8 then
							writestate <= WRITE_IDLE;
							dowrite <= false;
						end if;
						writebuf <= '1' & writebuf(7 downto 1);
						writebitcnt := writebitcnt + 1;
					end if;
					
			end case;
			
			
			
			if I_en = '1' then
				case I_addr(3 downto 2) is
					when "00" => -- data register
						if(I_write = '1') then
							-- accept new data to write
							writebuf <= I_data(31 downto 24);
							dowrite <= true;
						else
							-- deliver received data
							O_data <= readbuf & X"000000";
							read_ready <= false;
						end if;
						
					when "01" => -- receive status register
						O_data <= X"00000000";
						if read_ready then
							-- signal non-zero when something fresh is in
							-- the read buffer
							O_data(24) <= '1';
						end if;
					
					when "10" => -- send status register
						O_data <= X"00000000";
						if not dowrite then
							-- signal "ready" when not sending
							O_data(24) <= '1';
						end if;
				
				
					when others =>
						null;
				end case;
			end if;
			
			

		end if;
	end process;

	
	--O_tx <= I_rx;
	
end Behavioral;