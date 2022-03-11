; 10_LdFlashRead.asm
; 
; MCU: 68HC16
; 
; Worker function to read SBEC3 PCM's flash memory.
; 
; Commands:
; 
; Read flash memory:
; TX: 45 AA BB CC DD EE
; RX: 46 AA BB CC DD EE XX YY ZZ...
; 
; 45:       read flash memory request
; AA BB CC: flash memory offset
; DD EE:    number of bytes to read
; 46:       request accepted
; XX YY ZZ: flash memory values
; 
; Exit worker function:
; TX: E0
; RX: E1 22
; 
; E0: request exit
; E1: request accepted
; 22: function finished
; 
; Notes:
; Wait for echo before transmitting the next byte.

.include "68hc16def.inc"

	org	$200			; start offset in RAM

LdFlashRead:

	jsr	SCI_RX			; read SCI-byte to B
	cmpb	#$45			; $45 = read flash memory command
	beq	GetParameters		; branch to get read parameters
	cmpb	#$E0			; $E0 = exit worker function command
	beq	Break			; branch to exit
	bne	LdFlashRead		; try again with another command byte

GetParameters:

	ldab	#$46			; $46 = read flash memory request accepted
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read flash bank offset
	tbxk				; transfer lower 4 bits of B to XK (flash bank)
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read flash offset HB
	stab	DataHB			; save flash offset HB
	ldab	DataHB			; load flash offset HB from memory
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read flash offset LB
	stab	DataLB			; save flash offset LB
	ldx	DataHB			; IX = flash offset
	ldab	DataLB			; load flash offset LB from memory
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read byte count HB
	stab	DataHB			; save byte count HB
	ldab	DataHB			; load byte count HB from memory
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read byte count LB
	stab	DataLB			; save byte count lB
	ldab	DataLB			; load byte count LB from memory
	jsr	SCI_TX			; echo
	ldd	DataHB			; load D with byte count
	cpd	#0			; compare D to zero
	lbeq	LdFlashRead		; can't read zero bytes, try again

ReadNextByte:

	ldab	0, X			; load B with flash memory value at IX
	jsr	SCI_TX			; write SCI-byte from B
	aix	#1			; increment IX value
	decw	DataHB			; decrement byte count value
	bne	ReadNextByte		; branch if length is not zero
	lbra	LdFlashRead		; long branch always to read another command byte

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

DataHB: fcb $27
DataLB: fcb $4C