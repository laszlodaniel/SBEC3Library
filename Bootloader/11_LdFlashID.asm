; 11_LdFlashID.asm
; 
; MCU: 68HC16
; 
; Worker function to read manufacturer and chip ID 
; of the SBEC3 PCM's flash memory.
; 
; Commands:
; 
; Read flash memory manufacturer and chip ID:
; TX: 55
; RX: 56 XX YY
; 
; 55: read flash memory manufacturer and chip ID
; 56: request accepted
; XX: manufacturer ID
; YY: chip ID
; 
; Exit worker function:
; TX: E0
; RX: E1 22
; 
; E0: request exit
; E1: request accepted
; 22: function finished
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

	jsr	SCI_RX			; read SCI-byte to B
	cmpb	#$55			; $55 = read flash manufacturer and chip ID request
	beq	GetParameters		; branch to read flash IDs
	cmpb	#$E0			; $E0 = exit worker function command
	beq	Break			; branch to exit
	bne	LdFlashID		; try again with another command byte

GetParameters:

	ldab	#$56			; $56 = read flash manufacturer and chip ID request accepted
	jsr	SCI_TX			; echo
	ldab	#4			; B = 4
	tbxk				; XK = B = 4
	ldx	#0			; XK:IX = $40000
	ldd	#$90			; $90 = read electronic signature command
	std	0, X			; set command
	ldab	1, X			; read manufacturer ID
	jsr	SCI_TX			; echo
	ldab	3, X			; read chip ID
	jsr	SCI_TX			; echo
	ldd	#$FF			; $FF = switch to read mode command for M28F210/M28F220, reset command for M28F102
	std	0, X			; set command
	bra	LdFlashID		; try again with another command byte

Break:

	ldab	#$E1			; $E1 = exit request accepted
	jsr	SCI_TX			; echo
	ldab	#$22			; $22 = function finished
	jsr	SCI_TX			; echo
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