----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/17/2025 07:07:03 PM
-- Design Name: 
-- Module Name: PWDN - Behavioral
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

entity PWDN is
    Port ( 
        CLK : in std_logic;
        RST : in std_logic;
        EN : in std_logic;
        PWDN : out std_logic
        );
end PWDN;

architecture Behavioral of PWDN is

signal current_internal_count, next_internal_count : unsigned(19 downto 0);
signal enable_internal_counter, reset_internal_counter : std_logic;

-- POP = Power On Period
type pwdn_fsm_state_type is (
  PWDN_FSM_STATE_RESET, 
  PWDM_FSM_STATE_WAITPOP, 
  PWDM_FSM_STATE_ON,
  PWDM_FSM_STATE_OFF
);  

signal current_state, next_state: pwdn_fsm_state_type;

begin

internal_counter_label: process(CLK)
begin
  if CLK'event and CLK='1' then
    if reset_internal_counter = '1' then
      current_internal_count <= (others => '0');
    elsif enable_internal_counter = '1' then
      current_internal_count <= next_internal_count;
    end if;
  end if;
end process;

next_internal_count <= current_internal_count + 1;

state_process_label: process(CLK)
begin
  if CLK'event and CLK='1' then
    if RST = '1' then
      current_state <= PWDN_FSM_STATE_RESET;
    else
      current_state <= next_state;
    end if;
  end if;
end process;

combinatorial_process_label: process(EN, current_state, current_internal_count)

begin
  PWDN <= '1';
  enable_internal_counter <= '0';
  reset_internal_counter <= '0';
  
  case current_state is
    when PWDN_FSM_STATE_RESET =>
      reset_internal_counter <= '1';
      next_state <= PWDM_FSM_STATE_WAITPOP;
      
    when PWDM_FSM_STATE_WAITPOP =>
      enable_internal_counter <= '1';
      
      if current_internal_count(current_internal_count'left) = '1' then
        if EN = '1' then
            next_state <= PWDM_FSM_STATE_ON;
        else
            next_state <= PWDM_FSM_STATE_OFF;
        end if;
      else
        next_state <= current_state;
      end if;
    
    when PWDM_FSM_STATE_ON =>
      PWDN <= '0';
      
      if EN = '0' then
        next_state <= PWDM_FSM_STATE_OFF;
      else
        next_state <= current_state;
      end if;

    when PWDM_FSM_STATE_OFF =>
      reset_internal_counter <= '1';
      
      if EN = '1' then
        next_state <= PWDM_FSM_STATE_WAITPOP;
      else
        next_state <= current_state;
      end if;
    
    when others =>
      next_state <= PWDN_FSM_STATE_RESET;
    
    end case;

end process;

end Behavioral;
