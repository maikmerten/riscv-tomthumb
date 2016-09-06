library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity control is
	Port(
		I_clk: in std_logic;
		I_en: in std_logic;
		I_reset: in std_logic;
		I_busy: in boolean;
		I_interrupt: in std_logic; -- from outside world
		I_opcode: in std_logic_vector(4 downto 0);
		I_funct3: in std_logic_vector(2 downto 0);
		I_funct7: in std_logic_vector(6 downto 0);
		I_lt: in boolean := false;
		I_ltu: in boolean := false;
		I_zero: in boolean := false;
		-- enable signals for components
		O_aluen: out std_logic;
		O_decen: out std_logic;
		O_memen: out std_logic;
		O_pcuen: out std_logic;
		O_regen: out std_logic;
		-- op selection for devices
		O_aluop: out aluops_t;
		O_memop: out memops_t;
		O_pcuop: out pcuops_t;
		O_regop: out regops_t;
		-- muxer selection signals
		-- TODO: currently the ALU data muxers are directly controlled by the decoder
		O_mux_alu_dat1_sel: out integer range 0 to MUX_ALU_DAT1_PORTS-1;
		O_mux_alu_dat2_sel: out integer range 0 to MUX_ALU_DAT2_PORTS-1;
		O_mux_bus_addr_sel: out integer range 0 to MUX_BUS_ADDR_PORTS-1;
		O_mux_reg_data_sel: out integer range 0 to MUX_REG_DATA_PORTS-1
	);
end control;

architecture Behavioral of control is
	type states_t is (RESET, FETCH, DECODE, REGREAD, CUSTOM0, JAL, JAL2, JALR, JALR2, LUI, AUIPC, OP, OPIMM, STORE, STORE2, LOAD, LOAD2, BRANCH, BRANCH2, TRAP, REGWRITEBUS, REGWRITEALU, PCNEXT, PCREGIMM, PCIMM, PCUPDATE);
begin


	
	process(I_clk, I_en, I_reset, I_busy, I_interrupt, I_opcode, I_funct3, I_funct7, I_lt, I_ltu, I_zero)
		variable nextstate,state: states_t := RESET;
		variable in_interrupt, in_trap: boolean := false;
	begin
	
		-- run on falling edite to ensure that all control signals arrive in time
		-- for the controlled units, which run on the rising edge
		if falling_edge(I_clk) and I_en = '1' then
		
			O_aluen <= '0';
			O_decen <= '0';
			O_pcuen <= '0';
			O_regen <= '0';
			O_memen <= '0';
		
			O_aluop <= ALU_ADD;
			O_pcuop <= PCU_OUTPC;
			O_regop <= REGOP_READ;
			O_memop <= MEMOP_READB;
			
			O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_S1;
			O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_S2;
			O_mux_bus_addr_sel <= MUX_BUS_ADDR_PORT_ALU; -- address by default from ALU
			O_mux_reg_data_sel <= MUX_REG_DATA_PORT_ALU; -- data by default from ALU
			
			-- only forward state machine if every component is finished
			if not I_busy then
				state := nextstate;
			end if;
			
		
			case state is
				when RESET =>
					nextstate := FETCH;
				
				when FETCH =>
					O_memen <= '1';
					O_memop <= MEMOP_READW;
					O_mux_bus_addr_sel <= MUX_BUS_ADDR_PORT_PC;
					nextstate := DECODE;
				
				when DECODE =>
					O_decen <= '1';
					nextstate := REGREAD;

				when REGREAD =>
					O_regen <= '1';
					O_regop <= REGOP_READ;
					case I_opcode is
						when OP_OP => 			nextstate := OP;
						when OP_OPIMM => 		nextstate := OPIMM;
						when OP_LOAD =>		nextstate := LOAD;
						when OP_STORE =>		nextstate := STORE;
						when OP_JAL =>			nextstate := JAL;
						when OP_JALR => 		nextstate := JALR;
						when OP_BRANCH =>		nextstate := BRANCH;
						when OP_LUI =>			nextstate := LUI;
						when OP_AUIPC =>		nextstate := AUIPC;
						when OP_CUSTOM0 => 	nextstate := CUSTOM0;
						when OP_MISCMEM =>	nextstate := PCNEXT; -- NOP, fetch next instruction
						when others => 		nextstate := TRAP;	-- trap OP_SYSTEM or unknown opcodes
					end case;
				
				when OP =>
					O_aluen <= '1';
					O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_S1;
					O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_S2;
					case I_funct3 is
						when FUNC_ADD_SUB =>
							if I_funct7(5) = '0' then
								O_aluop <= ALU_ADD;
							else
								O_aluop <= ALU_SUB;
							end if;
						when FUNC_SLL => 			O_aluop <= ALU_SLL;
						when FUNC_SLT => 			O_aluop <= ALU_SLT;
						when FUNC_SLTU => 		O_aluop <= ALU_SLTU;
						when FUNC_XOR	=> 		O_aluop <= ALU_XOR;
						when FUNC_SRL_SRA =>
							if I_funct7(5) = '0' then
								O_aluop <= ALU_SRL;
							else
								O_aluop <= ALU_SRA;
							end if;
						when FUNC_OR => 			O_aluop <= ALU_OR;
						when FUNC_AND => 			O_aluop <= ALU_AND;
						when others => null;
					end case;
					nextstate := REGWRITEALU;
				
				when OPIMM =>
					O_aluen <= '1';
					O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_S1;
					O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_IMM;
					case I_funct3 is
						when FUNC_ADDI =>			O_aluop <= ALU_ADD;
						when FUNC_SLLI =>			O_aluop <= ALU_SLL;
						when FUNC_SLTI =>			O_aluop <= ALU_SLT;
						when FUNC_SLTIU =>		O_aluop <= ALU_SLTU;
						when FUNC_XORI =>			O_aluop <= ALU_XOR;
						when FUNC_SRLI_SRAI =>
							if I_funct7(5) = '0' then
								O_aluop <= ALU_SRL;
							else
								O_aluop <= ALU_SRA;
							end if;
						when FUNC_ORI =>			O_aluop <= ALU_OR;
						when FUNC_ANDI =>			O_aluop <= ALU_AND;
						when others => null;
					end case;
					nextstate := REGWRITEALU;
				
				when LOAD =>
					-- compute load address on ALU
					O_aluen <= '1';
					O_aluop <= ALU_ADD;
					O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_S1;
					O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_IMM;
					nextstate := LOAD2;
				
				when LOAD2 =>
					O_memen <= '1';
					O_mux_bus_addr_sel <= MUX_BUS_ADDR_PORT_ALU;
					case I_funct3 is
						when FUNC_LB =>		O_memop <= MEMOP_READB;
						when FUNC_LH =>		O_memop <= MEMOP_READH;
						when FUNC_LW =>		O_memop <= MEMOP_READW;
						when FUNC_LBU =>		O_memop <= MEMOP_READBU;
						when FUNC_LHU =>		O_memop <= MEMOP_READHU;
						when others => null;
					end case;
					nextstate := REGWRITEBUS;
					
				
				when STORE =>
					-- compute store address on ALU
					O_aluen <= '1';
					O_aluop <= ALU_ADD;
					O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_S1;
					O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_IMM;
					nextstate := STORE2;
				
				when STORE2 =>
					O_memen <= '1';
					O_mux_bus_addr_sel <= MUX_BUS_ADDR_PORT_ALU;
					case I_funct3 is
						when FUNC_SB =>		O_memop <= MEMOP_WRITEB;
						when FUNC_SH =>		O_memop <= MEMOP_WRITEH;
						when FUNC_SW =>		O_memop <= MEMOP_WRITEW;
						when others => null;
					end case;
					nextstate := PCNEXT;
				
				when JAL =>
					-- compute return address on ALU
					O_aluen <= '1';
					O_aluop <= ALU_ADD;
					O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_PC;
					O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_INSTLEN;
					nextstate := JAL2;
				
				when JAL2 =>
					-- write computed return address to register file
					O_regen <= '1';
					O_regop <= REGOP_WRITE;
					O_mux_reg_data_sel <= MUX_REG_DATA_PORT_ALU;
					nextstate := PCIMM;
				
				when JALR =>
					-- compute return address on ALU
					O_aluen <= '1';
					O_aluop <= ALU_ADD;
					O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_PC;
					O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_INSTLEN;
					nextstate := JALR2;
				
				when JALR2 =>
					-- write computed return address to register file
					O_regen <= '1';
					O_regop <= REGOP_WRITE;
					O_mux_reg_data_sel <= MUX_REG_DATA_PORT_ALU;
					nextstate := PCREGIMM;
				
				when BRANCH =>
					-- use ALU to compute flags
					O_aluen <= '1';
					O_aluop <= ALU_SUB;
					O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_S1;
					O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_S2;
					nextstate := BRANCH2;
					
				when BRANCH2 =>
					-- make branch decision by looking at flags
					nextstate := PCNEXT; -- by default, don't branch
					case I_funct3 is
						when FUNC_BEQ =>
							if I_zero then
								nextstate := PCIMM;
							end if;
						
						when FUNC_BNE =>
							if not I_zero then
								nextstate := PCIMM;
							end if;
							
						when FUNC_BLT =>
							if I_lt then
								nextstate := PCIMM;
							end if;
						
						when FUNC_BGE =>
							if not I_lt then
								nextstate := PCIMM;
							end if;

						when FUNC_BLTU =>
							if I_ltu then
								nextstate := PCIMM;
							end if;
						
						when FUNC_BGEU =>
							if not I_ltu then
								nextstate := PCIMM;
							end if;
						
						when others => null;
					end case;
				
				when LUI =>
					O_regen <= '1';
					O_regop <= REGOP_WRITE;
					O_mux_reg_data_sel <= MUX_REG_DATA_PORT_IMM;
					nextstate := PCNEXT;
				
				when AUIPC =>
					-- compute PC + IMM on ALU
					O_aluen <= '1';
					O_aluop <= ALU_ADD;
					O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_PC;
					O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_IMM;
					nextstate := REGWRITEALU;
					
				
				when CUSTOM0 =>
					-- TODO: implement custom instructions for interrupt and trap handling
					nextstate := PCNEXT;
					
				when TRAP =>
					-- TODO: implement trap handling
					nextstate := PCNEXT;
				
				when REGWRITEBUS =>
					O_regen <= '1';
					O_regop <= REGOP_WRITE;
					O_mux_reg_data_sel <= MUX_REG_DATA_PORT_BUS;
					nextstate := PCNEXT;
				
				when REGWRITEALU =>
					O_regen <= '1';
					O_regop <= REGOP_WRITE;
					O_mux_reg_data_sel <= MUX_REG_DATA_PORT_ALU;
					nextstate := PCNEXT;
				
				when PCNEXT =>
					-- compute new value for PC: PC + INST_LEN
					O_aluen <= '1';
					O_aluop <= ALU_ADD;
					O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_PC;
					O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_INSTLEN;
					nextstate := PCUPDATE;
				
				when PCREGIMM =>
					-- compute new value for PC: S1 + IMM;
					O_aluen <= '1';
					O_aluop <= ALU_ADD;
					O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_S1;
					O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_IMM;
					nextstate := PCUPDATE;
				
				when PCIMM =>
					-- compute new value for PC: PC + IMM;
					O_aluen <= '1';
					O_aluop <= ALU_ADD;
					O_mux_alu_dat1_sel <= MUX_ALU_DAT1_PORT_PC;
					O_mux_alu_dat2_sel <= MUX_ALU_DAT2_PORT_IMM;
					nextstate := PCUPDATE;
				
				when PCUPDATE =>
					O_pcuen <= '1';
					O_pcuop <= PCU_SETPC;
					nextstate := FETCH;
				

			end case;
		
		
			if I_reset = '1' then
				state := RESET;
				nextstate := RESET;
			end if;
		
		end if;
	end process;

	
end Behavioral;