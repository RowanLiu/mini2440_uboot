/*
 *  armboot - Startup Code for ARM920 CPU-core
 *
 *  Copyright (c) 2001	Marius Gröger <mag@sysgo.de>
 *  Copyright (c) 2002	Alex Züpke <azu@sysgo.de>
 *  Copyright (c) 2002	Gary Jennejohn <garyj@denx.de>
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */

#include <asm-offsets.h>
#include <common.h>
#include <config.h>

/*
 *************************************************************************
 *
 * Startup Code (called from the ARM reset exception vector)
 *
 * do important init only if we don't start from memory!
 * relocate armboot to ram
 * setup stack
 * jump to second stage
 *
 *************************************************************************
 */

	.globl	reset

reset:
	/*
	 * set the cpu to SVC32 mode
	 */
	mrs	r0, cpsr
	bic	r0, r0, #0x1f
	orr	r0, r0, #0xd3
	msr	cpsr, r0

	bl  Turn_on_led1

#  define pWTCON	0x53000000
#  define INTMSK	0x4A000008	/* Interrupt-Controller base addresses */
#  define INTSUBMSK	0x4A00001C
#  define CLKDIVN	0x4C000014	/* clock divisor register */

	ldr	r0, =pWTCON
	mov	r1, #0x0
	str	r1, [r0]

	/*
	 * mask all IRQs by setting all bits in the INTMR - default
	 */
	mov	r1, #0xffffffff
	ldr	r0, =INTMSK
	str	r1, [r0]
	ldr	r1, =0x3ff
	ldr	r0, =INTSUBMSK
	str	r1, [r0]

	//Rowan: config system clock !!!
#define CLK_CTL_BASE   0x4C000000
#define MDIV_405 0x7f << 12
#define PSDIV_405 0x21

#define UPLL_MDIV_48 0x38 << 12
#define MDIV_200 0xa1 << 12
#define PSDIV_200 0x31
#define UPLL_PSDIV_48 0x22

//set to 1:4:8 --- FCLK:400MHZ HCLK:100MHZ PCLK:50MHZ
	ldr r0,=CLKDIVN
	mov r1,#5
	str r1,[r0]

//	mrc p15,0,r1,c1,c0,0
//	orr r1,r1,#0xc0000000
//	mcr p15,0,r1,c1,c0,0

	mov r1,#CLK_CTL_BASE

	mov r2,#UPLL_MDIV_48
	add r2,r2,#UPLL_PSDIV_48
	str r2,[r1,#0x08]

	mov r2,#MDIV_405
	add r2,r2,#PSDIV_405
	str r2,[r1,#0x04]

	/*
	 * we do sys-critical inits only at reboot,
	 * not when booting from ram!
	 */
#ifndef CONFIG_SKIP_LOWLEVEL_INIT
	bl	cpu_init_crit
#endif

	bl	_main

/*------------------------------------------------------------------------------*/

	.globl	c_runtime_cpu_setup
c_runtime_cpu_setup:

	mov	pc, lr


/***********************************************************************************/
/*Rowan:Turn on/off led1 is very helpful for debuging uboot
************************************************************************************/
Turn_on_led1:

    ldr r0,=0x56000010       
	ldr r1,=0x15400
	str r1,[r0]

	ldr r0,=0x56000014
	mov r1,#00
	str r1,[r0]

	mov pc,lr

/*
 *************************************************************************
 *
 * CPU_init_critical registers
 *
 * setup important registers
 * setup memory timing
 *
 *************************************************************************
 */


#ifndef CONFIG_SKIP_LOWLEVEL_INIT
cpu_init_crit:
	/*
	 * flush v4 I/D caches
	 */
	mov	r0, #0
	mcr	p15, 0, r0, c7, c7, 0	/* flush v3/v4 cache */
	mcr	p15, 0, r0, c8, c7, 0	/* flush v4 TLB */

	/*
	 * disable MMU stuff and caches
	 */
	mrc	p15, 0, r0, c1, c0, 0
	bic	r0, r0, #0x00002300	@ clear bits 13, 9:8 (--V- --RS)
	bic	r0, r0, #0x00000087	@ clear bits 7, 2:0 (B--- -CAM)
	orr	r0, r0, #0x00000002	@ set bit 1 (A) Align
	orr	r0, r0, #0x00001000	@ set bit 12 (I) I-Cache
	mcr	p15, 0, r0, c1, c0, 0

#ifndef CONFIG_SKIP_LOWLEVEL_INIT_ONLY
	/*
	 * before relocating, we have to setup RAM timing
	 * because memory timing is board-dependend, you will
	 * find a lowlevel_init.S in your board directory.
	 */
	mov	ip, lr

	bl	lowlevel_init
	mov	lr, ip
#endif
	mov	pc, lr
#endif /* CONFIG_SKIP_LOWLEVEL_INIT */
