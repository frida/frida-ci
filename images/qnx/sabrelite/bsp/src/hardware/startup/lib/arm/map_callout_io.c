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

uintptr_t
callout_io_map(unsigned size, paddr_t phys)
{
    uintptr_t ret;
    uint32_t prot;

    // In the non-LPAE case it is sufficient to NOT set cacheable|bufferable 
    // For LPAE, we need to explicitly tag these as device mappings
    prot = ARM_PTE_RW | ARM_MAP_NOEXEC;
    if (paddr_bits != 32) {
        prot |= ARM_MAP_DEVICE;
    }

    // Get a virtual mapping 
    ret = arm_map(~0, phys, size, prot);

    if (debug_flag) {
        kprintf("%s: mapping paddr:%P returns:%x\n", __func__, phys, ret);
    }

	return ret;
}



#if defined(__QNXNTO__) && defined(__USESRCVERSION)
#include <sys/srcversion.h>
__SRCVERSION("$URL: http://svn/product/branches/6.5.0/trunk/hardware/startup/lib/arm/map_callout_io.c $ $Rev: 740407 $")
#endif
