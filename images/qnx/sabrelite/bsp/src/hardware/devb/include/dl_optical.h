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

#include <ntocam.h>




extern int dll_pdrvr_init_optical( cam_entry_t *cam_funcs, char *argv[] );
extern int cam_pdrv_version_optical;

/*
 * This list is matched with the exported symbol list.
 */
static const struct dll_syms optical_syms[] = {
	{ "dll_pdrvr_init", &dll_pdrvr_init_optical },
	{ "cam_pdrv_version", &cam_pdrv_version_optical },
	{ NULL, NULL }
};

/*
 * This matched the dll file name
 */
#define CAM_OPTICAL_LIST		"cam-optical.so", optical_syms

#if defined(__QNXNTO__) && defined(__USESRCVERSION)
#include <sys/srcversion.h>
__SRCVERSION("$URL: http://svn/product/branches/6.5.0/trunk/hardware/devb/include/dl_optical.h $ $Rev: 711024 $")
#endif
