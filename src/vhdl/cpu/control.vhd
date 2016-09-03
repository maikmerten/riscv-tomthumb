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
		I_regwrite: in std_logic;
		I_alubusy: in std_logic;
		I_membusy: in std_logic;
		I_memop: in memops_t; -- from decoder
		I_interrupt: in std_logic; -- from outside world
		I_in_interrupt: in boolean; -- from ALU
		I_interrupt_enabled: in boolean; -- from ALU
		I_in_trap: in boolean; -- from ALU
		-- enable signals for components
		O_decen: out std_logic;
		O_aluen: out std_logic;
		O_memen: out std_logic;
		O_regen: out std_logic;
		-- op selection for devices
		O_regop: out regops_t;
		O_memop: out memops_t;
		O_mux_bus_addr_sel: out integer range 0 to MUX_BUS_ADDR_PORTS-1;
		-- interrupt handling
		O_enter_interrupt: out boolean := false
	);
end control;

architecture Behavioral of control is
	type control_states is (RESET, FETCH, DECODE, REGREAD, EXECUTE, MEMORY, REGWRITE);
begin
	process(I_clk)
		variable nextstate,state: control_states := RESET;
		variable in_interrupt, in_trap: boolean := false;
	begin
		if rising_edge(I_clk) and I_en = '1' then
		
			O_regop <= REGOP_READ;
			O_mux_bus_addr_sel <= MUX_BUS_ADDR_PORT_ALU; -- address by default from ALU
			O_enter_interrupt <= false;
			
			
			if I_alubusy = '0' and I_membusy = '0' then
				state := nextstate;
			end if;
			
		
			case state is
				when RESET =>
					O_decen <= '0';
					O_aluen <= '0';
					O_memen <= '0';
					O_regen <= '0';
			
					nextstate := FETCH;
				
				when FETCH =>
					
					if I_interrupt = '1' and I_interrupt_enabled and not I_in_interrupt and not I_in_trap then
						O_enter_interrupt <= true;
					else				
						O_decen <= '0';
						O_aluen <= '0';
						O_memen <= '1';
						O_regen <= '0';
					
						O_mux_bus_addr_sel <= MUX_BUS_ADDR_PORT_PC; -- load from instruction memory
						O_memop <= MEMOP_READW;
				
						nextstate := DECODE;
					end if;

				
				when DECODE =>
					O_decen <= '1';
					O_aluen <= '0';
					O_memen <= '0';
					O_regen <= '0';
		
					nextstate := REGREAD;

				when REGREAD =>
					O_decen <= '0';
					O_aluen <= '0';
					O_memen <= '0';
					O_regen <= '1';
						
					nextstate := EXECUTE;
					
				when EXECUTE =>
					O_decen <= '0';
					O_aluen <= '1';
					O_memen <= '0';
					O_regen <= '0';
					
					if I_memop /= MEMOP_NOP then
						nextstate := MEMORY;
					elsif I_regwrite = '1' then
						nextstate := REGWRITE;
					else
						nextstate := FETCH;
					end if;
				when MEMORY =>
					O_decen <= '0';
					O_aluen <= '0';
					O_memen <= '1';
					O_regen <= '0';
						
					O_memop <= I_memop;
						
					if I_regwrite = '1' then
						nextstate := REGWRITE;
					else
						nextstate := FETCH;
					end if;

				when REGWRITE =>
				
					O_decen <= '0';
					O_aluen <= '0';
					O_memen <= '0';
					O_regen <= '1';

							
					if I_memop /= MEMOP_NOP then
						O_regop <= REGOP_WRITE_MEM;
					else
						O_regop <= REGOP_WRITE_ALU;
					end if;
					
					nextstate := FETCH;


			end case;
		
		
			if I_reset = '1' then
				state := RESET;
				nextstate := RESET;
			end if;
		
		end if;
	end process;

end Behavioral;