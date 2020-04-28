# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Configuration [ipgui::add_page $IPINST -name "Configuration"]
  ipgui::add_param $IPINST -name "ClkFrequencyHz" -parent ${Configuration}
  ipgui::add_param $IPINST -name "TimeoutUs_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "MaxRegCount_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "MinBuffers_g" -parent ${Configuration}
  ipgui::add_param $IPINST -name "Output_g" -parent ${Configuration} -widget comboBox


}

proc update_PARAM_VALUE.AxiSlaveAddrWidth_g { PARAM_VALUE.AxiSlaveAddrWidth_g } {
	# Procedure called to update AxiSlaveAddrWidth_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AxiSlaveAddrWidth_g { PARAM_VALUE.AxiSlaveAddrWidth_g } {
	# Procedure called to validate AxiSlaveAddrWidth_g
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ID_WIDTH { PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to update C_S00_AXI_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ID_WIDTH { PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to validate C_S00_AXI_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.ClkFrequencyHz { PARAM_VALUE.ClkFrequencyHz } {
	# Procedure called to update ClkFrequencyHz when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ClkFrequencyHz { PARAM_VALUE.ClkFrequencyHz } {
	# Procedure called to validate ClkFrequencyHz
	return true
}

proc update_PARAM_VALUE.MaxRegCount_g { PARAM_VALUE.MaxRegCount_g } {
	# Procedure called to update MaxRegCount_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MaxRegCount_g { PARAM_VALUE.MaxRegCount_g } {
	# Procedure called to validate MaxRegCount_g
	return true
}

proc update_PARAM_VALUE.MinBuffers_g { PARAM_VALUE.MinBuffers_g } {
	# Procedure called to update MinBuffers_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MinBuffers_g { PARAM_VALUE.MinBuffers_g } {
	# Procedure called to validate MinBuffers_g
	return true
}

proc update_PARAM_VALUE.Output_g { PARAM_VALUE.Output_g } {
	# Procedure called to update Output_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Output_g { PARAM_VALUE.Output_g } {
	# Procedure called to validate Output_g
	return true
}

proc update_PARAM_VALUE.TimeoutUs_g { PARAM_VALUE.TimeoutUs_g } {
	# Procedure called to update TimeoutUs_g when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TimeoutUs_g { PARAM_VALUE.TimeoutUs_g } {
	# Procedure called to validate TimeoutUs_g
	return true
}


proc update_MODELPARAM_VALUE.ClkFrequencyHz { MODELPARAM_VALUE.ClkFrequencyHz PARAM_VALUE.ClkFrequencyHz } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ClkFrequencyHz}] ${MODELPARAM_VALUE.ClkFrequencyHz}
}

proc update_MODELPARAM_VALUE.TimeoutUs_g { MODELPARAM_VALUE.TimeoutUs_g PARAM_VALUE.TimeoutUs_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TimeoutUs_g}] ${MODELPARAM_VALUE.TimeoutUs_g}
}

proc update_MODELPARAM_VALUE.MaxRegCount_g { MODELPARAM_VALUE.MaxRegCount_g PARAM_VALUE.MaxRegCount_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MaxRegCount_g}] ${MODELPARAM_VALUE.MaxRegCount_g}
}

proc update_MODELPARAM_VALUE.MinBuffers_g { MODELPARAM_VALUE.MinBuffers_g PARAM_VALUE.MinBuffers_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MinBuffers_g}] ${MODELPARAM_VALUE.MinBuffers_g}
}

proc update_MODELPARAM_VALUE.Output_g { MODELPARAM_VALUE.Output_g PARAM_VALUE.Output_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Output_g}] ${MODELPARAM_VALUE.Output_g}
}

proc update_MODELPARAM_VALUE.AxiSlaveAddrWidth_g { MODELPARAM_VALUE.AxiSlaveAddrWidth_g PARAM_VALUE.AxiSlaveAddrWidth_g } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AxiSlaveAddrWidth_g}] ${MODELPARAM_VALUE.AxiSlaveAddrWidth_g}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH PARAM_VALUE.C_S00_AXI_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ID_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ID_WIDTH}
}

