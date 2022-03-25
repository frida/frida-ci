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
#include <drvr/hwinfo.h>


/*******************************************************************************
 * hwi_set_busattr
 * 
 * Unconditionally set the bus attribute parameters for the device corresponding
 * to <hwi_off> to <clk>.
 * The API allows for the setting of a specific bus attribute tag in the case
 * where there could be more than 1 bus attribute per device.
 * 
 * Returns: true if the specified tag was successfully set, otherwise false 
 * 
*/
int hwitag_set_busattr(unsigned hwi_off, unsigned busattr_idx, struct hwi_busattr *busattr)
{
	hwi_tag *tag = hwi_tag_find(hwi_off, HWI_TAG_NAME_busattr, &busattr_idx);
	if (tag != NULL) {
		busattr->prefix = tag->prefix;
		tag->busattr = *busattr;
	}
	return (tag == NULL) ? 0 : 1;
}



#if defined(__QNXNTO__) && defined(__USESRCVERSION)
#include <sys/srcversion.h>
__SRCVERSION("$URL: http://svn/product/branches/6.5.0/trunk/hardware/startup/lib/hwitag_set_busattr.c $ $Rev: 711024 $")
#endif
