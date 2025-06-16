# Read command line argument for simulation time
# Set default value if $1 is empty
if [ -z "$1" ]; then
  simulation_time=60  # default value, change as needed
  echo "No simulation time provided. Using default: $simulation_time"
else
  simulation_time=$1
fi
export SIM_TIME=$simulation_time


# Source Questa environment
source /eda/scripts/init_questa_2024.3

# Open Questa without GUI
vsim -c -do "do scripts/questa_sim.tcl"