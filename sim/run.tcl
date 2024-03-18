#******set library******
set_app_var link_library ../lib/smic18_ff.db
set_app_var target_library ../lib/smic18_ff.db
#******read file********
read_verilog ../rtl/spi_tx.v
read_verilog ../rtl/spi_rx.v
read_verilog ../rtl/spi_master_controller.v
read_verilog ../rtl/clk_gen.v
read_verilog ../rtl/fifo.v
read_verilog ../rtl/apb_interface.v
read_verilog ../rtl/apb_spi_master.v
current_design apb_spi_master
check_design
#******timing control***
create_clock "pclk_i" -period 20
set_clock_uncertainty -setup 0.15 [get_ports pclk_i]
set_clock_transition -max 0.15 [get_ports pclk_i]
set_clock_latency -max 0.7 [get_ports pclk_i]
set_input_delay -max 3 -clock pclk_i [all_inputs]
set_output_delay -max 3 -clock pclk_i [all_outputs]
#******env control******
#set_input_transition 0.12 [get_ports A]
#set_load [expr{30.0/1000}] [get_ports B]
compile
#******print report*****
report_clock
report_timing
report_area
report_power
#******print output information****
write_sdc apb_spi_master.sdc
write_sdf apb_spi_master.sdf
write_file -format verilog -output apb_spi_master_netlist.v
