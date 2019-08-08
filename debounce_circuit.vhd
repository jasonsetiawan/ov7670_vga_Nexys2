----------------------------------------------------------------------------------
-- It is used to prevent bouncing from push button
	-- Push button will be used for ov7670 instantiation
-- This design will remove bouncing within 300 ms after trigerring process
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce_circuit is
    Port ( clk : in  STD_LOGIC;
           input : in  STD_LOGIC;
           output : out  STD_LOGIC);
end debounce_circuit;

architecture Behavioral of debounce_circuit is

signal counter : unsigned(23 downto 0);

begin
counting_proc : process (clk) begin
	if rising_edge (clk) then
		if input = '1' then
			if counter = x"FFFFFF" then 
			-- Counter will count 2^24 * 20ns
			-- ~300ms
				output <= '1';
			else
			-- Bouncing with high logic below 300ms will not trigger the output
			-- output, this case, pb that reset the camera
				output <= '0';
			end if;
		else
			output <= '0';
		end if;
	end if;
end process counting_proc;
end Behavioral;

