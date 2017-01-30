;
; Übung11.asm
;
; Created: 1/28/2017 3:41:15 PM
; Author : wurz1
;
.equ SSEG_TABLE_SIZE = 10

.dseg
.org $100
Table:
	.byte SSEG_TABLE_SIZE

.cseg
.org 0
	rjmp Main

SSEG_CODE:
	.db 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B

.macro INITSP
	ldi r16, high(ramend)
	out SPH, r16
	ldi r16, low(ramend)
	out SPL,r16
.endm

.def work = r16

INIT_PORTS:
	PUSH work		;save work to stack
	SER work		;work = 0xFF
	OUT DDRB, work	
	OUT DDRC, work	
	CLR work
	OUT PORTB, work
	OUT PORTC, work
	SBI PORTA, 0	;PA0 as Input with internal pullup
	CBI DDRA, 0
	SBI PORTA, 1	;PA1 as Input with internal pullup
	CBI DDRA, 1
	SBI DDRA, 2		;PA2 as Output	
	SBI DDRA, 3		;PA3 as Output
	CBI PORTD, 2	;PD2 as Input
	CBI DDRD, 2
	POP work
	RET	

SSEG_OUT:
	push work
	in work, PINC
	cpi work, $7B
	breq SSEG_OUT_NEXT
	ld work, X+
	cbi PORTA, 2
	out PORTC, work
	pop work
	rjmp SSEG_OUT
SSEG_OUT_NEXT:
	ldi XH, high(Table)
	ldi XL, low(Table)
	ld work, Z+
	cpi work, $5F
	breq SSEG_OUT_RESET
	out PORTB, work
	clr work
	out PORTC, work
	pop work
	rjmp SSEG_OUT
SSEG_OUT_RESET:
	clr work
	out PORTB, work
	out PORTC, work
	ldi ZH, high(Table)
	ldi ZL, low(Table)
	sbis PORTA, 0
	sbi PORTA, 2
	pop work
	rjmp SSEG_OUT

COUNT_UP:
	
	
; Replace with your application code
Main:
	INITSP
    call INIT_PORTS
	call Initialize_SSeg
Reset:	
	ldi XH, high(Table)
	ldi XL, low(Table)
	ldi ZH, high(Table)
	ldi ZL, low(Table)
	ld work, Z+
	out PORTB, work
	ld work, X+
	out PORTC, work
Loop:	
	sbic PINA, 0
	rjmp Reset
	sbic PINA, 1
	rjmp LOOP
	sbic PIND, 2
	call COUNT_UP
    rjmp LOOP

Initialize_SSeg:
	push work
	push r17
	ldi ZH, high(SSEG_CODE << 1)
	ldi ZL, low(SSEG_CODE << 1)
	ldi XH, high(Table)
	ldi XL, low(Table)
	ldi work, SSEG_TABLE_SIZE
Initialize_SSeg_Loop:
	lpm r17, Z+
	st X+, r17
	dec work
	brne Initialize_SSeg_Loop
	pop r17
	pop work
	ret