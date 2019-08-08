--------------------------------------------------------
-- Read Datasheet for further knowledge.
-- Thanks to Mike Field for the design
--------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_SCCB is
    Port ( clk : in  STD_LOGIC;
           reg_value : in  STD_LOGIC_VECTOR (7 downto 0);
           slave_addr : in  STD_LOGIC_VECTOR (7 downto 0);
           addr_reg : in  STD_LOGIC_VECTOR (7 downto 0);
           send : in  STD_LOGIC;
           siod : inout  STD_LOGIC;
           sioc : out  STD_LOGIC;
           taken : out  STD_LOGIC);
end ov7670_SCCB;

architecture Behavioral of ov7670_SCCB is 

-- Scaler is being used to manipulate the siod and sioc timing based on 50MHz clock,
-- See datasheet for timing.(View Tcyc (SCCB app.note) and Taa & Tdh (OV7670/7671 datasheet). 
-- Status Register is adjusted from pg. 10 SCCB app. note
signal scaler  : unsigned (7 downto 0) := x"01";
signal busy_sr : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal data_sr : STD_LOGIC_VECTOR(31 downto 0) := (others => '1');

begin
	process(busy_sr, data_sr(31)) begin
		if busy_sr(11 downto 10) = "10" or 
			busy_sr(20 downto 19) = "10" or
			busy_sr(29 downto 28) = "10" then
			siod <= 'Z'; -- Don't Care Bit, see pg.10 and pg.13.
		else
			siod <= data_sr(31); -- Serial (I2C like)
		end if;
	end process;

	process(clk) begin
		if rising_edge(clk) then
			taken <= '0';
			if busy_sr(31) = '0' then
				sioc <= '1';
				if send = '1' then
					if scaler = "00000000" then
						data_sr <= "100" & slave_addr & '0' & addr_reg & '0' & reg_value & '0' & "01";-- see pg.10
						busy_sr <= "111" & "111111111" & "111111111" & "111111111" & "11"; -- pg.10
						taken <= '1';
					else
						scaler <= scaler+1; -- this only happens once each cycle
					end if;
				end if;
			else
				case busy_sr(31 downto 29) & busy_sr(2 downto 0) is
					when "111"&"111" => -- start seq #1
						sioc <= '1';
					when "111"&"110" => -- start seq #2
						sioc <= '1';
					when "111"&"100" => -- start seq #3
						sioc <= '0';
					when "110"&"000" => -- end seq #1
						case scaler(7 downto 6) is
							when "00" => sioc <= '0';
							when "01" => sioc <= '1';
							when "10" => sioc <= '1';
							when others => sioc <= '1';
						end case;
					when "100"&"000" => -- end seq #2
						case scaler(7 downto 6) is
							when "00" => sioc <= '1';
							when "01" => sioc <= '1';
							when "10" => sioc <= '1';
							when others => sioc <= '1';
						end case;
					when "000"&"000" => -- Idle
						case scaler(7 downto 6) is
							when "00" => sioc <= '1';
							when "01" => sioc <= '1';
							when "10" => sioc <= '1';
							when others => sioc <= '1';
						end case;
					when others => -- normal waveform, adjusted with Taa and Tdh. See pg.11-13
						case scaler(7 downto 6) is
							when "00" => sioc <= '0';
							when "01" => sioc <= '1';
							when "10" => sioc <= '1';
							when others => sioc <= '0';
						end case;
				end case;
				if scaler = "11111111" then
					busy_sr <= busy_sr(30 downto 0) & '0'; -- Shift with 0
					data_sr <= data_sr(30 downto 0) & '1'; -- Shift with 1
					scaler <= (others => '0');
				else
					scaler <= scaler+1;
				end if;
			end if;
		end if;
	end process;
end Behavioral;
