library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity pcu is
	port(
		I_clk: in std_logic;
		I_en: in std_logic;
		I_reset: in std_logic;
		I_op: in pcuops_t;
		I_data: in std_logic_vector(XLEN-1 downto 0);
		O_data: out std_logic_vector(XLEN-1 downto 0);
		O_trapret: out std_logic_vector(XLEN-1 downto 0)
	);
end pcu;


architecture Behavioral of pcu is
	signal pc,ret_trap,ret_interrupt: std_logic_vector(XLEN-1 downto 1) := RESET_VECTOR(XLEN-1 downto 1);

begin
	process(I_clk, I_en, I_reset, I_op, I_data)
		variable newpc: std_logic_vector(XLEN-1 downto 0) := XLEN_ZERO;
	begin
		if rising_edge(I_clk) then
		
			O_trapret <= ret_trap & '0';
		
			if I_en = '1' then
		
				case I_op is
					-- output current program counter value
					when PCU_OUTPC =>
						O_data <= pc & '0';
						
					-- load and output program counter value
					when PCU_SETPC =>
						pc <= I_data(XLEN-1 downto 1);
						O_data <= I_data(XLEN-1 downto 1) & '0';
					
					-- output trap vector and save return address
					-- NOTE: a return address needs to be computed beforehand
					-- for that, the ALU will compute (PC + INSTR_LEN)
					when PCU_ENTERTRAP =>
						ret_trap <= I_data(XLEN-1 downto 1);
						pc <= TRAP_VECTOR(XLEN-1 downto 1);
						O_data <= TRAP_VECTOR(XLEN-1 downto 1) & '0';
					
					-- set program counter to trap return address
					when PCU_RETTRAP =>
						pc <= ret_trap;
						O_data <= ret_trap & '0';
					
					-- output interrupt return address
					when PCU_OUTINTRET =>
						O_data <= ret_interrupt & '0';
						
					-- output interrupt vector and save return address
					-- Note: the return address is the original pc value, unlike traps
					when PCU_ENTERINT =>
						ret_interrupt <= pc;
						pc <= INTERRUPT_VECTOR(XLEN-1 downto 1);
						O_data <= INTERRUPT_VECTOR(XLEN-1 downto 1) & '0';
					
					-- set program counter to interrupt return address
					when PCU_RETINT =>
						pc <= ret_interrupt;
						O_data <= ret_interrupt & '0';
				end case;
			end if;
			
			if I_reset = '1' then
				pc <= RESET_VECTOR(XLEN-1 downto 1);
				ret_trap <= RESET_VECTOR(XLEN-1 downto 1);
				ret_interrupt <= RESET_VECTOR(XLEN-1 downto 1);
				O_data <= RESET_VECTOR(XLEN-1 downto 1) & '0';
			end if;
			
		end if;
	end process;
	
end Behavioral;