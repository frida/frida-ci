/*
 * $QNXLicenseC:
 * Copyright 2013, QNX Software Systems. All Rights Reserved.
 *
 * You must obtain a written license from and pay applicable license fees to QNX
 * Software Systems before you may reproduce, modify or distribute this software,
 * or any work that includes all or part of this software.   Free development
 * licenses are available for evaluation and non-commercial purposes.  For more
 * information visit http://licensing.qnx.com or email licensing@qnx.com.
 *
 * This file may contain contributions from others.  Please review this entire
 * file for other proprietary rights or license notices, as well as the QNX
 * Development Suite License Guide at http://licensing.qnx.com/license-guide/
 * for other information.
 * $
 */
#ifndef PTP_H
#define PTP_H

#include <stdint.h>

/*
 * Protocol
 */
#define ETHERTYPE_PTP	0x88F7
#define PTP_UDP_PORT    319  /* UDP port for PTP event messages */

enum {
    PTP_MSG_SYNC=0x0,
    PTP_MSG_DELAY_REQ,
    PTP_MSG_PDELAY_REQ,
    PTP_MSG_PDELAY_RESP,
    PTP_MSG_FOLLOW_UP=0x8,
    PTP_MSG_DELAY_RESP,
    PTP_MSG_PDELAY_RESP_FOLLOW_UP,
    PTP_MSG_ANNOUNCE,
    PTP_MSG_SIGNALING,
    PTP_MSG_MANAGEMENT,
};

typedef struct {
    uint8_t  messageId;
    uint8_t  version;
    uint16_t messageLength;
    uint8_t  domainNumber;
    uint8_t  reserved1;
    uint16_t flags;
    uint64_t correctionField;
    uint32_t reserved2;
    uint8_t  clockIdentity[8];
    uint16_t sportId;
    uint16_t sequenceId;
    uint8_t  control;
    uint8_t  logMeanMessageInterval;
}  __attribute__((__packed__)) ptpv2hdr_t;

/*
 * Driver interface
 */
#define PTP_GET_RX_TIMESTAMP	0x100  /* get RX timestamp */
#define PTP_GET_TX_TIMESTAMP	0x101  /* get TX timestamp */
#define PTP_GET_TIME		0x102  /* get time */
#define PTP_SET_TIME		0x103  /* set time */
#define PTP_SET_COMPENSATION	0x104  /* set compensation */
#define PTP_GET_COMPENSATION	0x105  /* get compensation */

/* get/set time */
typedef struct {
    int32_t	sec;	/* ptp clock seconds */
    int32_t	nsec;	/* ptp clock nanoseconds */
} ptp_time_t;

/* get Rx/Tx timestamp */
typedef struct {
    uint8_t	msg_type;		/* msg type */
    int8_t	clock_identity[8];	/* Clock identity */
    uint16_t	sport_id;		/* Source port ID */
    uint16_t	sequence_id;		/* message sequence ID */
    ptp_time_t	ts;			/* timestamp */
} ptp_extts_t;

/* get/set compensation */
typedef struct {
    uint32_t		comp;		/* compensation value in nanoseconds */
    unsigned char	positive;	/* 1- positive, 0 - negative */
} ptp_comp_t;

#endif

#if defined(__QNXNTO__) && defined(__USESRCVERSION)
#include <sys/srcversion.h>
__SRCVERSION("$URL: http://svn/product/branches/6.5.0/trunk/lib/io-pkt/sys/lib/libdrvr/public/drvr/ptp.h $ $Rev: 726683 $")
#endif
