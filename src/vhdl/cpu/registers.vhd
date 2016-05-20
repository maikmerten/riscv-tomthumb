library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity registers is
	Port(
		I_clk: in std_logic;
		I_en: in std_logic;
		I_op: in regops_t;
		I_selS1: in std_logic_vector(4 downto 0);
		I_selS2: in std_logic_vector(4 downto 0);
		I_selD: in std_logic_vector(4 downto 0);
		I_dataAlu: in std_logic_vector(XLEN-1 downto 0);
		I_dataMem: in std_logic_vector(XLEN-1 downto 0);
		O_dataS1: out std_logic_vector(XLEN-1 downto 0) := XLEN_ZERO;
		O_dataS2: out std_logic_vector(XLEN-1 downto 0) := XLEN_ZERO
	);
end registers;


architecture Behavioral of registers is
	type store_t is array(0 to 31) of std_logic_vector(XLEN-1 downto 0);
	signal regs: store_t := (others => X"00000000");
	attribute ramstyle : string;
	attribute ramstyle of regs : signal is "no_rw_check";
begin


	process(I_clk)
		variable write_enabled: boolean;
		variable data: std_logic_vector(XLEN-1 downto 0);
	begin
		if rising_edge(I_clk) and I_en = '1' then

			data := X"00000000";
			-- by default assume read access
			write_enabled := false;

			-- determine details of write operations
			case I_op is
			
				when REGOP_WRITE_ALU =>
					-- write to destination register, unless R0 is selected
					write_enabled := true;
					if I_selD /= R0 then
						data := I_dataAlu;
					end if;
				
				when REGOP_WRITE_MEM =>
					-- write to destination register, unless R0 is selected
					write_enabled := true;
					if I_selD /= R0 then
						data := I_dataMem;
					end if;
				
				when others =>
					null;
			end case;

			-- this is a pattern that Quartus RAM synthesis understands
			-- as *not* being read-during-write (with no_rw_check attribute)
			if write_enabled then
				regs(to_integer(unsigned(I_selD))) <= data;
			else
				O_dataS1 <= regs(to_integer(unsigned(I_selS1)));
				O_dataS2 <= regs(to_integer(unsigned(I_selS2)));
			end if;
			
	
		end if;
	end process;
	
end Behavioral;