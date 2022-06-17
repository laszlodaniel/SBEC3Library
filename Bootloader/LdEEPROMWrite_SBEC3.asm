; LdEEPROMWrite_SBEC3.asm
; 
; SBEC3Library (https://github.com/laszlodaniel/SBEC3Library)
; Copyright (C) 2022, Daniel Laszlo
; 
; MCU: 68HC16
; 
; Worker function to write SBEC3 PCM's emulated EEPROM.
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
; TX: 39 AA BB CC DD XX YY...
; RX: 3A AA BB CC DD XX YY...
; RX: 01/80/84
; 
; 39:    request handshake with EEPROM block read
; AA BB: EEPROM offset
; CC DD: block size to write
; XX YY: block bytes read from EEPROM after writing them
; 3A:    request accepted
; 01:    write error
; 80:    invalid block size
; 84:    offset out of range
; 
; Stop EEPROM writing:
; TX: 3B
; RX: 22
; 
; 3B: stop EEPROM writing request
; 22: request accepted, function finished running
; 
; Notes:
; EEPROM size is generally 512 bytes (00 00 - 01 FF).
; Offset and block size do not have to be a power of 2.
; User can easily write the whole EEPROM in one go (TX: 39 00 00 02 00 XX YY ZZ...).

.include "68hc16def.inc"

	org	$200			; start offset in RAM

LdEEPROMWrite:

	ldab	#0			; B = 0
	tbyk				; YK = B = 0
	ldy	#$500			; YK:IY = $00500, offset in RAM to save EEPROM block
	
CommandLoop:

	jsr	ReadCMD			; jump to subroutine
	bcs	Exit			; branch to exit if carry bit is set in CCR
	bra	WriteLoop		; branch always

Retry:

	ldaa	Attempts		; A = number of write attempts
	cmpa	#5			; compare A to value
	beq	WriteError		; branch if no dice after 5 attempts
	inc	Attempts		; increment number of attempts

WriteLoop:

	jsr	WriteByte		; jump to subroutine
	bcs	Retry			; branch to retry if error occurred
	tab				; B = A
	jsr	SCI_TX			; write SCI-byte from B
	adde	#1			; increment offset in E
	clr	Attempts		; clear number of attempts
	incw	EEPROMOffset		; increment EEPROM offset
	decw	BlockSize		; decrement block size
	bne	WriteLoop		; branch if length is not zero
	bra	CommandLoop		; branch always to read another command

WriteError:

	ldab	#1			; $01 = write error
	jsr	SCI_TX			; jump to subroutine

Exit:

	rts				; return from subroutine

ReadCMD:

	jsr	GetCMD			; jump to subroutine
	bcc	ValidCMD		; branch if carry bit is clear
	lde	#$AA55			; E = value
	orp	#$100			; set carry bit in CCR register
	bra	ReturnCMD		; branch always to exit

ValidCMD:

	clre				; E = 0

SaveBlock:

	jsr	SCI_RX			; read next EEPROM byte
	stab	E, Y			; save EEPROM byte to RAM
	adde	#1			; E = E + 1, next empty offset in RAM
	cpe	BlockSize		; compare E with block size
	bcs	SaveBlock		; branch if lower (carry bit set) save another byte
	clre				; E = 0

ReturnCMD:

	rts				; return from subroutine

GetCMD:

	jsr	SCI_RX			; read SCI byte to B
	cmpb	#$39			; $39 = request handshake with EEPROM block write
	beq	SendHandshake		; branch if equal
	cmpb	#$3B			; $3B = stop writing
	beq	StopWriting		; branch if equal
	comb				; 1's complement B (flip bits) to indicate unknown command byte
	bra	Response		; branch always

StopWriting:

	ldab	#$22			; $22 = writing finished successfully
	bra	Response		; branch always

SendHandshake:

	ldab	#$3A			; $3A = handshake from programming device
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read EEPROM offset HB to B
	stab	EEPROMOffset		; save EEPROM offset HB to RAM
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read EEPROM offset LB to B
	stab	EEPROMOffset+1		; save EEPROM offset LB to RAM
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read block size HB to B
	stab	BlockSize		; save block size HB to RAM
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read block size LB to B
	stab	BlockSize+1		; save block size LB to RAM
	jsr	SCI_TX			; echo
	ldd	EEPROMOffset		; D = EEPROM offset
	cpd	#$200			; compare D to value
	bcc	InvalidOffset		; branch if greater or equal
	addd	BlockSize		; add block size to D
	cpd	#$200			; compare D to value
	bhi	InvalidBlockSize	; branch if higher
	ldd	BlockSize		; D = block size
	cpd	#0			; compare D to value
	beq	InvalidBlockSize	; branch if zero is given as block size
	andp	#$FEFF			; clear carry bit in CCR register
	clrd				; D = 0
	clr	Attempts		; Attempts = 0
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

GetReady:

	ldd	#$500			; D = value
	std	TR+2, Z			; store D to Transmit RAM
	ldd	#$101			; D = value
	std	SPCR2, Z		; store D to SPCR2
	jsr	QSPI_WaitTransfer	; jump to subroutine
	ldd	RR+2, Z			; D = value from Receive RAM
	rts				; return from subroutine

WriteByte:

	ldd	#6			; D = value
	std	TR+8, Z			; store D to Transmit RAM
	ldd	#$404			; D = value
	std	SPCR2, Z		; store D to SPCR2
	jsr	QSPI_WaitTransfer	; jump to subroutine
	bcs	Return			; branch if carry bit is set in CCR register
	ldd	EEPROMOffset		; D = next EEPROM offset
	asla				; arithmetic shift left A
	asla				; arithmetic shift left A
	asla				; arithmetic shift left A
	oraa	#2			; append EEPROM write command
	std	TR+$A, Z		; store D to Transmit RAM
	clra				; A = 0
	ldab	E, Y			; B = EEPROM byte to write
	std	TR+$C, Z		; store D to Transmit RAM
	bclr	CR+6, Z, #$80		; clear bit in Command RAM
	ldd	#$605			; D = value
	std	SPCR2, Z		; store D to SPCR2
	jsr	QSPI_WaitTransfer	; jump to subroutine
	bcs	Return			; branch if carry bit is set in CCR register
	ldd	#$1388			; D = value
	std	QSPITimeout		; store D to memory

Busy:

	jsr	GetReady		; jump to subroutine
	decw	QSPITimeout		; decrement QSPITimeout value
	beq	Fail			; branch if QSPITimeout = 0
	bitb	#3			; 
	bne	Busy			; branch if not zero
	ldd	EEPROMOffset		; D = next EEPROM offset
	jsr	ReadByte		; jump to subroutine
	bcs	Return			; branch if carry bit is set in CCR register
	cmpa	E, Y			; compare A to buffered EEPROM value
	beq	Return			; branch if equal

Fail:

	orp	#$100			; set carry bit in CCR register

Return:

	rts				; return from subroutine

ReadByte:

	asla				; arithmetic shift left A
	asla				; arithmetic shift left A
	asla				; arithmetic shift left A
	oraa	#3			; append EEPROM read command
	std	TR+$10, Z		; store D to Transmit RAM
	ldd	#$908			; D = value
	std	SPCR2, Z		; store D to SPCR2
	jsr	QSPI_WaitTransfer	; jump to subroutine
	bcs	Abort			; branch if carry bit is set in CCR register
	ldd	RR+$12, Z		; D = value from Receive RAM
	tsta				; test A for zero or minus

Abort:

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
QSPITimeout:	fcb $27
QSPITimeoutLB:	fcb $4C
Attempts:	fcb $27
DataLB:		fcb $4C