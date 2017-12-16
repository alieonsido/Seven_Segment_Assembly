; Spec 1: click SW13 and the segment_LED ++ with non-interrupt.
; Sepc 2: click SW13 and the segment_LED ++ with external interrupt.

; the program is non-interrupt.

; non-interrupt:

; ----------------defination

SWITCH EQU P3.3

SEGMENT0_ENABLE EQU P1.3 
SEGMENT1_ENABLE EQU P1.2
SEGMENT2_ENABLE EQU P1.1
SEGMENT3_ENABLE EQU P1.0

SEGMENT_A EQU P2.0
SEGMENT_B EQU P2.1
SEGMENT_C EQU P2.2
SEGMENT_D EQU P2.3
SEGMENT_E EQU P2.4
SEGMENT_F EQU P2.5
SEGMENT_G EQU P2.6
SEGMENT_DOT EQU P2.7


; ----------------defination

; Notes:
	; MOV P2,A let all of P2 be zero.
	; R0 R1 R2 R3 is used to be set "value".
	; R4 is FLAG for adder triggered
	; R5 is used to save the carry.
	; R6 is used to be displayer.
	; R7 is test register.


; Setup.
ORG 0000H
MOV A,00H 
MOV P2,A ;P2 = ""All"" of Port 2 
MOV P1,A
AJMP Setup

Setup:
	;Number Initial
	MOV R0,#0
	MOV R1,#0
	MOV R2,#0
	MOV R3,#0
	MOV R4,#1 ;for first equal checker & update initial state.
	MOV R5,#0
	MOV R6,#0
	MOV R7,#0
	MOV sp,#3FH
	JMP Segment_Loop


	

	
; for scan every segment loop, and it's main code.
; Segment_Chooser include displayer.
Segment_Loop:
	Segment_Adder:
	;JB SWITCH, Segment_Adder ;debounce

	MOV TL0,10H ; for test debounce 
	MOV TL0,01H ; for test debounce

	MOV A,R0
		INC A
		MOV R0,A
		CLR A

		CJNE R0,#0AH,Segment_Non_Carry ; because this is a add 1 circuit, we only need to care the LSB.
		JMP Segment_Carry_R0toR1

		Segment_Carry:
			Segment_Carry_R2toR3:
				MOV A,R3
				INC A
				MOV R3,A
				MOV R2,#00H
				JMP Segment_Carry_Complete

			Segment_Carry_R1toR2:
				CJNE R1,#0AH,Segment_Carry_R0toR1
				MOV A,R2
				INC A
				MOV R2,A
		 		MOV R1,#00H
		 		CJNE R2,#0AH,Segment_Carry_Complete
				JMP Segment_Carry_R2toR3

			Segment_Carry_R0toR1:
				CJNE R0,#0AH,Segment_Carry_Complete
				MOV A,R1
				INC A
				MOV R1,A
				MOV R0,#00H
				CJNE R1,#0AH,Segment_Carry_Complete
				JMP Segment_Carry_R1toR2

			Segment_Carry_Complete:
				JMP Segment_Loop 

		Segment_Non_Carry:
			JMP Segment_Loop 
	;Warning: you can't JMP to Segment_Numberdisplayer directly, or you won't ba able to back Segment_Adder.
END