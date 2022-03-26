; 02_LdPartNumberRead.asm
; 
; MCU: 68HC16
; 
; Worker function to read SBEC3 PCM part number.

.include "68hc16def.inc"

	org	$200			; start offset in RAM

LdPartNumberRead:

	lde	#$1E8			; E = offset in EEPROM
	jsr	GetEEPROMWord		; read EEPROM value at E to D
	bcs	Break			; error if carry set
	anda	#8			; check highest bit in A
	bne	FromFlash		; read part number from flash memory if bit not set
	jsr	Out20FF			; out 20x FF value to SCI
	bra	FromEEPROM		; read part number from EEPROM if bit is set

FromFlash:

	jsr	FlashRead		; jump to subroutine

FromEEPROM:

	jsr	EEPROMRead		; jump to subroutine

Break:

	rts				; return from subroutine

FlashRead:

	tykb				; B = YK
	tba				; A = B
	txkb				; B = XK
	pshm	D, X			; push multiple registers onto stack (save value)
	ldab	#4			; B = 4
	tbyk				; YK = B = 4
	ldy	#$200			; IY = $200 (YK:IY = $40200, part number start offset in flash memory)
	ldaa	1, Y			; IY = page address offset
	cmpa	#4			; check page
	bhi	Error			; error if page number greater or equal to 4
	aba				; A = A + B
	tab				; B = A
	tbxk				; XK = B
	ldx	2, Y			; IX = pointer to part number
	lde	#$14			; E = read length (20 bytes)
	jsr	ReadBlock		; jump to subroutine
	bra	Finish			; branch always to finish

Error:

	jsr	Out20FF			; out 20x FF value to SCI

Finish:

	pulm	X, D			; pull multiple registers from stack (restore value)
	tbxk				; XK = B
	tab				; B = A
	tbyk				; YK = B
	rts				; return from subroutine

Out20FF:

	lde	#$14			; E = transfer length

LoadFF:

	ldab	#$FF			; B = $FF
	jsr	SCI_TX			; echo
	sube	#1			; subtract 1 from E
	bne	LoadFF			; repeat until E = 0
	rts				; return from subroutine

EEPROMRead:

	lde	#$1E2			; E = offset in EEPROM

Again:

	jsr	GetEEPROMWord		; jump to subroutine
	pshm	D			; push multiple registers onto stack (save value)
	tab				; B = A
	jsr	SCI_TX			; echo
	pulm	D			; pull multiple registers from stack (restore value)
	jsr	SCI_TX			; echo
	adde	#2			; E = E + 2
	cpe	#$1E6			; compare E to value
	bne	Again			; repeat until E equals to $1E6
	lde	#$1E9			; E = offset in EEPROM
	jsr	GetEEPROMWord		; jump to subroutine
	pshm	D			; push multiple registers onto stack (save value)
	tab				; B = A
	jsr	SCI_TX			; echo
	pulm	D			; pull multiple registers from stack (restore value)
	jsr	SCI_TX			; echo
	lde	#$1E7			; E = offset in EEPROM
	jsr	GetEEPROMWord		; jump to subroutine
	pshm	D			; push multiple registers onto stack (save value)
	tab				; B = A
	jsr	SCI_TX			; echo
	pulm	D			; pull multiple registers from stack (restore value)
	jsr	SCI_TX			; echo
	lde	#$1EF			; E = offset in EEPROM
	jsr	GetEEPROMWord		; jump to subroutine
	tab				; B = A
	jsr	SCI_TX			; echo
	rts				; return from subroutine

SCI_TX:

	ldaa	SCSR, Z			; A = SCI Status Register HB
	anda	#1			; check TDRE flag
	beq	SCI_TX			; branch/loop until TDRE is cleared
	stab	SCDR_LB, Z		; save B to SCI Data Register LB
	ldd	#$190			; set 0.25 ms delay
	jsr	Delay			; wait here for a while
	rts				; return from subroutine

SCI_RX:

	ldaa	SCSR_LB, Z		; A = SCI Status Register LB
	anda	#$42			; check RDRF and FE flag
	cmpa	#$40			; check RDFR flag
	bne	SCI_RX			; branch/loop until RDRF is set and FE is cleared
	ldab	SCDR_LB, Z		; load B with SCI Data Register content
	rts				; return from subroutine

GetEEPROMWord:

	ted				; D = E
	asla				; arithmetic shift left A
	asla				; arithmetic shift left A
	asla				; arithmetic shift left A
	oraa	#3			; A = A OR value
	std	TR+$10, Z		; store D to a Transmit RAM register
	ldd	#$908			; load D with value
	std	SPCR2, Z		; store D to SPI register
	jsr	SPITransfer		; jump to subroutine
	bcs	Exit			; branch to exit if carry is set
	ldd	RR+$12, Z		; load D with value from a Receive RAM register
	tsta				; test value in A for negative
	bra	Exit			; branch always to exit
	orp	#$100			; set Carry bit in CCR register
	tpa				; A = CCR register content
	ldab	#$5A			; B = value

Exit:

	rts				; return from subroutine

SPITransfer:

	bclr	SPSR, Z, #$80		; clear bit in SPSR register
	bset	SPCR1, Z, #$80		; set bit in SPCR1 register
	clra				; A = 0

Loop:

	deca				; A = A - 1
	beq	Result			; branch if A = 0
	brclr	SPSR, Z, #$80, Loop	; branch if bit is clear in SPSR register
	bclr	SPSR, Z, #$80		; clear bit in SPSR register
	tsta				; test value in A for negative
	bra	Return			; branch always to return

Result:

	orp	#$100			; set Carry bit in CCR register
	tpa				; A = CCR register content
	ldab	#$A5			; B = value

Return:

	rts				; return from subroutine

ReadBlock:

	ldab	0, X			; B = flash memory value at IX
	jsr	SCI_TX			; echo
	aix	#1			; increment IX
	sube	#1			; decrement E
	bne	ReadBlock		; repeat until E = 0
	rts				; return from subroutine

Delay:
	subd	#1			; decrement D
	bne	Delay			; branch/loop until D equals zero, 1 loop takes 0.000625 ms to complete
	rts				; return from subroutine