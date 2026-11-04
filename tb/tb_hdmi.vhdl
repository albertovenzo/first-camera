library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library xil_defaultlib;
use xil_defaultlib.all;


entity TB_HDMI is
end entity;

architecture stimuli of TB_HDMI is

signal RST, RST_N : std_logic;
signal CLK : std_logic := '0';

signal TMDS_Clk_p : std_logic;
signal TMDS_Clk_n : std_logic;
signal TMDS_Data_p : std_logic_vector(2 downto 0);
signal TMDS_Data_n : std_logic_vector(2 downto 0);

signal vid_pData : std_logic_vector(23 downto 0);
signal vid_pVDE : std_logic;
signal vid_pHSync : std_logic;
signal vid_pVSync : std_logic;
signal PixelClk : std_logic := '0';
signal SerialClk : std_logic := '0';
		
signal pixel_x, pixel_y : std_logic_vector(15 downto 0);

begin

CLK <= not CLK after 4 ns; -- 125 MHz

-- Unit under test instantiation
uut: entity xil_defaultlib.HDMI_INT_wrapper
port map(
  -- DVI 1.0 TMDS video interface
  TMDS_Clk_p => TMDS_Clk_p,  --: out std_logic;
  TMDS_Clk_n => TMDS_Clk_n,  --: out std_logic;
  TMDS_Data_p => TMDS_Data_p,  --: out std_logic_vector(2 downto 0);
  TMDS_Data_n => TMDS_Data_n,  --: out std_logic_vector(2 downto 0);
  aRst => RST,  --: in std_logic; --asynchronous reset; must be reset when RefClk is not within spec

  vid_pData => vid_pData,  --: in std_logic_vector(23 downto 0);
  vid_pVDE => vid_pVDE,  --: in std_logic;
  vid_pHSync => vid_pHSync,  --: in std_logic;
  vid_pVSync => vid_pVSync,  --: in std_logic;
  SerialClk => SerialClk,
  PixelClk => PixelClk  --: in std_logic; --pixel-clock recovered from the DVI interface
);

clock_gen_0: entity xil_defaultlib.clock_gen
generic map(
  CLKIN_PERIOD =>  8.0000, --:    real := 8.000;  -- input clock period (8ns)
  CLK_MULTIPLY =>  8, --: integer := 8;      -- multiplier
  CLK_DIVIDE   =>  1, --: integer := 1;      -- divider
  CLKOUT0_DIV  =>  8, --: integer := 8;      -- serial clock divider
  CLKOUT1_DIV  =>  40 --: integer := 40      -- pixel clock divider
)
port map(
  clk_i  => CLK, --: in  std_logic; --  input clock
  clk0_o => SerialClk, --: out std_logic; -- serial clock
  clk1_o => PixelClk --: out std_logic  --  pixel clock
);

timing_generator_0: entity xil_defaultlib.timing_generator
generic map(
  RESOLUTION   =>  "VGA", --: string  := "HD720P"; -- hd1080p, hd720p, svga, vga
  GEN_PIX_LOC  =>  true, --: boolean := true;
  OBJECT_SIZE  =>  16 --: natural := 16
)
port map(
  clk  =>  PixelClk, --: in  std_logic;
  hsync => vid_PHSync,
  vsync  => vid_pVSync, --: out std_logic;
  video_active  =>  vid_pVDE, --: out std_logic;
  pixel_x       =>  pixel_x, --: out std_logic_vector(OBJECT_SIZE-1 downto 0);
  pixel_y       =>  pixel_y --: out std_logic_vector(OBJECT_SIZE-1 downto 0)
);

stimuli_generator: process
begin

RST <= '1';
wait for 10 us;
RST <= '0';

wait for 10 us;
wait until PixelClk'event and PixelClk='1';
vid_pData <= X"B0" & X"CE" & X"88" ;
wait until PixelClk'event and PixelClk='1';

wait;
end process;

RST_N <= not RST;

end architecture;
