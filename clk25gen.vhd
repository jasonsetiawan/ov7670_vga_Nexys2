----------------------------------------------------------------------------------
-- This entity converts 50MHz clock to 25MHz clock.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk25gen is
    Port ( clk50 : in  STD_LOGIC;
           clk25 : out  STD_LOGIC);
end clk25gen;

architecture Behavioral of clk25gen is
signal clkbuf : STD_LOGIC := '0';
begin
	process (clk50) begin
		if rising_edge(clk50) then
			clk25 <= not(clkbuf);
			clkbuf <= not (clkbuf);
		end if;
	end process;
end Behavioral;

