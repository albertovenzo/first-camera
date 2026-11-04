library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library first_camera;

use first_camera.all;


entity TB_MEMORY_INTERFACE is
end entity;


architecture stimuli of TB_MEMORY_INTERFACE is 

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

signal PIXOUT : std_logic_vector(63 downto 0);
signal GRAY_WRITE_ADDR : std_logic_vector(3 downto 0);
signal GRAY_READ_ADDR : std_logic_vector(3 downto 0);
signal FIFO_READ_EN : std_logic;
signal FIFO_READ_ADDR : std_logic_vector(3 downto 0);

-- camera related signals
signal CVALID : std_logic;
signal CREADY : std_logic;
signal CDATA : std_logic_vector(63 downto 0);
signal SYNC_FRAME : std_logic;

-- TB types
type stimuli_state_type is (IDLE, WAIT_SYNC_END, WAIT_DATA, SEND_CDATA, WAIT_NEXT_DATA);
signal current_camera_fsm_state : stimuli_state_type;

begin

----------------------------------------------------------------
-- Component instantiantion
----------------------------------------------------------------
uut: entity first_camera.MEMORY_INTERFACE
port map(
  CLK => CLK, --: in std_logic; -- high speed clock
  RST => RST, --: in std_logic;
  PCLK => PCLK, --: in std_logic;
  EN => EN, --: in std_logic;
  -- Camera signals
  CVALID => CVALID, --: in std_logic; -- camera valid signal
  CREADY => CREADY, --: out std_logic; -- camera ready signal
  CDATA => CDATA, --: in std_logic_vector(63 downto 0); -- camera data signals
  SYNC_FRAME => SYNC_FRAME, --: in std_logic; -- must be asserted when a new frame starts
  -- S2MM signals
  s2mm_err => '0', --: in std_logic;
  s_axis_s2mm_cmd_tvalid => S2MCTVALID, --: out std_logic;
  s_axis_s2mm_cmd_tready => S2MCTREADY, --: in std_logic;
  s_axis_s2mm_cmd_tdata => S2MCTDATA, --: out std_logic_vector( 71 downto 0 );
  m_axis_s2mm_sts_tvalid => '0', --: in std_logic;
  m_axis_s2mm_sts_tready => open, --: out std_logic;
  m_axis_s2mm_sts_tdata => X"00", --: in std_logic_vector( 7 downto 0 );
  m_axis_s2mm_sts_tkeep => open, --: out std_logic_vector( 0 to 0 );
  m_axis_s2mm_sts_tlast => '0', --: in std_logic;
  s_axis_s2mm_tdata => S2MDTDATA, --: out std_logic_vector( 63 downto 0 );
  s_axis_s2mm_tkeep => S2MDTKEEP, --: out std_logic_vector( 7 downto 0 );
  s_axis_s2mm_tlast => S2MDTLAST, --: out std_logic;
  s_axis_s2mm_tvalid => S2MDTVALID, --: out std_logic;
  s_axis_s2mm_tready => S2MDTREADY, --: in std_logic;
  -- MM2S signals
  mm2s_err => '0', --: in std_logic;
  s_axis_mm2s_cmd_tvalid => M2SCTVALID, --: out std_logic;
  s_axis_mm2s_cmd_tready => M2SCTREADY, --: in std_logic;
  s_axis_mm2s_cmd_tdata => M2SCTDATA, --: out std_logic_vector( 71 downto 0 );
  m_axis_mm2s_sts_tvalid => '0', --: in std_logic;
  m_axis_mm2s_sts_tready => open, --: out std_logic;
  m_axis_mm2s_sts_tdata => X"00", --: in std_logic_vector( 7 downto 0 );
  m_axis_mm2s_sts_tkeep => "0", --: in std_logic_vector( 0 to 0 );
  m_axis_mm2s_sts_tlast => '0', --: in std_logic;
  m_axis_mm2s_tdata => M2SDTDATA, --: in std_logic_vector( 63 downto 0 );
  m_axis_mm2s_tkeep => M2SDTKEEP, --: in std_logic_vector( 7 downto 0 );
  m_axis_mm2s_tlast => M2SDTLAST, --: in std_logic;
  m_axis_mm2s_tvalid => M2SDTVALID, --: in std_logic;
  m_axis_mm2s_tready => M2SDTREADY, --: out std_logic;
  -- signals to pixel loader
  PIXOUT => PIXOUT, --: out std_logic_vector(63 downto 0);
  GRAY_WRITE_ADDR => GRAY_WRITE_ADDR, --: out std_logic_vector(3 downto 0);
  GRAY_READ_ADDR => GRAY_READ_ADDR,
  -- signal from pixel loader
  FIFO_READ_EN => FIFO_READ_EN,
  FIFO_READ_ADDR => FIFO_READ_ADDR --: in std_logic_vector(3 downto 0);
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

-- !! To be changed in case of DM real case simulation !! --
S2MCTREADY <= '1';
S2MDTREADY <= '1';
-- !! !! --

stimuli_process: process(CLK, PCLK)

variable tready_count : integer := 0;
variable frame_count : integer := 0;
variable command_received : boolean := false;
variable fifo_addr_d, fifo_addr_dd : std_logic_vector(3 downto 0);
variable loader_count : integer := 0;
variable loader_count_grey : std_logic_vector(3 downto 0);

variable tdata : integer := 0;

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

  if PCLK'event and PCLK = '1' then
    if RST = '1' then
      loader_count := 0;
    elsif FIFO_READ_EN = '1' then
      loader_count := loader_count + 1;
      if loader_count > 15 then
        loader_count := 0;
      end if;
    end if;

    case loader_count is
      when 0 =>
        loader_count_grey := "0000";
      when 1 =>
        loader_count_grey := "0001";
      when 2 =>
        loader_count_grey := "0011";
      when 3 =>
        loader_count_grey := "0010";
      when 4 =>
        loader_count_grey := "0110";
      when 5 =>
        loader_count_grey := "0111";
      when 6 =>
        loader_count_grey := "0101";
      when 7 =>
        loader_count_grey := "0100";
      when 8 =>
        loader_count_grey := "1100";
      when 9 =>
        loader_count_grey := "1101";
      when 10 =>
        loader_count_grey := "1111";
      when 11 =>
        loader_count_grey := "1110";
      when 12 =>
        loader_count_grey := "1010";
      when 13 =>
        loader_count_grey := "1011";
      when 14 =>
        loader_count_grey := "1001";
      when 15 =>
        loader_count_grey := "1000";
      when others =>
        loader_count_grey := "XXXX";
    end case;

    FIFO_READ_EN <= M2SDTVALID;
    FIFO_READ_ADDR <= std_logic_vector(to_unsigned(loader_count, 4));

    GRAY_READ_ADDR <= fifo_addr_dd;
    fifo_addr_dd := fifo_addr_d;
    fifo_addr_d := loader_count_grey;
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
