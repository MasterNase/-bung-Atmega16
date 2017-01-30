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
.def work2 = r17
.def count_low = r18
.def count_high = r19

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

;SSEG_OUT:
;	push work
;	in work, PINC
;	cpi work, $7B
;	breq SSEG_OUT_NEXT
;	ld work, X+
;	cbi PORTA, 2
;	out PORTC, work
;	pop work
;	rjmp SSEG_OUT
;SSEG_OUT_NEXT:
;	ldi XH, high(Table)
;	ldi XL, low(Table)
;	ld work, Z+
;	cpi work, $5F
;	breq SSEG_OUT_RESET
;	out PORTB, work
;	clr work
;	out PORTC, work
;	pop work
;	rjmp SSEG_OUT
;SSEG_OUT_RESET:
;	clr work
;	out PORTB, work
;	out PORTC, work
;	ldi ZH, high(Table)
;	ldi ZL, low(Table)
;	pop work
;	rjmp SSEG_OUT

SSEG_OUT:					;advances through the lookup table until the pointer is at the right
	ldi ZH, high(Table)		;number and outputs it to portb or c
	ldi ZL, low(Table)
	mov work, count_low
	cpi count_low, $00
	breq skip
Loop_low:					;goes through the list for the low number
	adiw ZL, 1
	dec work
	brne Loop_low
skip:						;skips the loop when count_low = 0
	ld work, Z
	out PORTC, work			;outputs the number found in the table to port c
	ldi work2, $16
	mov work, count_high
	ldi ZH, high(Table)
	ldi ZL, low(Table)
	cpi work, $00
	brne Loop_high
	ret
Loop_high:					;goes through the table for the high number
	adiw ZL, 1
	subi work, $16
	brne Loop_high
	ld work,Z
	out PORTB,work			;outputs the number found in the table to portb
	ret
	
COUNT_UP:
	push work				;increments count_low
	push work2
	cbi PORTA, 2
	cpi count_low, $09
	breq count_up_high
	inc count_low
	call SSEG_OUT
	pop work
	pop work2
	ret
count_up_high:
	ldi count_low, $00		;increments count_high and resets count_low
	cpi count_high, $50
	breq count_reset
	ldi work, $16
	add count_high, work
	call SSEG_OUT
	pop work
	pop work2
	ret
count_reset:				;resets the counter after 1 minute has passed	
	ldi count_high, $00		
	out PORTB, count_high	;sets portb back to 0
	sbi PORTA, 2			;sets PINA2 to 1
	call SSEG_OUT
	pop work
	pop work2
	ret
	
; Replace with your application code
Main:
	INITSP					;Initializes StackPointer
    call INIT_PORTS			;initializes ports
	call Initialize_SSeg	;initiializes the lookup-table
Reset:	
	ldi ZH, high(Table)		;sets the output to the initial 00
	ldi ZL, low(Table)		
	ld work, Z
	out PORTB, work
	ld work, Z
	out PORTC, work
	ldi work, $F0
Loop:	
	sbrc work, 0
	sbi PORTA, 3
	sbrs work, 0
	cbi PORTA, 3
	swap work
	sbic PINA, 0			;loops until input or while pina1 is set
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