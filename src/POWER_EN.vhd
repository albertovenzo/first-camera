----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/21/2025 10:18:28 PM
-- Design Name: 
-- Module Name: POWER_EN - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity POWER_EN is
    Port ( CLK : in STD_LOGIC;
           RST : in STD_LOGIC;
           EN : in STD_LOGIC;
           POWER_EN : out STD_LOGIC);
end POWER_EN;

architecture Behavioral of POWER_EN is

signal current_internal_debouncing_counter, next_internal_debouncing_counter: unsigned(19 downto 0);
signal reset_internal_debouncing_counter, enable_internal_debouncing_counter: std_logic;
signal enable_power: std_logic;

type pwdn_fsm_state_type is (
  POWER_EN_FSM_STATE_RESET, 
  POWER_EN_FSM_STATE_DEBOUNCE, 
  POWER_EN_FSM_STATE_ON,
  POWER_EN_FSM_STATE_OFF
);

signal current_state, next_state : pwdn_fsm_state_type;

begin

debouncing_counter_process: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if reset_internal_debouncing_counter = '1' then
      current_internal_debouncing_counter <= (others => '0');
    elsif enable_internal_debouncing_counter = '1' then
      current_internal_debouncing_counter <= next_internal_debouncing_counter;
    end if;
  end if;
end process;

next_internal_debouncing_counter <= current_internal_debouncing_counter + 1; 

fsm_sequential_process: process(CLK)
begin
  if CLK'event and CLK = '1' then
    if RST = '1' then
      current_state <= POWER_EN_FSM_STATE_RESET;
    else
      current_state <= next_state;
    end if;
  end if;
end process;

fsm_combinatorial_process: process(current_internal_debouncing_counter, current_state, EN)
begin
  enable_power <= '0';
  reset_internal_debouncing_counter <= '0';
  enable_internal_debouncing_counter <= '0';
  
  case current_state is
    when POWER_EN_FSM_STATE_RESET =>
    
      reset_internal_debouncing_counter <= '1';
      next_state <= POWER_EN_FSM_STATE_DEBOUNCE;
      
    when POWER_EN_FSM_STATE_DEBOUNCE =>
      enable_internal_debouncing_counter <= '1';
      
      if current_internal_debouncing_counter(current_internal_debouncing_counter'left) = '1' then
        if EN = '1' then
          next_state <= POWER_EN_FSM_STATE_ON;
        else
          next_state <= POWER_EN_FSM_STATE_OFF;
        end if;
      else
        next_state <= current_state;
      end if;
      
    when POWER_EN_FSM_STATE_ON =>
      reset_internal_debouncing_counter <= '1';
      enable_power <= '1';
      
      if EN = '0' then
        next_state <= POWER_EN_FSM_STATE_DEBOUNCE;
      else
        next_state <= current_state;
      end if;
      
    when POWER_EN_FSM_STATE_OFF =>
      reset_internal_debouncing_counter <= '1';
      
      if EN = '1' then
        next_state <= POWER_EN_FSM_STATE_DEBOUNCE;
      else
        next_state <= current_state;
      end if;
      
    when others =>
      next_state <= POWER_EN_FSM_STATE_RESET;
      
    end case;

end process;


POWER_EN <= enable_power;

end Behavioral;
