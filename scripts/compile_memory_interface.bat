@echo off
rem Compilation file for HDL simulation

ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=first_camera --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-specs .\MEMORY_INTERFACE.vhdl
ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\TB_MEMORY_INTERFACE.vhdl

ghdl elaborate -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-binding -Wno-specs TB_MEMORY_INTERFACE
ghdl run TB_MEMORY_INTERFACE --stop-time=20ms --wave=tb_memory_interface.ghw --stop-delta=2000

