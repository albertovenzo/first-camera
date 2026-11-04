library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library first_camera;

use first_camera.all;


entity TB_MI_PL is
end entity;


architecture stimuli of TB_MI_PL is 

signal CLK : std_logic := '1';
signal PCLK : std_logic := '0';
signal PCLK_N : std_logic;
signal RST, RST_N : std_logic := '0';

signal EN : std_logic;


signal S2MCTVALID : std_logic;
signal S2MCTREADY : std_logic;
signal S2MCTDATA : std_logic_vector(71 downto 0);

signal S2MDTDATA : std_logic_vector(63 downto 0);
signal S2MDTKEEP : std_logic_vector(7 downto 0);
signal S2MDTLAST : std_logic;
signal S2MDTVALID : std_logic;
signal S2MDTREADY : std_logic;

signal M2SCTVALID : std_logic;
signal M2SCTREADY : std_logic;
signal M2SCTDATA : std_logic_vector(71 downto 0);

signal M2SDTDATA : std_logic_vector(63 downto 0);
signal M2SDTKEEP : std_logic_vector(7 downto 0);
signal M2SDTLAST : std_logic;
signal M2SDTVALID : std_logic;
signal M2SDTREADY : std_logic;

--signal PIXOUT : std_logic_vector(63 downto 0);
signal GRAY_WRITE_ADDR : std_logic_vector(3 downto 0);
signal GRAY_READ_ADDR : std_logic_vector(3 downto 0);
signal FIFO_READ_EN : std_logic;
signal FIFO_READ_ADDR : std_logic_vector(3 downto 0);

-- camera related signals
signal CVALID : std_logic;
signal CREADY : std_logic;
signal CDATA : std_logic_vector(63 downto 0);
signal SYNC_FRAME : std_logic;

-- pixel loader signals
signal VDE : std_logic;
signal PIXIN : std_logic_vector(63 downto 0);
signal RGBPX : std_logic_vector(23 downto 0);

-- TB types
type stimuli_state_type is (IDLE, WAIT_SYNC_END, WAIT_DATA, SEND_CDATA, WAIT_NEXT_DATA);
signal current_camera_fsm_state : stimuli_state_type;

begin

----------------------------------------------------------------
-- Component instantiantion
----------------------------------------------------------------
uut1: entity first_camera.MEMORY_INTERFACE
port map(
  CLK => CLK,
  RST => RST,
  PCLK => PCLK,
  EN => EN,
 
  CVALID => CVALID,
  CREADY => CREADY,
  CDATA => CDATA,
  SYNC_FRAME => SYNC_FRAME,
  -- S2MM signals
  s2mm_err => '0',
  s_axis_s2mm_cmd_tvalid => S2MCTVALID,
  s_axis_s2mm_cmd_tready => S2MCTREADY,
  s_axis_s2mm_cmd_tdata => S2MCTDATA,
  m_axis_s2mm_sts_tvalid => '0',
  m_axis_s2mm_sts_tready => open,
  m_axis_s2mm_sts_tdata => X"00",
  m_axis_s2mm_sts_tkeep => open,
  m_axis_s2mm_sts_tlast => '0',
  s_axis_s2mm_tdata => S2MDTDATA,
  s_axis_s2mm_tkeep => S2MDTKEEP,
  s_axis_s2mm_tlast => S2MDTLAST,
  s_axis_s2mm_tvalid => S2MDTVALID,
  s_axis_s2mm_tready => S2MDTREADY,
  -- MM2S signals
  mm2s_err => '0',
  s_axis_mm2s_cmd_tvalid => M2SCTVALID,
  s_axis_mm2s_cmd_tready => M2SCTREADY,
  s_axis_mm2s_cmd_tdata => M2SCTDATA,
  m_axis_mm2s_sts_tvalid => '0',
  m_axis_mm2s_sts_tready => open,
  m_axis_mm2s_sts_tdata => X"00",
  m_axis_mm2s_sts_tkeep => "0",
  m_axis_mm2s_sts_tlast => '0',
  m_axis_mm2s_tdata => M2SDTDATA,
  m_axis_mm2s_tkeep => M2SDTKEEP,
  m_axis_mm2s_tlast => M2SDTLAST,
  m_axis_mm2s_tvalid => M2SDTVALID,
  m_axis_mm2s_tready => M2SDTREADY,
  -- signals to pixel loader
  PIXOUT => PIXIN,
  GRAY_WRITE_ADDR => GRAY_WRITE_ADDR,
  GRAY_READ_ADDR => GRAY_READ_ADDR,
  -- signal from pixel loader
  FIFO_READ_EN => FIFO_READ_EN,
  FIFO_READ_ADDR => FIFO_READ_ADDR
);

uut2: entity first_camera.PIXEL_LOADER
port map(
  CLK => PCLK,
  RST => RST,
  VDE => VDE,
  EN => EN,
  GRAY_WRITE_ADDR => GRAY_WRITE_ADDR,
  PIXIN => PIXIN,
  RGBPX => RGBPX,
  GRAY_READ_ADDR => GRAY_READ_ADDR,
  FIFO_READ_ADDR => FIFO_READ_ADDR,
  FIFO_READ_EN => FIFO_READ_EN 
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
RST_N <= not RST;

VDE <= '0', '1' after 2 ms, '0' after 10 ms, '1' after 20 ms;
-- !! To be changed in case of DM real case simulation !! --
S2MCTREADY <= '1';
S2MDTREADY <= '1';
-- !! !! --

stimuli_process: process(CLK, PCLK)

variable tready_count : integer := 0;
variable frame_count : integer := 0;
variable command_received : boolean := false;

variable tdata : integer := 15;

begin
  if CLK'event and CLK = '1' then
    if RST = '1' then
      tready_count := 0;
      frame_count  := 0;
      command_received := false;
    else
      tready_count := tready_count + 1;
    end if;

    if tready_count >= 1000 then
      M2SCTREADY <= '1';
    end if;

    if tready_count >= 2000 then --and tready_count < 10000 then
      EN <= '1';
    else
      EN <= '0';
    end if;

    if M2SCTREADY = '1' and M2SCTVALID = '1' then
      command_received := true;
      M2SDTDATA <= std_logic_vector(to_unsigned(tdata, 64));
    end if;

    if M2SDTREADY = '1' and M2SDTVALID = '1' then
      tdata := tdata + 1; -- random numbers
      M2SDTDATA <= std_logic_vector(to_unsigned(tdata, 64));
      frame_count := frame_count + 1;
    end if;

    if command_received then

      if frame_count = 640*480 -1 then
        M2SDTLAST <= '1';
      else
        M2SDTLAST <= '0';
      end if;

      if frame_count <= 640*480 -1 then
        M2SDTKEEP <= (others => '1');
        M2SDTVALID <= '1';
      else
        M2SDTKEEP <= (others => '0');
        M2SDTVALID <= '0';
      end if;


    else
      M2SDTKEEP <= (others => '0');
      M2SDTVALID <= '0';
      M2SDTLAST <= '0';

    end if;

  end if;

end process;

pixel_saver_stimuli: process(CLK)

variable state : stimuli_state_type := IDLE;
variable count_lines : integer := 0;
variable count_pixels : integer := 0;
variable count_frame_sync_pulse : integer := 0;
variable wait_count : integer := 0;

begin
  if CLK'event and CLK = '1' then
    if EN = '1' then
      if state = IDLE then
        state := WAIT_SYNC_END;
      end if;
    else
      state := IDLE;
    end if;

    case state is
      when IDLE =>
        count_lines := 0;
        count_pixels := 0;
        count_frame_sync_pulse := 0;
        wait_count := 0;

        SYNC_FRAME <= '0';
        CVALID <= '0';
        CDATA <= (others => '0');

      when WAIT_SYNC_END =>
        CVALID <= '0';
        CDATA <= (others => '0');
        count_frame_sync_pulse := count_frame_sync_pulse + 1;
        if count_frame_sync_pulse <= 25000 then
          SYNC_FRAME <= '1';
        else
          SYNC_FRAME <= '0';
          count_frame_sync_pulse := 0;
          state := WAIT_DATA;
        end if;
          

      when WAIT_DATA =>
        SYNC_FRAME <= '0';
        CVALID <= '0';
        CDATA <= (others => '0');
        wait_count := wait_count + 1;
        if wait_count >= 100 then
          wait_count := 0;
          state := SEND_CDATA;
        end if;

      when SEND_CDATA =>
        SYNC_FRAME <= '0';
        CVALID <= '1';
        count_pixels := count_pixels + 8;
        CDATA <= std_logic_vector(to_unsigned(count_pixels, 64));
        state := WAIT_NEXT_DATA;
        if count_pixels > 639 then
          count_pixels := 0;
          count_lines := count_lines + 1;
        end if;

      when WAIT_NEXT_DATA =>
        SYNC_FRAME <= '0';
        CVALID <= '0';
        CDATA <= (others => '0');
        wait_count := wait_count + 1;
        if wait_count >= 40 then
          wait_count := 0;
          if count_lines > 479 then
            count_lines := 0;
            state := WAIT_SYNC_END;
          else
            state := SEND_CDATA;
          end if;
        end if;

    end case;

  end if;

  current_camera_fsm_state <= state;

end process;

end architecture;
