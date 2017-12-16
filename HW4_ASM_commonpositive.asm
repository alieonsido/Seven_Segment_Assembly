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
	; R4 is FLAG for timer.
	; R5 is used to save the carry.
	; R6 is used to be displayer.
	; R7 is test register.
; Notice:You need to stay alert on GPIO's speed, or you will find that the segment will be confusion.
	; Timer 0 is used to debounce
	; Timer 1 is used to lag Segment.

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
	MOV R4,#1 ;for Timer edge.
	MOV R5,#0
	MOV R6,#0
	MOV R7,#0
	MOV sp,#3FH
	MOV tmod,#00010001b  ;setting timer0 and timer 1 in MODE 1, Total range is 16bit.(TH+TL)
	MOV TH0,00A0H  
	MOV TL0,00H 
	
	MOV TH1,00H
	MOV TL1,01H


	LCALL Segment_Update
	JMP Segment_Loop


	
; for scan every segment loop, and it's main code.
; Segment_Chooser include displayer.
Segment_Loop:
	JNB SWITCH,Segment_Adder
	LCALL Segment_Update
	;JMP Segment_Adder
	JMP Segment_Loop
	



; for the number of every segment.
Segment_Adder:
	;LCALL Delay_Time0
	MOV R4,#0

	debounce:
		CJNE R4,#0,debounce_complete
		MOV R4,00B3H ;B3H is SWITCH address.
		JMP debounce
		LCALL Delay_Time0
		

	debounce_complete:
	LCALL Segment_Privious_Clear
	LCALL Delay_Time1
	MOV A,R0
	INC A
	MOV R0,A
	CLR A
	LCALL Delay_Time1

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


Delay_Time0:
	;The test environment is 12MHZ,so that 1/12 * 12MHZ (this is for machine cycle) = 1MHZ
	;and, 1/(1M) second =  1 micro second, every 1 micro second will add the Timer once.

	; I want 30 micro second , so we must initial set range.
	SETB TR0 ; set Timer 0 to use.
	Delay_Time0_Working:
		JNB TF0,Delay_Time0_Working ; if the time is up, the Timer Flag(TF) will from zero to one.
		CLR TF0;
		CLR TR0;
		RET

Delay_Time1:
	SETB TR1 ; set Timer 1 to use.
	Delay_Time1_Working:
		JNB TF1,Delay_Time1_Working ; if the time is up, the Timer Flag(TF) will from zero to one.
		CLR TF1;
		CLR TR1;
		RET


Segment_Update:

	; for choose the segment bit.
	Segment_Chooser:
		Segment_Chooser_0:
			CLR SEGMENT0_ENABLE ; the enable is low state trigger.
			SETB SEGMENT1_ENABLE
			SETB SEGMENT2_ENABLE
			SETB SEGMENT3_ENABLE
			MOV 06H,R0 ; for displayer's check.
			LCALL Segment_Numberdisplayer
			;LCALL Delay_Time1
		Segment_Chooser_1:
			SETB SEGMENT0_ENABLE ; 0 2 3
			;LCALL Delay_Time0
			LCALL Segment_Privious_Clear ;you need to clean the previous SEGMENT or you will get the previous status.
			CLR SEGMENT1_ENABLE 
			MOV 06H,R1 ; for displayer's check.
			LCALL Segment_Numberdisplayer
			;LCALL Delay_Time1
		Segment_Chooser_2:
			SETB SEGMENT1_ENABLE ; 0 1 3
			LCALL Segment_Privious_Clear
			CLR SEGMENT2_ENABLE
			MOV 06H,R2 ; for displayer's check.
			;LCALL Delay_Time1
			LCALL Segment_Numberdisplayer
			;LCALL Delay_Time1
		Segment_Chooser_3:
			SETB SEGMENT2_ENABLE ; 0 1 2
			;LCALL Delay_Time0
			LCALL Segment_Privious_Clear
			CLR SEGMENT3_ENABLE 
			MOV 06H,R3 ; for displayer's check.
			LCALL Segment_Numberdisplayer 
			;LCALL Delay_Time1
			SETB SEGMENT3_ENABLE ; It must be clear itself. 0 1 2 3
			LCALL Segment_Privious_Clear
		RET ;pop the stack, and you can back the main code.

	Segment_Privious_Clear:
		SETB SEGMENT_A
		SETB SEGMENT_B
		SETB SEGMENT_C
		SETB SEGMENT_D
		SETB SEGMENT_E
		SETB SEGMENT_F
		SETB SEGMENT_G
		RET
		
	; for number display and replace the position of Array.
	Segment_Numberdisplayer:

		Segment_Numberdisplayer_0:
		;segment 0
			CJNE R6,#0,Segment_Numberdisplayer_1
			CLR SEGMENT_A
			CLR SEGMENT_B
			CLR SEGMENT_C
			CLR SEGMENT_D
			CLR SEGMENT_E
			CLR SEGMENT_F
			SETB SEGMENT_G
			SETB SEGMENT_DOT
			MOV R6,#0
			RET  ;when display complete, you need to back to choose next one which need to display. 
		
		Segment_Numberdisplayer_1:
		;segment 1
			CJNE R6,#1,Segment_Numberdisplayer_2
			CLR SEGMENT_B
			CLR SEGMENT_C

			SETB SEGMENT_A
			SETB SEGMENT_D
			SETB SEGMENT_E
			SETB SEGMENT_F
			SETB SEGMENT_G
			SETB SEGMENT_DOT
			MOV R6,#0
			RET 

		Segment_Numberdisplayer_2:
		;segment 2
			CJNE R6,#2,Segment_Numberdisplayer_3
			CLR SEGMENT_A
			CLR SEGMENT_B
			SETB SEGMENT_C
			CLR SEGMENT_D
			CLR SEGMENT_E
			SETB SEGMENT_F
			CLR SEGMENT_G
			SETB SEGMENT_DOT
			MOV R6,#0
			RET 

		Segment_Numberdisplayer_3:
		;segment 3
			CJNE R6,#3,Segment_Numberdisplayer_4
			CLR SEGMENT_A
			CLR SEGMENT_B
			CLR SEGMENT_C
			CLR SEGMENT_D
			SETB SEGMENT_E
			SETB SEGMENT_F
			CLR SEGMENT_G
			SETB SEGMENT_DOT

			MOV R6,#0
			RET 

		Segment_Numberdisplayer_4:
		;segment 4
			CJNE R6,#4,Segment_Numberdisplayer_5
			SETB SEGMENT_A
			CLR SEGMENT_B
			CLR SEGMENT_C
			SETB SEGMENT_D
			SETB SEGMENT_E
			CLR SEGMENT_F
			CLR SEGMENT_G
			SETB SEGMENT_DOT
			MOV R6,#0
			RET 

		Segment_Numberdisplayer_5:
		;segment 5
			CJNE R6,#5,Segment_Numberdisplayer_6
			CLR SEGMENT_A
			SETB SEGMENT_B
			CLR SEGMENT_C
			CLR SEGMENT_D
			SETB SEGMENT_E
			CLR SEGMENT_F
			CLR SEGMENT_G
			SETB SEGMENT_DOT
			MOV R6,#0
			RET 

		Segment_Numberdisplayer_6:
		;segment 6
			CJNE R6,#6,Segment_Numberdisplayer_7
			CLR SEGMENT_A
			SETB SEGMENT_B
			CLR SEGMENT_C
			CLR SEGMENT_D
			CLR SEGMENT_E
			CLR SEGMENT_F
			CLR SEGMENT_G
			SETB SEGMENT_DOT

			MOV R6,#0
			RET 

		Segment_Numberdisplayer_7:
		;segment 7
			CJNE R6,#7,Segment_Numberdisplayer_8
			CLR SEGMENT_A
			CLR SEGMENT_B
			CLR SEGMENT_C
			SETB SEGMENT_D
			SETB SEGMENT_E
			SETB SEGMENT_F
			SETB SEGMENT_G
			SETB SEGMENT_DOT
			MOV R6,#0
			RET 

		Segment_Numberdisplayer_8:
		;segment 8
			CJNE R6,#8,Segment_Numberdisplayer_9
			CLR SEGMENT_A
			CLR SEGMENT_B
			CLR SEGMENT_C
			CLR SEGMENT_D
			CLR SEGMENT_E
			CLR SEGMENT_F
			CLR SEGMENT_G
			SETB SEGMENT_DOT
			MOV R6,#0
			RET 

		Segment_Numberdisplayer_9:
		;segment 9
			CLR SEGMENT_A
			CLR SEGMENT_B
			CLR SEGMENT_C
			CLR SEGMENT_D
			SETB SEGMENT_E
			CLR SEGMENT_F
			CLR SEGMENT_G
			SETB SEGMENT_DOT
			MOV R6,#0
			RET 

END