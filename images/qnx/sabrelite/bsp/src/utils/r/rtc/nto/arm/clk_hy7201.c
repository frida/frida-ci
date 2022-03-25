/*
 * $QNXLicenseC: 
 * Copyright 2007, 2008, QNX Software Systems.  
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





#include "rtc.h"
#include <time.h>
#include <arm/hy7201.h>


int
RTCFUNC(init,hy7201)(struct chip_loc *chip, char *argv[])
{
	if (chip->phys == NIL_PADDR) {
		chip->phys = HY7201_RTC_BASE;
	}
	if (chip->access_type == NONE) {
		chip->access_type = MEMMAPPED;
	}
	return 0;
}

int
RTCFUNC(get,hy7201)(struct tm *tm, int cent_reg)
{
	time_t		t;

	/*
	 * read RTC counter value
	 */
	t = chip_read(HY7201_RTC_RTCDR, 32);

#ifdef	VERBOSE_SUPPORTED
	if (verbose) {
		printf("rtc read: %d\n", t);
	}
#endif
	
	gmtime_r(&t,tm);	
	
	return 0;
}

int
RTCFUNC(set,hy7201)(struct tm *tm, int cent_reg)
{
	time_t		t;
	
	t = mktime(tm);

	/*
	 *	mktime assumes local time.  We will subtract timezone
	 */
	t -= timezone;

#ifdef	VERBOSE_SUPPORTED
	if (verbose) {
		printf("rtc write: %d\n", t);
	}
#endif

	chip_write(HY7201_RTC_RTCDR, t, 32);

	return 0;
}

__SRCVERSION( "$URL: http://svn/product/branches/6.5.0/trunk/utils/r/rtc/nto/arm/clk_hy7201.c $ $Rev: 217572 $" );
