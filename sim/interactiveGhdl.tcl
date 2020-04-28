##############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  Copyright (c) 2020 by Oliver Bründler, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
##############################################################################

#This script setps up Modelsim for interactively
# .. working from the TCL console.

#Import TCL Framework
source ../../../TCL/PsiSim/PsiSim.tcl
namespace import psi::sim::*

#Initialize Simulation
init -ghdl

#Configure
source ./config.tcl
compile_files -all -clean
