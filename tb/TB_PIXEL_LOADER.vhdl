library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library first_camera;
use first_camera.all;


entity TB_PIXEL_LOADER is
end entity; -- TB_PIXEL_LOADER


architecture stimuli of TB_PIXEL_LOADER is

signal CLK : std_logic := '0';
signal CLKH : std_logic := '0';
signal RST : std_logic;
signal VDE : std_logic;
signal EN : std_logic;
signal write_addr : unsigned(3 downto 0);
signal GRAY_WRITE_ADDR : std_logic_vector(3 downto 0);
signal PIXIN : std_logic_vector(63 downto 0);
signal RGBPX : std_logic_vector(23 downto 0);
signal GRAY_READ_ADDR : std_logic_vector(3 downto 0);
signal FIFO_READ_ADDR : std_logic_vector(3 downto 0);
signal FIFO_READ_EN : std_logic;

begin

uut: entity first_camera.PIXEL_LOADER
port map(
  CLK => CLK, --: in std_logic;
  RST => RST, --: in std_logic;
  VDE => VDE, --: in std_logic;
  EN => EN, --: in std_logic;
  GRAY_WRITE_ADDR => GRAY_WRITE_ADDR, --: in std_logic_vector(3 downto 0);
  PIXIN => PIXIN, --: in std_logic_vector(63 downto 0);
  RGBPX => RGBPX, --: out std_logic_vector(23 downto 0);
  GRAY_READ_ADDR => GRAY_READ_ADDR, --: out std_logic_vector(3 downto 0);
  FIFO_READ_ADDR => FIFO_READ_ADDR, --: out std_logic_vector(3 downto 0);
  FIFO_READ_EN => FIFO_READ_EN  --: out std_logic
);

----------------------------------------------------------------
-- Testing signals
----------------------------------------------------------------
CLK <= not CLK after 20 ns; -- 25 MHz => 40 ns
CLKH <= not CLKH after 4 ns; -- 125 MHz => 8 ns
RST <= '1', '0' after 20.3 us;

EN <= '0', '1' after 30 us, '0' after 30 ms;
VDE <= '0', '1' after 2 ms, '0' after 10 ms, '1' after 20 ms;


fake_memory : process(CLK)
type memory_type is array(0 to 15) of std_logic_vector(63 downto 0);

variable memory_data : memory_type := (
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01",
  X"08" & X"07" & X"06" & X"05" & X"04" & X"03" & X"02" & X"01"
);

begin

  if CLK'event and CLK = '1' then 
    if FIFO_READ_EN = '1' then
      PIXIN <= memory_data( to_integer(unsigned(FIFO_READ_ADDR)) );
    end if;
  end if;

end process;

write_address_generator: process(CLKH)
variable current_write_addr: unsigned(3 downto 0) := "0000";
variable current_read_addr: unsigned(3 downto 0) := "0000";
type state_type is (IDLE, START, WRITE_DATA, WAIT_PIXEL_LOADER);
variable state : state_type := IDLE;

begin
  if CLKH'event and CLKH = '1' then
    current_read_addr := unsigned(FIFO_READ_ADDR);
    if RST = '1' then
      state := IDLE;
    else
      case state is
        when IDLE =>
          if EN = '1' then
            state := START;
          end if;
  
        when START =>
          if current_read_addr = current_write_addr then
            state := WRITE_DATA;
          end if;
  
        when WRITE_DATA =>
          current_write_addr := current_write_addr + 1;
          if EN = '0' then
            state := IDLE;
          elsif (current_write_addr + 1) = current_read_addr then
            state := WAIT_PIXEL_LOADER;
          end if;
  
        when WAIT_PIXEL_LOADER =>
          if (current_write_addr + 1) /= current_read_addr then
            state := WRITE_DATA;
          end if;
      
        when others =>
          state := IDLE;
      end case;
    end if;
  
    write_addr <= current_write_addr;
  end if;
    
end process;

with write_addr select
  GRAY_WRITE_ADDR <=
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

  
end architecture; -- stimuli
