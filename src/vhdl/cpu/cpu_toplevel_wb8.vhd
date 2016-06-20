library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

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

	component alu
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
			O_leave_interrupt: out boolean := false;
			O_enter_trap: out boolean := false;
			O_leave_trap: out boolean := false
		);
	end component;
	
	component bus_wb8
		Port(
			-- wired to CPU core
			I_en: in std_logic;
			I_op: in memops_t; -- memory opcodes
			I_iaddr: in std_logic_vector(31 downto 0); -- instruction address, provided by PCU
			I_daddr: in std_logic_vector(31 downto 0); -- data address, provided by ALU
			I_data: in std_logic_vector(31 downto 0); -- data to be stored on write ops
			I_mem_imem: in std_logic := '0'; -- denotes if instruction memory is accessed (signal from control unit)
			O_data : out std_logic_vector(31 downto 0);
			O_busy: out std_logic := '0';

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
			WE_O: out std_logic := '0'
		);	
	end component;
	

	component control
		Port(
			I_clk: in std_logic;
			I_en: in std_logic;
			I_reset: in std_logic;
			I_regwrite: in std_logic;
			I_alubusy: in std_logic;
			I_membusy: in std_logic;
			I_memop: in memops_t; -- from decoder
			I_interrupt: in std_logic; -- from outside world
			I_leave_interrupt: in boolean; -- from ALU
			I_enter_trap: in boolean; -- from ALU
			I_leave_trap: in boolean; -- from ALU
			-- enable signals for components
			O_decen: out std_logic;
			O_aluen: out std_logic;
			O_memen: out std_logic;
			O_regen: out std_logic;
			-- op selection for devices
			O_regop: out regops_t;
			O_memop: out memops_t;
			O_mem_imem: out std_logic; -- 1: operation on instruction memory, 0: on data memory
			-- interrupt handling
			O_enter_interrupt: out boolean := false
		);	
	end component;
	
	component decoder
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
	end component;
	
	
	component registers
		Port(
			I_clk: in std_logic;
			I_en: in std_logic;
			I_op: in regops_t;
			I_selS1: in std_logic_vector(4 downto 0);
			I_selS2: in std_logic_vector(4 downto 0);
			I_selD: in std_logic_vector(4 downto 0);
			I_dataAlu: in std_logic_vector(XLEN-1 downto 0);
			I_dataMem: in std_logic_vector(XLEN-1 downto 0);
			O_dataS1: out std_logic_vector(XLEN-1 downto 0);
			O_dataS2: out std_logic_vector(XLEN-1 downto 0)
		);
	end component;
	
	
	signal alu_out: std_logic_vector(XLEN-1 downto 0);
	signal alu_memop: memops_t;
	signal alu_busy: std_logic := '0';
	signal alu_pc: std_logic_vector(XLEN-1 downto 0);
	signal alu_leave_interrupt: boolean := false;
	signal alu_enter_trap: boolean := false;
	signal alu_leave_trap: boolean := false;
	
	
	signal ctrl_pcuen: std_logic := '0';
	signal ctrl_decen: std_logic := '0';
	signal ctrl_aluen: std_logic := '0';
	signal ctrl_memen: std_logic := '0';
	signal ctrl_regen: std_logic := '0';
	signal ctrl_regop: regops_t;
	signal ctrl_memop: memops_t;
	signal ctrl_mem_imem: std_logic := '0';
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
		
	signal inv_clk: std_logic;
	
	signal bus_busy: std_logic := '0';
	signal bus_data: std_logic_vector(XLEN-1 downto 0);

	signal reg_dataS1: std_logic_vector(XLEN-1 downto 0);	
	signal reg_dataS2: std_logic_vector(XLEN-1 downto 0);
	
	signal en: std_logic := '1';

begin
	
	-- inverted clock for control unit to ensure that all control
	-- signals arive in time for the controlled units. Effectively
	-- makes control unit work on falling edge, all other units on
	-- rising edge
	inv_clk <= not CLK_I;

	alu_instance: alu port map(
		I_clk => CLK_I,
		I_en => ctrl_aluen,
		I_imm => dec_imm,
		I_reset => RST_I,
		I_dataS1 => reg_dataS1,
		I_dataS2 => reg_dataS2,
		I_aluop => dec_aluop,
		I_src_op1 => dec_src_op1,
		I_src_op2 => dec_src_op2,
		I_enter_interrupt => ctrl_enter_interrupt,
		O_busy => alu_busy,
		O_data => alu_out,
		O_PC => alu_pc,
		O_leave_interrupt => alu_leave_interrupt,
		O_enter_trap => alu_enter_trap,
		O_leave_trap => alu_leave_trap
	);

	bus_instance: bus_wb8 port map(
		I_en => ctrl_memen,
		I_op => ctrl_memop,
		I_iaddr => alu_pc,
		I_daddr => alu_out,
		I_data => reg_dataS2,
		I_mem_imem => ctrl_mem_imem,
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
	
	ctrl_instance: control port map(
		I_clk => inv_clk,	-- control runs on inverted clock!
		I_en => en,
		I_reset => RST_I,
		I_memop => dec_memop,
		I_regwrite => dec_regwrite,
		I_alubusy => alu_busy,
		I_membusy => bus_busy,
		I_interrupt => I_interrupt,
		I_leave_interrupt => alu_leave_interrupt,
		I_enter_trap => alu_enter_trap,
		I_leave_trap => alu_leave_trap,
		O_decen => ctrl_decen,
		O_aluen => ctrl_aluen,
		O_memen => ctrl_memen,
		O_regen => ctrl_regen,
		O_regop => ctrl_regop,
		O_memop => ctrl_memop,
		O_mem_imem => ctrl_mem_imem,
		O_enter_interrupt => ctrl_enter_interrupt
	);
	
	
	dec_instance: decoder port map(
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
		O_src_op2 => dec_src_op2
	);
	
	
	reg_instance: registers port map(
		I_clk => CLK_I,
		I_en => ctrl_regen,
		I_op => ctrl_regop,
		I_selS1 => dec_rs1,
		I_selS2 => dec_rs2,
		I_selD => dec_rd,
		I_dataAlu => alu_out,
		I_dataMem => bus_data,
		O_dataS1 => reg_dataS1,
		O_dataS2 => reg_dataS2
	);
	
	

	process(CLK_I)
	begin
	end process;
end Behavioral;