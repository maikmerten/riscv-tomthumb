library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity alu is
	Port(
		I_clk: in std_logic;
		I_en: in std_logic;
		I_imm: in std_logic_vector(XLEN-1 downto 0);
		I_dataS1: in std_logic_vector(XLEN-1 downto 0);
		I_dataS2: in std_logic_vector(XLEN-1 downto 0);
		I_reset: in std_logic := '0';
		I_aluop: in aluops_t;
		I_src_op1: in op1src_t;
		I_src_op2: in op2src_t;
		I_enter_interrupt: in boolean := false;
		O_busy: out std_logic := '0';
		O_data: out std_logic_vector(XLEN-1 downto 0);
		O_PC: out std_logic_vector(XLEN-1 downto 0);
		O_leave_interrupt: out boolean := false
	);
end alu;

architecture Behavioral of alu is
	signal rdcycle: std_logic_vector(63 downto 0) := X"0000000000000000";
	signal rdinstr: std_logic_vector(63 downto 0) := X"0000000000000000";
	-- program counter
	signal pc: std_logic_vector(XLEN-1 downto 0) := RESET_VECTOR;
	-- program counter copy (used for "return from interrupt (rti)" instruction)
	signal pc_rti: std_logic_vector(XLEN-1 downto 0) := RESET_VECTOR;
begin
	process(I_clk)
		variable newpc,pc4,pcimm,tmpval,op1,op2,sum: std_logic_vector(XLEN-1 downto 0);
		variable shiftcnt: std_logic_vector(4 downto 0);
		variable busy: boolean := false;
		variable do_reset: boolean := false;
		variable eq,lt,ltu: boolean;
	begin
	
		O_pc <= pc;
	
		if rising_edge(I_clk) then

			-- increment cycle counter each clock
			rdcycle <= std_logic_vector(unsigned(rdcycle) + 1);

			-- check for reset
			if(I_reset = '1') then
				do_reset := true;
				busy := false;
				pc <= RESET_VECTOR;
			else
				do_reset := false;
			end if;
			
			-- check if we enter an interrupt handler and need to
			-- save the pc and output the interrupt vector
			O_leave_interrupt <= false;
			if(I_enter_interrupt) then
				pc_rti <= pc;
				pc <= INTERRUPT_VECTOR; -- interrupt service routine expected there
			end if;

			-- select sources for operands
			op1 := I_dataS1;
			if I_src_op1 = SRC_PC then
				op1 := pc;
			end if;
			
			op2 := I_dataS2;
			if I_src_op2 = SRC_IMM then
				op2 := I_imm;
			end if;
			
			-- main business here
			if I_en = '1' and not do_reset and not I_enter_interrupt then
			
				-- PC = PC + 4
				pc4 := std_logic_vector(unsigned(pc) + 4);
				pcimm := std_logic_vector(unsigned(pc) + unsigned(I_imm));
				newpc := pc4;
			
				-------------------------------
				-- ALU core operations
				-------------------------------
			
				eq := op1 = op2;
				lt := signed(op1) < signed(op2);
				ltu := unsigned(op1) < unsigned(op2);
				sum := std_logic_vector(unsigned(op1) + unsigned(op2));

				case I_aluop is
		
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
							case I_aluop is
								when ALU_SLL => tmpval := tmpval(30 downto 0) & '0';
								when ALU_SRL => tmpval := '0' & tmpval(31 downto 1);
								when others => tmpval := tmpval(31) & tmpval(31 downto 1);
							end case;
							shiftcnt := std_logic_vector(unsigned(shiftcnt) - 1);
						else
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
						newpc := sum(31 downto 1) & '0';
						O_data <= pc4;

					when ALU_RTI =>
						newpc := pc_rti;
						O_leave_interrupt <= true;
			
					when ALU_NOP =>
						null;
				end case;
			
			
				if busy then
					O_busy <= '1';
				else
					O_busy <= '0';
					-- we processed an instruction, increase instruction counter
					rdinstr <= std_logic_vector(unsigned(rdinstr) + 1);
					pc <= newpc;
				end if;
		
			end if;
		end if;
	end process;

end Behavioral;