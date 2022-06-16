; LdFlashErase_M28F220_256k.asm
; 
; SBEC3Library (https://github.com/laszlodaniel/SBEC3Library)
; Copyright (C) unknown
; 
; MCU: 68HC16
; 
; Worker function to erase the M28F220 256k flash memory chip.
; 
; Command:
; 
; TX: 20
; RX: 21
; RX: 22/83
; 
; 20: start worker function request
; 21: request accepted
; 22: erase success
; 83: erase error

.include "68hc16def.inc"

	org	$200			; start offset in RAM

LdFlashErase_M28F220:

	jsr	InitIXIY		; initialize IX and IY index registers
	ldd	#$FA0			; set 2.5 ms delay
	jsr	Delay			; wait here for programming voltage
	jsr	InitIZGPT		; initialize IZ index register and the general purpose timer
	ldd	#$50			; $50 = clear status register
	std	0, X			; set command
	jsr	EraseBlock0		; jump to subroutine
	jsr	CheckReady		; jump to subroutine
	bne	Return			; branch if erase failed
	jsr	EraseBlock1		; jump to subroutine
	jsr	CheckReady		; jump to subroutine
	bne	Return			; branch if erase failed
	jsr	EraseBlock2		; jump to subroutine
	jsr	CheckReady		; jump to subroutine
	bne	Return			; branch if erase failed
	jsr	EraseBlock3		; jump to subroutine
	jsr	CheckReady		; jump to subroutine
	bne	Return			; branch if erase failed
	jsr	EraseBlock4		; jump to subroutine
	jsr	CheckReady		; jump to subroutine
	bne	Return			; branch if erase failed
	ldab	#$22			; $22 = erase success

Return:

	jsr	SCI_TX			; echo
	rts				; return from subroutine

EraseBlock0:

	ldd	#0			; D = 0
	addd	#0			; base offset = $00000
	xgdx				; X = D
	ldab	#4			; B = 4
	adcb	#2			; 
	tbxk				; XK = B, XK:IX = $60000
	jsr	Erase			; jump to subroutine
	rts				; return from subroutine

EraseBlock1:

	ldd	#0			; D = 0
	addd	#$8000			; base offset = $08000
	xgdx				; X = D
	ldab	#4			; B = 4
	adcb	#0			; 
	tbxk				; XK = B, XK:IX = $48000
	jsr	Erase			; jump to subroutine
	rts				; return from subroutine

EraseBlock2:

	ldd	#0			; D = 0
	addd	#$6000			; base offset = $06000
	xgdx				; X = D
	ldab	#4			; B = 4
	adcb	#0			; 
	tbxk				; XK = B, XK:IX = $46000
	jsr	Erase			; jump to subroutine
	rts				; return from subroutine

EraseBlock3:

	ldd	#0			; D = 0
	addd	#$4000			; base offset = $04000
	xgdx				; X = D
	ldab	#4			; B = 4
	adcb	#0			; 
	tbxk				; XK = B, XK:IX = $44000
	jsr	Erase			; jump to subroutine
	rts				; return from subroutine

EraseBlock4:

	ldd	#0			; D = 0
	addd	#0			; base offset = $00000
	xgdx				; X = D
	ldab	#4			; B = 4
	adcb	#0			; 
	tbxk				; XK = B, XK:IX = $40000
	jsr	Erase			; jump to subroutine
	rts				; return from subroutine

Erase:

	ldd	#$20			; $20 = erase
	std	0, X			; set command
	ldd	#$D0			; $D0 = erase resume / confirm
	std	0, X			; set command
	rts				; return from subroutine

CheckReady:

	jsr	SetTimeout		; jump to subroutine
	ldab	#$A			; B = number of attempts
	stab	Attempts		; store B to memory

Loop:

	brclr	TFLG1, Z, #$10, Check	; check ready status
	jsr	SetTimeout		; jump to subroutine
	decw	Attempts		; decrement number of attempts
	bne	Check			; check ready status
	ldab	#$83			; $83 = erase failed
	bra	Exit			; branch always to exit

Check:

	ldd	#$70			; $70 = read status register
	std	0, X			; set command
	ldd	0, X			; D = status register content
	andd	#$80			; check Ready flag
	beq	Loop			; branch if not ready
	ldd	0, X			; D = status register content
	andd	#$78			; check other error flags

Exit:

	rts				; return from subroutine

Attempts:	fcb $27
AttemptsLB:	fcb $4C

InitIXIY:

	ldab	#4			; B = 4
	tbxk				; XK = B
	ldx	#0			; XK:IX = $40000
	txy				; YK:IY = $40000
	rts				; return from subroutine

Redundant:

	txkb				; B = XK
	cmpb	#8			; compare B to value
	bcc	GOE			; branch if greater or equal (carry clear)
	orp	#$100			; set carry bit in CCR register
	bra	Break			; branch always to exit

GOE:

	ldab	#4			; B = 4
	tbxk				; XK = B
	andp	#$FEFF			; clear carry bit in CCR register

Break:

	rts				; return from subroutine

InitIZGPT:

	ldab	#$F			; B = value
	tbzk				; ZK = B
	ldz	#$8000			; ZK:IZ = $F8000
	clr	TCTL1, Z		; clear Timer Control Register 1
	ldab	#6			; B = value
	stab	TMSK2, Z		; store B to Timer Interrupt Mask Register 2
	rts				; return from subroutine

SetTimeout:

	ldd	TCNT, Z			; D = Timer Counter register
	addd	#$F424			; add timeout value to D
	std	TOC2, Z			; store value to Output Compare Register 2
	ldab	TFLG1, Z		; B = Timer Interrupt Flag Register 1
	bclr	TFLG1, Z, #$10		; clear bit in register
	rts				; return from subroutine

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