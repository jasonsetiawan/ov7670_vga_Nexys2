----------------------------------------------------------------------------------
-- This entity controls pixel reading and writing from camera to memory
-- The raw data is 640 x 480 pixels, 
	-- For nexys2, it is recommended to use 160 x 120
	-- href_hold is used to scale the width, it is scale by 8,
		-- because 1 pixel acquirement process needs 40ns from pclk pulse
	-- row is used to scale the vertical pixels. Divided by 4.
-----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_capture is
    Port ( pclk : in  STD_LOGIC;
           vsync : in  STD_LOGIC;
           href : in  STD_LOGIC;
           d : in  STD_LOGIC_VECTOR (7 downto 0);
           addr : out  STD_LOGIC_VECTOR (14 downto 0);
           dout : out  STD_LOGIC_VECTOR (11 downto 0);
           we : out  STD_LOGIC_VECTOR (0 downto 0));
end ov7670_capture;

architecture Behavioral of ov7670_capture is
   signal d_latch      : std_logic_vector(15 downto 0) := (others => '0');
   signal address      : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
   signal row         : std_logic_vector(1 downto 0)  := (others => '0');
   signal href_last    : std_logic_vector(6 downto 0)  := (others => '0');
   signal we_reg       : std_logic := '0';
   signal href_hold    : std_logic := '0';
   signal latched_vsync : STD_LOGIC := '0';
   signal latched_href  : STD_LOGIC := '0';
   signal latched_d     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
begin
   addr <= address;
   we(0) <= we_reg;
   dout<= d_latch(15 downto 12) & d_latch(10 downto 7) & d_latch(4 downto 1); 
   
capture_process: process(pclk)
   begin
      if rising_edge(pclk) then
         if we_reg = '1' then
            address <= std_logic_vector(unsigned(address)+1);
         end if;

         -- detect the rising edge on href - the start of the scan row
         if href_hold = '0' and latched_href = '1' then
            case row is
               when "00"   => row <= "01";
               when "01"   => row <= "10";
               when "10"   => row <= "11";
               when others => row <= "00";
            end case;
         end if;
         href_hold <= latched_href;
         
         -- capturing the data from the camera, 12-bit RGB
         if latched_href = '1' then
            d_latch <= d_latch(7 downto 0) & latched_d;
         end if;
         we_reg  <= '0';

         -- Is a new screen about to start (i.e. we have to restart capturing
         if latched_vsync = '1' then 
            address      <= (others => '0');
            href_last    <= (others => '0');
            row         <= (others => '0');
         else
            -- If not, set the write enable whenever we need to capture a pixel
            if href_last(href_last'high) = '1' then
               if row = "10" then
                  we_reg <= '1';
               end if;
               href_last <= (others => '0');
            else
               href_last <= href_last(href_last'high-1 downto 0) & latched_href;
            end if;
         end if;
      end if;
      if falling_edge(pclk) then
         latched_d     <= d;
         latched_href  <= href;
         latched_vsync <= vsync;
      end if;
   end process;
end Behavioral;
