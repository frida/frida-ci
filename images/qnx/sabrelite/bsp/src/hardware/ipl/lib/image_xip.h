/*
 * $QNXLicenseC:
 * Copyright 2013, QNX Software Systems.
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

#ifndef _IMAGE_XIP_INCLUDED
#define _IMAGE_XIP_INCLUDED

typedef struct image_xip {
	void	*ext;	// underlying XIP device, normally includes the arguments needed for a NOR part 
 	unsigned (*xip_load)(void *dev, unsigned long dst, unsigned long src, int size, int verbose);
	int		verbose;
} image_xip_t;

extern int xip_image_init(image_xip_t *xip_dev);
extern unsigned long xip_image_load(unsigned long dst, unsigned long src);

#endif /* #ifndef _IMAGE_XIP_INCLUDED */

#if defined(__QNXNTO__) && defined(__USESRCVERSION)
#include <sys/srcversion.h>
__SRCVERSION("$URL: http://svn/product/branches/6.5.0/trunk/hardware/ipl/lib/image_xip.h $ $Rev: 723411 $")
#endif
