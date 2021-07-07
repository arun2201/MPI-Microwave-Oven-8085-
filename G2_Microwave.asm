#make_bin#

#LOAD_SEGMENT=0FFFFh#
#LOAD_OFFSET=0000h#
    

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#
#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#


; Consts INIT       

A8255A EQU 00H
A8255B EQU 02H
A8255C EQU 04H
A8255CR EQU 06H
                           
A8253C0 EQU 08H  
A8253C1 EQU 0AH
A8253CR EQU 0EH

A8259A EQU 10H
A8259B EQU 12H  

; MEMORY HAS BEEN RESERVED AT THE END OF THE FILE


JMP STRTCODE
nop
 
; IVT init
db 316 dup(0)
dw startbut 
dw 0000h
dw stopbut  
dw 0000h
dw t10mbut  
dw 0000h
dw t1mbt  
dw 0000h
dw t10sbt  
dw 0000h
dw timesgn  
dw 0000h
dw pwrbt  
dw 0000h
db 676 dup(0)


STRTCODE: CLI

; intialize ds,es,ss to start of RAM
MOV AX, 00000H
MOV DS, AX  
MOV ES, AX
MOV SS, AX
MOV SP, 0FFFEH 

; 8253 INIT

MOV AL, 00110100b
OUT A8253CR, AL
MOV AL, 01110100b
OUT A8253CR, AL

MOV AL, 0C4H
OUT A8253C0, AL
MOV AL, 09H
OUT A8253C0, AL 

MOV AL, 0E8H
OUT A8253C1, AL
MOV AL, 03H
OUT A8253C1, AL 


; 8255 INIT

MOV AL, 10000000b
OUT A8255CR, AL

; 8259 INIT  


; ICW 1,2,4

MOV AL, 00010011b
OUT A8259A, AL
MOV AL, 50H
OUT A8259B, AL
MOV AL, 00000001b
OUT A8259B, AL

; OCW 1
MOV AL, 10000000b
OUT A8259B, AL



; INIT TIME/FLAGS/PLVL

MOV AL, 0
MOV FLAGS, AL
MOV T10M, AL
MOV T1M, AL
MOV T10S,AL
MOV T1S, AL
MOV PLVL, 12  ;stores the power level/10 (100% -> 10)
                   

MAIN:
    
    STI
    
    ; CHK FOR DISPLAYING PWR LEVEL
    MOV AH, FLAGS
    AND AH, 10001000b
    JNZ ACTIVE            ;jump here if microwave is active OR timer is on
    ; MOV AH, 0
    MOV AL, PLVL
    CMP AL, 10  ;AL contains the power level/10 (100% -> 10)
    JL NOTFULL  ;jump if AL<10 meaning power level is less than 100%
    MOV AH,1    ;AH contains 1 if 100%, 0 otherwise
    MOV AL,0    ;AL contains 0 meaning AH..AL mean 100% 
    ;power level =xyz where xyz=080% where x is 
NOTFULL:    ;jump if AL<10 meaning power level is less than 100%
            ;outputs to all 4 7seg display
    OUT A8255B,AL   ; OUTPUT FOR PORT B PWR LEVEL
            ; OUTPUT FOR PORT A PWR LEVEL
    MOV AL, AH      ;AL=AH
    MOV CL, 4       
    SHL AL, CL      ;formatting for 7 seg display cus of some bt
    OUT A8255A, AL  ;output for higher two 7 segment displays
    JMP UNLOCK          
    
    
    ; OUTPUT FOR PORT A, TIME LEFT IN MINS 
ACTIVE:                   ;jump here if microwave is active OR timer is on
    MOV AH, T1M   ;AH= 1 min time
    MOV AL, T10M  ;AL= 10 min time
    MOV CL, 4
    SHL AH, CL      ;formatting for 7 seg
    OR AL, AH       ;combining two nibbles for 7 seg into AL
    OUT A8255A, AL   
    
    
    ; OUTPUT FOR PORT B, TIME LEFT IN SECS
    ;same thing as last time but for port B
    MOV AH, T1S
    MOV AL, T10S
    MOV CL, 4
    SHL AH, CL
    OR AL, AH
    OUT A8255B , AL 

    ; BSR CHKS FOR LOCK
    MOV AH, FLAGS
    AND AH, 0C0H        ;1100 0000b active or paused
    JZ UNLOCK           ;jump if inactive AND unpaused
    MOV AL, 00000001b   
    OUT A8255CR, AL     ;engage lock
    JMP BUZZER 
    
UNLOCK: MOV AL, 00000000b
        OUT A8255CR, AL ;CR=control register

    ; BSR CHKS FOR BUZZER
    
BUZZER: MOV AH, FLAGS
    AND AH, 00010000b     ;check for buzzer flag
    JZ NOBUZZ
    MOV AL, 00000101b   ;activating buzzer
    OUT A8255CR, AL
    JMP MAIN
    
NOBUZZ: MOV AL, 00000100b   ;turn off buzzer
        OUT A8255CR, AL

    JMP MAIN

; START BUTTON ISR

startbut:

    MOV AH, [FLAGS]
    AND AH, 00001000b    ;checking if time has been set
    JNZ NOQUICK
    
    ; ADDING 30S when in quickstart
    ADD T10S, 03H
    CALL TIMEFIX    ;fixes time format
    
    ; SETTING ACTIVE FLAG   
NOQUICK:
    OR FLAGS, 80H
    
    ; EOI
    MOV AL, 01100000b
    OUT A8259A, AL      ;explicit end of Interrupt
    IRET    
    
    
    
; STOP/CLR ISR


stopbut:

    ; CHK IF PAUSED
    MOV AH, [FLAGS]
    AND AH, 40H ;check for pause flag
    JZ PAUSING     ;jmp if not paused
    
    ; RESET IF ALREADY PAUSED
    MOV AL, 0
    MOV FLAGS, AL
    MOV T10M, AL
    MOV T1M, AL
    MOV T10S, AL
    MOV T1S, AL
    MOV PLVL, 12  ;default values
    JMP CLEAR        
    
    ; PAUSING
PAUSING:    
    OR FLAGS, 40H ;pauses
    
CLEAR:
    MOV AL, 01100001b   
    OUT A8259A, AL      ;End of Interrupt
    IRET


; 10M ISR

t10mbut:
    ADD T10M, 1
    CALL TIMEFIX 
    
    ; SETTING TIME SET FLAG IF NOT ACTIVE
    MOV AH, FLAGS
    AND AH, 80H
    JNZ T10M1   ;jump if active
    OR FLAGS, 08H ;sets timeset
    
T10M1:
    MOV AL, 01100010b
    OUT A8259A, AL      ;explicit EOI
    IRET

; 1M ISR

t1mbt: 
    ADD T1M, 1
    CALL TIMEFIX   ;format time correctly
    
    ; SETTING TIME SET FLAG IF NOT ACTIVE
    
    MOV AH, FLAGS
    AND AH, 80H ;check active flag
    JNZ T1M1
    OR FLAGS, 08H ;same as last
    
T1M1:
    MOV AL, 01100011b
    OUT A8259A, AL      ;EOI
    IRET


; 10S ISR

t10sbt:
;same as last
    ADD T10S, 1
    
    CALL TIMEFIX 
    
    ; SETTING TIME SET FLAG IF NOT ACTIVE
    
    MOV AH, FLAGS
    AND AH, 80H
    JNZ T10S1
    OR FLAGS , 08H
    
T10S1:

    MOV AL, 01100100b
    OUT A8259A, AL
    IRET
  
pwrbt:
    ; CHKS IF TIME HAS BEEN SET OR IS ACTIVE
    MOV AH, FLAGS
    AND AH, 10001000b   ;check for active,timeset
    JNZ PE              ;jump if either is on
    
    ; CHANGING POWER LEVEL
    MOV AH, PLVL
    SUB AH, 2   ;-20%
    JNZ P1      ;if it doesn't go from 20% to 0%
    MOV AH, 10  ;if goes to 0% then change to 100%
    
P1: MOV PLVL, AH   ;store power level back
PE:
    MOV AL, 01100110b
    OUT A8259A, AL      ;EOI
    IRET
  
  
; 8253 ISR

timesgn: ;time signal

;if paused or not active then jump to end
    ; CHECKING IF ACTIVE
    MOV AH, FLAGS
    AND AH, 80H
    JZ POWEROFF
    
    ; CHECKING IF PAUSED
    MOV AH, FLAGS
    AND AH, 40H
    JNZ POWEROFF
    

    ; LOADING TIMER DATA INTO REGISTERS   
    MOV AL, T1S
    MOV AH, T10S
    MOV DL, T1M
    MOV DH, T10M
    
    
    ; TIMER UPDATE
    DEC AL
    CMP AL, 0   ;to check if 1 sec count is negative
    JGE TS2     ;if non-negative jump over next line of code
    MOV AL, 9   ;if it went to -1 change to 9
    
    DEC AH
    CMP AH, 0   ;same as before 
    JGE TS2
    MOV AH, 5
    
    DEC DL      ;same as before
    CMP DL, 0
    JGE TS2
    MOV DL, 9
    DEC DH
    
    
TS2: ; MOVE TIMER DATA TO MEMORY

    MOV T1S, AL
    MOV T10S, AH
    MOV T1M, DL
    MOV T10M, DH 
    
    
    ; CHK IF COOKING COMPLETED
    ADD AX, DX  ;add up all the time counts
    CMP AX, 0   ;if sum of all time counts=0, each is zero
    JG TS3      ;time set>0 implies cooking not complete
          
    OR FLAGS, 01010000B   ;sets pause and buzzer
    AND FLAGS, 01111111B  ;reset active
    JMP TSE                 ;jump to EOI
    
POWEROFF:
    MOV AL, 00000010b
    OUT A8255CR, AL       ;turns off power to magnetron
    JMP TSE     ;jump to EOI
    
TS3:        ;deciding based on power level if magnetron should be on
    MOV AL, T1S   
    CMP AL, PLVL  ;compare remaining time with power level
    JGE POWEROFF
    MOV AL, 00000011b
    OUT A8255CR, AL
    
TSE:
    MOV AL, 01100101b
    OUT A8259A, AL      ;EOI
    IRET
        
        
        
; PWR ISR




; SUB ROUTINE FOR NORMALIZING TIME DATA
TIMEFIX PROC NEAR

    ; LOADING TIMER DATA INTO REGISTERS
    
    MOV AL, T1S
    MOV AH, T10S
    MOV DL, T1M
    MOV DH, T10M
    
    ; CHK 1S DATA
    
    CMP AL, 10  ;compare second count to 10
    JL TF1      ;jump if 1sec time is lower than 10
    SUB AL, 10  ;if higher reduce by 10
    INC AH      ;carry
    
    ; CHK 10S
             
TF1:CMP AH, 6   ;compare counts of 10 sec
    JL TF2      ;if 10sec count<6
    SUB AH, 6   ;subtract 6
    INC DL      ;carry
     
    ; CHK 1M DATA
    
TF2:CMP DL, 10  ;compare count of min
    JL TF3      ;if count of min<10
    SUB DL, 10  ;if count>=10, subtract 10
    INC DH      ;carry
    
    ; CHK 10M DATA
TF3:CMP DH, 10  ;compare 10min count
    JL TF4
    SUB DL, 10

TF4: 

    MOV T1S, AL
    MOV T10S, AH
    MOV T1M, DL
    MOV T10M, DH

    RET  
TIMEFIX ENDP   



FLAGS DB 00H ; 0000-0000 : APRB-T000
;ACTIVE
;PAUSED
;poweR
;BUZZER
;TIME SET

T10M  DB 00H
T1M DB 00H
T10S DB 00H
T1S DB 00H
PLVL DB 00H