; 01_LdBoot_256k.asm
; 
; MCU: 68HC16
; 
; Bootloader for an SBEC3 PCM that has been placed 
; into bootstrap mode (12V applied to SCI-RX pin 
; while powering up) and security challange 
; has been solved.
; 
; After configuring the MCU it waits for code 
; to be uploaded, then executes it on request.
; 
; Commands:
; 
; Upload worker function:
; TX: 10 AA BB XX YY ZZ...
; RX: 11 AA BB XX YY ZZ... 14
; 
; 10:       upload worker function request
; AA BB:    function length
; XX YY ZZ: instructions
; 11:       request accepted
; 14:       upload finished
; 
; Execute worker function:
; TX: 20
; RX: 21 XX YY ZZ 22
; 
; 20:       execute worker function request
; 21:       request accepted
; XX YY ZZ: returned values by the function (if any)
; 22:       function finished
; 
; Notes:
; Wait for echo before transmitting the next byte.
; To save RAM space the worker function overwrites 
; parts of the bootloader code which are unused 
; anyways.
; Worker functions not always terminate with 22.

.include "68hc16def.inc"

	org	$100			; start offset in RAM

	lbra	Reset			; long branch always to configure MCU first

BootLoop:

	jsr	SCI_RX			; read SCI-byte to B
	cmpb	#$10			; $10 = upload worker function command
	beq	UploadFunction		; branch if equal
	cmpb	#$20			; $20 = execute worker function command
	beq	ExecuteFunction		; branch if equal
	bne	BootLoop		; read command byte again

UploadFunction:

	ldab	#$11			; $11 = upload request accepted
	jsr	SCI_TX			; write SCI-bus byte from B
	jsr	SCI_RX			; read function length HB from SCI-bus
	stab	FncLenHB		; save length HB to RAM
	ldab	FncLenHB		; load length HB from RAM
	jsr	SCI_TX			; write SCI-bus byte from B (echo)
	jsr	SCI_RX			; read function length LB from SCI-bus
	stab	FncLenLB		; save length LB to RAM
	ldab	FncLenLB		; load length LB from RAM
	jsr	SCI_TX			; write SCI-bus byte from B (echo)
	ldab	#0			; B = 0
	tbxk				; XK = B = 0
	ldx	#WorkerFunctionStart	; IX = start offset of the uploaded worker function

ReadNextByte:

	jsr	SCI_RX			; read next byte from SCI-bus to B
	stab	0, X			; save byte to RAM
	ldab	0, X			; load byte from RAM
	jsr	SCI_TX			; SCI-bus echo
	aix	#1			; increment IX value
	decw	FncLenHB		; decrement function length
	bne	ReadNextByte		; branch if length is not zero
	ldd	#$FA0			; set 2.5 ms delay
	jsr	Delay			; wait here for a while
	ldab	#4			; B = 4
	tbxk				; XK = B = 4
	ldx	#$8000			; IX = $8000
	ldab	#$14			; $14 = worker function upload finished
	jsr	SCI_TX			; write SCI-bus byte from B
	bra	BootLoop		; branch always to read another command byte

ExecuteFunction:

	ldab	#$21			; $21 = worker function execute request accepted
	jsr	SCI_TX			; write SCI-bus byte from B
	jsr	WorkerFunctionStart	; jump to the worker function
	bra	BootLoop		; branch to the command reader when done

SCI_Echo:

	jsr	SCI_RX			; read SCI-bus byte to B
	jsr	SCI_TX			; write byte from B to SCI-bus
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
	ldab	SCDR_LB, Z		; copy SCI Data Register content to B
	rts				; return from subroutine

Delay:

	subd	#1			; decrement D
	bne	Delay			; branch/loop until D equals zero, 1 loop takes 0.000625 ms to complete
	rts				; return from subroutine

FncLenHB: fcb $27			; Worker function length HB
FncLenLB: fcb $4C			; Worker function length LB

Reset:

	orp	#$E0			; set S, MV, H flags in CCR register
	ldab	#$F			; B = $0F
	tbzk				; ZK = B = $F
	ldz	#$8000			; Z = $8000
	ldab	#0			; B = 0
	tbsk				; SK = B = 0
	lds	#$7F6			; S = $7F6 = lowest RAM word offset for Stack Pointer
	clrb				; B = 0
	tbek				; EK = B = 0
	tbyk				; YK = B = 0
	ldab	#4			; B = 4
	tbxk				; XK = B = 4
	ldx	#$8000			; XK:IX = $48000
	ldd	#$148
	std	SIMCR, Z		; save D to Module Configuration Register
	bclr	SYPCR, Z, #$80		; clear SWE flag (software watchdog disabled) in System Protection Control Register
	ldd	#$CF
	std	CSPAR0, Z		; configure CSPAR0
					; CSBTPA = 11
					; CS0PA  = 11 (16-bit port)
					; CS1PA  = 00 (output)
					; CS2PA  = 11 (16-bit port)
	ldd	#$405
	std	CSBARBT, Z		; configure CSBARBT
					; BLKSZ = 101 = 256 kB
					; ADDR  = 0x40000
	std	CSBAR0, Z		; configure CSBAR0
					; BLKSZ = 101 = 256 kB
					; ADDR  = 0x40000
	ldd	#$68F0
	std	CSORBT, Z		; configure CSORBT
					; MODE  = 0b: asynchronous mode selected
					; BYTE  = 11b: both bytes are selected in the pin assignment register
					; RW    = 01b: chip select to be asserted only for read
					; STRB  = 0b: chip select to be asserted synchronized with address strobe
					; DSACK = 0011b: 3 wait states are inserted to op-timize bus speed
					; SPACE = 11b: select supervisor/user space field for chip select logic
					; IPL   = 000b: any level for interrupt priority level
					; AVEC  = 0b: external interrupt vector enabled
	ldd	#$70F0

WorkerFunctionStart:

	std	CSOR0, Z		; set register
	ldd	#$FF88
	std	CSBAR2, Z		; set register
	ldd	#$7830
	std	CSOR2, Z		; set register
	ldd	#$F881
	std	$814, Z
	ldd	$812, Z
	ord	#1
	std	$812, Z
	ldd	#0
	std	$818, Z
	bsetw	$806, Z, #$FFFF
	bsetw	$808, Z, #$3FF
	clrd
	lde	#$824

BusyLoop:

	std	E, Z
	adde	#4
	cpe	#$838
	bls	BusyLoop
	clr	TMSK1, Z		; clear Timer Interrupt Mask Register 1
	bclrw	$860, Z, #$2000		; clear bits in a word
	jsr	Settings		; jump to subroutine
	ldab	#$22			; $22 = bootloader is ready to accept instructions
	jsr	SCI_TX			; write SCI-bus byte from B (echo)
	jmp	BootLoop		; jump to the command byte reader loop

Settings:

	ldd	#$4088
	std	QSMCR, Z
	ldaa	#6
	staa	QILR, Z
	ldaa	#$FE
	staa	QIVR, Z
	ldaa	#$33
	staa	PQSPAR, Z
	ldaa	#$F8
	staa	PORTQS, Z
	ldaa	#$FE
	staa	DDRQS, Z
	ldd	#$8108
	std	SPCR0, Z
	ldd	#$1000
	std	SPCR1, Z
	ldd	#0
	std	SPCR2, Z
	ldaa	#0
	staa	SPCR3, Z
	lde	#$4242
	ste	CR+1, Z
	lde	#$202
	ste	CR+3, Z
	lde	#$C202
	ste	CR+5, Z
	lde	#$C242
	ste	CR+8, Z
	ldd	#$100
	std	TR+4, Z
	ldd	#$202
	std	SPCR2, Z
	jsr	QSPI_Handler
	rts

QSPI_Handler:

	bclr	SPSR, Z, #$80
	bset	SPCR1, Z, #$80
	clra

Wait:

	deca
	beq	Done
	brclr	SPSR, Z, #$80, Wait
	bclr	SPSR, Z, #$80
	tsta
	bra	Break

Done:

	orp	#$100
	tpa
	ldab	#$A5

Break:

	rts 