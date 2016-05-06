library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

------------------------------------------------------------------
-- this is a toplevel for debugging vga signal generation without
-- the rest of the SOC being synthesized
------------------------------------------------------------------

entity vga_wb8_toplevel is
	Port(
		I_clk: in std_logic;
		O_vga_hsync, O_vga_vsync, O_vga_r, O_vga_g, O_vga_b: out std_logic
	);
end vga_wb8_toplevel;


architecture Behavioral of vga_wb8_toplevel is

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

			O_vga_vsync, O_vga_hsync, O_vga_r, O_vga_g, O_vga_b: out std_logic := '0'
		);
	end component;
	
	component wizpll
		PORT(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		);
	end component;
	

	signal vga_ack: std_logic := '0';
	signal vga_dat: std_logic_vector(7 downto 0);
	
	signal pll_clk: std_logic;
	
begin


	vga_instance: vga_wb8 port map(
		ADR_I => X"00000000",
		CLK_I => pll_clk,
		DAT_I => X"00",
		STB_I => '0',
		WE_I => '0',
		ACK_O => vga_ack,
		DAT_O => vga_dat,

		O_vga_vsync => O_vga_vsync,
		O_vga_hsync => O_vga_hsync,
		O_vga_r => O_vga_r,
		O_vga_g => O_vga_g,
		O_vga_b => O_vga_b
	);
	
	pll_instance: wizpll port map(
			inclk0 => I_clk,
			c0		=> pll_clk
	);


end architecture;