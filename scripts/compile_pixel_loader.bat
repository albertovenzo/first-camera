@echo off
rem Compilation file for HDL simulation

ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=first_camera --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-specs .\PIXEL_LOADER.vhdl
ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\TB_PIXEL_LOADER.vhdl

ghdl elaborate -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-binding -Wno-specs TB_PIXEL_LOADER
ghdl run TB_PIXEL_LOADER --stop-time=20ms --wave=tb_pixel_loader.ghw --stop-delta=1000

