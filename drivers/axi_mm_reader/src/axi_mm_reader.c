/*############################################################################
#  Copyright (c) 2020 by Oliver Bründler, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
############################################################################*/

#include "axi_mm_reader.h"
#include <xil_io.h>

//*******************************************************************************
// Helper Functions
//*******************************************************************************


//*******************************************************************************
// Functions
//*******************************************************************************

MmReader_ErrCode MmReader_SetEnable(const uint32_t baseAddr, const bool ena) {	
	//Set enable register
	Xil_Out32(baseAddr + MM_READER_ENA_REG, (ena ? MM_READER_ENA_REG_ENA : 0));
	
	return MmReader_Success;
}

MmReader_ErrCode MmReader_GetEnable(const uint32_t baseAddr, bool* const ena_p) {
	//variable definition
	uint32_t reg;
	
	//Read register
	reg = Xil_In32(baseAddr + MM_READER_ENA_REG);
	*ena_p = (bool)reg;
	
	return MmReader_Success;
}

MmReader_ErrCode MmReader_SetRegTable(const uint32_t baseAddr, const uint32_t* const regs_p, const uint32_t numRegs) {
	//variable definition
	bool enaState;
	MmReader_ErrCode ret;
	uint32_t idx;
	
	//Checks
	ret = MmReader_GetEnable(baseAddr, &enaState);
	if (MmReader_Success != ret) {
		return ret;
	}
	if (true == enaState) {
		return MmReader_IpMustBeDisabled
	}
	
	//Set all registers
	for (idx = 0; idx < numRegs; idx++){
		Xil_Out32(baseAddr + MM_READER_REGMAP_OFFS + 4*i, regs_p[idx]);
	}
	//Set number of registers
	Xil_Out32(baseAddr + MM_READER_REG_CNT_REG, numRegs);
	
	return MmReader_Success;
}

SpiSimple_ErrCode MmReader_GetLevel(const uint32_t baseAddr, uint32_t* const level_p) {
	//Read register
	*level_p = Xil_In32(baseAddr + MM_READER_LEVEL_REG);
	
	return MmReader_Success;
}

SpiSimple_ErrCode MmReader_ReadFifoEntry(const uint32_t baseAddr, uint32_t* const data_p, bool* const last_p) {
	//variable definitions
	MmReader_ErrCode ret;
	uint32_t level;
	uint32_t reg;
	
	//checks
	ret = MmReader_GetLevel(baseAddr, &level);
	if (MmReader_Success != ret) {
		return ret;
	}
	if (0 == level) {
		return MmReader_FifoIsEmpty;
	}
	
	//Read last first (because reading data removes the FIFO entry)
	reg = Xil_In32(baseAddr + MM_READER_RD_LAST_REG);
	*last_p = (bool)reg;
	*data_p = Xil_In32(baseAddr + MM_READER_RD_DATA_REG);
	
	return SpiSimple_Success;
}

SpiSimple_ErrCode MmReader_ReadFifoPacket(const uint32_t baseAddr, uint32_t* const buffer_p, const uint32_t size, uint32_t* const pktSize_p) {
	//variable definition
	MmReader_ErrCode ret;
	bool last;
	uint32_t idx;
	
	for (idx = 0; idx < size; idx++) {
		ret = MmReader_ReadFifoEntry(baseAddr, &buffer_p[idx], &last);
		if (MmReader_Success != ret) {
			return ret;
		}
		//Stop reading when last element of a packet was read
		if (true == last) {
			*pktSize_p = idx+1;
			break;
		}
	}
	//Check if the packet was complete
	if (!last) {
		return MmReader_NoCompletePacketInFifo;
	}
	
	return SpiSimple_Success;
}

