Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

-- FIFO_DUALCLOCK_MACRO: Dual-Clock First-In, First-Out (FIFO) RAM Buffer
-- 7 Series
-- Xilinx HDL Libraries Guide, version 14.7
-- Note - This Unimacro model assumes the port directions to be "downto".
-- Simulation of this model with "to" in the port directions could lead to erroneous results.
-----------------------------------------------------------------
-- DATA_WIDTH | FIFO_SIZE | FIFO Depth | RDCOUNT/WRCOUNT Width --
-- ===========|===========|============|=======================--
-- 37-72 | "36Kb" | 512 | 9-bit --
-- 19-36 | "36Kb" | 1024 | 10-bit --
-- 19-36 | "18Kb" | 512 | 9-bit --
-- 10-18 | "36Kb" | 2048 | 11-bit --
-- 10-18 | "18Kb" | 1024 | 10-bit --
-- 5-9 | "36Kb" | 4096 | 12-bit --
-- 5-9 | "18Kb" | 2048 | 11-bit --
-- 1-4 | "36Kb" | 8192 | 13-bit --
-- 1-4 | "18Kb" | 4096 | 12-bit --
-----------------------------------------------------------------
FIFO_DUALCLOCK_MACRO_inst : FIFO_DUALCLOCK_MACRO
generic map (
  DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES"
  ALMOST_FULL_OFFSET => X"0080", -- Sets almost full threshold
  ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
  DATA_WIDTH => 64, -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
  FIFO_SIZE => "36Kb", -- Target BRAM, "18Kb" or "36Kb"
  FIRST_WORD_FALL_THROUGH => FALSE) -- Sets the FIFO FWFT to TRUE or FALSE
port map (
  ALMOSTEMPTY => ALMOSTEMPTY, -- 1-bit output almost empty
  ALMOSTFULL => ALMOSTFULL, -- 1-bit output almost full
  DO => DO, -- Output data, width defined by DATA_WIDTH parameter
  EMPTY => EMPTY, -- 1-bit output empty
  FULL => FULL, -- 1-bit output full
  RDCOUNT => RDCOUNT, -- Output read count, width determined by FIFO depth
  RDERR => RDERR, -- 1-bit output read error
  WRCOUNT => WRCOUNT, -- Output write count, width determined by FIFO depth
  WRERR => WRERR, -- 1-bit output write error
  DI => DI, -- Input data, width defined by DATA_WIDTH parameter
  RDCLK => RDCLK, -- 1-bit input read clock
  RDEN => RDEN, -- 1-bit input read enable
  RST => RST, -- 1-bit input reset
  WRCLK => WRCLK, -- 1-bit input write clock
  WREN => WREN -- 1-bit input write enable
);
-- End of FIFO_DUALCLOCK_MACRO_inst instantiation

