library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity spirom_wb8 is
	
	Port(
		-- bus signal naming according to Wishbone B4 spec
		CLK_I: in std_logic;
		STB_I: in std_logic;
		ADR_I: in std_logic_vector(XLEN-1 downto 0);
		DAT_O: out std_logic_vector(7 downto 0);
		ACK_O: out std_logic;
		
		-- SPI signal lines
		I_spi_miso: in std_logic := '0';
		O_spi_sel: out std_logic := '1';
		O_spi_clk: out std_logic := '0';
		O_spi_mosi: out std_logic := '0'
	);
end spirom_wb8;


architecture Behavioral of spirom_wb8 is
	signal tx_data, rx_data: std_logic_vector(7 downto 0) := X"00";
	signal tx_start: boolean := false;
	signal spi_busy: boolean := true;
begin

	spimaster_instance: entity work.spimaster port map(
		I_clk => CLK_I,
		I_tx_data => tx_data,
		I_tx_start => tx_start,
		I_spi_miso => I_spi_miso,
		
		O_spi_clk => O_spi_clk,
		O_spi_mosi => O_spi_mosi,
		O_rx_data => rx_data,
		O_busy => spi_busy
	);
	

	process(CLK_I)
		type ctrlstates is (IDLE, OPCODE, ADDR1, ADDR2, ADDR3, READ1, READ2, ACK, TX1, TX2);
		variable state, retstate: ctrlstates := IDLE;
		variable addr: std_logic_vector(23 downto 0) := X"000000";
		variable delay_counter: std_logic_vector(20 downto 0);
	begin
	
		if rising_edge(CLK_I) then
		
		
			O_spi_sel <= '0'; -- select device
			ACK_O <= '0'; -- don't ACK bus
			
		
			case state is
				when IDLE =>
					O_spi_sel <= '1'; -- deselect device
					if not spi_busy and STB_I = '1' then
						addr := ADR_I(23 downto 0);
						state := OPCODE;
					end if;
				
				when OPCODE =>
					tx_data <= X"03";
					state := TX1;
					retstate := ADDR1;
					
				
				when ADDR1 =>
					tx_data <= addr(23 downto 16);
					state := TX1;
					retstate := ADDR2;
					
				when ADDR2 =>
					tx_data <= addr(15 downto 8);
					state := TX1;
					retstate := ADDR3;
					
				when ADDR3 =>				
					tx_data <= addr(7 downto 0);
					state := TX1;
					retstate := READ1;
					
				when READ1 =>
					tx_data <= X"00";
					state := TX1;
					retstate := READ2;
					
				when READ2 =>
					DAT_O <= rx_data;
					state := ACK;
				
				when ACK =>
					ACK_O <= '1';
					if STB_I = '0' then
						state := IDLE;
					end if;
				
				
				when TX1 =>
					-- signal beginning of transmission
					tx_start <= true;
					-- wait for ack that transmission is in progress
					if spi_busy then
						state := TX2;
					end if;
				
				when TX2 =>
					tx_start <= false;
					-- wait until transmission has ended
					if not spi_busy then
						state := retstate;
					end if;
					
			
			end case;
			
		
		end if;
		
		
	end process;

end Behavioral;

