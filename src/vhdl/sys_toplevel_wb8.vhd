library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;
use work.arbiter_types.all;

entity sys_toplevel_wb8 is
	Port(
		I_clk: in std_logic;
		I_reset: in std_logic := '0';
		I_serial_rx: in std_logic;
		I_interrupt: in std_logic;
		O_leds: out std_logic_vector(7 downto 0) := X"00";
		O_serial_tx: out std_logic;
		O_vga_vsync, O_vga_hsync, O_vga_r, O_vga_g, O_vga_b: out std_logic := '0'
	);
end sys_toplevel_wb8;


architecture Behavioral of sys_toplevel_wb8 is

	component arbiter_wb8
		Port(
			ADR_I: in std_logic_vector(31 downto 0);
			ACK_I: in arb_ACK_I_t;
			DAT_I: in arb_DAT_I_t;
			STB_I: in std_logic := '0';
			ACK_O: out std_logic := '0';
			DAT_O: out std_logic_vector(7 downto 0);
			STB_O: out arb_STB_O_t
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
			WE_O: out std_logic := '0';
			I_interrupt: in std_logic := '0'
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
	
	component serial_wb8 is
		Port(
			-- naming according to Wishbone B4 spec
			ADR_I: in std_logic_vector(31 downto 0);
			CLK_I: in std_logic;
			DAT_I: in std_logic_vector(7 downto 0);
			STB_I: in std_logic;
			WE_I: in std_logic;
			ACK_O: out std_logic;
			DAT_O: out std_logic_vector(7 downto 0);	
	
			-- serial interface (receive, transmit)
			I_rx: in std_logic;
			O_tx: out std_logic
	);
	end component;
	
	component vga_wb8
		Port(
			-- naming according to Wishbone B4 spec
			ADR_I: in std_logic_vector(31 downto 0);
			CLK_I: in std_logic;
			DAT_I: in std_logic_vector(7 downto 0);
			STB_I: in std_logic;
			WE_I: in std_logic;
			ACK_O: out std_logic;
			DAT_O: out std_logic_vector(7 downto 0);

			I_vga_clk: in std_logic := '0';
			O_vga_vsync, O_vga_hsync, O_vga_r, O_vga_g, O_vga_b: out std_logic := '0'
	);	
	
	end component;
	
	
	component wizpll
		PORT(
			inclk0: IN STD_LOGIC := '0';
			c0: OUT STD_LOGIC 
		);
	end component;
	
	
	component wizpll_vga
		PORT(
			inclk0: IN STD_LOGIC := '0';
			c0: OUT STD_LOGIC 
		);
	end component;
	
	signal arb_ACK_O: std_logic := '0';
	signal arb_DAT_O: std_logic_vector(7 downto 0) := X"00";
	signal arb_ACK_I: arb_ACK_I_t;
	signal arb_DAT_I: arb_DAT_I_t;
	signal arb_STB_O: arb_STB_O_t;
	
	signal cpu_DAT_O: std_logic_vector(7 downto 0);
	signal cpu_ADR_O: std_logic_vector(XLEN-1 downto 0);
	signal cpu_STB_O, cpu_CYC_O, cpu_WE_O: std_logic := '0';

	
	signal pll_clk, pll_vga_clk: std_logic;
	
	signal leds_DAT_O: std_logic_vector(7 downto 0);
	signal leds_ACK_O: std_logic := '0';
	signal dummy_leds_O: std_logic_vector(7 downto 0);
	
	signal ram_DAT_O: std_logic_vector(7 downto 0);
	signal ram_ACK_O: std_logic := '0';
	
	signal serial_DAT_O: std_logic_vector(7 downto 0);
	signal serial_ACK_O: std_logic := '0';
	
	signal vga_DAT_O: std_logic_vector(7 downto 0);
	signal vga_ACK_O: std_logic := '0';
	
	
	signal inv_reset: std_logic := '0';
	signal inv_interrupt: std_logic := '0';

begin


	-- reset button is inverted
	inv_reset <= not I_reset;
	-- interrupt button is also inverted
	inv_interrupt <= not I_interrupt;
	

	arbiter_instance: arbiter_wb8 port map(
		ADR_I => cpu_ADR_O,
		ACK_I => arb_ACK_I,
		DAT_I => arb_DAT_I,
		STB_I => cpu_STB_O,
		ACK_O => arb_ACK_O,
		DAT_O => arb_DAT_O,
		STB_O => arb_STB_O
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
		WE_O => cpu_WE_O,
		I_interrupt => inv_interrupt
	);
	
	leds_instance: leds_wb8 port map(
		ADR_I => cpu_ADR_O,
		CLK_I => pll_clk,
		DAT_I => cpu_DAT_O,
		STB_I => arb_STB_O(1),
		WE_I => cpu_WE_O,
		ACK_O => arb_ACK_I(1),
		DAT_O => arb_DAT_I(1),
		-- control signal for onboard LEDs
		O_leds => O_leds -- dummy_leds_O
	);
	
	serial_instance: serial_wb8 port map(
		ADR_I => cpu_ADR_O,
		CLK_I => pll_clk,
		DAT_I => cpu_DAT_O,
		STB_I => arb_STB_O(2),
		WE_I => cpu_WE_O,
		ACK_O => arb_ACK_I(2),
		DAT_O => arb_DAT_I(2),
		I_rx => I_serial_rx,
		O_tx => O_serial_tx
	);
	
	vga_instance: vga_wb8 port map(
		ADR_I => cpu_ADR_O,
		CLK_I => pll_clk,
		DAT_I => cpu_DAT_O,
		STB_I => arb_STB_O(3),
		WE_I => cpu_WE_O,
		ACK_O => arb_ACK_I(3),
		DAT_O => arb_DAT_I(3),
		I_vga_clk => pll_vga_clk,
		O_vga_vsync => O_vga_vsync,
		O_vga_hsync => O_vga_hsync,
		O_vga_r => O_vga_r,
		O_vga_g => O_vga_g,
		O_vga_b => O_vga_b
	);
	
	
	-- I/O device 0
	ram_instance: ram_wb8 port map(
		CLK_I => pll_clk,
		STB_I => arb_STB_O(0),
		WE_I => cpu_WE_O,
		ADR_I => cpu_ADR_O,
		DAT_I => cpu_DAT_O,
		DAT_O => arb_DAT_I(0),
		ACK_O => arb_ACK_I(0)
	);
	
	pll_instance: wizpll port map(
			inclk0 => I_clk,
			c0 => pll_clk
	);

	pll_vga_instance: wizpll_vga port map(
			inclk0 => I_clk,
			c0 => pll_vga_clk
	);
	

end Behavioral;