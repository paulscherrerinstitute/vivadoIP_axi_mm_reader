##############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
##############################################################################

#Load dependencies
source ../../../TCL/PsiSim/PsiSim.tcl

#Initialize Simulation
psi::sim::init -ghdl

#Configure
source ./config.tcl

#Run Simulation
puts "------------------------------"
puts "-- Compile"
puts "------------------------------"
psi::sim::compile -all -clean
puts "------------------------------"
puts "-- Run"
puts "------------------------------"
psi::sim::run_tb -all
puts "------------------------------"
puts "-- Check"
puts "------------------------------"

psi::sim::run_check_errors "###ERROR###"