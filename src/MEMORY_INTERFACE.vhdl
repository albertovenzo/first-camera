library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;


entity MEMORY_INTERFACE is
port(
  CLK : in std_logic; -- high speed clock
  RST : in std_logic;
  PCLK : in std_logic;
  EN : in std_logic;
  VSYNC : in std_logic;
  -- Camera signals
  CVALID : in std_logic; -- camera valid signal
  CREADY : out std_logic; -- camera ready signal
  CDATA : in std_logic_vector(63 downto 0); -- camera data signals
  SYNC_FRAME : in std_logic; -- must be asserted when a new frame starts
  -- S2MM signals
  s2mm_err : in std_logic;
  s_axis_s2mm_cmd_tvalid : out std_logic;
  s_axis_s2mm_cmd_tready : in std_logic;
  s_axis_s2mm_cmd_tdata : out std_logic_vector( 71 downto 0 );
  m_axis_s2mm_sts_tvalid : in std_logic;
  m_axis_s2mm_sts_tready : out std_logic;
  m_axis_s2mm_sts_tdata : in std_logic_vector( 7 downto 0 );
  m_axis_s2mm_sts_tkeep : out std_logic_vector( 0 to 0 );
  m_axis_s2mm_sts_tlast : in std_logic;
  s_axis_s2mm_tdata : out std_logic_vector( 63 downto 0 );
  s_axis_s2mm_tkeep : out std_logic_vector( 7 downto 0 );
  s_axis_s2mm_tlast : out std_logic;
  s_axis_s2mm_tvalid : out std_logic;
  s_axis_s2mm_tready : in std_logic;
  -- MM2S signals
  mm2s_err : in std_logic;
  s_axis_mm2s_cmd_tvalid : out std_logic;
  s_axis_mm2s_cmd_tready : in std_logic;
  s_axis_mm2s_cmd_tdata : out std_logic_vector( 71 downto 0 );
  m_axis_mm2s_sts_tvalid : in std_logic;
  m_axis_mm2s_sts_tready : out std_logic;
  m_axis_mm2s_sts_tdata : in std_logic_vector( 7 downto 0 );
  m_axis_mm2s_sts_tkeep : in std_logic_vector( 0 to 0 );
  m_axis_mm2s_sts_tlast : in std_logic;
  m_axis_mm2s_tdata : in std_logic_vector( 63 downto 0 );
  m_axis_mm2s_tkeep : in std_logic_vector( 7 downto 0 );
  m_axis_mm2s_tlast : in std_logic;
  m_axis_mm2s_tvalid : in std_logic;
  m_axis_mm2s_tready : out std_logic;
  -- signals to pixel loader
  PIXOUT : out std_logic_vector(63 downto 0);
  GRAY_WRITE_ADDR : out std_logic_vector(3 downto 0);
  GRAY_READ_ADDR : in std_logic_vector(3 downto 0);
  -- signal from pixel loader
  FIFO_READ_EN : in std_logic;
  FIFO_READ_ADDR : in std_logic_vector(3 downto 0)
);
end entity;

architecture behavioral of MEMORY_INTERFACE is

signal cdata_d, cdata_dd: std_logic_vector(63 downto 0);
signal cvalid_d : std_logic;
signal camera_data_valid : std_logic;
signal change_address : std_logic;
signal s2m_register_value, s2m_register_next_value : std_logic_vector(31 downto 0);
signal m2s_register_value: std_logic_vector(31 downto 0);
signal m2s_sample_frame_address : std_logic;
signal sync_frame_d : std_logic;

----------------------------------------------------------------
-- GREY coding signals
----------------------------------------------------------------
signal input_binary, output_gray: std_logic_vector(3 downto 0);
signal input_gray, output_binary: std_logic_vector(3 downto 0);

----------------------------------------------------------------
-- Memory signals
----------------------------------------------------------------
signal m2s_base_frame_address : std_logic_vector(31 downto 0);

signal s2m_frame_address : unsigned(31 downto 0);
signal s2m_sample_frame_address : std_logic;
signal m_axis_mm2s_tready_internal : std_logic;

signal reset_s2m_offset_counter : std_logic;
signal enable_s2m_offset_counter : std_logic;
signal s2m_current_offset : unsigned(31 downto 0);
signal s2m_next_offset : unsigned(31 downto 0);
signal s2m_current_address : unsigned(31 downto 0);
signal s2m_next_address : unsigned(31 downto 0);
signal enable_s2m_address_register : std_logic;

----------------------------------------------------------------
-- Fifo signals
----------------------------------------------------------------
signal m2s_fifo_current_write_address, m2s_fifo_next_write_address : unsigned(3 downto 0);
signal m2s_fifo_read_address_gray_d, m2s_fifo_read_address_gray_dd : std_logic_vector(3 downto 0);
signal m2s_fifo_current_read_address : unsigned(3 downto 0);
signal m2s_fifo_write_enable : std_logic;
signal m2s_fifo_read_enable : std_logic;
signal fifo_counter_enable : std_logic;
signal reset_fifo_counter : std_logic;

----------------------------------------------------------------
-- FSM Signals and type definition
----------------------------------------------------------------
type memory_interface_s2m_state_type is (
  MEMORY_INTERFACE_S2M_STATE_RESET,
  MEMORY_INTERFACE_S2M_STATE_IDLE,
  MEMORY_INTERFACE_S2M_STATE_WAIT_SYNC,
  MEMORY_INTERFACE_S2M_STATE_WAIT_DATA,
  MEMORY_INTERFACE_S2M_STATE_SET_MEMORY_ADDRESS,
  MEMORY_INTERFACE_S2M_STATE_INC_OFFSET,
  MEMORY_INTERFACE_S2M_STATE_SEND_COMMAND,
  MEMORY_INTERFACE_S2M_STATE_SEND_DATA,
  MEMORY_INTERFACE_S2M_STATE_CHANGE_ADDRESS, 
  MEMORY_INTERFACE_S2M_STATE_NEXT_SYNC
);

type memory_interface_m2s_state_type is (
  MEMORY_INTERFACE_M2S_STATE_RESET,
  MEMORY_INTERFACE_M2S_STATE_IDLE,
  MEMORY_INTERFACE_M2S_WAIT_VSYNC,
  MEMORY_INTERFACE_M2S_STATE_SAMPLE_FRAME_ADDRESS,
  MEMORY_INTERFACE_M2S_STATE_SEND_CMD,
  MEMORY_INTERFACE_M2S_STATE_LOAD_DATA,
  MEMORY_INTERFACE_M2S_STATE_WAIT_FIFO_BOTTLENECK
);

signal s2m_current_state, s2m_next_state : memory_interface_s2m_state_type;
signal m2s_current_state, m2s_next_state : memory_interface_m2s_state_type;


begin
----------------------------------------------------------------
-- Stream to Memory Mapped section (S2M)
----------------------------------------------------------------
camera_input_sampler: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if RST = '1' then
      cdata_d <= (others => '0');
      cvalid_d <= '0';
      sync_frame_d <= '0';
    else
      cdata_d <= CDATA;
      cvalid_d <= CVALID;
      sync_frame_d <= SYNC_FRAME;
    end if;
  end if;
end process;

camera_data_valid <= cvalid_d;
CREADY <= '1'; -- stuck at '1' since it is not used

valid_data_sampler : process(CLK)
begin
  if CLK'event and CLK = '1' then
    if camera_data_valid = '1' then
      cdata_dd <= cdata_d;
    end if;
  end if;
end process;

s_axis_s2mm_tdata <= cdata_dd;

m2s_register: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if RST = '1' then
      m2s_register_value <= (others => '0');
    elsif change_address = '1' then
      m2s_register_value <= s2m_register_value;
    end if;
  end if;
end process;

s2m_register: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if RST = '1' then
      s2m_register_value <= (24 => '1', others => '0');
    elsif change_address = '1' then
      s2m_register_value <= s2m_register_next_value;
    end if;
  end if;
end process;

s2m_register_next_value(31 downto 26) <= s2m_register_value(31 downto 26); 
s2m_register_next_value(25) <= not s2m_register_value(25);
s2m_register_next_value(24 downto 0) <= s2m_register_value(24 downto 0); 

s2m_frame_address <= unsigned(s2m_register_value);

s2m_offset_counter: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if reset_s2m_offset_counter = '1' then
      s2m_current_offset <= to_unsigned(0, 32);
		elsif enable_s2m_offset_counter = '1' then
      s2m_current_offset <= s2m_next_offset;
    end if;
  end if;
end process;

s2m_next_offset <= s2m_current_offset + 8;

s2m_next_address <= s2m_frame_address + s2m_current_offset ;

s2m_address_register: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if enable_s2m_address_register = '1' then
      s2m_current_address <= s2m_next_address;
    end if;
  end if;
end process;

s_axis_s2mm_cmd_tdata(22 downto 0) <= std_logic_vector(to_unsigned(8, 23));
s_axis_s2mm_cmd_tdata(23) <= '1';
s_axis_s2mm_cmd_tdata(29 downto 24) <= "000000";
s_axis_s2mm_cmd_tdata(30) <= '1';
s_axis_s2mm_cmd_tdata(31) <= '0';
s_axis_s2mm_cmd_tdata(63 downto 32) <= std_logic_vector(s2m_current_address);
s_axis_s2mm_cmd_tdata(67 downto 64) <= "0000";
s_axis_s2mm_cmd_tdata(71 downto 68) <= "0000";


s2m_fsm_sequential_part: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if RST = '1' then
      s2m_current_state <= MEMORY_INTERFACE_S2M_STATE_RESET;
    else
      s2m_current_state <= s2m_next_state;
    end if;
  end if;
end process;

s2m_fsm_next_state_combinational_part: process(s2m_current_state, EN,
  cvalid_d, sync_frame_d, s_axis_s2mm_cmd_tready, s_axis_s2mm_tready)
begin

  case s2m_current_state is

    when MEMORY_INTERFACE_S2M_STATE_RESET =>
      s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_IDLE;

    when MEMORY_INTERFACE_S2M_STATE_IDLE =>
      if EN = '1' then
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_WAIT_SYNC;
      else
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_IDLE;
      end if;

    when MEMORY_INTERFACE_S2M_STATE_WAIT_SYNC => 
      if sync_frame_d = '1' then
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_WAIT_DATA;
      else
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_WAIT_SYNC;
      end if;

    when MEMORY_INTERFACE_S2M_STATE_WAIT_DATA =>
      if sync_frame_d = '1' then
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_CHANGE_ADDRESS;
      elsif cvalid_d = '1' then
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_SET_MEMORY_ADDRESS;
      else
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_WAIT_DATA;
      end if;

    when MEMORY_INTERFACE_S2M_STATE_SET_MEMORY_ADDRESS =>
      s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_INC_OFFSET;

    when MEMORY_INTERFACE_S2M_STATE_INC_OFFSET =>
      s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_SEND_COMMAND;

    when MEMORY_INTERFACE_S2M_STATE_SEND_COMMAND =>
      if s_axis_s2mm_cmd_tready = '1' then
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_SEND_DATA;
      else
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_SEND_COMMAND;
      end if;

    when MEMORY_INTERFACE_S2M_STATE_SEND_DATA =>
      if EN = '0' then
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_IDLE;
      elsif s_axis_s2mm_tready = '1' then
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_WAIT_DATA;
      else
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_SEND_DATA;
      end if;

    when MEMORY_INTERFACE_S2M_STATE_CHANGE_ADDRESS => 
      s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_NEXT_SYNC;

    when MEMORY_INTERFACE_S2M_STATE_NEXT_SYNC =>
      if sync_frame_d = '0' then
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_WAIT_DATA;
      else
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_NEXT_SYNC;
      end if;

    when others =>
        s2m_next_state <= MEMORY_INTERFACE_S2M_STATE_RESET;

  end case;
end process;

s2m_fsm_next_output_combinational_part: process(s2m_current_state)
begin
  m_axis_s2mm_sts_tready <= '1';
  s_axis_s2mm_cmd_tvalid <= '0';
  s_axis_s2mm_tkeep <= "0000" & "0000";
  s_axis_s2mm_tlast <= '0';
  s_axis_s2mm_tvalid <= '0';
  reset_s2m_offset_counter <= '1';
  enable_s2m_offset_counter <= '0';
  enable_s2m_address_register <= '0';
  change_address <= '0';

  case s2m_current_state is

    when MEMORY_INTERFACE_S2M_STATE_RESET =>

    when MEMORY_INTERFACE_S2M_STATE_IDLE =>

    when MEMORY_INTERFACE_S2M_STATE_WAIT_SYNC => 

    when MEMORY_INTERFACE_S2M_STATE_WAIT_DATA =>
      reset_s2m_offset_counter <= '0';

    when MEMORY_INTERFACE_S2M_STATE_SET_MEMORY_ADDRESS =>
      enable_s2m_address_register <= '1';
      reset_s2m_offset_counter <= '0';

    when MEMORY_INTERFACE_S2M_STATE_INC_OFFSET =>
      reset_s2m_offset_counter <= '0';
      enable_s2m_offset_counter <= '1';

    when MEMORY_INTERFACE_S2M_STATE_SEND_COMMAND =>
      s_axis_s2mm_cmd_tvalid <= '1';
      reset_s2m_offset_counter <= '0';

    when MEMORY_INTERFACE_S2M_STATE_SEND_DATA =>
      s_axis_s2mm_tkeep <= "1111" & "1111";
      s_axis_s2mm_tlast <= '1';
      s_axis_s2mm_tvalid <= '1';
      reset_s2m_offset_counter <= '0';

    when MEMORY_INTERFACE_S2M_STATE_CHANGE_ADDRESS =>
      change_address <= '1';

    when MEMORY_INTERFACE_S2M_STATE_NEXT_SYNC =>

    when others =>

  end case;
end process;

----------------------------------------------------------------
-- END Stream to Memory Mapped section (S2M)
----------------------------------------------------------------
----------------------------------------------------------------
-- Memory Mapped to stream section (M2S)
----------------------------------------------------------------

frame_address_sample_register: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if m2s_sample_frame_address = '1' then
      m2s_base_frame_address <= m2s_register_value;
    end if;
  end if;
end process;

input_binary <= std_logic_vector(m2s_fifo_current_write_address);

with input_binary select
  output_gray <= "0000" when "0000",
                 "0001" when "0001",
                 "0011" when "0010",
                 "0010" when "0011",
                 "0110" when "0100",
                 "0111" when "0101",
                 "0101" when "0110",
                 "0100" when "0111",
                 "1100" when "1000",
                 "1101" when "1001",
                 "1111" when "1010",
                 "1110" when "1011",
                 "1010" when "1100",
                 "1011" when "1101",
                 "1001" when "1110",
                 "1000" when "1111",
                 "XXXX" when others;

GRAY_WRITE_ADDR <= output_gray;

-- cdc stage and convertion to binary of gray cdc read address
gray_cdc_stage: process(CLK)
begin
  if CLK'event and CLK = '1' then
    m2s_fifo_read_address_gray_d <= GRAY_READ_ADDR;
    m2s_fifo_read_address_gray_dd <= m2s_fifo_read_address_gray_d;
  end if;

end process; --grey_cdc_stage

input_gray <= m2s_fifo_read_address_gray_dd; 

with input_gray select
  output_binary <= "0000" when "0000",
                   "0001" when "0001",
                   "0010" when "0011",
                   "0011" when "0010",
                   "0100" when "0110",
                   "0101" when "0111",
                   "0110" when "0101",
                   "0111" when "0100",
                   "1000" when "1100",
                   "1001" when "1101",
                   "1010" when "1111",
                   "1011" when "1110",
                   "1100" when "1010",
                   "1101" when "1011",
                   "1110" when "1001",
                   "1111" when "1000",
                   "XXXX" when others;

m2s_fifo_current_read_address <= unsigned(output_binary);
-- END cdc stage and convertion to binary of gray cdc read address

-- fifo instance
m2s_fifo_read_enable <= FIFO_READ_EN;

m2s_fifo_memory_process: process(CLK, PCLK)
  type m2s_fifo_mem_t is array(0 to 15) of std_logic_vector(63 downto 0);
  variable m2s_fifo_memory : m2s_fifo_mem_t;

  begin
    if CLK'event and CLK = '1' then
      if m2s_fifo_write_enable = '1' then
        m2s_fifo_memory(to_integer(m2s_fifo_current_write_address)) := m_axis_mm2s_tdata; 
      end if;
    end if;
    if PCLK'event and PCLK = '1' then
      if m2s_fifo_read_enable = '1' then
          PIXOUT <= m2s_fifo_memory(to_integer(unsigned(FIFO_READ_ADDR)));
      end if;
    end if;
  end process; -- m2s_fifo_memory

fifo_counter_enable <= m_axis_mm2s_tready_internal and  m_axis_mm2s_tvalid;
m2s_fifo_write_enable <= fifo_counter_enable;

-- fifo counter
fifo_counter: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if reset_fifo_counter = '1' then
      m2s_fifo_current_write_address <= to_unsigned(0, 4);
    elsif fifo_counter_enable = '1' then
      m2s_fifo_current_write_address <= m2s_fifo_next_write_address;
    end if;
  end if;
end process;

m2s_fifo_next_write_address <= m2s_fifo_current_write_address + 1;
-- END fifo counter

-- FSM 
m2s_fsm_sequential_part: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if RST = '1' then
      m2s_current_state <= MEMORY_INTERFACE_M2S_STATE_RESET;
    else
      m2s_current_state <= m2s_next_state;
    end if;
  end if;
end process;

s_axis_mm2s_cmd_tdata(22 downto 0) <= std_logic_vector(to_unsigned(307200, 23)); -- read an entire frame command
s_axis_mm2s_cmd_tdata(31 downto 23) <= (23 => '1', 30 => '1', others => '0'); 
s_axis_mm2s_cmd_tdata(63 downto 32) <= m2s_base_frame_address;
s_axis_mm2s_cmd_tdata(67 downto 64) <= "0000";
s_axis_mm2s_cmd_tdata(71 downto 68) <= "0000";

m2s_fsm_combinational_part: process(m2s_current_state, EN, s_axis_mm2s_cmd_tready, 
  m2s_fifo_current_write_address, m2s_fifo_next_write_address, m2s_fifo_current_read_address, m_axis_mm2s_tlast )
begin

    m_axis_mm2s_sts_tready <= '1'; -- not used
    m_axis_mm2s_tready_internal <= '0';
    s_axis_mm2s_cmd_tvalid <= '0';

    reset_fifo_counter <= '0';
    m2s_sample_frame_address <= '0';

  case m2s_current_state is
    
    when MEMORY_INTERFACE_M2S_STATE_RESET =>
      reset_fifo_counter <= '1';
      m2s_next_state <= MEMORY_INTERFACE_M2S_STATE_IDLE;

    when MEMORY_INTERFACE_M2S_STATE_IDLE => 
      m2s_sample_frame_address <= '1';
      if EN = '1' then
        m2s_next_state <= MEMORY_INTERFACE_M2S_WAIT_VSYNC;
      else
        m2s_next_state <= MEMORY_INTERFACE_M2S_STATE_IDLE;
      end if;

    when MEMORY_INTERFACE_M2S_WAIT_VSYNC =>
      m2s_sample_frame_address <= '1';
      if VSYNC = '0' then
        m2s_next_state <= MEMORY_INTERFACE_M2S_STATE_SEND_CMD;
      else
        m2s_next_state <= MEMORY_INTERFACE_M2S_WAIT_VSYNC;
      end if;
  
    when MEMORY_INTERFACE_M2S_STATE_SEND_CMD =>
      s_axis_mm2s_cmd_tvalid <= '1';

      if s_axis_mm2s_cmd_tready = '1' then
        m2s_next_state <= MEMORY_INTERFACE_M2S_STATE_LOAD_DATA;
      else
        m2s_next_state <= MEMORY_INTERFACE_M2S_STATE_SEND_CMD;
      end if;

    when MEMORY_INTERFACE_M2S_STATE_LOAD_DATA =>
      m_axis_mm2s_tready_internal <= '1';

      if m_axis_mm2s_tlast = '1' then
        if EN = '1' then
          m2s_next_state <=MEMORY_INTERFACE_M2S_STATE_IDLE;
        else
          m2s_next_state <=MEMORY_INTERFACE_M2S_WAIT_VSYNC;
        end if;
      elsif m2s_fifo_next_write_address + 8 = m2s_fifo_current_read_address then
        m2s_next_state <= MEMORY_INTERFACE_M2S_STATE_WAIT_FIFO_BOTTLENECK;
      else
        m2s_next_state <= MEMORY_INTERFACE_M2S_STATE_LOAD_DATA;
      end if;

    when MEMORY_INTERFACE_M2S_STATE_WAIT_FIFO_BOTTLENECK =>

      if m2s_fifo_current_write_address + 8 /= m2s_fifo_current_read_address then
        m2s_next_state <= MEMORY_INTERFACE_M2S_STATE_LOAD_DATA;
      else
        m2s_next_state <= MEMORY_INTERFACE_M2S_STATE_WAIT_FIFO_BOTTLENECK;
      end if;
    when others =>
      m2s_next_state <= MEMORY_INTERFACE_M2S_STATE_RESET;

  end case;

end process;

m_axis_mm2s_tready <= m_axis_mm2s_tready_internal;

----------------------------------------------------------------
-- END Memory Mapped to stream section (M2S)
----------------------------------------------------------------


end architecture; -- MEMORY_INTERFACE
