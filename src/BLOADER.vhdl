--! \file BLOADER.vhdl

library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--! \brief Simple binary loader
--!
--! This module takes a binary file and
--! reads bytes one by one.
--! A clock signal is required to transfer
--! bytes properly.
--! The loader requires one clock cycle to be functional.
entity BLOADER is
generic(
  filename : string := "data.dat"
);
port(
  CLK : in std_logic; --! Input clock signal
  OUTBYTE: out std_logic_vector(7 downto 0); --! Output signal
  VALID: out std_logic; --!  Valid signal from this module
  READY: in std_logic --! Ready signal from slave module
);
end entity BLOADER;

architecture procedural of BLOADER is

begin

loader: process(CLK)
type byte_file_type is file of character;
file fp : byte_file_type  is in filename;
variable byte_read : character;
variable file_index : integer := 0;
variable memory_init : boolean := false;
variable byte_value : std_logic_vector(7 downto 0);

type memory_array is array(0 to 2**22-1) of std_logic_vector(7 downto 0);
variable memory_data : memory_array;
variable data_index : integer := 0;

variable s_valid : std_logic :='0';
variable s_ready : std_logic :='0';
variable s_outbyte : std_logic_vector(7 downto 0);

begin
  s_ready := READY;
  if memory_init = false then
    s_valid := '0';
    while not endfile(fp) and file_index < 2**22 loop
      read(fp, byte_read);
      byte_value := std_logic_vector(to_unsigned(character'pos(byte_read), 8));
      --report "Value read: " & character'image(character'pos(byte_read));
      memory_data(file_index) := byte_value;
      file_index := file_index + 1;
    end loop;
    memory_init := true;
  end if;

  if memory_init = true then
    s_valid := '1';
    if CLK'event and CLK='1' then
      if( s_ready = '1' and s_valid = '1' ) then
        if data_index <= file_index then
          data_index := data_index + 1;
        else
          s_valid := '0';
        end if;
      end if;
    end if;

  else
    s_valid := '0';
  end if;

  s_outbyte := memory_data(data_index);
  VALID <= s_valid;
  OUTBYTE <= s_outbyte;

end process;

end architecture procedural;
