library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity sys_wb8_tb is
end sys_wb8_tb;

architecture Behavior of sys_wb8_tb is


	component sys_toplevel_wb8
		Port(
			I_clk: in std_logic;
			I_reset: in std_logic := '0';
			O_leds: out std_logic_vector(7 downto 0) := X"00"
		);
	end component;


	constant I_clk_period : time := 10 ns;
	signal I_clk : std_logic := '0';
	signal I_reset: std_logic := '0';
	signal O_leds: std_logic_vector(7 downto 0) := X"00";


begin

	-- instantiate unit under test
	uut: sys_toplevel_wb8 port map(
		I_clk => I_clk,
		I_reset => I_reset,
		O_leds => O_leds
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
		I_reset <= '0';
		wait for 10 * I_clk_period;
		I_reset <= '1';
		
		wait for 100 * I_clk_period;
		I_reset <= '0';
		wait for 10* I_clk_period;
		I_reset <= '1';
		
		wait for 10000 * I_clk_period;		
		assert false report "end of simulation" severity failure;
	
	end process;
	

end architecture;