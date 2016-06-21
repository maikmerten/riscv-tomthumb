library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity decoder_tb is
end decoder_tb;

architecture Behavior of decoder_tb is


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


	constant I_clk_period : time := 10 ns;
	signal I_clk : std_logic := '0';
	signal I_en: std_logic := '1';
	signal I_instr: std_logic_vector(XLEN-1 downto 0) := X"00000000";
	signal O_rs1: std_logic_vector(4 downto 0);
	signal O_rs2: std_logic_vector(4 downto 0);
	signal O_rd: std_logic_vector(4 downto 0);
	signal O_imm: std_logic_vector(XLEN-1 downto 0) := X"00000000";
	signal O_regwrite: std_logic := '0';
	signal O_memop: memops_t;
	signal O_aluop: aluops_t;
	signal O_src_op1: op1src_t;
	signal O_src_op2: op2src_t;
	

begin

	-- instantiate unit under test
	uut: decoder port map(
		I_clk => I_clk,
		I_en => I_en,
		I_instr => I_instr,
		O_rs1 => O_rs1,
		O_rs2 => O_rs2,
		O_rd => O_rd,
		O_imm => O_imm,
		O_regwrite => O_regwrite,
		O_memop => O_memop,
		O_aluop => O_aluop,
		O_src_op1 => O_src_op1,
		O_src_op2 => O_src_op2
	);

	proc_clock: process
	begin
		I_clk <= '0';
		wait for I_clk_period/2;
		I_clk <= '1';
		wait for I_clk_period/2;
	end process;
	
	proc_stimuli: process
	begin
	
		wait until falling_edge(I_clk);

		I_instr <= X"00f00313"; -- addi t1,x0,15
		wait until falling_edge(I_clk);
		assert O_rs1 = R0 report "wrong rs1 decoded" severity failure;
		assert O_rd = T1 report "wrong rd decoded" severity failure;
		assert to_integer(signed(O_imm)) = 15 report "wrong immediate decoded" severity failure;
		assert O_regwrite = '1' report "wrong regwrite decoded" severity failure;
		assert O_memop = MEMOP_NOP report "wrong memop decoded" severity failure;
		assert O_aluop = ALU_ADD report "wrong aluop decoded" severity failure;
		assert O_src_op1 = SRC_S1 report "wrong op1 src decoded" severity failure;
		assert O_src_op2 = SRC_IMM report "wrong op2 src decoded" severity failure;
		
		
		I_instr <= X"006282b3"; -- add t0,t0,t1
		wait until falling_edge(I_clk);
		assert O_rs1 = T0 report "wrong rs1 decoded" severity failure;
		assert O_rs2 = T1 report "wrong rs2 decoded" severity failure;
		assert O_rd = T0 report "wrong rd decoded" severity failure;
		assert O_regwrite = '1' report "wrong regwrite decoded" severity failure;
		assert O_memop = MEMOP_NOP report "wrong memop decoded" severity failure;
		assert O_aluop = ALU_ADD report "wrong aluop decoded" severity failure;
		assert O_src_op1 = SRC_S1 report "wrong op1 src decoded" severity failure;
		assert O_src_op2 = SRC_S2 report "wrong op2 src decoded" severity failure;

		
		I_instr <= X"00502e23"; -- sw t0,28(x0)
		wait until falling_edge(I_clk);
		assert O_rs1 = R0 report "wrong rs1 decoded" severity failure;
		assert O_rs2 = T0 report "wrong rs2 decoded" severity failure;
		assert to_integer(signed(O_imm)) = 28 report "wrong immediate decoded" severity failure;
		assert O_regwrite = '0' report "wrong regwrite decoded" severity failure;
		assert O_memop = MEMOP_WRITEW report "wrong memop decoded" severity failure;
		assert O_aluop = ALU_ADD report "wrong aluop decoded" severity failure;
		assert O_src_op1 = SRC_S1 report "wrong op1 src decoded" severity failure;
		assert O_src_op2 = SRC_IMM report "wrong op2 src decoded" severity failure;

		
		I_instr <= X"e0502023"; -- sw t0,-512(x0)
		wait until falling_edge(I_clk);
		assert O_rs1 = R0 report "wrong rs1 decoded" severity failure;
		assert O_rs2 = T0 report "wrong rs2 decoded" severity failure;
		assert to_integer(signed(O_imm)) = -512 report "wrong immediate decoded" severity failure;
		assert O_regwrite = '0' report "wrong regwrite decoded" severity failure;
		assert O_memop = MEMOP_WRITEW report "wrong memop decoded" severity failure;
		assert O_aluop = ALU_ADD report "wrong aluop decoded" severity failure;
		assert O_src_op1 = SRC_S1 report "wrong op1 src decoded" severity failure;
		assert O_src_op2 = SRC_IMM report "wrong op2 src decoded" severity failure;

		

		I_instr <= X"01c02283"; -- lw t0,28(x0)
		wait until falling_edge(I_clk);
		assert O_rs1 = R0 report "wrong rs1 decoded" severity failure;
		assert O_rd = T0 report "wrong rd decoded" severity failure;
		assert to_integer(signed(O_imm)) = 28 report "wrong immediate decoded" severity failure;
		assert O_regwrite = '1' report "wrong regwrite decoded" severity failure;
		assert O_memop = MEMOP_READW report "wrong memop decoded" severity failure;
		assert O_aluop = ALU_ADD report "wrong aluop decoded" severity failure;
		assert O_src_op1 = SRC_S1 report "wrong op1 src decoded" severity failure;
		assert O_src_op2 = SRC_IMM report "wrong op2 src decoded" severity failure;



		I_instr <= X"ff1ff3ef"; -- jal x7,4 (from 0x14)
		wait until falling_edge(I_clk);
		assert O_rd = R7 report "wrong rd decoded" severity failure;
		assert to_integer(signed(O_imm)) = -16 report "wrong immediate decoded" severity failure;
		assert O_regwrite = '1' report "wrong regwrite decoded" severity failure;
		assert O_memop = MEMOP_NOP report "wrong memop decoded" severity failure;
		assert O_aluop = ALU_JAL report "wrong aluop decoded" severity failure;
		assert O_src_op1 = SRC_S1 report "wrong op1 src decoded" severity failure;
		assert O_src_op2 = SRC_IMM report "wrong op2 src decoded" severity failure;
		
		
		I_instr <= X"fec003e7"; -- jalr x7,x0,-20
		wait until falling_edge(I_clk);
		assert O_rs1 = R0 report "wrong rs1 decoded" severity failure;
		assert O_rd = R7 report "wrong rd decoded" severity failure;
		assert to_integer(signed(O_imm)) = -20 report "wrong immediate decoded" severity failure;
		assert O_regwrite = '1' report "wrong regwrite decoded" severity failure;
		assert O_memop = MEMOP_NOP report "wrong memop decoded" severity failure;
		assert O_aluop = ALU_JALR report "wrong aluop decoded" severity failure;
		assert O_src_op1 = SRC_S1 report "wrong op1 src decoded" severity failure;
		assert O_src_op2 = SRC_IMM report "wrong op2 src decoded" severity failure;

		
		I_instr <= X"f0f0f2b7"; -- lui t0,0xf0f0f
		wait until falling_edge(I_clk);
		assert O_rs1 = R0 report "wrong rs1 decoded" severity failure;
		assert O_rd = T0 report "wrong rd decoded" severity failure;
		assert O_imm = X"f0f0f000" report "wrong immediate decoded" severity failure;
		assert O_regwrite = '1' report "wrong regwrite decoded" severity failure;
		assert O_memop = MEMOP_NOP report "wrong memop decoded" severity failure;
		assert O_aluop = ALU_ADD report "wrong aluop decoded" severity failure;
		assert O_src_op1 = SRC_S1 report "wrong op1 src decoded" severity failure;
		assert O_src_op2 = SRC_IMM report "wrong op2 src decoded" severity failure;

		
		I_instr <= X"fe7316e3"; -- bne t1,t2,4 (from 0x18)
		wait until falling_edge(I_clk);
		assert O_rs1 = T1 report "wrong rs1 decoded" severity failure;
		assert O_rs2 = T2 report "wrong rs2 decoded" severity failure;
		assert to_integer(signed(O_imm)) = -20 report "wrong immediate decoded" severity failure;
		assert O_regwrite = '0' report "wrong regwrite decoded" severity failure;
		assert O_memop = MEMOP_NOP report "wrong memop decoded" severity failure;
		assert O_aluop = ALU_BNE report "wrong aluop decoded" severity failure;
		assert O_src_op1 = SRC_S1 report "wrong op1 src decoded" severity failure;
		assert O_src_op2 = SRC_S2 report "wrong op2 src decoded" severity failure;
		
		
		I_instr <= X"c0002373"; -- rdcycle t1
		wait until falling_edge(I_clk);
		assert O_rs1 = R0 report "wrong rs1 decoded" severity failure;
		assert O_rs2 = R0 report "wrong rs2 decoded" severity failure;
		assert O_regwrite = '1' report "wrong regwrite decoded" severity failure;
		assert O_memop = MEMOP_NOP report "wrong memop decoded" severity failure;
		assert O_aluop = ALU_TRAP report "wrong aluop decoded" severity failure;
		
		
		I_instr <= X"c80023f3"; -- rdcycleh t1
		wait until falling_edge(I_clk);
		assert O_rs1 = R0 report "wrong rs1 decoded" severity failure;
		assert O_rs2 = R0 report "wrong rs2 decoded" severity failure;
		assert O_regwrite = '1' report "wrong regwrite decoded" severity failure;
		assert O_memop = MEMOP_NOP report "wrong memop decoded" severity failure;
		assert O_aluop = ALU_TRAP report "wrong aluop decoded" severity failure;

		
		wait for I_clk_period;		
		assert false report "end of simulation" severity failure;
	
	end process;
	

end architecture;