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

void
startnext() {
	uintptr_t eip = lsp.system_private.p->boot_pgm[0].entry;

	if(debug_flag) {
		kprintf("\nSystem page at phys:%l user:%l kern:%l\n", (paddr32_t)syspage_paddr,
			lsp.system_private.p->user_syspageptr, lsp.system_private.p->kern_syspageptr);
		kprintf("Starting next program at v%l\n", eip);
	}
	if(eip == ~(uintptr_t)0) {
		crash("No next program to start\n");
	}
	cpu_startnext(eip, 0);
}



#if defined(__QNXNTO__) && defined(__USESRCVERSION)
#include <sys/srcversion.h>
__SRCVERSION("$URL: http://svn/product/branches/6.5.0/trunk/hardware/startup/lib/startnext.c $ $Rev: 711024 $")
#endif
