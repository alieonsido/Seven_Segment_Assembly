; Spec 1: click SW13 and the segment_LED ++ with non-interrupt.
; Sepc 2: click SW13 and the segment_LED ++ with external interrupt.

; the program is non-interrupt.


; ----------------defination

SWITCH EQU P3.3 ;INT1

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

DELAYTIME EQU 5
BLINKTIMES EQU 3H

; ----------------defination

; Notes:
	; MOV P2,A let all of P2 be zero.
	; R0 R1 R2 R3 is used to be set "value".
	; R4 is FLAG for timer.
	; R5 is used to save the carry.
	; R6 is used to be displayer.
	; R7 is for blink counter 
; Notice:You need to stay alert on GPIO's speed, or you will find that the segment will be confusion.
	; Timer 0 is used to debounce
	; Timer 1 is used to lag Segment.

; Setup.
ORG 0000H
MOV A,00H 
MOV P2,A ;P2 = ""All"" of Port 2 
MOV P1,A
AJMP Setup


; Interrupt 
ORG 0013H ; Interrupt 1 Address
LCALL Interrupt_event
RETI

Setup:
	;Number Initial
	CLR RS0
	CLR RS1
	MOV R0,#0
	MOV R1,#0
	MOV R2,#0
	MOV R3,#0
	MOV R4,#DELAYTIME ;for Timer0 5 * 500 micro second is 2500 micro second = 2.5ms. 
		;Warning:the Timer is not accurate, it will be effect by other instruction.
	MOV R5,#0
	MOV R6,#0
	MOV R7,#0
	MOV sp,#3FH

	
	;timer Initial.
	MOV tmod,#00010001b  ;setting timer0 and timer 1 in MODE 1, Total range is 16bit.(TH+TL)
	
	MOV TH0,0013H  
	MOV TL0,0088H
	;totally is 5000 micro second = 5ms
	SETB TR0

	MOV TH1,00H
	MOV TL1,01H


	
	SETB EA ; for Interrupt Initial.
	SETB EX1 ; for INT1 Enable
	SETB IT1 ; for INT1 negative edge trigger 

	LCALL Segment_Update
	JMP Segment_Loop

;uncomplete
Interrupt_event:
	
	;Save data to another memory.
	MOV 08H,R0
	MOV 09H,R1
	MOV 0AH,R2
	MOV 0BH,R3

	MOV 00H,#4
	MOV 01H,#0
	MOV 02H,#4
	MOV 03H,#0

	Interrupt_event_loop:
		CLR TR0

		MOV R4,#DELAYTIME;
		SETB TR0

		Segment_Light_Interrupt:
			LCALL Segment_Update
			LCALL Time_Checker
			CJNE R4,#0,Segment_Light_Interrupt

			MOV R4,#DELAYTIME ;For next Initial

		Segment_Extinguish_Interrupt:
			LCALL Delay_Time0 ;delay 5ms
			MOV A,R4
			DEC A
			MOV R4,A
			CJNE R4,#0,Segment_Extinguish_Interrupt ;5ms * 100 = 500ms

		MOV A,R7
		INC A
		MOV R7,A
		CJNE R7,#BLINKTIMES,Interrupt_event_loop ;blink three times.

	MOV R7,#00H ;clear.
	MOV R4,#DELAYTIME
	CLR TR0
	SETB TR0

	LCALL Delay_Time1
	;save data to get back.
	SETB RS0
	MOV 00H,R0
	MOV 01H,R1
 	MOV 02H,R2
	MOV 03H,R3
	CLR RS0


	RET

	
; for scan every segment loop, and it's main code.
; Segment_Chooser include displayer.
Segment_Loop:
	LCALL Segment_Update
	LCALL Time_Checker
	CJNE R4,#0000H,Segment_Loop ; check counter times. C8H = 12*16 + 8 = 200(dec)
	JMP Segment_Adder
	

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

Time_Checker:
	; count for R4 times.
	JB TF0,Time_Up
	JMP Time_Not_Up

	Time_Up:
		MOV A,R4
		;LCALL Delay_Time1
		DEC A
		MOV R4,A ;decrement R4.
		CLR TF0
		CLR TR0
		;LCALL Delay_Time1
		SETB TR0
		RET
	
	Time_Not_Up:
		RET


; for the number of every segment.
Segment_Adder:

	MOV A,R0
	;LCALL Delay_Time1
	INC A
	MOV R0,A
	CLR A

	;LCALL Delay_Time1

	CJNE R0,#0AH,Segment_Non_Carry ; because this is a add 1 circuit, we only need to care the LSB.
	JMP Segment_Carry_R0toR1

	Segment_Carry:
		Segment_Carry_R2toR3:
			MOV A,R3
			INC A
			MOV R3,A
			MOV R2,#00H
			CJNE R3,#0AH,Segment_Carry_Complete
			JMP Segment_Clear

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
			CLR TR0
			SETB TR0 ; reset for next loop. 
			MOV R4,#DELAYTIME ; reset for next loop.
			JMP Segment_Loop 

	Segment_Non_Carry:
		CLR TR0
		SETB TR0 ; reset for next loop. 
		MOV R4,#DELAYTIME ; reset for next loop.
		JMP Segment_Loop 
	;Warning: you can't JMP to Segment_Numberdisplayer directly, or you won't ba able to back Segment_Adder.
	Segment_Clear:
		MOV R3,#0
		MOV R2,#0
		MOV R1,#0
		MOV R0,#0
		JMP Segment_Loop




Segment_Update:

	; for choose the segment bit.
	Segment_Chooser:
		Segment_Chooser_0:
			CLR SEGMENT0_ENABLE ; the enable is low state trigger.
			SETB SEGMENT1_ENABLE
			SETB SEGMENT2_ENABLE
			SETB SEGMENT3_ENABLE
			MOV 06H,00H ; for displayer's check.
			LCALL Segment_Numberdisplayer
		Segment_Chooser_1:
			SETB SEGMENT0_ENABLE ; 0 2 3
			LCALL Segment_Privious_Clear ;you need to clean the previous SEGMENT or you will get the previous status.
			CLR SEGMENT1_ENABLE 
			MOV 06H,01H ; for displayer's check.
			LCALL Segment_Numberdisplayer
		Segment_Chooser_2:
			SETB SEGMENT1_ENABLE ; 0 1 3
			LCALL Segment_Privious_Clear
			CLR SEGMENT2_ENABLE
			MOV 06H,02H ; for displayer's check.
			LCALL Segment_Numberdisplayer
		Segment_Chooser_3:
			SETB SEGMENT2_ENABLE ; 0 1 2
			LCALL Segment_Privious_Clear
			CLR SEGMENT3_ENABLE 
			MOV 06H,03H ; for displayer's check.
			LCALL Segment_Numberdisplayer 
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