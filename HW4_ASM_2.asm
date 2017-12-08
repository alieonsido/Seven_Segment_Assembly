; Spec 1: click SW13 and the segment_LED ++ with non-interrupt.
; Sepc 2: click SW13 and the segment_LED ++ with external interrupt.

; the program is non-interrupt.

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
; MOV P2,A let all of P2 be zero.
; R0 R1 R2 R3 map to SEGMENT0_ENABLE SEGMENT1_ENABLE SE.......


; Setup.
ORG 0000H
MOV A,00H 
MOV P2,A
MOV P1,A
AJMP Start_State



; main code.
Start_State:
	JNB SWITCH,Segment_Loop
	JMP Start_State Start
	
; for scan every segment loop.
Segment_Loop:
	

; for the number of every segment.
Segment_Adder:
	
; for number display and replace the position of Array.
Segment_Numberdisplayer:

