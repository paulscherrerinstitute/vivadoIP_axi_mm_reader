/*############################################################################
#  Copyright (c) 2020 by Oliver Bründler, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
############################################################################*/

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

//*******************************************************************************
// Includes
//*******************************************************************************
#include <stdint.h>
#include <stdbool.h>

//*******************************************************************************
// Definitions
//*******************************************************************************
// Return codes
typedef enum MmReader_ErrCode
{
	MmReader_Success = 0,
	MmReader_IpMustBeDisabled = -1,
	MmReader_FifoIsEmpty = -2,
	MmReader_NoCompletePacketInFifo = -3,
} MmReader_ErrCode;

// Register
#define MM_READER_ENA_REG					0x00
#define MM_READER_REG_CNT_REG				0x04
#define MM_READER_RD_DATA_REG				0x08
#define MM_READER_RD_LAST_REG				0x0C
#define MM_READER_LEVEL_REG					0x10
#define MM_READER_REGMAP_OFFS				0x20

// Register Bitmasks
#define MM_READER_ENA_REG_ENA 				(1 << 0)
#define MM_READER_RD_REG_LAST				(1 << 1)

//*******************************************************************************
// Functions
//*******************************************************************************
/**
 * Enable/Disable component
 *
 * @param baseAddr		Base address of the IP component to access
 * @param ena			True = enabled, False = disabled
 * @return				Return Code (zero on success)
 */
MmReader_ErrCode MmReader_SetEnable(const uint32_t baseAddr, const bool ena);

/**
 * Get status of the component (enabled/disabled)
 *
 * @param baseAddr		Base address of the IP component to access
 * @param ena_p			True = enabled, False = disabled
 * @return				Return Code (zero on success)
 */
MmReader_ErrCode MmReader_GetEnable(const uint32_t baseAddr, bool* const ena_p);

/**
 * Configure the register-table containing all registers to read. 
 *
 * Note that the size of the table is not checked against the capabilities of the IP-Core. The
 * user is responsible for not choosing more registers than the IP-supports.
 *
 * This function shall only be called if the IP-Core is disabled.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param regs_p		Array containing the register addresses
 * @param numRegs		Number of registers in the regs array
 * @return				Return Code (zero on success)
 */
MmReader_ErrCode MmReader_SetRegTable(const uint32_t baseAddr, const uint32_t* const regs_p, const uint32_t numRegs);

/**
 * Get the level of the IP internal buffer.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param level_p		Level of the buffer (in 32-bit values = registers)
 * @return				Return Code (zero on success)
 */
MmReader_ErrCode MmReader_GetLevel(const uint32_t baseAddr, uint32_t* const level_p);

/**
 * Read one FIFO entry.
 *
 * Note that this function can only be used if data is output over AXIMM. If AXI-Stream
 * output is chosen int the IP-Configuration, the user must not call this function.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param data_p		Register content
 * @param last_p		True if this value is the last one of a read cycle
 * @return				Return Code (zero on success)
 */
MmReader_ErrCode MmReader_ReadFifoEntry(const uint32_t baseAddr, uint32_t* const data_p, bool* const last_p);

/**
 * Read one complete data packet (all registers of a read cycle, until a LAST flag) from the internal FIFO.
 *
 * Note that this function can only be used if data is output over AXIMM. If AXI-Stream
 * output is chosen int the IP-Configuration, the user must not call this function.
 *
 * @param baseAddr		Base address of the IP component to access
 * @param buffer_p		Data buffer
 * @param size			Size of buffer_p (in 32-bit words)
 * @param pktSize_p		Number of registers (32-bit words) actually read
 * @return				Return Code (zero on success)
 */
MmReader_ErrCode MmReader_ReadFifoPacket(const uint32_t baseAddr, uint32_t* const buffer_p, const uint32_t size, uint32_t* const pktSize_p);



#ifdef __cplusplus
}
#endif


