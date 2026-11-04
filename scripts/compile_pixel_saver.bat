@echo off
rem Compilation file for HDL simulation

ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=first_camera --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-specs .\PIXEL_SAVER.vhdl
ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=first_camera --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-specs .\BLOADER.vhdl
ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\TB_PIXEL_SAVER.vhdl

ghdl elaborate -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-binding -Wno-specs TB_PIXEL_SAVER
ghdl run TB_PIXEL_SAVER --stop-time=20ms --wave=tb_pixel_saver.ghw --stop-delta=5000

