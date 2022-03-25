/*
 * $QNXLicenseC:
 * Copyright 2014, QNX Software Systems. 
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
 * Additional Cortex A7 MPCore specific CPU initialisation
 */

extern unsigned is_bootstrap_cpu_a15;

static __inline__ void
arm_TPIDRURW_set(unsigned TPIDRURW)
{
	__asm__ __volatile__("mcr	p15, 0, %0, c13, c0, 2" : : "r" (TPIDRURW));
}

void
armv_setup_a7(struct cpuinfo_entry *cpu, unsigned cpuid)
{
	unsigned	aux;
	unsigned	cpunum;

	cpunum = arm_v6_cpunum();
	
	arm_TPIDRURW_set(cpunum);
	
	if (cpunum != 0 && gic_cpu_base != 0) {
		/*
		 * Initialise GIC interface for this cpu.
		 * For CPU0, this should be initialised in init_intrinfo()
		 */
		arm_gic_cpu_init();
	}

	/*
	 * Configure CP15 auxiliary control register
	 *
	 * FIXME: should use symbolic constants
	 */
	aux = arm_v6_cp15_auxcr_get();	
	if (lsp.syspage.p->num_cpu >= 1) {
		/*
		 * Set SMP (bit 6) to enable coherency requests from other cpus
		 */
		aux |= (1 << 6);
	}
	arm_v6_cp15_auxcr_set(aux);	

	/*
	 * Processor implements ARMv7 Multiprocessor Extensions
	 */
	cpu->flags |= ARM_CPU_FLAG_V7_MP;

	/*
	 * Perform generic ARMv7 CPU initialisation
	 */
	armv_setup_v7(cpu, cpuid, cpunum);
}

#if defined(__QNXNTO__) && defined(__USESRCVERSION)
#include <sys/srcversion.h>
__SRCVERSION("$URL: http://svn/product/branches/6.5.0/trunk/hardware/startup/lib/arm/armv_setup_a7.c $ $Rev: 757173 $")
#endif
