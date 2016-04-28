library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity alu is
	Port(
		I_clk: in std_logic;
		I_en: in std_logic;
		I_fop: in std_logic_vector(7 downto 0);
		I_imm: in std_logic_vector(XLEN-1 downto 0);
		I_dataS1: in std_logic_vector(XLEN-1 downto 0);
		I_dataS2: in std_logic_vector(XLEN-1 downto 0);
		I_reset: in std_logic := '0';
		O_alumemop: out std_logic_vector(2 downto 0);
		O_busy: out std_logic := '0';
		O_data: out std_logic_vector(XLEN-1 downto 0);
		O_PC: out std_logic_vector(XLEN-1 downto 0)
	);
end alu;

architecture Behavioral of alu is
	type aluops is (ALU_NOP, ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_SLT, ALU_SLTU, ALU_SLL, ALU_SRL, ALU_SRA, ALU_OP2, ALU_CYCLE, ALU_CYCLEH, ALU_INSTR, ALU_INSTRH, ALU_BEQ, ALU_BNE, ALU_BLT, ALU_BGE, ALU_BLTU, ALU_BGEU, ALU_JAL, ALU_JALR);
	signal rdcycle: std_logic_vector(63 downto 0) := X"0000000000000000";
	signal rdinstr: std_logic_vector(63 downto 0) := X"0000000000000000";
	-- program counter
	signal pc: std_logic_vector(XLEN-1 downto 0) := XLEN_ZERO;
begin
	process(I_clk)
		variable aluop: aluops := ALU_NOP;
		variable funct7: std_logic_vector(6 downto 0);
		variable funct3: std_logic_vector(2 downto 0);
		variable opcode: std_logic_vector(4 downto 0);
		variable newpc,pc4,pcimm,tmpval,op1,op2,sum: std_logic_vector(XLEN-1 downto 0);
		variable shiftcnt: std_logic_vector(4 downto 0);
		variable busy: boolean := false;
		variable sign: std_logic := '0';
		variable do_reset: boolean := false;
		variable eq,lt,ltu: boolean;
	begin

		-- increment cycle counter and check for reset on each clock
		if rising_edge(I_clk) then
			rdcycle <= std_logic_vector(unsigned(rdcycle) + 1);
			if(I_reset = '1') then
				do_reset := true;
				busy := false;
				pc <= XLEN_ZERO;
				O_PC <= XLEN_ZERO;
			else
				do_reset := false;
			end if;
		end if;
	
		-- main business here
		if rising_edge(I_clk) and I_en = '1' and not do_reset then
		
			funct7 := I_imm(11 downto 5);		
			funct3 := I_fop(7 downto 5);
			opcode := I_fop(4 downto 0);

			op1 := I_dataS1;
			op2 := I_imm;
			aluop := ALU_NOP;

			-- PC = PC + 4
			pc4 := std_logic_vector(unsigned(pc) + 4);
			pcimm := std_logic_vector(unsigned(pc) + unsigned(I_imm));
			newpc := pc4;
			
			--------------------------------------------------------
			-- first step: determine operands and operations for ALU
			--------------------------------------------------------
	
			case opcode is

				----------------			
				-- OP_OP
				----------------
				when OP_OP =>
					op2 := I_dataS2;
								
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
					aluop := ALU_OP2; -- simply pass I_imm to O_data
				
				----------------
				-- OP_AUIPC
				----------------
				when OP_AUIPC =>
					op1 := pc;
					aluop := ALU_ADD;

				----------------
				-- OP_LOAD
				----------------				
				
				when OP_LOAD =>
					aluop := ALU_ADD;
					case funct3 is
				
						when FUNC_LB =>
							O_alumemop <= MEMOP_READB;
					
						when FUNC_LH =>
							O_alumemop <= MEMOP_READH;
					
						when FUNC_LW =>
							O_alumemop <= MEMOP_READW;
					
						when FUNC_LBU =>
							O_alumemop <= MEMOP_READBU;
					
						when FUNC_LHU =>
							O_alumemop <= MEMOP_READHU;
							
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
							O_alumemop <= MEMOP_WRITEB;
					
						when FUNC_SH =>
							O_alumemop <= MEMOP_WRITEH;

						when FUNC_SW =>
							O_alumemop <= MEMOP_WRITEW;
						
						when others =>
							null;

					end case;

				----------------
				-- OP_BRANCH
				----------------
				
				when OP_BRANCH =>
					op2 := I_dataS2;
				
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
				-- OP_SYSTEM
				----------------
				
				when OP_SYSTEM =>
					case I_imm(11 downto 0) is
						when "110000000000" => aluop := ALU_CYCLE;  -- RDCYCLE
						when "110010000000" => aluop := ALU_CYCLEH; -- RDCYCLEH
						when "110000000001" => aluop := ALU_CYCLE;  -- RDTIME
						when "110010000001" => aluop := ALU_CYCLEH; -- RDTIMEH
						when "110000000010" => aluop := ALU_INSTR;  -- RDINSTRET
						when "110010000010" => aluop := ALU_INSTRH; -- RDINSTRETH
						when others => null;
					end case;
				
			
				when others =>
					-- ignore unknown ops for now
					null;
			end case;
			
			-------------------------------
			-- second step: generate output
			-------------------------------
			
			eq := op1 = op2;
			lt := signed(op1) < signed(op2);
			ltu := unsigned(op1) < unsigned(op2);
			sum := std_logic_vector(unsigned(op1) + unsigned(op2));

			case aluop is
		
				when ALU_ADD =>
					O_data <= sum;
				
				when ALU_SUB =>
					O_data <= std_logic_vector(unsigned(op1) - unsigned(op2));
					
				when ALU_AND =>
					O_data <= op1 and op2;
				
				when ALU_OR =>
					O_data <= op1 or op2;
					
				when ALU_XOR =>
					O_data <= op1 xor op2;
				
				when ALU_SLT =>
					O_data <= XLEN_ZERO;
					if lt then
						O_data(0) <= '1';
					end if;
				
				when ALU_SLTU =>
					O_data <= XLEN_ZERO;
					if ltu then
						O_data(0) <= '1';
					end if;
				
				when ALU_SLL | ALU_SRL | ALU_SRA =>
					if not busy then
						busy := true;
						tmpval := op1;
						shiftcnt := op2(4 downto 0);
					elsif shiftcnt /= "00000" then
						case aluop is
							when ALU_SLL => tmpval := tmpval(30 downto 0) & '0';
							when others =>
							if aluop = ALU_SRL then
								sign := '0';
							else
								sign := tmpval(31);
							end if;
							tmpval := sign & tmpval(31 downto 1);
						end case;
						shiftcnt := std_logic_vector(unsigned(shiftcnt) - 1);
					end if;
					
					if shiftcnt = "00000" then
						busy := false;
						O_data <= tmpval;
					end if;
					
				when ALU_OP2 =>
					O_data <= op2;
				
				when ALU_CYCLE =>
					O_data <= rdcycle(31 downto 0);
				
				when ALU_CYCLEH =>
					O_data <= rdcycle(63 downto 32);
				
				when ALU_INSTR =>
					O_data <= rdinstr(31 downto 0);
				
				when ALU_INSTRH =>
					O_data <= rdinstr(63 downto 32);
					
				when ALU_BEQ =>
					if eq then
						newpc := pcimm;
					end if;
					
				when ALU_BNE =>
					if not eq then
						newpc := pcimm;
					end if;
					
				when ALU_BLT =>
					if lt then
						newpc := pcimm;
					end if;
					
				when ALU_BGE =>
					if not lt then
						newpc := pcimm;
					end if;

				when ALU_BLTU =>
					if ltu then
						newpc := pcimm;
					end if;
					
				when ALU_BGEU =>
					if not ltu then
						newpc := pcimm;
					end if;

				when ALU_JAL =>
					newpc := pcimm;
					O_data <= pc4;
				
				when ALU_JALR =>
					newpc := sum; --std_logic_vector(unsigned(I_dataS1) + unsigned(I_imm));
					newpc(0) := '0';
					O_data <= pc4;

			
				when ALU_NOP =>
					null;
			end case;
			
			
			if busy then
				O_busy <= '1';
			else
				O_busy <= '0';
				-- we processed an instruction, increase counters
				rdinstr <= std_logic_vector(unsigned(rdinstr) + 1);
				pc <= newpc;
				O_pc <= newpc;
			end if;
			
		
		end if;
	end process;

end Behavioral;