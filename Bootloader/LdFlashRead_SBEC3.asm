; LdFlashRead_SBEC3.asm
; 
; SBEC3Library (https://github.com/laszlodaniel/SBEC3Library)
; Copyright (C) 2022, Daniel Laszlo
; 
; MCU: 68HC16
; 
; Worker function to read SBEC3 PCM's flash memory.
; 
; Commands:
; 
; Start worker function:
; TX: 20
; RX: 21
; 
; 20: start worker function request
; 21: request accepted
; 
; Request handshake with flash block read:
; 
; TX: 33 AA BB CC DD EE
; RX: 34 AA BB CC DD EE XX YY ZZ...
; RX: 80
; 
; 33:       request handshake with flash block read
; AA BB CC: flash memory offset
; DD EE:    block size to read
; 34:       request accepted
; XX YY ZZ: flash memory values
; 80:       invalid block size
; 
; Stop memory reading:
; TX: 35
; RX: 22
; 
; 35: stop memory reading request
; 22: request accepted, function finished running

.include "68hc16def.inc"

	org	$200			; start offset in RAM

LdFlashRead:

	ldab	#4			; B = 4
	tbxk				; XK = B = 4
	ldx	#0			; XK:IX = $40000
	ldd	#0			; $00 = read memory
	std	0, X			; set command
	
CommandLoop:

	jsr	ReadCMD			; jump to subroutine
	bcs	Exit			; branch to exit if carry bit is set in CCR

ReadLoop:

	ldab	0, X			; load B with flash memory value at IX
	jsr	SCI_TX			; write SCI-byte from B
	aix	#1			; increment IX value
	decw	DataHB			; decrement byte count value
	bne	ReadLoop		; branch if length is not zero
	bra	CommandLoop		; branch always to read another command

Exit:

	rts				; return from subroutine

ReadCMD:

	jsr	GetCMD			; jump to subroutine
	bcc	ValidCMD		; branch if carry bit is clear
	orp	#$100			; set carry bit in CCR register

ValidCMD:

	rts				; return from subroutine

GetCMD:

	jsr	SCI_RX			; read SCI byte to B
	cmpb	#$33			; $33 = request handshake with flash block read
	beq	SendHandshake		; branch if equal
	cmpb	#$35			; $35 = stop reading
	beq	StopReading		; branch if equal
	comb				; 1's complement B (flip bits) to indicate unknown command byte
	bra	Response		; branch always

StopReading:

	ldab	#$22			; $22 = reading finished successfully
	bra	Response		; branch always

SendHandshake:

	ldab	#$34			; $34 = handshake from programming device
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read flash bank offset
	tba				; A = B, save original flash bank value
	addb	#4			; B = B + 4, flash memory base offset is $40000 set by bootloader
	tbxk				; transfer lower 4 bits of B to XK (flash bank)
	tab				; B = A, restore saved value
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read flash offset HB
	stab	DataHB			; save flash offset HB
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read flash offset LB
	stab	DataLB			; save flash offset LB
	ldx	DataHB			; IX = flash offset
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read byte count HB
	stab	DataHB			; save byte count HB
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read byte count LB
	stab	DataLB			; save byte count lB
	jsr	SCI_TX			; echo
	ldd	DataHB			; load D with byte count
	cpd	#0			; compare D to zero
	beq	InvalidBlockSize	; branch if equal
	andp	#$FEFF			; clear carry bit in CCR register
	clrd				; D = 0
	bra	CommandFinish		; branch to exit

InvalidBlockSize:

	ldab	#$80			; $80 = block size error

Response:

	jsr	SCI_TX			; echo
	orp	#$100			; set carry bit in CCR register

CommandFinish:

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

DataHB:		fcb $27
DataLB:		fcb $4C