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


#include "proto.h"

int 
i2c_master_getfuncs(i2c_master_funcs_t *funcs, int tabsize)
{
    I2C_ADD_FUNC(i2c_master_funcs_t, funcs, 
            init, mx35_init, tabsize);
    I2C_ADD_FUNC(i2c_master_funcs_t, funcs,
            fini, mx35_fini, tabsize);
    I2C_ADD_FUNC(i2c_master_funcs_t, funcs,
            send, mx35_send, tabsize);
    I2C_ADD_FUNC(i2c_master_funcs_t, funcs,
            recv, mx35_recv, tabsize);
    I2C_ADD_FUNC(i2c_master_funcs_t, funcs,
            set_slave_addr, mx35_set_slave_addr, tabsize);
    I2C_ADD_FUNC(i2c_master_funcs_t, funcs,
            set_bus_speed, mx35_set_bus_speed, tabsize);
    I2C_ADD_FUNC(i2c_master_funcs_t, funcs,
            version_info, mx35_version_info, tabsize);
    I2C_ADD_FUNC(i2c_master_funcs_t, funcs,
            driver_info, mx35_driver_info, tabsize);
    return 0;
}

__SRCVERSION( "$URL: http://svn/product/branches/6.5.0/trunk/hardware/i2c/mx35/lib.c $ $Rev: 217585 $" );
