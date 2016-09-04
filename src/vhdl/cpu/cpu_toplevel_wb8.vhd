library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;
use work.mux_types_pkg.all;

entity cpu_toplevel_wb8 is
	Port(
		-- wired to outside world, RAM, devices etc.
		-- naming of signals taken from Wishbone B4 spec
		CLK_I: in std_logic := '0';
		ACK_I: in std_logic := '0';
		DAT_I: in std_logic_vector(7 downto 0);
		RST_I: in std_logic := '0';
		ADR_O: out std_logic_vector(31 downto 0);
		DAT_O: out std_logic_vector(7 downto 0);
		CYC_O: out std_logic := '0';
		STB_O: out std_logic := '0';
		WE_O: out std_logic := '0';
		-- interrupt is not a standard Wishbone signal
		I_interrupt: in std_logic := '0'
	);
end cpu_toplevel_wb8;


architecture Behavioral of cpu_toplevel_wb8 is
	
	signal alu_out: std_logic_vector(XLEN-1 downto 0);
	signal alu_memop: memops_t;
	signal alu_busy: std_logic := '0';
	signal alu_pc: std_logic_vector(XLEN-1 downto 0);
	signal alu_in_interrupt: boolean := false;
	signal alu_interrupt_enabled: boolean := false;
	signal alu_in_trap: boolean := false;
	signal alu_lt: boolean := false;
	signal alu_ltu: boolean := false;
	signal alu_zero: boolean := false;
	
	signal ctrl_pcuen: std_logic := '0';
	signal ctrl_decen: std_logic := '0';
	signal ctrl_aluen: std_logic := '0';
	signal ctrl_memen: std_logic := '0';
	signal ctrl_regen: std_logic := '0';
	signal ctrl_pcuop: pcuops_t;
	signal ctrl_regop: regops_t;
	signal ctrl_memop: memops_t;
	signal ctrl_mux_alu_dat1_sel: integer range 0 to MUX_ALU_DAT1_PORTS-1;
	signal ctrl_mux_alu_dat2_sel: integer range 0 to MUX_ALU_DAT2_PORTS-1;
	signal ctrl_mux_bus_addr_sel: integer range 0 to MUX_BUS_ADDR_PORTS-1;
	signal ctrl_mux_reg_data_sel: integer range 0 to MUX_REG_DATA_PORTS-1;
	signal ctrl_reset: std_logic := '0';
	signal ctrl_enter_interrupt: boolean := false;

	signal dec_memop: memops_t;
	signal dec_rs1: std_logic_vector(4 downto 0);
	signal dec_rs2: std_logic_vector(4 downto 0);
	signal dec_rd: std_logic_vector(4 downto 0);
	signal dec_regwrite: std_logic := '0';
	signal dec_imm: std_logic_vector(XLEN-1 downto 0);
	signal dec_aluop: aluops_t;
	signal dec_src_op1: op1src_t;
	signal dec_src_op2: op2src_t;
	signal dec_opcode: std_logic_vector(4 downto 0);
	signal dec_funct3: std_logic_vector(2 downto 0);
	signal dec_funct7: std_logic_vector(6 downto 0);
		
	signal bus_busy: std_logic := '0';
	signal bus_data: std_logic_vector(XLEN-1 downto 0);

	signal mux_alu_dat1_input: mux_input_t(MUX_ALU_DAT1_PORTS-1 downto 0)(XLEN-1 downto 0);
	signal mux_alu_dat1_sel: integer range 0 to MUX_ALU_DAT1_PORTS-1;
	signal mux_alu_dat1_output: std_logic_vector(XLEN-1 downto 0);

	signal mux_alu_dat2_input: mux_input_t(MUX_ALU_DAT2_PORTS-1 downto 0)(XLEN-1 downto 0);
	signal mux_alu_dat2_sel: integer range 0 to MUX_ALU_DAT2_PORTS-1;
	signal mux_alu_dat2_output: std_logic_vector(XLEN-1 downto 0);	
	
	signal mux_bus_addr_input: mux_input_t(MUX_BUS_ADDR_PORTS-1 downto 0)(XLEN-1 downto 0);
	signal mux_bus_addr_sel: integer range 0 to MUX_BUS_ADDR_PORTS-1;
	signal mux_bus_addr_output: std_logic_vector(XLEN-1 downto 0);
	
	signal mux_reg_data_input: mux_input_t(MUX_REG_DATA_PORTS-1 downto 0)(XLEN-1 downto 0);
	signal mux_reg_data_sel: integer range 0 to MUX_REG_DATA_PORTS-1;
	signal mux_reg_data_output: std_logic_vector(XLEN-1 downto 0);
	
	signal pcu_out: std_logic_vector(XLEN-1 downto 0);
	
	signal reg_dataS1: std_logic_vector(XLEN-1 downto 0);	
	signal reg_dataS2: std_logic_vector(XLEN-1 downto 0);
	
	signal en: std_logic := '1';

begin
	
	mux_alu_dat1_input(MUX_ALU_DAT1_PORT_S1) <= reg_dataS1;
	mux_alu_dat1_input(MUX_ALU_DAT1_PORT_PC) <= alu_pc;
	
	mux_alu_dat2_input(MUX_ALU_DAT2_PORT_S2) <= reg_dataS2;
	mux_alu_dat2_input(MUX_ALU_DAT2_PORT_IMM) <= dec_imm;
	mux_alu_dat2_input(MUX_ALU_DAT2_PORT_INSTLEN) <= X"00000004";
	
	mux_bus_addr_input(MUX_BUS_ADDR_PORT_ALU) <= alu_out;
	mux_bus_addr_input(MUX_BUS_ADDR_PORT_PC) <= alu_pc;
	
	mux_reg_data_input(MUX_REG_DATA_PORT_ALU) <= alu_out;
	mux_reg_data_input(MUX_REG_DATA_PORT_BUS) <= bus_data;
	mux_reg_data_input(MUX_REG_DATA_PORT_IMM) <= dec_imm;
	mux_reg_data_input(MUX_REG_DATA_PORT_PC) <= alu_pc;


	alu_instance: entity work.alu port map(
		I_clk => CLK_I,
		I_en => ctrl_aluen,
		I_imm => dec_imm, -- TODO: remove later on, still neede for PC computation
		I_reset => RST_I,
		I_dataS1 => mux_alu_dat1_output,
		I_dataS2 => mux_alu_dat2_output,
		I_aluop => dec_aluop,
		I_enter_interrupt => ctrl_enter_interrupt,
		O_busy => alu_busy,
		O_data => alu_out,
		O_PC => alu_pc,
		O_in_interrupt => alu_in_interrupt,
		O_interrupt_enabled => alu_interrupt_enabled,
		O_in_trap => alu_in_trap,
		O_lt => alu_lt,
		O_ltu => alu_ltu,
		O_zero => alu_zero
	);

	bus_instance: entity work.bus_wb8 port map(
		I_en => ctrl_memen,
		I_op => ctrl_memop,
		I_addr => mux_bus_addr_output,
		I_data => reg_dataS2,
		O_data => bus_data,
		O_busy => bus_busy,
		
		-- wishbone signals
		CLK_I => CLK_I,
		ACK_I => ACK_I,
		DAT_I => DAT_I,
		RST_I => RST_I,
		ADR_O => ADR_O,
		DAT_O => DAT_O,
		CYC_O => CYC_O,
		STB_O => STB_O,
		WE_O => WE_O
	);	
	
	ctrl_instance: entity work.control port map(
		I_clk => CLK_I,
		I_en => en,
		I_reset => RST_I,
		I_memop => dec_memop,
		I_regwrite => dec_regwrite,
		I_busy => (alu_busy = '1' or bus_busy = '1'),
		I_interrupt => I_interrupt,
		I_in_interrupt => alu_in_interrupt,
		I_interrupt_enabled => alu_interrupt_enabled,
		I_in_trap => alu_in_trap,
		I_src_op1 => dec_src_op1,
		I_src_op2 => dec_src_op2,
		I_opcode => dec_opcode,
		I_funct3 => dec_funct3,
		I_funct7 => dec_funct7,
		O_decen => ctrl_decen,
		O_aluen => ctrl_aluen,
		O_memen => ctrl_memen,
		O_regen => ctrl_regen,
		O_regop => ctrl_regop,
		O_memop => ctrl_memop,
		O_mux_alu_dat1_sel => ctrl_mux_alu_dat1_sel,
		O_mux_alu_dat2_sel => ctrl_mux_alu_dat2_sel,
		O_mux_bus_addr_sel => ctrl_mux_bus_addr_sel,
		O_mux_reg_data_sel => ctrl_mux_reg_data_sel,
		O_enter_interrupt => ctrl_enter_interrupt
	);
	
	dec_instance: entity work.decoder port map(
		I_clk => CLK_I,
		I_en => ctrl_decen,
		I_instr => bus_data,
		O_rs1 => dec_rs1,
		O_rs2 => dec_rs2,
		O_rd => dec_rd,
		O_imm => dec_imm,
		O_regwrite => dec_regwrite,
		O_memop => dec_memop,
		O_aluop => dec_aluop,
		O_src_op1 => dec_src_op1,
		O_src_op2 => dec_src_op2,
		O_opcode => dec_opcode,
		O_funct3 => dec_funct3,
		O_funct7 => dec_funct7
	);
	
	mux_alu_dat1: entity work.mux
	generic map(
		PORTS => MUX_ALU_DAT1_PORTS
	)
	port map(
		I_inputs => mux_alu_dat1_input,
		I_sel => ctrl_mux_alu_dat1_sel,
		O_output => mux_alu_dat1_output
	);
	
	mux_alu_dat2: entity work.mux
	generic map(
		PORTS => MUX_ALU_DAT2_PORTS
	)
	port map(
		I_inputs => mux_alu_dat2_input,
		I_sel => ctrl_mux_alu_dat2_sel,
		O_output => mux_alu_dat2_output
	);
	
	mux_bus_addr: entity work.mux
	generic map(
		PORTS => MUX_BUS_ADDR_PORTS
	)
	port map(
		I_inputs => mux_bus_addr_input,
		I_sel => ctrl_mux_bus_addr_sel,
		O_output => mux_bus_addr_output
	);
	
	mux_reg_data: entity work.mux
	generic map(
		PORTS => MUX_REG_DATA_PORTS
	)
	port map(
		I_inputs => mux_reg_data_input,
		I_sel => ctrl_mux_reg_data_sel,
		O_output => mux_reg_data_output
	);
	
	pcu_instance: entity work.pcu port map(
		I_clk => CLK_I,
		I_en => ctrl_pcuen,
		I_reset => RST_I,
		I_op => ctrl_pcuop,
		I_data => alu_out,
		O_data => pcu_out
	);
	
	
	reg_instance: entity work.registers port map(
		I_clk => CLK_I,
		I_en => ctrl_regen,
		I_op => ctrl_regop,
		I_selS1 => dec_rs1,
		I_selS2 => dec_rs2,
		I_selD => dec_rd,
		I_data => mux_reg_data_output,
		O_dataS1 => reg_dataS1,
		O_dataS2 => reg_dataS2
	);
	
	

	process(CLK_I)
	begin

	end process;
end Behavioral;