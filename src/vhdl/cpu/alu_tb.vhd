library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity alu_tb is
end alu_tb;

architecture Behavior of alu_tb is


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
			O_leave_interrupt: out boolean := false
		);
	end component;


	constant I_clk_period : time := 10 ns;
	signal I_clk : std_logic := '0';
	signal I_en: std_logic := '0';
	signal I_imm: std_logic_vector(XLEN-1 downto 0) := X"00000000";
	signal I_dataS1: std_logic_vector(XLEN-1 downto 0) := X"00000000";
	signal I_dataS2: std_logic_vector(XLEN-1 downto 0) := X"00000000";
	signal I_reset: std_logic;
	signal I_aluop: aluops_t;
	signal I_src_op1: op1src_t;
	signal I_src_op2: op2src_t;
	signal I_enter_interrupt: boolean := false;
	signal O_busy: std_logic;
	signal O_data: std_logic_vector(31 downto 0);
	signal O_PC: std_logic_vector(XLEN-1 downto 0);
	signal O_leave_interrupt: boolean := false;

begin

	-- instantiate unit under test
	uut: alu port map(
		I_clk => I_clk,
		I_en => I_en,
		I_imm => I_imm,
		I_dataS1 => I_dataS1,
		I_dataS2 => I_dataS2,
		I_reset => I_reset,
		I_aluop => I_aluop,
		I_src_op1 => I_src_op1,
		I_src_op2 => I_src_op2,
		I_enter_interrupt => I_enter_interrupt,
		O_busy => O_busy,
		O_data => O_data,
		O_PC => O_PC,
		O_leave_interrupt => O_leave_interrupt
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
	
		-- test sub/add
	
		wait until falling_edge(I_clk);
		I_en <= '1';
		I_dataS1 <= X"0000000F";
		I_dataS2 <= X"00000001";
		I_aluop <= ALU_SUB;
		I_src_op1 <= SRC_S1;
		I_src_op2 <= SRC_S2;
		wait until falling_edge(I_clk);
		assert O_data = X"0000000E" report "wrong output value" severity failure;
		I_aluop <= ALU_ADD;
		wait until falling_edge(I_clk);
		assert O_data = X"00000010" report "wrong output value" severity failure;
		
		-- test xor
	
		wait until falling_edge(I_clk);
		I_en <= '1';
		I_dataS1 <= X"00000055";
		I_dataS2 <= X"000000FF";
		I_aluop <= ALU_XOR;
		I_src_op1 <= SRC_S1;
		I_src_op2 <= SRC_S2;
		wait until falling_edge(I_clk);
		assert O_data = X"000000AA" report "wrong output value" severity failure;


		-- test shift operations

		wait until falling_edge(I_clk);		
		I_dataS1 <= X"0000000F";
		I_dataS2 <= X"00000004";
		I_aluop <= ALU_SLL;
		I_src_op1 <= SRC_S1;
		I_src_op2 <= SRC_S2;
		wait until falling_edge(O_busy);
		assert O_data = X"000000F0" report "wrong output value" severity failure;


		wait until falling_edge(I_clk);		
		I_dataS1 <= X"0000000F";
		I_dataS2 <= X"00000008";
		I_aluop <= ALU_SLL;
		I_src_op1 <= SRC_S1;
		I_src_op2 <= SRC_S2;
		wait until falling_edge(O_busy);
		assert O_data = X"00000F00" report "wrong output value" severity failure;
		
		
		wait until falling_edge(I_clk);		
		I_dataS1 <= X"0000000F";
		I_dataS2 <= X"00000000"; -- test shift by zero, should output original value
		I_aluop <= ALU_SLL;
		I_src_op1 <= SRC_S1;
		I_src_op2 <= SRC_S2;
		wait until falling_edge(O_busy);
		assert O_data = X"0000000F" report "wrong output value" severity failure;
		

		wait until falling_edge(I_clk);
		I_dataS1 <= X"F0000000";
		I_dataS2 <= X"00000004";
		I_aluop <= ALU_SRA;
		I_src_op1 <= SRC_S1;
		I_src_op2 <= SRC_S2;
		wait until falling_edge(O_busy);
		assert O_data = X"FF000000" report "wrong output value" severity failure;
		I_aluop <= ALU_SRL;
		wait until falling_edge(O_busy);
		assert O_data = X"0F000000" report "wrong output value" severity failure;
		
		
		wait until falling_edge(I_clk);
		I_dataS1 <= X"0000000F";
		I_imm <= X"00000008";
		I_aluop <= ALU_SLL;
		I_src_op1 <= SRC_S1;
		I_src_op2 <= SRC_IMM;
		wait until falling_edge(O_busy);
		assert O_data = X"00000F00" report "wrong output value" severity failure;
		

		wait until falling_edge(I_clk);
		I_dataS1 <= X"F0000000";
		I_imm <= X"00000004";
		I_aluop <= ALU_SRA;
		I_src_op1 <= SRC_S1;
		I_src_op2 <= SRC_IMM;
		wait until falling_edge(O_busy);
		assert O_data = X"FF000000" report "wrong output value" severity failure;
		I_aluop <= ALU_SRL;
		I_src_op1 <= SRC_S1;
		I_src_op2 <= SRC_IMM;		
		wait until falling_edge(O_busy);
		assert O_data = X"0F000000" report "wrong output value" severity failure;
		

		wait for I_clk_period;		
		assert false report "end of simulation" severity failure;
	
	end process;
	

end architecture;