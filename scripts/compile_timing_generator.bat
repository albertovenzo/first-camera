@echo off
rem Compilation file for HDL simulation

ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-specs .\vhdl-hdmi-out-master\rtl\timing_generator.vhd
ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\tb_timing_generator.vhdl

ghdl elaborate -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-binding -Wno-specs tb_timing_generator
ghdl run tb_timing_generator --stop-time=20ms --wave=tb_hdmi.ghw --stop-delta=200

