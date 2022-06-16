; LdEEPROMRead_SBEC3.asm
; 
; SBEC3Library (https://github.com/laszlodaniel/SBEC3Library)
; Copyright (C) 2022, Daniel Laszlo
; 
; MCU: 68HC16
; 
; Worker function to read SBEC3 PCM's emulated EEPROM.
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
; Request handshake with EEPROM block read:
; 
; TX: 36 AA BB CC DD
; RX: 37 AA BB CC DD XX YY...
; RX: 80/84
; 
; 36:    request handshake with EEPROM block read
; AA BB: EEPROM offset
; CC DD: block size to read
; 37:    request accepted
; XX YY: EEPROM values
; 80:    invalid block size
; 84:    offset out of range
; 
; Stop memory reading:
; TX: 38
; RX: 22
; 
; 38: stop memory reading request
; 22: request accepted, function finished running
; 
; Notes:
; EEPROM size is generally 512 bytes (00 00 - 01 FF).
; Offset and block size do not have to be a power of 2.
; User can easily read the whole EEPROM in one go (TX: 36 00 00 02 00).

.include "68hc16def.inc"

	org	$200			; start offset in RAM

LdEEPROMRead:

	ldd	#0			; D = 0
	
CommandLoop:

	jsr	ReadCMD			; jump to subroutine
	bcs	Exit			; branch to exit if carry bit is set in CCR

ReadLoop:

	jsr	ReadByte		; jump to subroutine
	bcs	CommandLoop		; branch if error occurred
	tab				; B = A
	jsr	SCI_TX			; write SCI-byte from B
	adde	#1			; increment offset in E
	decw	BlockSize		; decrement block size
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
	cmpb	#$36			; $36 = request handshake with EEPROM block read
	beq	SendHandshake		; branch if equal
	cmpb	#$38			; $38 = stop reading
	beq	StopReading		; branch if equal
	comb				; 1's complement B (flip bits) to indicate unknown command byte
	bra	Response		; branch always

StopReading:

	ldab	#$22			; $22 = reading finished successfully
	bra	Response		; branch always

SendHandshake:

	ldab	#$37			; $37 = handshake from programming device
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read EEPROM offset HB
	stab	EEPROMOffset		; save EEPROM offset HB
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read EEPROM offset LB
	stab	EEPROMOffset+1		; save EEPROM offset LB
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read byte count HB
	stab	BlockSize		; save byte count HB
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read byte count LB
	stab	BlockSize+1		; save byte count LB
	jsr	SCI_TX			; echo
	ldd	EEPROMOffset		; D = EEPROM offset
	cpd	#$200			; compare D to value
	bcc	InvalidOffset		; branch if greater or equal
	addd	BlockSize		; add byte count to D
	cpd	#$200			; compare D to value
	bhi	InvalidBlockSize	; branch if higher
	ldd	BlockSize		; D = block size
	cpd	#0			; compare D to value
	beq	InvalidBlockSize	; branch if zero is given as block size
	andp	#$FEFF			; clear carry bit in CCR register
	clrd				; D = 0
	lde	EEPROMOffset		; E = start offset
	bra	CommandFinish		; branch to exit

InvalidBlockSize:

	ldab	#$80			; $80 = block size error
	bra	Response		; branch always

InvalidOffset:

	ldab	#$84			; $84 = offset out of range

Response:

	jsr	SCI_TX			; echo
	orp	#$100			; set carry bit in CCR register

CommandFinish:

	rts				; return from subroutine

ReadByte:

	ted				; D = E
	asla				; arithmetic shift left A
	asla				; arithmetic shift left A
	asla				; arithmetic shift left A
	oraa	#3			; append EEPROM read command
	std	TR+2, Z			; store D to Transmit RAM
	ldd	#$CB4B			; D = value
	std	CR+1, Z			; store D to Command RAM
	ldd	#$201			; D = value
	std	SPCR2, Z		; store D to QSPI register
	jsr	QSPI_WaitTransfer	; jump to subroutine
	bcs	Return			; branch if carry bit is set in CCR register
	ldd	RR+4, Z			; D = value from Receive RAM
	tsta				; test A for zero or minus

Return:

	rts				; return from subroutine
	

QSPI_WaitTransfer:

	bclr	SPSR, Z, #$80		; clear SPIF bit, QSPI not finished
	bset	SPCR1, Z, #$80		; set SPE bit, enable QSPI
	clra				; A = 0

Wait:

	deca				; decrement A
	beq	Error			; branch if A = 0
	brclr	SPSR, Z, #$80, Wait	; branch if SPIF bit is clear
	bclr	SPSR, Z, #$80		; clear SPIF bit, QSPI not finished
	tsta				; test A for zero or minus
	bra	Break			; branch always to exit

Error:

	orp	#$100			; set carry bit in CCR register
	tpa				; A = CCR MSB
	ldab	#$A5			; B = value

Break:

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

BlockSize:	fcb $27
BlockSizeLB:	fcb $4C
EEPROMOffset:	fcb $27
EEPROMOffsetLB:	fcb $4C