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

const struct armv_chip armv_chip_80200 = {
	.cpuid		= 0x2000,
	.name		= "i80200",
	.mmu_cr_set	= ARM_MMU_CR_S|ARM_MMU_CR_I|ARM_MMU_CR_Z,
	.mmu_cr_clr	= 0,
	.cycles		= 2,
	.cache		= &armv_cache_xscale,
	.power		= &power_xscale,
	.flush		= &page_flush_xscale,
	.deferred	= &page_flush_deferred_xscale,
	.pte		= &armv_pte_v5wb,
	.pte_wa		= &armv_pte_v5wa,
	.pte_wb		= &armv_pte_v5wb,
	.pte_wt		= &armv_pte_v5wt,
	.setup		= armv_setup_xscale,
	.ttb_attr	= 0,
	.pte_attr	= 0,
};




#if defined(__QNXNTO__) && defined(__USESRCVERSION)
#include <sys/srcversion.h>
__SRCVERSION("$URL: http://svn/product/branches/6.5.0/trunk/hardware/startup/lib/arm/armv_chip_80200.c $ $Rev: 711024 $")
#endif
