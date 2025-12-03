transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vmap -link {C:/Users/Monster/Xilinx/Vivado_Projects/CS401_LAB4/CS401_LAB4.cache/compile_simlib/activehdl}
vlib activehdl/xpm
vlib activehdl/xil_defaultlib

vlog -work xpm  -sv2k12 "+incdir+../../../ipstatic" -l xpm -l xil_defaultlib \
"D:/Kod/Vivado/2023.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  \
"D:/Kod/Vivado/2023.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../ipstatic" -l xpm -l xil_defaultlib \
"../../../../CS401_LAB4.gen/sources_1/ip/clk_wiz_100_to_50/clk_wiz_100_to_50_clk_wiz.v" \
"../../../../CS401_LAB4.gen/sources_1/ip/clk_wiz_100_to_50/clk_wiz_100_to_50.v" \

vlog -work xil_defaultlib \
"glbl.v"

