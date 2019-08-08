----------------------------------------------------------------------------------
-- OV7670 -- FPGA -- VGA -- Monitor
-- The 1st revision
-- Revision : 
	-- Adjustment several entities so they can fit with the top module.
	-- Generate single clock modificator.
-- Credit:
	-- Thanks to Mike Field for Registers Reference
-- Your design might has diffent pin assignment.
-- Discuss with me by email : Jason Danny Setiawan [jasondannysetiawan@gmail.com]
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Top is
	Port	(	clk50	: in STD_LOGIC; -- Crystal Oscilator 50MHz  --B8
				pb		: in STD_LOGIC; -- Push Button --B18
				led : out STD_LOGIC; -- Indicates configuration has been done --J14
			  
				-- OV7670
				ov7670_pclk  : in  STD_LOGIC; -- Pmod JB8 --R16
				ov7670_xclk  : out STD_LOGIC; -- Pmod JB2 --R18
				ov7670_vsync : in  STD_LOGIC; -- Pmod JB9 --T18
				ov7670_href  : in  STD_LOGIC; -- Pmod JB3 --R15
				ov7670_data  : in  STD_LOGIC_vector(7 downto 0);
									-- D0 : Pmod JA2 --K12 			-- D4 : Pmod JA4  --M15
									-- D1 : Pmod JA8 --L16			-- D5 : Pmod JA10 --M16
									-- D2 : Pmod JA3 --L17			-- D6 : Pmod JB1  --M13
									-- D3 : Pmod JA9 --M14			-- D7 : Pmod JB7  --P17
				ov7670_sioc  : out STD_LOGIC; -- Pmod JB10 --J12
				ov7670_siod  : inout STD_LOGIC; -- Pmod JB4 --H16
				ov7670_pwdn  : out STD_LOGIC; -- Pmod JA1 --L15
				ov7670_reset : out STD_LOGIC; -- Pmod JA7 --K13
				
				--VGA
				vga_hsync : out STD_LOGIC; --T4
				vga_vsync : out STD_LOGIC; --U3
				vga_rgb	: out STD_LOGIC_VECTOR(7 downto 0)
				-- R : R9(MSB), T8, R8
				-- G : N8, P8, P6
				-- Bc: U5, U4(LSB) 
			 );
end Top;

architecture Structural of Top is

COMPONENT debounce_circuit
	Port ( clk : in STD_LOGIC;
			 input : in STD_LOGIC;
			 output : out STD_LOGIC);
END COMPONENT;

COMPONENT clk25gen
	Port ( clk50 : in  STD_LOGIC;
          clk25 : out  STD_LOGIC);
END COMPONENT;

COMPONENT ov7670_capture
	Port ( pclk : in  STD_LOGIC;
          vsync : in  STD_LOGIC;
          href : in  STD_LOGIC;
          d : in  STD_LOGIC_VECTOR (7 downto 0);
          addr : out  STD_LOGIC_VECTOR (14 downto 0);
          dout : out  STD_LOGIC_VECTOR (11 downto 0);
          we : out  STD_LOGIC_VECTOR (0 downto 0));
END COMPONENT;

COMPONENT ov7670_controller
	Port ( clk : in  STD_LOGIC;
          resend : in  STD_LOGIC;
          sioc : out  STD_LOGIC;
          siod : inout  STD_LOGIC;
          conf_done : out  STD_LOGIC;
          pwdn : out  STD_LOGIC;
			 reset: out  STD_LOGIC;
			 xclk_in : in  STD_LOGIC;
          xclk_out: out  STD_LOGIC);
END COMPONENT;

COMPONENT frame_buffer
	Port ( clkA : in STD_LOGIC;
			 weA	: in STD_LOGIC_VECTOR(0 downto 0);
			 addrA: in STD_LOGIC_VECTOR(14 downto 0);
			 dinA	: in STD_LOGIC_VECTOR(11 downto 0);
			 clkB : in STD_LOGIC;
			 addrB: in STD_LOGIC_VECTOR(14 downto 0);
			 doutB: out STD_LOGIC_VECTOR(11 downto 0));
END COMPONENT;

COMPONENT vga_imagegenerator
	Port ( Data_in : in  STD_LOGIC_VECTOR (11 downto 0);
          active_area : in  STD_LOGIC;
          RGB_out : out  STD_LOGIC_VECTOR (7 downto 0));
END COMPONENT;

COMPONENT address_generator
	Port ( clk25 : in STD_LOGIC;
			 enable : in STD_LOGIC;
			 vsync : in STD_LOGIC;
			 address : out STD_LOGIC_VECTOR (14 downto 0));
END COMPONENT;

COMPONENT VGA_timing_synch
	Port ( clk25 : in  STD_LOGIC;
          Hsync : out  STD_LOGIC;
          Vsync : out  STD_LOGIC;
          activeArea : out  STD_LOGIC);
END COMPONENT;

signal clk25 : STD_LOGIC;
signal resend : STD_LOGIC;

-- RAM
signal wren : STD_LOGIC_VECTOR(0 downto 0);
signal wr_d: STD_LOGIC_VECTOR(11 downto 0);
signal wr_a: STD_LOGIC_VECTOR(14 downto 0);
signal rd_d: STD_LOGIC_VECTOR(11 downto 0);
signal rd_a: STD_LOGIC_VECTOR(14 downto 0);

--VGA
signal active : STD_LOGIC;
signal vga_vsync_sig : STD_LOGIC;

begin
	inst_clk25: clk25gen port map(
		clk50 => clk50,
		clk25 => clk25);
	
	inst_debounce: debounce_circuit port map(
		clk => clk50,
		input => pb,
		output => resend);
	
	inst_ov7670contr: ov7670_controller port map(
		clk => clk50,
		resend => resend,
		sioc => ov7670_sioc,
		siod => ov7670_siod,
		conf_done => led,
		pwdn => ov7670_pwdn,
		reset => ov7670_reset,
		xclk_in => clk25,
		xclk_out => ov7670_xclk);
	
	inst_ov7670capt: ov7670_capture port map(
		pclk => ov7670_pclk,
		vsync => ov7670_vsync,
		href => ov7670_href,
		d => ov7670_data,
		addr => wr_a,
		dout => wr_d,
		we => wren);
	
	inst_framebuffer : frame_buffer port map(
		weA => wren,
		clkA => ov7670_pclk,
		addrA => wr_a,
		dinA => wr_d,
		clkB => clk25,
		addrB => rd_a,
		doutB => rd_d);
	
	inst_addrgen : address_generator port map(
		clk25 => clk25,
		enable => active,
		vsync => vga_vsync_sig,
		address => rd_a);

	inst_imagegen : vga_imagegenerator port map(
		Data_in => rd_d,
		active_area => active,
		RGB_out => vga_rgb);
	
	inst_vgatiming : VGA_timing_synch port map(
		clk25 => clk25,
		Hsync => vga_hsync,
		Vsync => vga_vsync_sig,
		activeArea => active);

vga_vsync <= vga_vsync_sig;

end Structural;

