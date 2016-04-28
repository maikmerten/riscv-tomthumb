library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity arbiter_wb8 is
	Port(
		ADR_I: in std_logic_vector(31 downto 0);
		ACK0_I, ACK1_I, ACK2_I, ACK3_I: in std_logic;
		DAT0_I, DAT1_I, DAT2_I, DAT3_I: in std_logic_vector(7 downto 0);
		STB_I: in std_logic := '0';
		ACK_O: out std_logic := '0';
		DAT_O: out std_logic_vector(7 downto 0);
		STB0_O, STB1_O, STB2_O, STB3_O: out std_logic
	);
end arbiter_wb8;


architecture Behavioral of arbiter_wb8 is
begin
	process(ADR_I, STB_I, DAT0_I, DAT1_I, DAT2_I, DAT3_I, ACK0_I, ACK1_I, ACK2_I, ACK3_I)
	begin
	
		STB0_O <= '0';
		STB1_O <= '0';
		STB2_O <= '0';
		STB3_O <= '0';
		
		-- most significant nibble selects device - room for 16 devices
		case ADR_I(29 downto 28) is
			when "00" =>
				STB0_O <= STB_I;
				DAT_O <= DAT0_I;
				ACK_O <= ACK0_I;
				
			when "01" =>
				STB1_O <= STB_I;
				DAT_O <= DAT1_I;
				ACK_O <= ACK1_I;
					
			when "10" =>
				STB2_O <= STB_I;
				DAT_O <= DAT2_I;
				ACK_O <= ACK2_I;
					
			when others => -- "11" presumably
				STB3_O <= STB_I;
				DAT_O <= DAT3_I;
				ACK_O <= ACK3_I;
	
		end case;		

	end process;
end Behavioral;