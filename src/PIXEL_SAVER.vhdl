library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity PIXEL_SAVER is
port(
  CLK : in std_logic; -- System clock 125 MHz
  RST : in std_logic; -- System Reset
  VSYNC : in std_logic;
  HREF : in std_logic;
  PCLK : in std_logic;
  PIXIN : in std_logic_vector(7 downto 0);
  EN : in std_logic;
  TVALID : out std_logic;
  TREADY : in std_logic;
  SYNC_FRAME : out std_logic;
  PIXOUT : out std_logic_vector(63 downto 0)
);
end entity;


architecture behavioral of PIXEL_SAVER is

signal vsync_d, href_d, pclk_d : std_logic; -- delayed signals
signal vsync_dd, href_dd, pclk_dd : std_logic;
signal pixin_d : std_logic_vector(7 downto 0);
signal pixin_dd : std_logic_vector(7 downto 0);
signal pixout_internal : std_logic_vector(63 downto 0);
signal enable_internal_shift_register : std_logic;

signal current_pixel_count,  next_pixel_count: unsigned(2 downto 0);
signal reset_pixel_counter, enable_pixel_counter : std_logic;

type pixel_saver_fsm_state_type is (
  PIXEL_SAVER_FSM_STATE_RESET,
  PIXEL_SAVER_FSM_STATE_IDLE,
  PIXEL_SAVER_FSM_STATE_WAIT_VSYNC,
  PIXEL_SAVER_FSM_STATE_FILTER_GLITCH,
  PIXEL_SAVER_FSM_STATE_WAIT_VSYNC_END,
  PIXEL_SAVER_FSM_STATE_WAIT_HREF,
  PIXEL_SAVER_FSM_STATE_FILTER_HREF_GLITCH,
  PIXEL_SAVER_FSM_STATE_WAIT_PCLK,
  PIXEL_SAVER_FSM_STATE_SAMPLE_PIXEL,
  PIXEL_SAVER_FSM_STATE_SEND_WORD,
  PIXEL_SAVER_FSM_STATE_WAIT_PCLK_END
);

signal current_state, next_state : pixel_saver_fsm_state_type;

begin

-- datapath
sample_inputs_process: process(CLK)
begin
  if CLK'event and CLK= '1' then
    vsync_d <= VSYNC;
    href_d <= HREF;
    pclk_d <= PCLK;
    pixin_d <= PIXIN;
  end if;
end process;

second_sample_stage_process: process(CLK)
begin
  if CLK'event and CLK = '1' then
    vsync_dd <= vsync_d;
		href_dd <= href_d;
		pclk_dd <= pclk_d;
		pixin_dd <= pixin_d;
  end if;
end process;


internal_shift_register_label: for I in 0 to 7 generate

  first_reg_label: if I = 0 generate
    pixel_shift_register: process(CLK)
    begin
      if CLK'event and CLK = '1' then
        if RST = '1' then
          pixout_internal( (8*I+7) downto 8*I ) <= std_logic_vector(to_unsigned(0,pixin_dd'length));
        elsif enable_internal_shift_register = '1' then
          pixout_internal( (8*I+7) downto 8*I ) <= pixin_dd;
        end if;
      end if;
    end process;
  end generate;

  reg_label: if  I > 0 generate
    pixel_shift_register: process(CLK)
    begin
      if CLK'event and CLK = '1' then
        if RST = '1' then
          pixout_internal( (8*I+7) downto 8*I ) <= std_logic_vector(to_unsigned(0,pixin_dd'length));
        elsif enable_internal_shift_register = '1' then
          pixout_internal( (8*I+7) downto 8*I ) <= pixout_internal( 8*(I-1)+7 downto 8*(I-1) );
        end if;
      end if;
    end process;
  end generate;

end generate;

pixel_counter_process: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if reset_pixel_counter = '1' then
      current_pixel_count <= to_unsigned(0, current_pixel_count'length);
    elsif enable_pixel_counter = '1' then
      current_pixel_count <= next_pixel_count;
    end if;
  end if;
end process;

next_pixel_count <= current_pixel_count + 1; 

--fsm
state_process: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if RST = '1' then
      current_state <= PIXEL_SAVER_FSM_STATE_RESET;
    else
      current_state <= next_state;
    end if;
  end if;
end process;

combinatorial_process: process(current_state, EN, current_pixel_count, vsync_dd, href_dd, pclk_dd)
begin

  TVALID <= '0';
  reset_pixel_counter <= '0';
  enable_pixel_counter <= '0';
  enable_internal_shift_register <= '0';

  -- TREADY -- kept for future use

  case current_state is
    when PIXEL_SAVER_FSM_STATE_RESET =>

      TVALID <= '0';
      reset_pixel_counter <= '1';
      enable_pixel_counter <= '0';
      enable_internal_shift_register <= '0';

      next_state <= PIXEL_SAVER_FSM_STATE_IDLE;

    when PIXEL_SAVER_FSM_STATE_IDLE =>

      TVALID <= '0';
      reset_pixel_counter <= '1';
      enable_pixel_counter <= '0';
      enable_internal_shift_register <= '0';

      if EN = '1' then
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_VSYNC;
      else
        next_state <= PIXEL_SAVER_FSM_STATE_IDLE;
      end if;

    when PIXEL_SAVER_FSM_STATE_WAIT_VSYNC =>

      TVALID <= '0';
      reset_pixel_counter <= '1';
      enable_pixel_counter <= '0';
      enable_internal_shift_register <= '0';

      if vsync_dd = '1' then
        next_state <= PIXEL_SAVER_FSM_STATE_FILTER_GLITCH;
      else
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_VSYNC;
      end if;

    when PIXEL_SAVER_FSM_STATE_FILTER_GLITCH =>

      TVALID <= '0';
      reset_pixel_counter <= '0';
      enable_pixel_counter <= '0';
      enable_internal_shift_register <= '0';

      if vsync_dd = '1' then
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_VSYNC_END;
      else
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_VSYNC;
      end if;


    when PIXEL_SAVER_FSM_STATE_WAIT_VSYNC_END =>

      TVALID <= '0';
      reset_pixel_counter <= '1';
      enable_pixel_counter <= '0';
      enable_internal_shift_register <= '0';

      if vsync_dd = '0' then
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_HREF;
      else
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_VSYNC_END;
      end if;


    when PIXEL_SAVER_FSM_STATE_WAIT_HREF =>

      TVALID <= '0';
      reset_pixel_counter <= '1';
      enable_pixel_counter <= '0';
      enable_internal_shift_register <= '0';

      if href_dd = '1' then
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_PCLK;
      elsif vsync_dd = '1' then
        next_state <= PIXEL_SAVER_FSM_STATE_FILTER_HREF_GLITCH;
      else
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_HREF;
      end if;

when PIXEL_SAVER_FSM_STATE_FILTER_HREF_GLITCH =>

      TVALID <= '0';
      reset_pixel_counter <= '0';
      enable_pixel_counter <= '0';
      enable_internal_shift_register <= '0';

      if vsync_dd = '1' then
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_VSYNC;
      else
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_HREF;
      end if;

    when PIXEL_SAVER_FSM_STATE_WAIT_PCLK =>

      TVALID <= '0';
      reset_pixel_counter <= '0';
      enable_pixel_counter <= '0';
      enable_internal_shift_register <= '0';
      
      if href_dd = '0' then
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_HREF;
      elsif pclk_dd = '1' then
        next_state <= PIXEL_SAVER_FSM_STATE_SAMPLE_PIXEL; 
      else
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_PCLK;
      end if;

    when PIXEL_SAVER_FSM_STATE_SAMPLE_PIXEL =>

      TVALID <= '0';
      reset_pixel_counter <= '0';
      enable_pixel_counter <= '1';
      enable_internal_shift_register <= '1';

      if current_pixel_count = to_unsigned(7,current_pixel_count'length) then
        next_state <= PIXEL_SAVER_FSM_STATE_SEND_WORD; 
      else
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_PCLK_END; 
      end if;

    when PIXEL_SAVER_FSM_STATE_SEND_WORD =>

      TVALID <= '1';
      reset_pixel_counter <= '1';
      enable_pixel_counter <= '0';
      enable_internal_shift_register <= '0';
      
      next_state <= PIXEL_SAVER_FSM_STATE_WAIT_PCLK_END; 

    when PIXEL_SAVER_FSM_STATE_WAIT_PCLK_END =>

      TVALID <= '0';
      reset_pixel_counter <= '0';
      enable_pixel_counter <= '0';
      enable_internal_shift_register <= '0';

      if EN = '0' then
        next_state <= PIXEL_SAVER_FSM_STATE_IDLE;
      elsif pclk_dd = '0' then
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_PCLK; 
      else
        next_state <= PIXEL_SAVER_FSM_STATE_WAIT_PCLK_END;
      end if;

    when others =>

      TVALID <= '0';
      reset_pixel_counter <= '1';
      enable_pixel_counter <= '0';
      enable_internal_shift_register <= '0';
      
      next_state <= PIXEL_SAVER_FSM_STATE_RESET;

  end case;

end process;

SYNC_FRAME <= vsync_dd;
PIXOUT <= pixout_internal;

end architecture; -- behavioral
