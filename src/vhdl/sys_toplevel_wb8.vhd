library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity sys_toplevel_wb8 is
	Port(
		I_clk: in std_logic;
		I_reset: in std_logic := '0';
		O_leds: out std_logic_vector(7 downto 0) := X"00"
	);
end sys_toplevel_wb8;


architecture Behavioral of sys_toplevel_wb8 is

	component arbiter_wb8
		Port(
			ADR_I: in std_logic_vector(31 downto 0);
			ACK0_I, ACK1_I, ACK2_I, ACK3_I: in std_logic;
			DAT0_I, DAT1_I, DAT2_I, DAT3_I: in std_logic_vector(7 downto 0);
			STB_I: in std_logic := '0';
			ACK_O: out std_logic := '0';
			DAT_O: out std_logic_vector(7 downto 0);
			STB0_O, STB1_O, STB2_O, STB3_O: out std_logic
		);
	end component;


	component cpu_toplevel_wb8
		Port(
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
	
	component leds_wb8 is
		Port(
			-- naming according to Wishbone B4 spec
			ADR_I: in std_logic_vector(31 downto 0);
			CLK_I: in std_logic;
			DAT_I: in std_logic_vector(7 downto 0);
			STB_I: in std_logic;
			WE_I: in std_logic;
			ACK_O: out std_logic;
			DAT_O: out std_logic_vector(7 downto 0);
			-- control signal for onboard LEDs
			O_leds: out std_logic_vector(7 downto 0)
		);
	end component;
	
	
	component ram_wb8
		Port(
			CLK_I: in std_logic;
			STB_I: in std_logic;
			WE_I: in std_logic;
			ADR_I: in std_logic_vector(XLEN-1 downto 0);
			DAT_I: in std_logic_vector(7 downto 0);
			DAT_O: out std_logic_vector(7 downto 0);
			ACK_O: out std_logic
		);	
	end component;
	
	
	component wizpll
		PORT(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		);
	end component;
	
	signal arb_ACK_O: std_logic := '0';
	signal arb_DAT_O: std_logic_vector(7 downto 0) := X"00";
	signal arb_STB0_O, arb_STB1_O, arb_STB2_O, arb_STB3_O: std_logic := '0';
	
	signal cpu_DAT_O: std_logic_vector(7 downto 0);
	signal cpu_ADR_O: std_logic_vector(XLEN-1 downto 0);
	signal cpu_STB_O, cpu_CYC_O, cpu_WE_O: std_logic := '0';

	
	signal pll_clk: std_logic;
	
	signal leds_DAT_O: std_logic_vector(7 downto 0);
	signal leds_ACK_O: std_logic := '0';
	signal dummy_leds_O: std_logic_vector(7 downto 0);
	
	signal ram_DAT_O: std_logic_vector(7 downto 0);
	signal ram_ACK_O: std_logic := '0';
	
	-- unconnected dummy signals for bus arbiter
	signal dummy1_ACK_O, dummy2_ACK_O, dummy3_ACK_O: std_logic := '0';
	signal dummy1_DAT_O, dummy2_DAT_O, dummy3_DAT_O: std_logic_vector(7 downto 0) := X"00";
	
	signal inv_reset: std_logic := '0';

begin

	--O_leds <= cpu_ADR_O(29 downto 28) & arb_STB3_O & arb_STB2_O & arb_STB1_O & arb_STB0_O & cpu_STB_O & cpu_CYC_O;
	--O_leds <= dummy_leds_O;
	
	-- reset button is inverted
	inv_reset <= not I_reset;
	

	arbiter_instance: arbiter_wb8 port map(
		ADR_I => cpu_ADR_O,
		ACK0_I => ram_ACK_O,
		ACK1_I => leds_ACK_O,
		ACK2_I => dummy2_ACK_O,
		ACK3_I => dummy3_ACK_O,
		DAT0_I => ram_DAT_O,
		DAT1_I => leds_DAT_O,
		DAT2_I => dummy2_DAT_O,
		DAT3_I => dummy3_DAT_O,
		STB_I => cpu_STB_O,
		ACK_O => arb_ACK_O,
		DAT_O => arb_DAT_O,
		STB0_O => arb_STB0_O,
		STB1_O => arb_STB1_O,
		STB2_O => arb_STB2_O,
		STB3_O => arb_STB3_O
	);


	cpu_instance: cpu_toplevel_wb8 port map(
		CLK_I => pll_clk,
		ACK_I => arb_ACK_O,
		DAT_I => arb_DAT_O,
		RST_I => inv_reset,
		ADR_O => cpu_ADR_O,
		DAT_O => cpu_DAT_O,
		CYC_O => cpu_CYC_O,
		STB_O => cpu_STB_O,
		WE_O => cpu_WE_O
	);
	
	leds_instance: leds_wb8 port map(
		ADR_I => cpu_ADR_O,
		CLK_I => pll_clk,
		DAT_I => cpu_DAT_O,
		STB_I => arb_STB1_O,
		WE_I => cpu_WE_O,
		ACK_O => leds_ACK_O,
		DAT_O => leds_DAT_O,
		-- control signal for onboard LEDs
		O_leds => O_leds -- dummy_leds_O
	);
	
	-- I/O device 0
	ram_instance: ram_wb8 port map(
		CLK_I => pll_clk,
		STB_I => arb_STB0_O,
		WE_I => cpu_WE_O,
		ADR_I => cpu_ADR_O,
		DAT_I => cpu_DAT_O,
		DAT_O => ram_DAT_O,
		ACK_O => ram_ACK_O
	);
	
	pll_instance: wizpll port map(
			inclk0 => I_clk,
			c0		=> pll_clk
	);


	

end Behavioral;