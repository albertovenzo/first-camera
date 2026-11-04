library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library xil_defaultlib;
use xil_defaultlib.all;


entity tb_timing_generator is
end entity;

architecture stimuli of tb_timing_generator is

signal PCLK : std_logic := '0';

signal vid_pVDE : std_logic;
signal vid_pHSync : std_logic;
signal vid_pVSync : std_logic;
		
signal pixel_x, pixel_y : std_logic_vector(15 downto 0);

begin

PCLK <= not PCLK after 20 ns; -- 25 MHz

timing_generator_0: entity xil_defaultlib.timing_generator
generic map(
  RESOLUTION   =>  "VGA", --: string  := "HD720P"; -- hd1080p, hd720p, svga, vga
  GEN_PIX_LOC  =>  true, --: boolean := true;
  OBJECT_SIZE  =>  16 --: natural := 16
)
port map(
  clk  => PCLK, --: in  std_logic;
  hsync => vid_PHSync,
  vsync  => vid_pVSync, --: out std_logic;
  video_active  =>  vid_pVDE, --: out std_logic;
  pixel_x       =>  pixel_x, --: out std_logic_vector(OBJECT_SIZE-1 downto 0);
  pixel_y       =>  pixel_y --: out std_logic_vector(OBJECT_SIZE-1 downto 0)
);

end architecture;
