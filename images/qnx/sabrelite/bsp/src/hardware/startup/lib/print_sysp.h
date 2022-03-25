/*
 * $QNXLicenseC:
 * Copyright 2009, QNX Software Systems. 
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



#if !defined(CPU_PRT_SYSPAGE_RTN)

#include "startup.h"

#define PSP_STARTUP			1
#define PSP_SYSPAGE			lsp.syspage.p
#define PSP_SPRINTF			ksprintf
#define PSP_VERBOSE(lvl)	(debug_flag > (lvl))

#define PSP_NATIVE_ENDIAN16(v)	(v)
#define PSP_NATIVE_ENDIAN32(v)	(v)
#define PSP_NATIVE_ENDIAN64(v)	(v)
#define PSP_NATIVE_ENDIANPTR(v)	(v)

#endif

#include "cpu_print_sysp.ci"
