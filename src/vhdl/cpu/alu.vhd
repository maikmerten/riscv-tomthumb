library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity alu is
	Port(
		I_clk: in std_logic;
		I_en: in std_logic;
		I_dataS1: in std_logic_vector(XLEN-1 downto 0);
		I_dataS2: in std_logic_vector(XLEN-1 downto 0);
		I_reset: in std_logic := '0';
		I_aluop: in aluops_t;
		O_busy: out std_logic := '0';
		O_data: out std_logic_vector(XLEN-1 downto 0);
		O_lt: out boolean := false;
		O_ltu: out boolean := false;
		O_zero: out boolean := false
	);
end alu;

architecture Behavioral of alu is
	alias op1 is I_dataS1(XLEN-1 downto 0);
	alias op2 is I_dataS2(XLEN-1 downto 0);
begin
	process(I_clk, I_en, I_dataS1, I_dataS2, I_reset, I_aluop)
		variable tmpval,sum,result: std_logic_vector(XLEN-1 downto 0);
		variable shiftcnt: std_logic_vector(4 downto 0);
		variable busy: boolean := false;
		variable lt,ltu: boolean;
	begin
	
	
		if rising_edge(I_clk) then

			-- check for reset
			if(I_reset = '1') then
				busy := false;
			elsif I_en = '1' then
			
				-------------------------------
				-- ALU core operations
				-------------------------------

				lt := signed(op1) < signed(op2);
				ltu := unsigned(op1) < unsigned(op2);
				sum := std_logic_vector(unsigned(op1) + unsigned(op2));
				
				O_lt <= lt;
				O_ltu <= ltu;

				case I_aluop is
		
					when ALU_ADD =>
						result := sum;
				
					when ALU_SUB =>
						result := std_logic_vector(unsigned(op1) - unsigned(op2));
					
					when ALU_AND =>
						result := op1 and op2;
				
					when ALU_OR =>
						result := op1 or op2;
					
					when ALU_XOR =>
						result := op1 xor op2;
				
					when ALU_SLT =>
						result := XLEN_ZERO;
						if lt then
							result(0) := '1';
						end if;
				
					when ALU_SLTU =>
						result := XLEN_ZERO;
						if ltu then
							result(0) := '1';
						end if;
				
					when ALU_SLL | ALU_SRL | ALU_SRA =>
						if not busy then
							busy := true;
							tmpval := op1;
							shiftcnt := op2(4 downto 0);
						elsif shiftcnt /= "00000" then
							case I_aluop is
								when ALU_SLL => tmpval := tmpval(30 downto 0) & '0';
								when ALU_SRL => tmpval := '0' & tmpval(31 downto 1);
								when others => tmpval := tmpval(31) & tmpval(31 downto 1);
							end case;
							shiftcnt := std_logic_vector(unsigned(shiftcnt) - 1);
						else
							busy := false;
							result := tmpval;
						end if;
		
				end case;
			
		
				if busy then
					O_busy <= '1';
				else
					O_busy <= '0';
				end if;
				
				O_data <= result;
				O_zero <= result = X"00000000";
		
			end if;
		end if;
	end process;

end Behavioral;