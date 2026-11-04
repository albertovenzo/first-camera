----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/11/2025 07:57:12 PM
-- Design Name: 
-- Module Name: TOP - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TOP is
    Port ( 
           sysclk : in STD_LOGIC;
           hdmi_tx_hpd : out STD_LOGIC;
           hdmi_tx_scl : out STD_LOGIC;
           hdmi_tx_sda : inout std_logic;
           hdmi_tx_clk_n : out std_logic;
           hdmi_tx_clk_p : out std_logic;
           hdmi_tx_n : out STD_LOGIC_VECTOR(2 downto 0);
           hdmi_tx_p : out STD_LOGIC_VECTOR(2 downto 0);
           sw : in STD_LOGIC_VECTOR (3 downto 0);
           btn : in STD_LOGIC_VECTOR (3 downto 0);
           led : out STD_LOGIC_VECTOR (3 downto 0);
           jc : out STD_LOGIC_VECTOR (7 downto 0);
           jd : in STD_LOGIC_VECTOR (7 downto 0);
           je: in STD_LOGIC_VECTOR (7 downto 0));
end TOP;

architecture Behavioral of TOP is

-- Output to Image Sensor
signal XVCLK : std_logic;
signal XVCLK_LOCKED : std_logic;
signal RST: std_logic;
signal RST_N: std_logic;
signal PWDN : std_logic;
signal POWER_EN : std_logic;

-- Input from Image Sensor
signal D : std_logic_vector(7 downto 0);
signal VSYNC, HREF, PCLK : std_logic;

signal current_count, next_count : unsigned(23 downto 0);

signal DDR_addr: STD_LOGIC_VECTOR ( 14 downto 0 );
signal DDR_ba: STD_LOGIC_VECTOR ( 2 downto 0 );
signal DDR_cas_n: STD_LOGIC;
signal DDR_ck_n : STD_LOGIC;
signal DDR_ck_p : STD_LOGIC;
signal DDR_cke : STD_LOGIC;
signal DDR_cs_n : STD_LOGIC;
signal DDR_dm : STD_LOGIC_VECTOR ( 3 downto 0 );
signal DDR_dq : STD_LOGIC_VECTOR ( 31 downto 0 );
signal DDR_dqs_n : STD_LOGIC_VECTOR ( 3 downto 0 );
signal DDR_dqs_p : STD_LOGIC_VECTOR ( 3 downto 0 );
signal DDR_odt : STD_LOGIC;
signal DDR_ras_n : STD_LOGIC;
signal DDR_reset_n : STD_LOGIC;
signal DDR_we_n : STD_LOGIC;
signal FIXED_IO_ddr_vrn : STD_LOGIC;
signal FIXED_IO_ddr_vrp : STD_LOGIC;
signal FIXED_IO_mio : STD_LOGIC_VECTOR ( 53 downto 0 );
signal FIXED_IO_ps_clk : STD_LOGIC;
signal FIXED_IO_ps_porb : STD_LOGIC;
signal FIXED_IO_ps_srstb : STD_LOGIC;


signal PixelClk : STD_LOGIC;
signal SerialClk : STD_LOGIC;
signal TMDS_Clk_n : STD_LOGIC;
signal TMDS_Clk_p : STD_LOGIC;
signal TMDS_Data_n : STD_LOGIC_VECTOR ( 2 downto 0 );
signal TMDS_Data_p : STD_LOGIC_VECTOR ( 2 downto 0 );
signal aRst : STD_LOGIC;
signal vid_pData : STD_LOGIC_VECTOR ( 23 downto 0 );
signal vid_pHSync : STD_LOGIC;
signal vid_pVDE : STD_LOGIC;
signal vid_pVSync: STD_LOGIC;

signal pixel_x, pixel_y : STD_LOGIC_VECTOR(15 downto 0);

signal CVALID : std_logic;
signal CDATA : std_logic_vector(63 downto 0);
signal SYNC_FRAME : std_logic;

signal PIXOUT : std_logic_vector(63 downto 0);
signal GRAY_WRITE_ADDR : std_logic_vector(3 downto 0);
signal PIXIN : std_logic_vector(63 downto 0);
signal RGBPX : std_logic_vector(23 downto 0);
signal GRAY_READ_ADDR : std_logic_vector(3 downto 0);
signal FIFO_READ_ADDR : std_logic_vector(3 downto 0);
signal FIFO_READ_EN : std_logic;

----------------------------------------------------------------
-- AXI Signals
----------------------------------------------------------------
signal m_axis_mm2s_sts_tdata : std_logic_vector(7 downto 0);
signal m_axis_mm2s_sts_tkeep : std_logic_vector(0 to 0);
signal m_axis_mm2s_sts_tlast : std_logic;
signal m_axis_mm2s_sts_tready : std_logic;
signal m_axis_mm2s_sts_tvalid : std_logic;
signal m_axis_mm2s_tdata : std_logic_vector(63 downto 0);
signal m_axis_mm2s_tkeep : std_logic_vector(7 downto 0);
signal m_axis_mm2s_tlast : std_logic;
signal m_axis_mm2s_tready : std_logic;
signal m_axis_mm2s_tvalid : std_logic;
signal m_axis_s2mm_sts_tdata : std_logic_vector(7 downto 0);
signal m_axis_s2mm_sts_tkeep : std_logic_vector(0 to 0);
signal m_axis_s2mm_sts_tlast : std_logic;
signal m_axis_s2mm_sts_tready : std_logic;
signal m_axis_s2mm_sts_tvalid : std_logic;
signal mm2s_err : std_logic;
signal reset_rtl : std_logic;
signal s2mm_err : std_logic;
signal s_axis_mm2s_cmd_tdata : std_logic_vector(71 downto 0);
signal s_axis_mm2s_cmd_tready : std_logic;
signal s_axis_mm2s_cmd_tvalid : std_logic;
signal s_axis_s2mm_cmd_tdata : std_logic_vector(71 downto 0);
signal s_axis_s2mm_cmd_tready : std_logic;
signal s_axis_s2mm_cmd_tvalid : std_logic;
signal s_axis_s2mm_tdata : std_logic_vector(63 downto 0);
signal s_axis_s2mm_tkeep : std_logic_vector(7 downto 0);
signal s_axis_s2mm_tlast : std_logic;
signal s_axis_s2mm_tready : std_logic;
signal s_axis_s2mm_tvalid : std_logic;


begin

RST_N <= not RST;
RST <= not XVCLK_LOCKED;
reset_rtl <= RST;

processing_system_label: entity xil_defaultlib.FirstCameraIP_wrapper
  port map(
    DDR_addr => DDR_addr,
    DDR_ba => DDR_ba,
    DDR_cas_n => DDR_cas_n,
    DDR_ck_n => DDR_ck_n,
    DDR_ck_p => DDR_ck_p,
    DDR_cke => DDR_cke,
    DDR_cs_n => DDR_cs_n,
    DDR_dm => DDR_dm,
    DDR_dq => DDR_dq,
    DDR_dqs_n => DDR_dqs_n,
    DDR_dqs_p => DDR_dqs_p,
    DDR_odt => DDR_odt,
    DDR_ras_n => DDR_ras_n,
    DDR_reset_n => DDR_reset_n,
    DDR_we_n => DDR_we_n,
    FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
    FIXED_IO_mio => FIXED_IO_mio,
    FIXED_IO_ps_clk => FIXED_IO_ps_clk,
    FIXED_IO_ps_porb => FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
    HCLK => SerialClk,
    m_axis_mm2s_sts_tdata =>  m_axis_mm2s_sts_tdata,
    m_axis_mm2s_sts_tkeep =>  m_axis_mm2s_sts_tkeep,
    m_axis_mm2s_sts_tlast =>  m_axis_mm2s_sts_tlast,
    m_axis_mm2s_sts_tready =>  m_axis_mm2s_sts_tready,
    m_axis_mm2s_sts_tvalid =>  m_axis_mm2s_sts_tvalid,
    m_axis_mm2s_tdata =>  m_axis_mm2s_tdata,
    m_axis_mm2s_tkeep =>  m_axis_mm2s_tkeep,
    m_axis_mm2s_tlast =>  m_axis_mm2s_tlast,
    m_axis_mm2s_tready =>  m_axis_mm2s_tready,
    m_axis_mm2s_tvalid =>  m_axis_mm2s_tvalid,
    m_axis_s2mm_sts_tdata =>  m_axis_s2mm_sts_tdata,
    m_axis_s2mm_sts_tkeep =>  m_axis_s2mm_sts_tkeep,
    m_axis_s2mm_sts_tlast =>  m_axis_s2mm_sts_tlast,
    m_axis_s2mm_sts_tready =>  m_axis_s2mm_sts_tready,
    m_axis_s2mm_sts_tvalid =>  m_axis_s2mm_sts_tvalid,
    mm2s_err =>  mm2s_err,
    reset_rtl =>  reset_rtl,
    s2mm_err =>  s2mm_err,
    s_axis_mm2s_cmd_tdata =>  s_axis_mm2s_cmd_tdata,
    s_axis_mm2s_cmd_tready =>  s_axis_mm2s_cmd_tready,
    s_axis_mm2s_cmd_tvalid =>  s_axis_mm2s_cmd_tvalid,
    s_axis_s2mm_cmd_tdata =>  s_axis_s2mm_cmd_tdata,
    s_axis_s2mm_cmd_tready =>  s_axis_s2mm_cmd_tready,
    s_axis_s2mm_cmd_tvalid =>  s_axis_s2mm_cmd_tvalid,
    s_axis_s2mm_tdata =>  s_axis_s2mm_tdata,
    s_axis_s2mm_tkeep =>  s_axis_s2mm_tkeep,
    s_axis_s2mm_tlast =>  s_axis_s2mm_tlast,
    s_axis_s2mm_tready =>  s_axis_s2mm_tready,
    s_axis_s2mm_tvalid =>  s_axis_s2mm_tvalid 
 );

pll_instance : entity xil_defaultlib.XVCLK_PLL_wrapper
  port map(
    LOCKED => XVCLK_LOCKED,
    SerialClk => SerialClk,
    XVCLK => XVCLK,
    reset_rtl => '0',
    sys_clock => sysclk
  );
  
pwdn_signal_block : entity xil_defaultlib.PWDN
    port map( 
        CLK => XVCLK,
        RST => RST,
        EN => POWER_EN,
        PWDN => PWDN
        );

power_enable_signal_block: entity xil_defaultlib.POWER_EN
  port map(
    CLK => XVCLK,
    RST => RST,
    EN => sw(1),
    POWER_EN => POWER_EN
    );

next_count <= current_count + 1;

camera_clock_blinker : process(XVCLK)
begin
  if XVCLK'event and XVCLK = '1' then
    if (RST = '1') then
      current_count <= to_unsigned(0, 24);
    else
      current_count <= next_count;
    end if;
  end if;
end process;

hdmi_dvi_interface: entity HDMI_INT_wrapper
  port map(
    PixelClk => XVCLK,
    SerialClk => SerialClk,
    TMDS_Clk_n => TMDS_Clk_n,  
    TMDS_Clk_p => TMDS_Clk_p, 
    TMDS_Data_n => TMDS_Data_n, 
    TMDS_Data_p => TMDS_Data_p, 
    aRst => aRst,
    vid_pData => vid_pData, 
    vid_pHSync => vid_pHSync,
    vid_pVDE => vid_pVDE,
    vid_pVSync => vid_pVSync
  );

timing_generator_0: entity xil_defaultlib.timing_generator
generic map(
  RESOLUTION   =>  "VGA",
  GEN_PIX_LOC  =>  true,
  OBJECT_SIZE  =>  16
)
port map(
  clk  =>  XVCLK,
  hsync => vid_PHSync,
  vsync  => vid_pVSync,
  video_active  => vid_pVDE,
  pixel_x =>  pixel_x,
  pixel_y =>  pixel_y
);

-- Video Signals
PixelClk <= XVCLK;
vid_pData <= RGBPX;

hdmi_tx_hpd <= '1';
hdmi_tx_clk_n <=  TMDS_Clk_n;
hdmi_tx_clk_p <= TMDS_Clk_p;
hdmi_tx_n <= TMDS_Data_n;
hdmi_tx_p <= TMDS_Data_p;

-- Camera Signals
-- OUTPUTS
jc(0) <= XVCLK;
jc(1) <= XVCLK_LOCKED;
jc(2) <= PWDN;
jc(3) <= POWER_EN;

jc(7 downto 4) <= (others => '0');
led(0) <= RST;
led(1) <= sw(1);
led(2) <= std_logic(current_count(current_count'left));
led(3) <= PWDN;

-- INPUTS
D(0) <= je(0);
D(1) <= je(1);
D(2) <= je(2);
D(3) <= je(3);
D(4) <= je(4);
D(5) <= je(5);
D(6) <= je(6);
D(7) <= je(7);

VSYNC <= jd(0);
HREF <= jd(1);
PCLK <= jd(2);

-- Camera IP
pixel_saver_inst: entity xil_defaultlib.PIXEL_SAVER
port map(
  CLK =>  SerialClk,
  RST =>  RST,
  VSYNC => VSYNC,
  HREF => HREF,
  PCLK => PCLK,
  PIXIN => D,
  EN =>  POWER_EN,
  TVALID => CVALID,
  TREADY =>  '1',
	SYNC_FRAME => SYNC_FRAME,
  PIXOUT => CDATA
);

mem_int_inst: entity xil_defaultlib.MEMORY_INTERFACE
port map(
  CLK =>  SerialClk,
  RST =>  RST,
  PCLK =>  XVCLK,
  EN =>  POWER_EN,
  -- Camera signals
  CVALID =>  CVALID,
  CREADY =>  open,
  CDATA =>  CDATA,
  SYNC_FRAME => SYNC_FRAME,
  -- S2MM signals
  s2mm_err => s2mm_err,
  s_axis_s2mm_cmd_tvalid => s_axis_s2mm_cmd_tvalid,
  s_axis_s2mm_cmd_tready => s_axis_s2mm_cmd_tready,
  s_axis_s2mm_cmd_tdata => s_axis_s2mm_cmd_tdata,
  m_axis_s2mm_sts_tvalid => m_axis_s2mm_sts_tvalid,
  m_axis_s2mm_sts_tready => m_axis_s2mm_sts_tready,
  m_axis_s2mm_sts_tdata => m_axis_s2mm_sts_tdata,
  m_axis_s2mm_sts_tkeep => m_axis_s2mm_sts_tkeep,
  m_axis_s2mm_sts_tlast => m_axis_s2mm_sts_tlast,
  s_axis_s2mm_tdata => s_axis_s2mm_tdata,
  s_axis_s2mm_tkeep => s_axis_s2mm_tkeep,
  s_axis_s2mm_tlast => s_axis_s2mm_tlast,
  s_axis_s2mm_tvalid => s_axis_s2mm_tvalid,
  s_axis_s2mm_tready => s_axis_s2mm_tready,
  -- MM2S signals
  mm2s_err => mm2s_err,
  s_axis_mm2s_cmd_tvalid => s_axis_mm2s_cmd_tvalid,
  s_axis_mm2s_cmd_tready => s_axis_mm2s_cmd_tready,
  s_axis_mm2s_cmd_tdata => s_axis_mm2s_cmd_tdata,
  m_axis_mm2s_sts_tvalid => m_axis_mm2s_sts_tvalid,
  m_axis_mm2s_sts_tready => m_axis_mm2s_sts_tready,
  m_axis_mm2s_sts_tdata => m_axis_mm2s_sts_tdata,
  m_axis_mm2s_sts_tkeep => m_axis_mm2s_sts_tkeep,
  m_axis_mm2s_sts_tlast => m_axis_mm2s_sts_tlast,
  m_axis_mm2s_tdata => m_axis_mm2s_tdata,
  m_axis_mm2s_tkeep => m_axis_mm2s_tkeep,
  m_axis_mm2s_tlast => m_axis_mm2s_tlast,
  m_axis_mm2s_tvalid => m_axis_mm2s_tvalid,
  m_axis_mm2s_tready => m_axis_mm2s_tready,
  -- signals to pixel loader
  PIXOUT => PIXOUT,
  GRAY_WRITE_ADDR => GRAY_WRITE_ADDR,
  GRAY_READ_ADDR => GRAY_READ_ADDR,
  -- signal from pixel loader
  FIFO_READ_EN => FIFO_READ_EN,
  FIFO_READ_ADDR => FIFO_READ_ADDR 
);

pixel_loader_inst: entity xil_defaultlib.PIXEL_LOADER
port map(
  CLK => SerialClk,
  RST => RST,
  VDE => vid_pVDE,
  EN => POWER_EN,
  GRAY_WRITE_ADDR => GRAY_WRITE_ADDR,
  PIXIN => PIXOUT,
  RGBPX => RGBPX,
  GRAY_READ_ADDR => GRAY_READ_ADDR,
  FIFO_READ_ADDR => FIFO_READ_ADDR,
  FIFO_READ_EN => FIFO_READ_EN 
);

end Behavioral;
