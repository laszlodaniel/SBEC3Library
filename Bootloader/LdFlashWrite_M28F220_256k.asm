; LdFlashWrite_M28F220_256k.asm
; 
; SBEC3Library (https://github.com/laszlodaniel/SBEC3Library)
; Copyright (C) 2022, Daniel Laszlo
; 
; MCU: 68HC16
; 
; Worker function to write data to the M28F220 256k flash memory chip.
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
; Request handshake with flash block upload:
; TX: 30 AA BB CC XX YY KK LL MM NN...
; RX: 31 AA BB CC XX YY KK LL MM NN...
; RX: 01/80
; 
; 30:          request handshake with flash block upload
; AA:          flash bank (0 or 1)
; BB CC:       flash offset
; XX YY:       flash block size (must be a power of 2)
; KK LL MM NN: flash block bytes read from flash memory chip after writing them
; 31:          request accepted
; 01:          write error
; 80:          invalid block size
; 
; Request handshake without flash block upload (use previously saved flash block):
; TX: 40 AA BB CC XX YY
; RX: 31 AA BB CC XX YY KK LL MM NN...
; RX: 01/80
; 
; 40:          request handshake without flash block upload (use previously saved flash block)
; AA:          flash bank (0 or 1)
; BB CC:       flash offset
; XX YY:       flash block size (must be a power of 2)
; KK LL MM NN: flash block bytes read from flash memory chip after writing them
; 31:          request accepted
; 01:          write error
; 80:          invalid block size
; 
; Stop programming:
; TX: 32
; RX: 22
; 
; 32: stop programming request
; 22: request accepted, function finished running
; 
; Notes:
; Maximum block size depends on available RAM in the MCU.
; Older variants have 2kB RAM only which limits block size up to 512 bytes.
; Later variants have 4kB RAM wich allows block size up to 2048 bytes.
; In any case, RAM range is checked before flash block upload.

.include "68hc16def.inc"

	org	$200			; start offset in RAM

LdFlashWrite_M28F220:

	ldab	#0			; B = 0
	tbyk				; YK = B = 0
	ldy	#$500			; YK:IY = $00500, offset in RAM to save flash block

CommandLoop:

	jsr	ReadCMD			; jump to subroutine
	bcs	Exit			; branch to exit if carry bit is set in CCR
	ldd	#$50			; $50 = clear status register
	std	E, X			; set command

WriteFlash:

	ldd	E, Y			; D = next flash word from RAM
	cpd	#$FFFF			; compare D to value
	beq	SkipWrite		; skip writing, read erased FFFF value instead
	ldd	#$40			; $40 = setup program
	std	E, X			; set command
	ldd	E, Y			; D = next flash word from RAM
	std	E, X			; write flash word

CheckReady:

	ldd	#$70			; $70 = read status register
	std	E, X			; set command
	ldd	E, X			; D = status register content
	andd	#$80			; check Ready bit
	beq	CheckReady		; wait until ready
	ldd	E, X			; D = status register content
	andd	#$78			; check other flags
	bne	Error			; branch if any of the selected bits are set
	
SkipWrite:

	ldd	#$FF			; $FF = read memory
	std	E, X			; set command
	ldd	E, X			; D = flash word at X + E
	subd	E, Y			; subtract flash word to write
	bne	Error			; branch if they are not equal
	ldd	E, X			; D = flash word at X + E
	jsr	EchoFlashWord		; jump to subroutine
	adde	#2			; E = E + 2, next flash word in RAM
	cpe	BlockSize		; check if E equals to block size
	blt	WriteFlash		; branch if there are words left to write
	bra	CommandLoop		; branch always to read another command

Error:

	ldd	#$FFFF			; $xxFF = read memory
	std	E, X			; set command
	ldab	#1			; B = 1, flash memory write error
	jsr	SCI_TX			; echo

Exit:

	rts				; return from subroutine

ReadCMD:

	jsr	GetCMD			; jump to subroutine
	bcc	ValidCMD		; branch if carry bit is clear
	lde	#$AA55			; E = value
	orp	#$100			; set carry bit in CCR register
	bra	ReturnCMD		; branch to exit if error occurred

ValidCMD:

	clre				; E = 0
	cmpb	#$40			; $40 = skip saving next flash block and use the previously saved one (useful for FFFF only block)
	beq	SkipBlock		; branch if equal

SaveBlock:

	jsr	SCI_RX			; read next flash byte
	stab	E, Y			; save flash byte to RAM
	adde	#1			; E = E + 1, next empty offset in RAM
	cpe	BlockSize		; compare E with block size
	bcs	SaveBlock		; branch if lower (carry bit set) save another byte
	ldd	#$FA0			; set 2.5 ms delay
	jsr	Delay			; wait here for programming voltage

SkipBlock:

	clre				; E = 0

ReturnCMD:

	rts				; return from subroutine

GetCMD:

	jsr	SCI_RX			; read SCI byte to B
	stab	CommandByte		; save B to RAM
	cmpb	#$30			; $30 = request handshake with flash block upload
	beq	SendHandshake		; branch if equal
	cmpb	#$40			; $40 = request handshake without flash block upload (use previously saved block)
	beq	SendHandshake		; branch if equal
	cmpb	#$32			; $32 = stop programming
	beq	StopProgramming		; branch if equal
	comb				; 1's complement B (flip bits) to indicate unknown command byte
	bra	Response		; branch always

StopProgramming:

	ldab	#$22			; $22 = programming finished successfully
	bra	Response		; branch always

SendHandshake:

	ldab	#$31			; $31 = handshake from programming device
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read flash bank to B
	tba				; A = B, save original flash bank value
	addb	#4			; B = B + 4, flash memory base offset is $40000 set by bootloader
	tbxk				; XK = B
	tab				; B = A, restore saved value
	jsr	SCI_TX			; echo original flash bank value
	jsr	SCI_RX			; read flash offset HB to B
	stab	FlashOffset		; save flash offset HB to RAM
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read flash offset LB to B
	stab	FlashOffset+1		; save flash offset LB to RAM
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read flash block size HB to B
	stab	BlockSize		; save flash block size HB to RAM
	jsr	SCI_TX			; echo
	jsr	SCI_RX			; read flash block size LB to B
	stab	BlockSize+1		; save flash block size LB to RAM
	jsr	SCI_TX			; echo
	ldd	BlockSize		; D = flash block size
	cpd	#0			; compare D to value
	beq	InvalidBlockSize	; branch if block size is zero
	jsr	CheckRAMRange		; jump to subroutine
	bcs	InvalidBlockSize	; branch if block does not fit into RAM
	ldx	FlashOffset		; X = flash offset start
	ldab	CommandByte		; B = command byte
	andp	#$FEFF			; clear carry bit in CCR register
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

EchoFlashWord:

	stab	DataLB			; save B to RAM
	tab				; B = A
	jsr	SCI_TX			; echo HB
	ldab	DataLB			; load saved value from RAM
	jsr	SCI_TX			; echo LB
	rts				; return from subroutine

CheckRAMRange:

	pshm	D			; push D onto stack (save value)
	addd	#$500			; add value to D (base RAM address for flash block)
	cmpa	#7			; compare A to value (2kB RAM)
	bls	RangeOK			; branch if lower or same
	ldab	SIMTR, Z		; B = SIMTR register content
	cmpb	#$83			; compare B to magic value
	beq	RangeError		; branch if equal
	cmpa	#$F			; compare A to value (4kB RAM)
	bls	RangeOK			; branch if lower or same

RangeError:

	orp	#$100			; set carry bit in CCR register
	bra	Break			; branch to exit

RangeOK:

	andp	#$FEFF			; clear carry bit in CCR register

Break:

	pulm	D			; pull D from stack (restore value)
	rts				; return from subroutine

BlockSize:	fcb $27
BlockSizeLB:	fcb $4C
FlashOffset:	fcb $27
FlashOffsetLB:	fcb $4C
CommandByte:	fcb $27
DataLB:		fcb $4C