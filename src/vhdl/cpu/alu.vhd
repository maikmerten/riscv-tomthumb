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
		O_in_interrupt: out boolean := false;
		O_interrupt_enabled: out boolean := false;
		O_in_trap: out boolean := false
	);
end alu;

architecture Behavioral of alu is
	-- program counter
	signal pc: std_logic_vector(XLEN-1 downto 0) := RESET_VECTOR;
	-- program counter copy (used for "return from interrupt (rti)" instruction)
	signal pc_rti: std_logic_vector(XLEN-1 downto 0) := RESET_VECTOR;
	signal in_interrupt: boolean := false;
	signal interrupt_enabled: boolean := false;
	-- program counter copy (used for "return from trap (rtt)" instruction)
	signal pc_rtt: std_logic_vector(XLEN-1 downto 0) := RESET_VECTOR;
	signal in_trap: boolean := false;
begin
	process(I_clk)
		variable newpc,pc4,pcimm,tmpval,op1,op2,sum: std_logic_vector(XLEN-1 downto 0);
		variable shiftcnt: std_logic_vector(4 downto 0);
		variable busy: boolean := false;
		variable do_reset: boolean := false;
		variable eq,lt,ltu: boolean;
	begin
	
		O_pc <= pc;
		O_in_interrupt <= in_interrupt;
		O_interrupt_enabled <= interrupt_enabled;
		O_in_trap <= in_trap;
	
		if rising_edge(I_clk) then

			-- check for reset
			if(I_reset = '1') then
				do_reset := true;
				busy := false;
				pc <= RESET_VECTOR;
				interrupt_enabled <= false;
				in_interrupt <= false;
				in_trap <= false;
			else
				do_reset := false;
			end if;
			
			-- check if we enter an interrupt handler and need to
			-- save the pc and output the interrupt vector
			if(I_enter_interrupt) then
				pc_rti <= pc;
				pc <= INTERRUPT_VECTOR; -- interrupt service routine expected there
				in_interrupt <= true;
			end if;

			-- select sources for operands
			case I_src_op1 is
				when SRC_S1 => op1 := I_dataS1;
				when SRC_PC => op1 := pc;
			end case;

			case I_src_op2 is
				when SRC_S2 => op2 := I_dataS2;
				when SRC_IMM => op2 := I_imm;
			end case;
			
			
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
						
					when ALU_ENABLEI =>
						interrupt_enabled <= true;
						
					when ALU_DISABLEI =>
						interrupt_enabled <= false;

					when ALU_RTI =>
						newpc := pc_rti;
						in_interrupt <= false;
					
					when ALU_TRAP =>
						-- enter a trap
						newpc := TRAP_VECTOR;
						pc_rtt <= pc4; -- return to succeeding instruction
						in_trap <= true;
						
					when ALU_RTT =>
						-- return from trap
						newpc := pc_rtt; -- jump to trap retrun address
						in_trap <= false;
					
					when ALU_GETTRAPRET =>
						-- retrieve return address for trap
						O_data <= pc_rtt;
			
				end case;
			
			
				if busy then
					O_busy <= '1';
				else
					O_busy <= '0';
					pc <= newpc;
				end if;
		
			end if;
		end if;
	end process;

end Behavioral;