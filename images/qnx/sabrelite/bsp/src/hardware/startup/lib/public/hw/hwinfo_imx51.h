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


/*
* IMX51 SOC devices
*
* This file contains names for all of the devices that may exists on any IMX51
* processor variant. Specifically, these are the internal devices that are part
* of the IMX51 SOC and not board specific devices. Board specific devices
* are defined in a similarly named board specific file
* 
* The names are added to the hwinfo section of the syspage (at the discretion of
* the startup writer) so that drivers can use hwi_find_device() to determine
* the existence of SOC device instances in a portable fashion and optionally
* retrieve device specific information like interrupt vectors, etc.
* 
* Not all of the devices are on every processor so hwi_find_device() may return
* HWI_NULL_OFF if a device, or device instance (ie. unit) is not found.
*
*/

#ifndef __HWINFO_IMX51_H_INCLUDED
#define __HWINFO_IMX51_H_INCLUDED

#include <hw/sysinfo.h>

/*
 * =============================================================================
 * 
 *                                B U S E S
 * 
 * =============================================================================
*/
/* I2C - 1 interrupt */
#define IMX51_HWI_I2C                        HWI_ITEM_BUS_I2C

/* USB */
#define IMX51_HWI_USB                        HWI_ITEM_BUS_USB

/* SPI */
#define IMX51_HWI_SPI                        HWI_ITEM_BUS_SPI

/*
 * =============================================================================
 * 
 *                              D E V I C E S
 * 
 * =============================================================================
*/
/* SDHC */
#define IMX51_HWI_SDHC               "sdhc"

/* DMA - multiple interrupts are assigned per available channel for each device */
#define IMX51_HWI_DMA                "dma"

/* FEC - interrupts are assigned */
#define IMX51_HWI_FEC		     "FEC" // "fec"
#define IMX51_HWI_LEGACY_FEC         "fec"  // "tsec"

/* DUART - 1 interrupt */
#define IMX51_HWI_UART               "uart"

/* Security - 1 interrupt per device */
#define IMX51_HWI_SECURITY   "security"

/* GPIO - 1 interrupt per device */
#define IMX51_HWI_GPIO               "gpio"

/* SSI BUS  */
#define IMX51_HWI_SSI                "ssi"

#endif  /* __HWINFO_IMX51_H_INCLUDED */



#if defined(__QNXNTO__) && defined(__USESRCVERSION)
#include <sys/srcversion.h>
__SRCVERSION("$URL: http://svn/product/branches/6.5.0/trunk/hardware/startup/lib/public/hw/hwinfo_imx51.h $ $Rev: 711024 $")
#endif
