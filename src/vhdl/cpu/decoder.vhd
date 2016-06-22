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
		O_regwrite : out std_logic;
		O_memop: out memops_t;
		O_aluop: out aluops_t;
		O_src_op1: out op1src_t;
		O_src_op2: out op2src_t
	);
end decoder;

architecture Behavioral of decoder is
begin
	process(I_clk)
		alias opcode: std_logic_vector(4 downto 0) is I_instr(6 downto 2);
		alias funct3: std_logic_vector(2 downto 0) is I_instr(14 downto 12);
		alias funct7: std_logic_vector(6 downto 0) is I_instr(31 downto 25);
		alias funct12: std_logic_vector(11 downto 0) is I_instr(31 downto 20);
		variable memop: memops_t;
		variable aluop: aluops_t;
		variable op1: op1src_t;
		variable op2: op2src_t;
	begin
		if rising_edge(I_clk) and I_en = '1' then

			O_rs1 <= I_instr(19 downto 15);
			O_rs2 <= I_instr(24 downto 20);
			O_rd <= I_instr(11 downto 7);
			O_regwrite <= '1';

			-- extract immediate value
			case opcode is
				when OP_STORE =>
					-- S-type
					O_regwrite <= '0';
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
					-- immediate carries no actual meaning for R-type instructions
					O_imm <= std_logic_vector(resize(signed(I_instr(31 downto 20)), O_imm'length));
			end case;
			

			--------------------------------------------------------
			-- determine operands and operations for ALU
			--------------------------------------------------------
			op1 := SRC_S1;
			op2 := SRC_IMM;
			aluop := ALU_TRAP;
			memop := MEMOP_NOP;
	
			case opcode is

				----------------			
				-- OP_OP
				----------------
				when OP_OP =>
					op2 := SRC_S2;
								
					case funct3 is

						when FUNC_ADD_SUB =>
							if funct7(5) = '1' then
								-- SUB
								aluop := ALU_SUB;
							else
								-- ADD
								aluop := ALU_ADD;
							end if;
				
						when FUNC_SLL =>
							aluop := ALU_SLL;

						when FUNC_SLT =>
							aluop := ALU_SLT;

						when FUNC_SLTU =>
							aluop := ALU_SLTU;

						when FUNC_XOR =>
							aluop := ALU_XOR;

						when FUNC_SRL_SRA =>
							if funct7(5) = '1' then
								-- SRA
								aluop := ALU_SRA;
							else
								-- SRL
								aluop := ALU_SRL;
							end if;

						when FUNC_OR =>
							aluop := ALU_OR;

						when FUNC_AND =>
							aluop := ALU_AND;
						
						when others =>
							null;
					
					end case;
					
				----------------
				-- OP_OPIMM
				----------------
				
				when OP_OPIMM =>
				
					case funct3 is
				
						when FUNC_ADDI =>
							aluop := ALU_ADD;
					
						when FUNC_SLTI =>
							aluop := ALU_SLT;
					
						when FUNC_SLTIU =>
							aluop := ALU_SLTU;
					
						when FUNC_XORI =>
							aluop := ALU_XOR;
					
						when FUNC_ORI =>
							aluop := ALU_OR;
					
						when FUNC_ANDI =>
							aluop := ALU_AND;
					
						when FUNC_SLLI =>
							aluop := ALU_SLL;

						when FUNC_SRLI_SRAI =>
							if funct7(5) = '1' then
								--SRAI
								aluop := ALU_SRA;
							else
								--SRLI
								aluop := ALU_SRL;
							end if;
						
						when others =>
							null;
					
					end case;
					
				----------------
				-- OP_LUI
				----------------
				when OP_LUI =>
					-- ALU should output immediate value via addition with zero
					aluop := ALU_ADD;
					O_rs1 <= R0;
				
				----------------
				-- OP_AUIPC
				----------------
				when OP_AUIPC =>
					op1 := SRC_PC;
					aluop := ALU_ADD;

				----------------
				-- OP_LOAD
				----------------				
				
				when OP_LOAD =>
					aluop := ALU_ADD;
					case funct3 is
				
						when FUNC_LB =>
							memop := MEMOP_READB;
					
						when FUNC_LH =>
							memop := MEMOP_READH;
					
						when FUNC_LW =>
							memop := MEMOP_READW;
					
						when FUNC_LBU =>
							memop := MEMOP_READBU;
					
						when FUNC_LHU =>
							memop := MEMOP_READHU;
							
						when others =>
							null;

					end case;

				----------------
				-- OP_STORE
				----------------
				
				when OP_STORE =>
					aluop := ALU_ADD;
					case funct3 is
				
						when FUNC_SB =>
							memop := MEMOP_WRITEB;
					
						when FUNC_SH =>
							memop := MEMOP_WRITEH;

						when FUNC_SW =>
							memop := MEMOP_WRITEW;
						
						when others =>
							null;

					end case;

				----------------
				-- OP_BRANCH
				----------------
				
				when OP_BRANCH =>
					op2 := SRC_S2;
				
					case funct3 is
						when FUNC_BEQ => aluop := ALU_BEQ;
						when FUNC_BNE => aluop := ALU_BNE;
						when FUNC_BLT => aluop := ALU_BLT;
						when FUNC_BGE => aluop := ALU_BGE;
						when FUNC_BLTU => aluop := ALU_BLTU;
						when FUNC_BGEU => aluop := ALU_BGEU;
						when others =>	null;
					end case;
					
				----------------
				-- OP_JAL
				----------------
				
				when OP_JAL => aluop := ALU_JAL;
				
				----------------
				-- OP_JALR
				----------------
				
				when OP_JALR => aluop := ALU_JALR;
					
				----------------
				-- OP_MISCMEM
				----------------
				
				when OP_MISCMEM => aluop := ALU_ADD; -- basically NOP FENCE instructions
				
				
				-- interrupt and trap handling via custom-0 opcode
				when OP_CUSTOM0 =>
					case funct7 is
						when "0000000" => aluop := ALU_RTI; -- "return from interrupt" instruction
						when "0000001" => aluop := ALU_ENABLEI; -- "enable interrupt" instruction
						when "0000010" => aluop := ALU_DISABLEI; -- "disable interrupt" instruction
						when "0001000" => aluop := ALU_RTT; -- "return from trap" instruction
						when "0001001" => aluop := ALU_GETTRAPRET; -- "get trap return address" instruction
						when others => null;
					end case;
			
			
				when others =>
					-- ignore unknown ops for now
					null;
			end case;
			
			O_memop <= memop;
			O_aluop <= aluop;
			O_src_op1 <= op1;
			O_src_op2 <= op2;
			
			
		end if;
	end process;

end Behavioral;