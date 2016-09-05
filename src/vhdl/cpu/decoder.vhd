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
		O_opcode: out std_logic_vector(4 downto 0);
		O_funct3: out std_logic_vector(2 downto 0);
		O_funct7: out std_logic_vector(6 downto 0)
	);
end decoder;

architecture Behavioral of decoder is
begin
	process(I_clk)
		alias opcode: std_logic_vector(4 downto 0) is I_instr(6 downto 2);
		alias funct3: std_logic_vector(2 downto 0) is I_instr(14 downto 12);
		alias funct7: std_logic_vector(6 downto 0) is I_instr(31 downto 25);
	begin
		if rising_edge(I_clk) and I_en = '1' then

			O_rs1 <= I_instr(19 downto 15);
			O_rs2 <= I_instr(24 downto 20);
			O_rd <= I_instr(11 downto 7);
			
			O_opcode <= opcode;
			O_funct3 <= funct3;
			O_funct7 <= funct7;

			-- extract immediate value
			case opcode is
				when OP_STORE =>
					-- S-type
					O_imm <= std_logic_vector(resize(signed(I_instr(31 downto 25) & I_instr(11 downto 8) & I_instr(7)), O_imm'length));
			
				when OP_BRANCH =>
					-- SB-type
					O_imm <= std_logic_vector(resize(signed(I_instr(31) & I_instr(7) & I_instr(30 downto 25) & I_instr(11 downto 8) & '0'), O_imm'length));
			
				when OP_LUI | OP_AUIPC =>
					-- U-type
					O_imm <= std_logic_vector(I_instr(31 downto 12) & X"000");
					
				when OP_JAL =>
					-- UJ-type
					O_imm <= std_logic_vector(resize(signed(I_instr(31) & I_instr(19 downto 12) & I_instr(20) & I_instr(30 downto 25) & I_instr(24 downto 21) & '0'), O_imm'length));

				when others =>
					-- I-type and R-type
					-- immediate carries no actual meaning for R-type instructions
					O_imm <= std_logic_vector(resize(signed(I_instr(31 downto 20)), O_imm'length));
			end case;
			
		end if;
	end process;

end Behavioral;