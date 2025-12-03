set_property SRC_FILE_INFO {cfile:c:/Users/Monster/Xilinx/Vivado_Projects/CS401_LAB4/CS401_LAB4.gen/sources_1/ip/clk_wiz_100_to_50/clk_wiz_100_to_50.xdc rfile:../../../CS401_LAB4.gen/sources_1/ip/clk_wiz_100_to_50/clk_wiz_100_to_50.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
current_instance inst
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.100
