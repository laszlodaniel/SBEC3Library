; LdFlashErase_M28F102_128k.asm
; 
; SBEC3Library (https://github.com/laszlodaniel/SBEC3Library)
; Copyright (C) 2022, Daniel Laszlo
; 
; MCU: 68HC16
; 
; Worker function to erase the M28F102 128k flash memory chip 
; found in some earlier SBEC3 units.
; 
; Command:
; 
; TX: 20
; RX: 21
; RX: 22/81/82
; 
; 20: start worker function request
; 21: request accepted
; 22: erase success
; 81: erase error while flipping bits from 1 to 0
; 82: erase error while flipping bits from 0 to 1
; 
; Notes:
; The first step of erasing this type of flash memory chip is 
; to program all bytes to 00 (_P) then erase them to FF (_E).
; A complete erase cycle takes around 2 seconds.

.include "68hc16def.inc"

	org	$200			; start offset in RAM

LdFlashErase_M28F102:

	ldab	#4			; B = 4
	tbxk				; XK = B = 4
	ldx	#0			; XK:IX = $40000
	ldd	#$FA0			; set 2.5 ms delay
	jsr	Delay			; wait here for programming voltage

Loop_P:

	clrw	PulseCount		; PulseCount = 0
	bra	Try_P			; branch always

Retry_P:

	ldd	PulseCount		; D = PulseCount
	cpd	#25			; compare PulseCount to 25
	lbeq	Error_P			; branch if no dice after 25 tries
	incw	PulseCount		; increment PulseCount

Try_P:

	ldd	#$40			; $40 = setup program
	std	0, X			; set command
	ldd	#0			; D = 0
	std	0, X			; overwrite flash word with 0
	ldd	#$10			; set 10 us delay
	jsr	Delay			; wait here for a while
	ldd	#$C0			; $C0 = program verify
	std	0, X			; set command
	ldd	#10			; set 6 us delay
	jsr	Delay			; wait here for a while
	ldd	0, X			; D = flash word at X
	bne	Retry_P			; branch if not zero to try again
	aix	#2			; X = X + 2, next flash word
	txkb				; B = XK
	cmpb	#6			; compare Bank to value, valid banks are 4 and 5 (128k)
	bcs	Loop_P			; branch if lower
	ldab	#4			; B = 4
	tbxk				; XK = B = 4
	ldx	#0			; XK:IX = $40000
	ldd	#0			; $00 = read memory
	std	0, X			; set command
	clrw	PulseCount		; PulseCount = 0
	bra	Try_E			; branch always

Retry_E:

	ldd	PulseCount		; D = PulseCount
	cpd	#1000			; compare PulseCount to 1000
	lbeq	Error_E			; branch if no dice after 1000 tries
	incw	PulseCount		; increment PulseCount

Try_E:

	ldd	#$20			; $20 = setup erase
	std	0, X			; set command
	ldd	#$20			; $20 = erase confirm
	std	0, X			; set command
	ldd	#$3E80			; set 10 ms delay
	jsr	Delay			; wait here for a while

Loop_E:

	ldd	#$A0			; $A0 = erase verify
	std	0, X			; set command
	ldd	#10			; set 6 us delay
	jsr	Delay			; wait here for a while
	ldd	0, X			; D = flash word at X
	cpd	#$FFFF			; compare word to $FFFF
	bne	Retry_E			; branch if not $FFFF to try again
	aix	#2			; X = X + 2, next flash word
	txkb				; B = XK
	cmpb	#6			; compare Bank to value, valid banks are 4 and 5 (128k)
	bcs	Loop_E			; branch if lower
	ldab	#4			; B = 4
	tbxk				; XK = B = 4
	ldx	#0			; XK:IX = $40000
	ldd	#0			; $00 = read memory
	std	0, X			; set command
	ldab	#$22			; erase success

Return:

	jsr	SCI_TX			; echo
	ldd	#0			; $00 = read memory
	std	0, X			; set command
	rts				; return from subroutine

Error_P:

	ldab	#$81			; erase error
	bra	Return			; branch always

Error_E:

	ldab	#$82			; erase error
	bra	Return			; branch always

SCI_TX:

	ldaa	SCSR, Z			; A = SCI Status Register HB
	anda	#1			; check TDRE flag
	beq	SCI_TX			; branch/loop until TDRE is cleared
	stab	SCDR_LB, Z		; save B to SCI Data Register LB
	rts				; return from subroutine

SCI_RX:

	ldaa	SCSR_LB, Z		; A = SCI Status Register LB
	anda	#$42			; check RDRF and FE flag
	cmpa	#$40			; check RDFR flag
	bne	SCI_RX			; branch/loop until RDRF is set and FE is cleared
	ldab	SCDR_LB, Z		; load B with SCI Data Register content
	rts				; return from subroutine

Delay:

	subd	#1			; decrement D
	bne	Delay			; branch/loop until D equals zero, 1 loop takes 0.000625 ms or 0.625 us to complete
	rts				; return from subroutine

PulseCount:	fcb $27
PulseCountLB:	fcb $4C