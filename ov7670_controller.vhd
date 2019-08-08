---------------------------------------------
-- simulation completed 2/08/19
-- This entity is needed to setup the camera
	-- Thanks to Mike Field for Register Value
---------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_controller is
    Port ( clk : in  STD_LOGIC;
           resend : in  STD_LOGIC;
           sioc : out  STD_LOGIC;
           siod : inout  STD_LOGIC;
           conf_done : out  STD_LOGIC;
           pwdn : out  STD_LOGIC;
			  reset: out STD_LOGIC;
           xclk_in : in STD_LOGIC;
			  xclk_out : out  STD_LOGIC);
end ov7670_controller;

architecture Behavioral of ov7670_controller is

component ov7670_registers
	Port ( clk : in  STD_LOGIC;
          resend : in  STD_LOGIC;
          advance : in  STD_LOGIC;
          command : out  STD_LOGIC_VECTOR (15 downto 0);
          done : out  STD_LOGIC);
end component;

component ov7670_SCCB
	Port ( clk : in  STD_LOGIC;
          reg_value : in  STD_LOGIC_VECTOR (7 downto 0);
          slave_addr : in  STD_LOGIC_VECTOR (7 downto 0);
          addr_reg : in  STD_LOGIC_VECTOR (7 downto 0);
          send : in  STD_LOGIC;
          siod : inout  STD_LOGIC;
          sioc : out  STD_LOGIC;
          taken : out  STD_LOGIC);
end component;	

signal clk25 : std_logic := '0';
signal command : std_logic_vector(15 downto 0);
signal done : std_logic := '0';
signal taken : std_logic := '0';
signal send : std_logic;
constant camera_address : std_logic_vector(7 downto 0) := x"42"; -- Device write ID, see pg.10. (OV datasheet)

begin
conf_done <= done; -- overall finish
send <= not done;


Registers: ov7670_registers port map(
	clk => clk,
	resend => resend,
	advance => taken,
	command => command,
	done => done);

SCCB : ov7670_SCCB port map(
	clk => clk,
	reg_value => command (7 downto 0),
	slave_addr => camera_address,
	addr_reg => command (15 downto 8),
	send => send,
	sioc => sioc,
	siod => siod,
	taken => taken);

pwdn <= '0';
reset <= '1';
xclk_out <= xclk_in;

end Behavioral;

