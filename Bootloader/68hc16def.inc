; MC68HC16Z REGISTER OFFSETS

; ANALOG TO DIGITAL CONVERTER PERIPHERAL REGISTERS

ADMCR:      equ  $7700 ; A/D Module Config Reg
ADCTEST:    equ  $7702 ; A/D Test Register
PADR:       equ  $7706 ; Port Data Reg
ADCTL0:     equ  $770A ; A/D Control Reg 0
ADCTL1:     equ  $770C ; A/D Control Reg 1
ADSTAT:     equ  $770E ; A/D Status Reg
URRES0:     equ  $7710 ; Unsigned Right Result 0
URRES1:     equ  $7712 ; Unsigned Right Result 1
URRES2:     equ  $7714 ; Unsigned Right Result 2
URRES3:     equ  $7716 ; Unsigned Right Result 3
URRES4:     equ  $7718 ; Unsigned Right Result 4
URRES5:     equ  $771A ; Unsigned Right Result 5
URRES6:     equ  $771C ; Unsigned Right Result 6
URRES7:     equ  $771E ; Unsigned Right Result 7
SLRES0:     equ  $7720 ; Signed Left Result 0
SLRES1:     equ  $7722 ; Signed Left Result 1
SLRES2:     equ  $7724 ; Signed Left Result 2
SLRES3:     equ  $7726 ; Signed Left Result 3
SLRES4:     equ  $7728 ; Signed Left Result 4
SLRES5:     equ  $772A ; Signed Left Result 5
SLRES6:     equ  $772C ; Signed Left Result 6
SLRES7:     equ  $772E ; Signed Left Result 7
ULRES0:     equ  $7730 ; Unsigned Left Result 0
ULRES1:     equ  $7732 ; Unsigned Left Result 1
ULRES2:     equ  $7734 ; Unsigned Left Result 2
ULRES3:     equ  $7736 ; Unsigned Left Result 3
ULRES4:     equ  $7738 ; Unsigned Left Result 4
ULRES5:     equ  $773A ; Unsigned Left Result 5
ULRES6:     equ  $773C ; Unsigned Left Result 6
ULRES7:     equ  $773E ; Unsigned Left Result 7

; MASKED ROM MODULE PERIPHERAL REGISTERS

MRMCR:      equ  $7820 ; Masked ROM Module Control Reg
MRMROMBAH:  equ  $7824 ; MRM Array Base Address Reg HB
MRMROMBAL:  equ  $7826 ; MRM Array Base Address Reg LB
RSIGHI:     equ  $7828 ; ROM Signature High Reg
RSIGLO:     equ  $782A ; ROM Signature Low Reg
ROMBS0:     equ  $7830 ; ROM Bootstrap Word 0
ROMBS1:     equ  $7832 ; ROM Bootstrap Word 1
ROMBS2:     equ  $7834 ; ROM Bootstrap Word 2
ROMBS3:     equ  $7836 ; ROM Bootstrap Word 3

; GENERAL PURPOSE TIMER MODULE PERIPHERAL REGISTERS

GPTMCR:     equ  $7900 ; Module Configuration Reg
ICR:        equ  $7904 ; Interrupt Configuration Reg
PDDR:       equ  $7906 ; Parallel Data Direction
PDR:        equ  $7907 ; Parallel Data Reg
OC1M:       equ  $7908 ; Action Mask Reg
OC1D:       equ  $7909 ; Action Data Reg
TCNT:       equ  $790A ; Timer Counter Reg
PACTL:      equ  $790C ; Pulse Accu Control Reg
PACNT:      equ  $790D ; Pulse Accu Counter Reg
TIC1:       equ  $790E ; Input Capture Reg 1
TIC2:       equ  $7910 ; Input Capture Reg 2
TIC3:       equ  $7912 ; Input Capture Reg 3
TOC1:       equ  $7914 ; Output Compare Reg 1
TOC2:       equ  $7916 ; Output Compare Reg 2
TOC3:       equ  $7918 ; Output Compare Reg 3
TOC4:       equ  $791A ; Output Compare Reg 4
TI4O5:      equ  $791C ; Input 4 or Output Reg 5
TCTL1:      equ  $791E ; Timer Control Reg 1
TCTL2:      equ  $791F ; Timer Control Reg 2
TMSK1:      equ  $7920 ; Timer Interrupt Mask Reg 1
TMSK2:      equ  $7921 ; Timer Interrupt Mask Reg 2
TFLG1:      equ  $7922 ; Timer Interrupt Flag Reg 1
TFLG2:      equ  $7923 ; Timer Interrupt Flag Reg 2
CFRPWM:     equ  $7924 ; Compare Force and PWM Ctrl
PWMC:       equ  $7925 ; PWM Reg C
PWMA:       equ  $7926 ; PWM Reg A
PWMB:       equ  $7927 ; PWM Reg B
PWMCNT:     equ  $7928 ; PWM Count Reg
PWBUFA:     equ  $792A ; PWM Buffer Reg A
PWBUFB:     equ  $792B ; PWM Buffer Reg B
PRESCL:     equ  $792C ; GPT Prescaler

; SYSTEM INTEGRATION MODULE PERIPHERAL REGISTERS

SIMCR:      equ  $7A00 ; Module Configuration Reg
SIMTR:      equ  $7A02 ; System Integration Test Reg
SYNCR:      equ  $7A04 ; Clock Synthesizer Ctrl Reg
RSR         equ  $7A07 ; Reset Status Reg
SIMTRE:     equ  $7A08 ; System Integration Test E Reg
PORTE:      equ  $7A11 ; Port E Data Reg
DDRE:       equ  $7A15 ; Port E Data Direction Reg
PEPAR:      equ  $7A17 ; Port E Pin Assignment Reg
PORTF:      equ  $7A19 ; Port F Data Reg
DDRF:       equ  $7A1D ; Port F Data Direction Reg
PFPAR:      equ  $7A1F ; Port F Pin Assignment Reg
SYPCR:      equ  $7A21 ; System Protection Ctrl Reg
PICR:       equ  $7A22 ; Periodic Interrupt Ctrl Reg
PITR:       equ  $7A24 ; Periodic Interrupt Timer
SWSR:       equ  $7A27 ; Software Service Reg
TSTMSRA:    equ  $7A30 ; Master Shift Reg A
TSTMSRB:    equ  $7A32 ; Master Shift Reg B
TSTSC:      equ  $7A34 ; Test Module Shift Count Reg
TSTRC:      equ  $7A36 ; Test Module Repetition Count Reg
CREG:       equ  $7A38 ; Test Module Control Reg
DREG:       equ  $7A3A ; Test Module Distributed Reg
CSPDR:      equ  $7A41 ; Chip Select Pin Data Reg
CSPAR0:     equ  $7A44 ; Chip Select Pin Asgn Reg 0
CSPAR1:     equ  $7A46 ; Chip Select Pin Asgn Reg 1
CSBARBT:    equ  $7A48 ; Chip Select Base Reg Boot
CSORBT:     equ  $7A4A ; Chip Select Option Reg Boot
CSBAR0:     equ  $7A4C ; Chip Select Base Reg 0
CSOR0:      equ  $7A4E ; Chip Select Option Reg 0
CSBAR1:     equ  $7A50 ; Chip Select Base Reg 1
CSOR1:      equ  $7A52 ; Chip Select Option Reg 1
CSBAR2:     equ  $7A54 ; Chip Select Base Reg 2
CSOR2:      equ  $7A56 ; Chip Select Option Reg 2
CSBAR3:     equ  $7A58 ; Chip Select Base Reg 3
CSOR3:      equ  $7A5A ; Chip Select Option Reg 3
CSBAR4:     equ  $7A5C ; Chip Select Base Reg 4
CSOR4:      equ  $7A5E ; Chip Select Option Reg 4
CSBAR5:     equ  $7A60 ; Chip Select Base Reg 5
CSOR5:      equ  $7A62 ; Chip Select Option Reg 5
CSBAR6:     equ  $7A64 ; Chip Select Base Reg 6
CSOR6:      equ  $7A66 ; Chip Select Option Reg 6
CSBAR7:     equ  $7A68 ; Chip Select Base Reg 7
CSOR7:      equ  $7A6A ; Chip Select Option Reg 7
CSBAR8:     equ  $7A6C ; Chip Select Base Reg 8
CSOR8:      equ  $7A6E ; Chip Select Option Reg 8
CSBAR9:     equ  $7A70 ; Chip Select Base Reg 9
CSOR9:      equ  $7A72 ; Chip Select Option Reg 9
CSBAR10:    equ  $7A74 ; Chip Select Base Reg 10
CSOR10:     equ  $7A76 ; Chip Select Option Reg 10

; STANDBY RAM MODULE PERIPHERAL REGISTERS

RAMMCR:     equ  $7B00 ; Module Configuration Reg
RAMTST:     equ  $7B02 ; Ram Test Reg
RAMBAH:     equ  $7B04 ; Array Base Address Reg High
RAMBAL:     equ  $7B06 ; Array Base Address Reg Low

; QUEUED SERIAL MODULE PERIPHERAL REGISTERS

QSMCR:      equ  $7C00 ; Module Configuration Reg
QTEST:      equ  $7C02 ; QSM Test Register
QILR:       equ  $7C04 ; Interrupt Level Reg
QIVR:       equ  $7C05 ; Interrupt Vector Reg
SCCR0:      equ  $7C08 ; SCI Control Reg 0
SCCR1:      equ  $7C0A ; SCI Control Reg 1
SCSR:       equ  $7C0C ; SCI Status Reg
SCSR_LB:    equ  $7C0D ; SCI Status Reg LB
SCDR:       equ  $7C0E ; SCI Data Reg
SCDR_LB:    equ  $7C0F ; SCI Data Reg LB
PORTQS:     equ  $7C15 ; Port Data Reg
PQSPAR:     equ  $7C16 ; Pin Assignment Reg
DDRQS:      equ  $7C17 ; Data Direction Reg
SPCR0:      equ  $7C18 ; SPI Control Reg 0
SPCR1:      equ  $7C1A ; SPI Control Reg 1
SPCR2:      equ  $7C1C ; SPI Control Reg 2
SPCR3:      equ  $7C1E ; SPI Control Reg 3
SPSR:       equ  $7C1F ; SPI Status Reg
RR:         equ  $7D00 ; Receive Data RAM
TR:         equ  $7D20 ; Transmit Data RAM
CR:         equ  $7D40 ; Command RAM

; INSERT DEFINITIONS HERE

