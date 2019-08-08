----------------------------------------------------------------------------------
-- 'Command' contains the registers address (8 bit) and 
-- the value assigned to those registers (8 bit). Both of them is concantenated.
-- View datasheet page 10 - 19.  
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_registers is
    Port ( clk : in  STD_LOGIC;
           resend : in  STD_LOGIC;
           advance : in  STD_LOGIC;
           command : out  STD_LOGIC_VECTOR (15 downto 0);
           done : out  STD_LOGIC);
end ov7670_registers;

architecture Behavioral of ov7670_registers is

signal cmd_reg : STD_LOGIC_VECTOR (15 downto 0);
signal sequence : INTEGER := 0;

type cmd_rom is array (0 to 55) of STD_LOGIC_VECTOR (15 downto 0);
constant commandrom : cmd_rom :=(
	0  => x"1280", -- COM7 Reset
	1  => x"1280", -- COM7 Reset
	2  => x"1100", -- CLKRC Prescaler - F(clkin)/(2), disable double speed pll
	3  => x"1204", -- COM7 QIF image with RGB output
	4  => x"0C04", -- COM3 enable scaling
	5  => x"3E00", -- COM14 PCLK scaling off ,3E19 to div by 2
	6  => x"4010", -- COM15 Full 0-255 output, RGB 565
	7  => x"3A04", -- TSLB Set UV ordering, do not auto-reset window
	8  => x"8C00", -- RGB444 Set RGB format
	9  => x"1714", -- HSTART HREF start (high 8 bits)
	10 => x"1802", -- HSTOP HREF stop (high 8 bits)
	11 => x"32A4", -- HREF Edge offset and low 3 bits of HSTART and HSTOP
	12 => x"1903", -- VSTART VSYNC start (high 8 bits)
	13 => x"1A7B", -- VSTOP VSYNC stop (high 8 bits)
	14 => x"030A", -- VREF VSYNC low two bits
	15 => x"703A", -- SCALING_XSC
	16 => x"7135", -- SCALING_YSC
	17 => x"7211", -- SCALING_DCWCTR
	18 => x"73f1", -- SCALING_PCLK_DIV
	19 => x"A202", -- SCALING_PCLK_DELAY PCLK scaling = 4, must match COM14
	20 => x"1500", -- COM10 Use HREF not hSYNC
	21 => x"7A20", -- SLOP
	22 => x"7B10", -- GAM1
	23 => x"7C1E", -- GAM2
	24 => x"7D35", -- GAM3
	25 => x"7E5A", -- GAM4
	26 => x"7F69", -- GAM5
	27 => x"8076", -- GAM6
	28 => x"8180", -- GAM7
	29 => x"8288", -- GAM8
	30 => x"838F", -- GAM9
	31 => x"8496", -- GAM10
	32 => x"85A3", -- GAM11
	33 => x"86AF", -- GAM12
	34 => x"87C4", -- GAM13
	35 => x"88D7", -- GAM14
	36 => x"89E8", -- GAM15
	37 => x"13E0", -- COM8 - AGC, White balance
	38 => x"0000", -- GAIN AGC
	39 => x"1000", -- AECH Exposure
	40 => x"0D40", -- COMM4 - Window Size
	41 => x"1418", -- COMM9 AGC
	42 => x"A505", -- AECGMAX banding filter step
	43 => x"2495", -- AEW AGC Stable upper limite
	44 => x"2533", -- AEB AGC Stable lower limi
	45 => x"26E3", -- VPT AGC fast mode limits
	46 => x"9F78", -- HRL High reference level
	47 => x"A068", -- LRL low reference level
	48 => x"A103", -- DSPC3 DSP control
	49 => x"A6D8", -- LPH Lower Prob High
	50 => x"A7D8", -- UPL Upper Prob Low
	51 => x"A8F0", -- TPL Total Prob Low
	52 => x"A990", -- TPH Total Prob High
	53 => x"AA94", -- NALG AEC Algo select
	54 => x"13E5", -- COM8 AGC Settings
	55 => x"FFFF");-- STOP (using WITH .. SELECT below) 			

begin
command <= cmd_reg;

with cmd_reg select done <= '1' when x"FFFF", '0' when others;

sequence_proc : process (clk) begin
	if rising_edge(clk) then
		if resend = '1' then
			sequence <= 0;
		elsif advance = '1' then
			sequence <= sequence + 1;
		end if;

		cmd_reg <= commandrom(sequence);
		if sequence > 55 then
			cmd_reg <= x"FFFF";
		end if;
	end if;
end process sequence_proc;
end Behavioral;

