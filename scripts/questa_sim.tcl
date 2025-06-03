# Compile the design files
source scripts/compile_vsim.tcl

# Start simulation
source scripts/start_vsim.tcl

# Load waveforms
do scripts/waves/tb_axi_llc.vsim.do

# Save the simulation results in vcd format
#wlf2vcd -o logs/axi_llc.vcd logs/axi_llc.wlf
vcd file logs/axi_llc.vcd
vcd add -r /tb_axi_llc/i_axi_llc_dut/*  ;# Record all signals recursively

# Run the simulation
set sim_time $::env(SIM_TIME)
run $sim_time

#vcd flush

quit