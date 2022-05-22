; 11_LdFlashID.asm
; 
; MCU: 68HC16
; 
; Worker function to read manufacturer and chip ID 
; of the SBEC3 PCM's flash memory.
; 
; Command:
; 
; TX: 20
; RX: 21 XX YY
; 
; 20: start worker function request
; 21: request accepted
; XX: manufacturer ID
; YY: chip ID
; 
; Known manufacturer and chip IDs:
; 
; Manufacturer:
; $20: STMicroelectronics
; $31: CATALYST
; 
; Chip ID:
; $50: M28F102 (128k)
; $51: CAT28F102 (128k)
; $E0: M28F210 (256k)
; $E6: M28F220 (256k)
; 
; Notes:
; M28F102 needs bootstrap voltage to output these information.
; To be tested.

.include "68hc16def.inc"

	org	$200			; start offset in RAM

LdFlashID:

	ldab	#4			; B = 4
	tbxk				; XK = B = 4
	ldx	#0			; XK:IX = $40000
	ldd	#$3E80			; set 10 ms delay
	jsr	Delay			; wait here for programming voltage
	ldd	#$90			; $90 = read electronic signature command
	std	0, X			; set command
	ldab	1, X			; read manufacturer ID
	jsr	SCI_TX			; echo
	ldab	3, X			; read chip ID
	jsr	SCI_TX			; echo
	ldd	#$FFFF			; $xxFF = switch to read mode command for M28F210/M28F220, $FFFF = reset command for M28F102
	std	0, X			; set command
	ldd	#$FFFF			; reset command confirmation for M28F102
	std	0, X			; set command
	ldd	#0			; $00 = mandatory switch to read mode command for M28F102, invalid for M28F210/M28F220
	std	0, X			; set command
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
	bne	Delay			; branch/loop until D equals zero, 1 loop takes 0.000625 ms to complete
	rts				; return from subroutine