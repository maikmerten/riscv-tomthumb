library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;
use work.vga_font_init.all;

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
	
	signal ram_font: font_store_t := FONT_RAM_INIT;
	signal font_byte: std_logic_vector(7 downto 0) := X"00";
	
begin


	pixel_clk <= CLK_I;

	ctrl_logic: process(CLK_I)
	begin
		if rising_edge(CLK_I) then
		
	
			
		end if;
	end process;
	
	vga_out: process(pixel_clk)
		variable col_vec: std_logic_vector(11 downto 0);
		variable row_vec: std_logic_vector(10 downto 0);
		variable font_addr: integer range 0 to 2047;
		
		variable font_address: std_logic_vector(10 downto 0);
		variable font_code: std_logic_vector(7 downto 0) := X"00";
		variable font_row: std_logic_vector(2 downto 0);
		--variable font_byte: std_logic_vector(7 downto 0);
		variable font_pixel: std_logic;

		variable col_next: integer range 0 to (h_visible + h_front_porch + h_pulse + h_back_porch) := 0;
		variable row_next: integer range 0 to (v_visible + v_front_porch + v_pulse + v_back_porch) := 0;
	begin
		if rising_edge(pixel_clk) then
		
			col_vec := std_logic_vector(to_unsigned(col, col_vec'length));
			row_vec := std_logic_vector(to_unsigned(row, row_vec'length));
			
			if col < h_visible and row < v_visible then
				-- just create a colored stripe pattern for now
				O_r <= col_vec(4);
				O_g <= col_vec(5);
				O_b <= col_vec(6);
				
				-- pick font pixel from font byte for current column
				case col_vec(3 downto 1) is
					when "000" =>
						font_pixel := font_byte(7);
					when "001" =>
						font_pixel := font_byte(6);
					when "010" =>
						font_pixel := font_byte(5);
					when "011" =>
						font_pixel := font_byte(4);
					when "100" =>
						font_pixel := font_byte(3);
					when "101" =>
						font_pixel := font_byte(2);
					when "110" =>
						font_pixel := font_byte(1);
					when others =>
						font_pixel := font_byte(0);
				end case;
				
				if font_pixel = '1' then
					O_r <= '1';
					O_g <= '1';
					O_b <= '1';
				end if;
				
			else
				-- not in visible region
				O_r <= '0';
				O_g <= '0';
				O_b <= '0';
			end if;

	
			---------------------------------------------
			-- generate sync signals, update row and col
			---------------------------------------------
			col_next := col + 1;	
			row_next := row;
		
			if col = (h_visible + h_front_porch - 1) then
				O_hsync <= '1';
			end if;
		
			if col = (h_visible + h_front_porch + h_pulse - 1) then
				O_hsync <= '0';
			end if;

			if col = (h_visible + h_front_porch + h_pulse + h_back_porch - 1) then
				col_next := 0;
				row_next := row + 1;
			end if;
			
			if row = (v_visible + v_front_porch - 1) then
				O_vsync <= '1';
			end if;
			
			if row = (v_visible + v_front_porch + v_pulse - 1) then
				O_vsync <= '0';
			end if;
			
			if row = (v_visible + v_front_porch + v_pulse + v_back_porch - 1) then
				row_next := 0;
			end if;
			
			col <= col_next;
			row <= row_next;
			
			----------------------------------
			-- fetch font byte for next pixel
			----------------------------------
			col_vec := std_logic_vector(to_unsigned(col_next, col_vec'length));
			row_vec := std_logic_vector(to_unsigned(row_next, row_vec'length));
			
			font_code := col_vec(11 downto 4); -- TODO: fetch from text RAM
			font_row := row_vec(3 downto 1);
			font_address := font_code & font_row;
			font_byte <= ram_font(to_integer(unsigned(font_address)));
		
		end if;
	end process;
	
	
end Behavioral;