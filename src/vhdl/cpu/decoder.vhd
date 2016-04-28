library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity decoder is
	Port(
		I_clk: in std_logic;
		I_en: in std_logic;
		I_instr: in std_logic_vector(31 downto 0);
		O_rs1: out std_logic_vector(4 downto 0);
		O_rs2: out std_logic_vector(4 downto 0);
		O_rd: out std_logic_vector(4 downto 0);
		O_imm: out std_logic_vector(31 downto 0) := XLEN_ZERO;
		O_fop: out std_logic_vector(7 downto 0);
		O_regwrite : out std_logic;
		O_memop: out std_logic
	);
end decoder;

architecture Behavioral of decoder is
begin
	process(I_clk)
		variable opcode: std_logic_vector(4 downto 0);
		variable funct3: std_logic_vector(2 downto 0);
	begin
		if rising_edge(I_clk) and I_en = '1' then
			opcode := I_instr(6 downto 2);
			funct3 := I_instr(14 downto 12);			
			
			O_rs1 <= I_instr(19 downto 15);
			O_rs2 <= I_instr(24 downto 20);
			O_rd <= I_instr(11 downto 7);
			O_regwrite <= '1';
			O_memop <= '0';

		
			case opcode is
				when OP_STORE =>
					-- S-type
					O_regwrite <= '0';
					O_memop <= '1';
					O_imm <= std_logic_vector(resize(signed(I_instr(31 downto 25) & I_instr(11 downto 8) & I_instr(7)), O_imm'length));
			
				when OP_BRANCH =>
					-- SB-type
					O_regwrite <= '0';
					O_imm <= std_logic_vector(resize(signed(I_instr(31) & I_instr(7) & I_instr(30 downto 25) & I_instr(11 downto 8) & '0'), O_imm'length));
			
				when OP_LUI | OP_AUIPC =>
					-- U-type
					O_imm <= std_logic_vector(I_instr(31 downto 12) & X"000");
					
				when OP_JAL =>
					-- UJ-type
					O_imm <= std_logic_vector(resize(signed(I_instr(31) & I_instr(19 downto 12) & I_instr(20) & I_instr(30 downto 25) & I_instr(24 downto 21) & '0'), O_imm'length));

				when others =>
					-- I-type and R-type
					-- for R-type: func7 is in bits 11 downto 5 of immediate
					O_imm <= std_logic_vector(resize(signed(I_instr(31 downto 20)), O_imm'length));
					if opcode = OP_LOAD then
						O_memop <= '1';
					end if;
			end case;
			
			O_fop <= funct3 & opcode;
			
		end if;
	end process;

end Behavioral;