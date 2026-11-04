@echo off
rem Compilation file for HDL simulation

rem ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\HDMI\ClockGen.vhd
rem ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\HDMI\DVI_Constants.vhd
rem ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\HDMI\OutputSERDES.vhd
rem rem ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\HDMI\SyncAsync.vhd
rem ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\HDMI\SyncAsyncReset.vhd
rem ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\HDMI\TMDS_Encoder.vhd
rem ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\HDMI\rgb2dvi.vhd
ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-specs .\HDMI\HDMI_INT_rgb2dvi_0_0_sim_netlist.vhdl
ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-specs .\vhdl-hdmi-out-master\rtl\clock_gen.vhd
ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-specs .\vhdl-hdmi-out-master\rtl\timing_generator.vhd
ghdl analyse -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit .\tb_hdmi.vhdl

ghdl elaborate -Pxilinx-vivado\unisim\v93 -Pworkfolder --work=xil_defaultlib --workdir=workfolder -fsynopsys -frelaxed -fexplicit -Wno-binding -Wno-specs TB_HDMI
ghdl run TB_HDMI --stop-time=20ms --wave=tb_hdmi.ghw --stop-delta=4000

