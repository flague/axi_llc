# Read command line argument for simulation time
if [ -z "$1" ]; then
  echo "Usage: $0 <simulation_time>"
  exit 1
fi

export SIM_TIME=$1


# Source Questa environment
source /eda/scripts/init_questa_2024.3

# Open Questa without GUI
vsim -c -do "do scripts/questa_sim.tcl"