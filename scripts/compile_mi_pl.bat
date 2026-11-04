@echo off
rem Compilation file for HDL simulation

ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=first_camera --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-specs .\MEMORY_INTERFACE.vhdl
ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=first_camera --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-specs .\PIXEL_LOADER.vhdl
ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\TB_MI_PL.vhdl

ghdl elaborate -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-binding -Wno-specs TB_MI_PL
ghdl run TB_MI_PL --stop-time=20ms --wave=tb_mi_pl.ghw --stop-delta=2000

