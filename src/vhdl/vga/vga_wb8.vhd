library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity vga_wb8 is
	Port(
		-- naming according to Wishbone B4 spec
		ADR_I: in std_logic_vector(31 downto 0);
		CLK_I: in std_logic;
		DAT_I: in std_logic_vector(7 downto 0);
		STB_I: in std_logic;
		WE_I: in std_logic;
		ACK_O: out std_logic;
		DAT_O: out std_logic_vector(7 downto 0);

		O_vsync, O_hsync, O_r, O_g, O_b: out std_logic := '0'
	);
end vga_wb8;


architecture Behavioral of vga_wb8 is
	--	timings for 800x600, 72 Hz, 50 MHz pixel clock
	constant h_visible: integer := 800;
	constant h_front_porch: integer := 56;
	constant h_pulse: integer := 120;
	constant h_back_porch: integer := 64;
	constant v_visible: integer := 600;
	constant v_front_porch: integer := 37;
	constant v_pulse: integer := 6;
	constant v_back_porch: integer := 23;
	

	signal pixel_clk: std_logic := '0';
	signal col: integer range 0 to (h_visible + h_front_porch + h_pulse + h_back_porch) := 0;
	signal row: integer range 0 to (v_visible + v_front_porch + v_pulse + v_back_porch) := 0;
begin

	pixel_clk <= CLK_I;

	ctrl_logic: process(CLK_I)
	begin
		if rising_edge(CLK_I) then
		
			
		end if;
	end process;
	
	vga_out: process(pixel_clk)
		variable col_vec: std_logic_vector(11 downto 0);
	begin
		if rising_edge(pixel_clk) then
		
			col_vec := std_logic_vector(to_unsigned(col, col_vec'length));
			
			if col < h_visible and row < v_visible then
				-- just create a colored stripe pattern for now
				O_r <= col_vec(5);
				O_g <= col_vec(6);
				O_b <= col_vec(7);
			else
				O_r <= '0';
				O_g <= '0';
				O_b <= '0';
			end if;

	
			---------------------------------------------
			-- generate sync signals, update row and col
			---------------------------------------------
			col <= col + 1;	
		
			if col = (h_visible + h_front_porch - 1) then
				O_hsync <= '1';
			end if;
		
			if col = (h_visible + h_front_porch + h_pulse - 1) then
				O_hsync <= '0';
			end if;

			if col = (h_visible + h_front_porch + h_pulse + h_back_porch - 1) then
				col <= 0;
				row <= row + 1;
			end if;
			
			if row = (v_visible + v_front_porch - 1) then
				O_vsync <= '1';
			end if;
			
			if row = (v_visible + v_front_porch + v_pulse - 1) then
				O_vsync <= '0';
			end if;
			
			if row = (v_visible + v_front_porch + v_pulse + v_back_porch - 1) then
				row <= 0;
			end if;
		
		end if;
	end process;
	
	
end Behavioral;