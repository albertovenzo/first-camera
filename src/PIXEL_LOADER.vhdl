library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity PIXEL_LOADER is
port(
  CLK : in std_logic;
  RST : in std_logic;
  VDE : in std_logic;
  EN : in std_logic;
  GRAY_WRITE_ADDR : in std_logic_vector(3 downto 0);
  PIXIN : in std_logic_vector(63 downto 0);
  RGBPX : out std_logic_vector(23 downto 0);
  GRAY_READ_ADDR : out std_logic_vector(3 downto 0);
  FIFO_READ_ADDR : out std_logic_vector(3 downto 0);
  FIFO_READ_EN : out std_logic
);
end entity; -- PIXEL_LOADER


architecture behavioral of PIXEL_LOADER is 

signal enable_shift_register : std_logic;
signal load_shift_register : std_logic;
signal unlock_shift_register : std_logic;
signal shift_register_array : std_logic_vector(63 downto 0);

signal gray_write_addr_d : std_logic_vector(3 downto 0);
signal gray_write_addr_dd : std_logic_vector(3 downto 0);
signal binary_write_addr : unsigned(3 downto 0);
signal current_read_addr : unsigned(3 downto 0);
signal next_read_addr : unsigned(3 downto 0);

signal inc_read_addr : std_logic;

signal current_pixel_count : unsigned(2 downto 0);
signal next_pixel_count : unsigned(2 downto 0);
signal reset_pixel_counter : std_logic;
signal enable_pixel_counter : std_logic;

type pixel_loader_fsm_state_type is (
  RESET,
  IDLE,
  WAIT_PIXEL_VALID,
  LOAD_FIRST_PIXELS,
  WAIT_VDE,
  EMPTY_SHIFT_REG,
  CHECK_NEW_PIXELS,
  LOAD_NEW_PIXELS,
  SEND_LAST_PIXEL
);

signal current_state, next_state : pixel_loader_fsm_state_type;

begin

shift_register: for I in 0 to 7 generate

  shift_register_I: if I /= 0 generate
    pixel_shift_register : process(CLK)
    begin
      if CLK'event and CLK = '1' then
        if RST = '1' then
          shift_register_array(7+8*I downto 8*I) <= (others => '0');
        elsif load_shift_register = '1' then
          shift_register_array(7+8*I downto 8*I) <= PIXIN(7+8*I downto 8*I);
        elsif enable_shift_register = '1' then
          shift_register_array(7+8*I downto 8*I) <= shift_register_array(7+8*(I-1) downto 8*(I-1));  
        end if;
      end if;
    end process;
  end generate;

  shift_register_7: if I = 0 generate
    pixel_shift_register : process(CLK)
    begin
      if CLK'event and CLK = '1' then
        if RST = '1' then
          shift_register_array(7+8*I downto 8*I) <= (others => '0');
        elsif load_shift_register = '1' then
          shift_register_array(7+8*I downto 8*I) <= PIXIN(7+8*I downto 8*I);
        elsif enable_shift_register = '1' then
          shift_register_array(7+8*I downto 8*I) <= X"00";
        end if;
      end if;
    end process;
  end generate;

end generate;

enable_shift_register <= VDE and unlock_shift_register;
RGBPX <= shift_register_array(63 downto 56) & shift_register_array(63 downto 56) & shift_register_array(63 downto 56);

gray_write_addr_cdc: process(CLK)
begin
  if CLK'event and CLK = '1' then
    gray_write_addr_d <= GRAY_WRITE_ADDR;
    gray_write_addr_dd <= gray_write_addr_d;
  end if;
end process;


with gray_write_addr_dd select
  binary_write_addr <= 
    to_unsigned(0, 4) when "0000",
    to_unsigned(1, 4) when "0001",
    to_unsigned(2, 4) when "0011",
    to_unsigned(3, 4) when "0010",
    to_unsigned(4, 4) when "0110",
    to_unsigned(5, 4) when "0111",
    to_unsigned(6, 4) when "0101",
    to_unsigned(7, 4) when "0100",
    to_unsigned(8, 4) when "1100",
    to_unsigned(9, 4) when "1101",
    to_unsigned(10, 4) when "1111",
    to_unsigned(11, 4) when "1110",
    to_unsigned(12, 4) when "1010",
    to_unsigned(13, 4) when "1011",
    to_unsigned(14, 4) when "1001",
    to_unsigned(15, 4) when "1000",
    to_unsigned(0, 4) when others;

with current_read_addr select
  GRAY_READ_ADDR <=
    "0000" when "0000",
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

fifo_read_address_register: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if RST = '1' then
      current_read_addr <= to_unsigned(0, 4);
    elsif inc_read_addr = '1' then
      current_read_addr <= next_read_addr;
    end if;
  end if;
end process;

next_read_addr <= current_read_addr + 1;
FIFO_READ_ADDR <= std_logic_vector(current_read_addr);

pixel_counter_register: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if reset_pixel_counter = '1' then
      current_pixel_count <= to_unsigned(0, 3);
    elsif enable_pixel_counter = '1' then
      current_pixel_count <= next_pixel_count;
    end if;
  end if;
end process;

next_pixel_count <= current_pixel_count + 1;

pixel_loader_fsm_sequential_part: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if RST = '1' then
      current_state <= RESET;
    else
      current_state <= next_state;
    end if;
  end if;
end process;

pixel_loader_fsm_state_combinational_part: process(current_state, VDE, EN,
  binary_write_addr, current_pixel_count, current_read_addr)
begin

  case current_state is

    when RESET =>
      next_state <= IDLE;

    when IDLE =>
      if EN = '1' then 
        next_state <= WAIT_PIXEL_VALID;
      else
        next_state <= IDLE;
      end if;

    when WAIT_PIXEL_VALID =>
      if binary_write_addr /= current_read_addr then
        next_state <= LOAD_FIRST_PIXELS;
      else
        next_state <= WAIT_PIXEL_VALID;
      end if;

    when LOAD_FIRST_PIXELS =>
        next_state <= WAIT_VDE;

    when WAIT_VDE =>
      if VDE = '1' then
        next_state <= EMPTY_SHIFT_REG;
      else
        next_state <= WAIT_VDE;
      end if;

    when EMPTY_SHIFT_REG =>
      if current_pixel_count = 4 then
        next_state <= CHECK_NEW_PIXELS;
      else
        next_state <= EMPTY_SHIFT_REG;
      end if;

    when CHECK_NEW_PIXELS =>
      if binary_write_addr = current_read_addr then
        next_state <= SEND_LAST_PIXEL;
      else
        next_state <= LOAD_NEW_PIXELS;
      end if;

    when SEND_LAST_PIXEL =>
        next_state <= WAIT_PIXEL_VALID;

    when LOAD_NEW_PIXELS =>
        next_state <= WAIT_VDE;

    when others =>
        next_state <= RESET;

  end case;

end process;

pixel_loader_fsm_output_combinational_part: process(current_state)
begin

load_shift_register <= '0';
unlock_shift_register <= '0';
reset_pixel_counter <= '0';
enable_pixel_counter <= '0';
inc_read_addr <= '0';
FIFO_READ_EN <= '0';


case current_state is

  when RESET =>
    reset_pixel_counter <= '1';

  when IDLE =>
    reset_pixel_counter <= '1';
  
  when WAIT_PIXEL_VALID =>
    reset_pixel_counter <= '1';
    FIFO_READ_EN <= '1';
  
  when LOAD_FIRST_PIXELS =>
    load_shift_register <= '1';
    inc_read_addr <= '1';

  when WAIT_VDE =>
    unlock_shift_register <= '1';
    
  when EMPTY_SHIFT_REG =>
    unlock_shift_register <= '1';
    enable_pixel_counter <= '1';
    
  when CHECK_NEW_PIXELS =>
    reset_pixel_counter <= '1';
    unlock_shift_register <= '1';
    FIFO_READ_EN <= '1';
    
  when SEND_LAST_PIXEL =>
    unlock_shift_register <= '1';
    
  when LOAD_NEW_PIXELS =>
    unlock_shift_register <= '1';
    load_shift_register <= '1';
    inc_read_addr <= '1';
    
  when others =>
  
end case;

end process;

end architecture; -- behavioral
