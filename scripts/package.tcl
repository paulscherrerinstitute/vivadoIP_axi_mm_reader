##############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  Copyright (c) 2020 by Oliver Bründler, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
##############################################################################

###############################################################
# Include PSI packaging commands
###############################################################
source ../../../TCL/PsiIpPackage/PsiIpPackage.tcl
namespace import -force psi::ip_package::latest::*

###############################################################
# General Information
###############################################################
set IP_NAME axi_mm_reader
set IP_VERSION 1.0
set IP_REVISION "auto"
set IP_LIBRARY PSI
set IP_DESCIRPTION "AXI-MM register readout (periodic readout)"

init $IP_NAME $IP_VERSION $IP_REVISION $IP_LIBRARY
set_description $IP_DESCIRPTION
set_vendor "Oliver Bründler"
set_vendor_short "oliver.bruendler"
set_vendor_url "https://none.com"
set_logo_relative "../doc/LogoRhino.png"
set_datasheet_relative "../doc/index.html"

###############################################################
# Add Source Files
###############################################################

#Relative Source Files
add_sources_relative { \
	../hdl/definitions_pkg.vhd \
	../hdl/axi_mm_reader.vhd \
	../hdl/axi_mm_reader_wrp.vhd \
}

#PSI Common
add_lib_relative \
	"../../../VHDL/psi_common/hdl"	\
	{ \
		psi_common_array_pkg.vhd \
		psi_common_math_pkg.vhd \
		psi_common_sdp_ram.vhd  \
		psi_common_sync_fifo.vhd \
		psi_common_logic_pkg.vhd \
		psi_common_pl_stage.vhd \
		psi_common_axi_slave_ipif.vhd \
		psi_common_axi_master_simple.vhd \
		psi_common_tdp_ram.vhd \
	}

###############################################################
# Driver Files
###############################################################	

add_drivers_relative ../drivers/axi_mm_reader { \
	src/axi_mm_reader.c \
	src/axi_mm_reader.h \
}
	

###############################################################
# GUI Parameters
###############################################################

#User Parameters
gui_add_page "Configuration"

gui_create_parameter "AxiSlaveAddrWidth_g" "Address with of the s00_axi interface"
gui_parameter_set_range 8 24
gui_add_parameter

gui_create_parameter "ClkFrequencyHz" "Clock frequency in Hz"
gui_add_parameter

gui_create_parameter "TimeoutUs_g" "Timeout in us (automatically start reading if not trigger arrives for this time)"
gui_parameter_set_range 1 10000
gui_add_parameter

gui_create_parameter "MaxRegCount_g" "Maximum number or registers to read for each cycle"
gui_add_parameter

gui_create_parameter "MinBuffers_g" "Buffer space for this number of read cycles is reserved"

gui_add_parameter

gui_create_parameter "Output_g" "Output type (read from registers or transmit via AXI-S)"
gui_parameter_set_widget_dropdown {"AXIMM" "AXIS"}
gui_add_parameter


###############################################################
# Remove wrongly detected interfaces
###############################################################
remove_autodetected_interface Rst

###############################################################
# Optional Ports
###############################################################

add_port_enablement_condition m_axis_* "\$Output_g == \"AXIS\""
add_interface_enablement_condition m_axis "\$Output_g == \"AXIS\""

###############################################################
# Package Core
###############################################################
set TargetDir ".."
#											Edit  	Synth	Part
package_ip $TargetDir 						false 	true	xc7a*




