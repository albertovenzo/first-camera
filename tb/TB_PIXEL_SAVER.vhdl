library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library first_camera;

use first_camera.all;


entity TB_PIXEL_SAVER is
end entity;


architecture stimuli of TB_PIXEL_SAVER is 

signal CLK : std_logic := '1';
signal PCLK : std_logic := '0';
signal PCLK_N : std_logic;
signal RST, RST_N : std_logic := '0';


signal enable_pixel_saver : std_logic;
signal PIXIN : std_logic_vector(7 downto 0);
signal PIXOUT : std_logic_vector(63 downto 0);

-- camera related signals
signal VSYNC, HREF : std_logic; 
signal memory_valid, memory_ready, bloader_valid, bloader_ready : std_logic;

begin

----------------------------------------------------------------
-- Component instantiantion
----------------------------------------------------------------
binary_loader_label: entity first_camera.BLOADER
port map
(
  CLK => PCLK_N, --: in std_logic; --! Input clock signal
  OUTBYTE => PIXIN, --: out std_logic_vector(7 downto 0); --! Output signal
  VALID => bloader_valid, --: out std_logic; --!  Valid signal from this module
  READY => bloader_ready  --: in std_logic --! Ready signal from slave module
);


uut: entity first_camera.PIXEL_SAVER
port map(
  CLK => CLK, --: in std_logic; -- System clock 125 MHz
  RST => RST, --: in std_logic; -- System Reset
  VSYNC => VSYNC, --: in std_logic;
  HREF => HREF, --: in std_logic;
  PCLK => PCLK, --: in std_logic;
  PIXIN => PIXIN, --: in std_logic_vector(7 downto 0);
  EN => enable_pixel_saver, --: in std_logic;
  TVALID => memory_valid, --: out std_logic;
  TREADY => memory_ready, --: in std_logic;
  PIXOUT => PIXOUT --: out std_logic_vector(63 downto 0)
);

----------------------------------------------------------------
-- End Component instantiantion
----------------------------------------------------------------

----------------------------------------------------------------
-- Stimuli
----------------------------------------------------------------
CLK <= not CLK after 4 ns;
PCLK <= not PCLK after 20 ns;
PCLK_N <= not PCLK;

RST <= '1', '0' after 1.1 us;
enable_pixel_saver <= '0', '1' after 2 us, '0' after 20 ms;
memory_ready <= '1';

vga_camera_signal_generator: process(PCLK)
variable count_pixels : integer := 0;
variable count_lines : integer := 0;

begin
  if PCLK'event and PCLK = '1' then
    count_pixels := count_pixels + 1;
    if count_pixels = 784 then
      count_pixels := 0;
      count_lines := count_lines + 1;
    end if;

    if count_lines = 510 then
      count_lines := 0;
    end if;

    if HREF = '1' then
      bloader_ready <= '1';
    else
      bloader_ready <= '0';
    end if;

  elsif PCLK'event and PCLK = '0' then
    -- VSYNC signaling
    if count_lines <= 3 then
      VSYNC <= '1';
    else
      VSYNC <= '0';
    end if;
  
    -- HREF signaling
    if count_lines >= 17 and count_lines < 497 then
      if count_pixels < 640 then
        HREF <= '1';
      else
        HREF <= '0';
        end if;
    else
      HREF <= '0';
    end if;

  end if;

end process;

end architecture;
