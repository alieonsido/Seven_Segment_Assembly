; Spec 1: click SW13 and the segment_LED ++ with non-interrupt.
; Sepc 2: click SW13 and the segment_LED ++ with external interrupt.

; the program is non-interrupt.

; non-interrupt:

; ----------------defination

SWITCH EQU P2.0

SEGMENT0_ENABLE EQU P1.0 
SEGMENT1_ENABLE EQU P1.1
SEGMENT2_ENABLE EQU P1.2
SEGMENT3_ENABLE EQU P1.3

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
	; R4 is Segment number state ,but I think it's can be replaced by A (add register)
		; If R4 is at the position of #10~#19, that means it need to be set on the SEGMENT1_ENABLE.
	; R5 is used to save the carry.
	; R6 is used to be If_Else register.


; Setup.
ORG 0000H
MOV A,00H 
MOV P2,A ;P2 = ""All"" of Port 2 
MOV P1,A
AJMP Setup

Setup:
	;Number Initial
	MOV R0,0
	MOV R1,0
	MOV R2,0
	MOV R3,0
	MOV R4,0
	MOV R5,0
	MOV R6,0
	MOV R7,0
	LCALL Segment_Update
	JMP Segment_Loop

; equal check from zero to nine.
; Warning:If_CJE only can be called by """LCALL"""
; Warning2: when the macro over, A won't clear the value.
Segment_Equalchecker:

	CJNE A,R6,Non_Equal

	; Here is """"""""BIG"""""""" bug.
	MOV A,#1 ;TRUE
	Checkcomplete:
		JNZ Segment_Numberdisplayer_0
		JNZ Segment_Numberdisplayer_1
		JNZ Segment_Numberdisplayer_0
		JNZ Segment_Numberdisplayer_2
		JNZ Segment_Numberdisplayer_3
		JNZ Segment_Numberdisplayer_4
		JNZ Segment_Numberdisplayer_5
		JNZ Segment_Numberdisplayer_6
		JNZ Segment_Numberdisplayer_7
		JNZ Segment_Numberdisplayer_8
		JNZ Segment_Numberdisplayer_9


	Non_Equal:
		MOV A,#0 ; FALSE
		JMP Checkcomplete
	

	
; for scan every segment loop, and it's main code.
; Segment_Chooser include displayer.
Segment_Loop:
	JNB SWITCH,Segment_Adder
	LCALL Segment_Update
	JMP Segment_Loop
	



; for the number of every segment.
Segment_Adder:
	JB SWITCH, Segment_Adder ;debounce

	MOV A,R0
	INC A
	MOV R0,A

	CJNE R0,#0AH,Segment_Non_Carry ; because this is a add 1 circuit, we only need to care the LSB.
	

	;uncomplete
	Segment_Carry:
		CJNE R2,#0AH,Segment_Carry_R1toR2
		Segment_Carry_R2toR3:
			MOV A,R3
			INC A
			MOV R3,A
			CLR R2

		Segment_Carry_R1toR2:
			CJNE R1,#0AH,Segment_Carry_R0toR1
			MOV A,R2
			INC A
			MOV R2,A
			CLR R1

		Segment_Carry_R0toR1:
			CJNE R0,#0AH,Segment_Carry_Complete
			MOV A,R1
			INC A
			MOV R1,A
			CLR R0

		Segment_Carry_Complete:
			JMP Segment_Loop 

	Segment_Non_Carry:
	MOV R4,A
	CLR A
	JMP Segment_Loop 
	;Warning: you can't JMP to Segment_Numberdisplayer directly, or you won't ba able to back Segment_Adder.


Segment_Update:

	; for choose the segment bit.
	Segment_Chooser:
		Segment_Chooser_0:
			SETB SEGMENT0_ENABLE
			MOV R0,#1 ; the flag open, and it means the SEGMENT is enabled.
			LCALL Segment_Numberdisplayer
		Segment_Chooser_1:
			CLR SEGMENT0_ENABLE ;you need to clean the previous SEGMENT or you will get the previous status.
			LCALL Segment_Privious_Clear
			SETB SEGMENT1_ENABLE
			MOV R1,#1 ; the flag open, and it means the SEGMENT is enabled.
			LCALL Segment_Numberdisplayer
		Segment_Chooser_2:
			CLR SEGMENT1_ENABLE ;you need to clean the previous SEGMENT or you will get the previous status.
			LCALL Segment_Privious_Clear
			SETB SEGMENT2_ENABLE
			MOV R2,#1 ; the flag open, and it means the SEGMENT is enabled.
			LCALL Segment_Numberdisplayer
		Segment_Chooser_3:
			CLR SEGMENT2_ENABLE ;you need to clean the previous SEGMENT or you will get the previous status.
			LCALL Segment_Privious_Clear
			SETB SEGMENT3_ENABLE
			MOV R3,#1 ; the flag open, and it means the SEGMENT is enabled.
			LCALL Segment_Numberdisplayer 
			
			CLR SEGMENT3_ENABLE ; It must be clear itself.
			LCALL Segment_Privious_Clear
		RET ;pop the stack, and you can back the main code.

	Segment_Privious_Clear:
		CLR SEGMENT_A
		CLR SEGMENT_B
		CLR SEGMENT_C
		CLR SEGMENT_D
		CLR SEGMENT_E
		CLR SEGMENT_F
		CLR SEGMENT_G
		RET
		
	; for number display and replace the position of Array.
	Segment_Numberdisplayer:


		;here is bug
		JMP Segment_Equalchecker



		Segment_Numberdisplayer_0:
		;segment 0
			SETB SEGMENT_A
			SETB SEGMENT_B
			SETB SEGMENT_C
			SETB SEGMENT_D
			SETB SEGMENT_E
			SETB SEGMENT_F
			RET  ;when display complete, you need to back to choose next one which need to display. 
		
		Segment_Numberdisplayer_1:
		;segment 1
			SETB SEGMENT_B
			SETB SEGMENT_C
			RET 

		Segment_Numberdisplayer_2:
		;segment 2
			SETB SEGMENT_A
			SETB SEGMENT_B
			SETB SEGMENT_D
			SETB SEGMENT_E
			SETB SEGMENT_G
			RET 

		Segment_Numberdisplayer_3:
		;segment 3
			SETB SEGMENT_A
			SETB SEGMENT_B
			SETB SEGMENT_C
			SETB SEGMENT_D
			SETB SEGMENT_G
			RET 

		Segment_Numberdisplayer_4:
		;segment 4
			SETB SEGMENT_B
			SETB SEGMENT_C
			SETB SEGMENT_F
			SETB SEGMENT_G
			RET 

		Segment_Numberdisplayer_5:
		;segment 5
			SETB SEGMENT_A
			SETB SEGMENT_C
			SETB SEGMENT_D
			SETB SEGMENT_F
			SETB SEGMENT_G
			RET 

		Segment_Numberdisplayer_6:
		;segment 6
			SETB SEGMENT_C
			SETB SEGMENT_D
			SETB SEGMENT_E
			SETB SEGMENT_F
			SETB SEGMENT_G
			RET 

		Segment_Numberdisplayer_7:
		;segment 7
			SETB SEGMENT_A
			SETB SEGMENT_B
			SETB SEGMENT_C
			RET 

		Segment_Numberdisplayer_8:
		;segment 8
			SETB SEGMENT_A
			SETB SEGMENT_B
			SETB SEGMENT_C
			SETB SEGMENT_D
			SETB SEGMENT_E
			SETB SEGMENT_F
			SETB SEGMENT_G
			RET 

		Segment_Numberdisplayer_9:
		;segment 9
			SETB SEGMENT_A
			SETB SEGMENT_B
			SETB SEGMENT_C
			SETB SEGMENT_D
			SETB SEGMENT_E
			SETB SEGMENT_F
			SETB SEGMENT_G
			RET 

	