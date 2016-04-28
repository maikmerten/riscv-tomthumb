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
	end component;


	constant I_clk_period : time := 10 ns;
	signal I_clk : std_logic := '0';
	signal I_en: std_logic := '0';
	signal I_fop: std_logic_vector(7 downto 0) := "00000000";
	signal I_imm: std_logic_vector(XLEN-1 downto 0) := X"00000000";
	signal I_dataS1: std_logic_vector(XLEN-1 downto 0) := X"00000000";
	signal I_dataS2: std_logic_vector(XLEN-1 downto 0) := X"00000000";
	signal I_reset: std_logic;
	signal O_alumemop: std_logic_vector(2 downto 0) := "000";
	signal O_busy: std_logic;
	signal O_data: std_logic_vector(31 downto 0);
	signal O_PC: std_logic_vector(XLEN-1 downto 0);

begin

	-- instantiate unit under test
	uut: alu port map(
		I_clk => I_clk,
		I_en => I_en,
		I_fop => I_fop,
		I_imm => I_imm,
		I_dataS1 => I_dataS1,
		I_dataS2 => I_dataS2,
		I_reset => I_reset,
		O_alumemop => O_alumemop,
		O_busy => O_busy,
		O_data => O_data,
		O_PC => O_PC
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
		I_imm <= X"00000" & "0100" & X"00"; -- select SUB
		I_dataS1 <= X"0000000F";
		I_dataS2 <= X"00000001";
		I_fop <= FUNC_ADD_SUB & OP_OP;
		wait until falling_edge(I_clk);
		assert O_data = X"0000000E" report "wrong output value" severity failure;
		I_imm <= X"00000" & "0000" & X"00"; -- select ADD
		wait until falling_edge(I_clk);
		assert O_data = X"00000010" report "wrong output value" severity failure;
		
		-- test xor
	
		wait until falling_edge(I_clk);
		I_en <= '1';
		I_dataS1 <= X"00000055";
		I_dataS2 <= X"000000FF";
		I_fop <= FUNC_XOR & OP_OP;
		wait until falling_edge(I_clk);
		assert O_data = X"000000AA" report "wrong output value" severity failure;


		-- test shift operations
		
		I_dataS1 <= X"0000000F";
		I_dataS2 <= X"00000004";
		I_fop <= FUNC_SLL & OP_OP;
		wait until falling_edge(O_busy);
		wait until falling_edge(I_clk);
		assert O_data = X"000000F0" report "wrong output value" severity failure;


		I_dataS1 <= X"0000000F";
		I_dataS2 <= X"00000000"; -- test shift by zero, should output original value
		I_fop <= FUNC_SLL & OP_OP;
		wait until falling_edge(I_clk);
		assert O_data = X"0000000F" report "wrong output value" severity failure;
		
		I_imm <= X"00000" & "0100" & X"00"; -- select SRA
		I_dataS1 <= X"F0000000";
		I_dataS2 <= X"00000004";
		I_fop <= FUNC_SRL_SRA & OP_OP;
		wait until falling_edge(O_busy);
		wait until falling_edge(I_clk);
		assert O_data = X"FF000000" report "wrong output value" severity failure;
		I_imm <= X"00000" & "0000" & X"00"; -- select SRL
		wait until falling_edge(O_busy);
		wait until falling_edge(I_clk);
		assert O_data = X"0F000000" report "wrong output value" severity failure;
		
		
		I_dataS1 <= X"0000000F";
		I_imm <= X"00000004";
		I_fop <= FUNC_SLLI & OP_OPIMM;
		wait until falling_edge(O_busy);
		wait until falling_edge(I_clk);
		assert O_data = X"000000F0" report "wrong output value" severity failure;
		

		I_dataS1 <= X"F0000000";
		I_imm <= X"00000" & "0100000" & "00100"; -- select SRAI with shift amount four
		I_fop <= FUNC_SRLI_SRAI & OP_OPIMM;
		wait until falling_edge(O_busy);
		wait until falling_edge(I_clk);
		assert O_data = X"FF000000" report "wrong output value" severity failure;
		I_imm <= X"00000" & "0000000" & "00100"; -- select SRLI with shift amount four
		wait until falling_edge(O_busy);
		wait until falling_edge(I_clk);
		assert O_data = X"0F000000" report "wrong output value" severity failure;
		

		wait for I_clk_period;		
		assert false report "end of simulation" severity failure;
	
	end process;
	

end architecture;