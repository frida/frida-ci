/*
 * $QNXLicenseC:
 * Copyright 2008, QNX Software Systems. 
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"). You 
 * may not reproduce, modify or distribute this software except in 
 * compliance with the License. You may obtain a copy of the License 
 * at: http://www.apache.org/licenses/LICENSE-2.0 
 * 
 * Unless required by applicable law or agreed to in writing, software 
 * distributed under the License is distributed on an "AS IS" basis, 
 * WITHOUT WARRANTIES OF ANY KIND, either express or implied.
 *
 * This file may contain contributions from others, either as 
 * contributors under the License or as licensors under other terms.  
 * Please review this entire file for other proprietary rights or license 
 * notices, as well as the QNX Development Suite License Guide at 
 * http://licensing.qnx.com/license-guide/ for other information.
 * $
 */




#include "startup.h"

/*
 * ARMv5 Write-Allocate extended page table entries:
 * - RO pages use default cached access
 * - RW pages use write-allocate caching
 * - uncached pages need to clear the X bit as well as the CB bits
 */
const struct armv_pte	armv_pte_v5wa= {
	ARM_PTE_XSP | ARM_XSP_PROT(ARM_PTE_RO|ARM_PTE_U) | ARM_PTE_CB,		// upte_ro
	ARM_PTE_XSP | ARM_XSP_PROT(ARM_PTE_RW|ARM_PTE_U) | ARM_PTE_XS_WA,	// upte_rw
	ARM_PTE_XSP | ARM_XSP_PROT(ARM_PTE_RO)           | ARM_PTE_CB,		// kpte_ro
	ARM_PTE_XSP | ARM_XSP_PROT(ARM_PTE_RW)           | ARM_PTE_XS_WA,	// kpte_rw
	ARM_PTE_CB  | ARM_PTE_XS_X,											// mask_nc
	ARM_PTP_L2,															// l1_pgtable
	ARM_PTP_SC | ARM_PTP_AP_RO,											// kscn_ro
	ARM_PTP_SC | ARM_PTP_AP_RW,											// kscn_rw
	ARM_PTP_XS_WA														// kscn_cb
};




#if defined(__QNXNTO__) && defined(__USESRCVERSION)
#include <sys/srcversion.h>
__SRCVERSION("$URL: http://svn/product/branches/6.5.0/trunk/hardware/startup/lib/arm/armv_pte_v5wa.c $ $Rev: 711024 $")
#endif
