;
; PUBTAB.ASM - Include this file to E11.ASM and then it is much easier
; to debug it with symbolic debugger!
;
	PUBLIC INSTR0         ; 0000?? HALT,WAIT,RTI,BPT,IOT,RESET,RTT,MFPT
	PUBLIC JMP11          ; 0001??
	PUBLIC INSTR2         ; 0002?? RTS, SPL, Clear/Set condition codes.
	PUBLIC SWAB11         ; 0003??
	PUBLIC BR11           ; 0004??
	PUBLIC BNE11          ; 0010??
	PUBLIC BEQ11          ; 0014??
	PUBLIC BGE11          ; 0020??
	PUBLIC BGE11          ; 0023??
	PUBLIC BLT11          ; 0024??
	PUBLIC BGT11          ; 0030??
	PUBLIC BLE11          ; 0034??
	PUBLIC JSR11          ; 0040??
	PUBLIC CLR11          ; 0050??
	PUBLIC COM11          ; 0051??
	PUBLIC INC11          ; 0052??
	PUBLIC DEC11          ; 0053??
	PUBLIC NEG11          ; 0054??
	PUBLIC ADC11          ; 0055??
	PUBLIC SBC11          ; 0056??
	PUBLIC TST11          ; 0057??
	PUBLIC ROR11          ; 0060??
	PUBLIC ROL11          ; 0061??
	PUBLIC ASR11          ; 0062??
	PUBLIC ASL11          ; 0063??
	PUBLIC MARK11         ; 0064??
	PUBLIC MFPI11         ; 0065??
	PUBLIC MTPI11         ; 0066??
	PUBLIC SXT11          ; 0067??
	PUBLIC CSM11          ; 0070??
	PUBLIC NEOP           ; 0071??
	PUBLIC MOV11          ; 0100??
	PUBLIC CMP11          ; 0200??
	PUBLIC BIT11          ; 0300??
	PUBLIC BIC11          ; 0400??
	PUBLIC BIS11          ; 0500??
	PUBLIC ADD11          ; 0600??
	PUBLIC MUL11EVEN      ; 0700??  Multiple with even register.
	PUBLIC MUL11ODD       ; 0701??  Multiple with odd register.
	PUBLIC DIV11          ; 0710??
	PUBLIC ASH11          ; 0720??
	PUBLIC ASHC11EVEN     ; 0730??
	PUBLIC ASHC11ODD      ; 0731??
	PUBLIC XOR11          ; 0740??
;	PUBLIC FISUTAB        ; 0750?? FADD, FSUB, FMUL, FDIV
	PUBLIC SOB11          ; 0770??
	PUBLIC BPL11          ; 1000??
	PUBLIC BMI11          ; 1004??
	PUBLIC BHI11          ; 1010??
	PUBLIC BLOS11         ; 1014??
	PUBLIC BVC11          ; 1020??
	PUBLIC BVS11          ; 1024??
	PUBLIC BCC11          ; 1030??
	PUBLIC BCS11          ; 1034??
	PUBLIC EMT11          ; 1040??
	PUBLIC TRAP11         ; 1044??
	PUBLIC CLRB11         ; 1050??
	PUBLIC COMB11         ; 1051??
	PUBLIC INCB11         ; 1052??
	PUBLIC DECB11         ; 1053??
	PUBLIC NEGB11         ; 1054??
	PUBLIC ADCB11         ; 1055??
	PUBLIC SBCB11         ; 1056??
	PUBLIC TSTB11         ; 1057??
	PUBLIC RORB11         ; 1060??
	PUBLIC ROLB11         ; 1061??
	PUBLIC ASRB11         ; 1062??
	PUBLIC ASLB11         ; 1063??
	PUBLIC MTPS11         ; 1064??
	PUBLIC MFPD11         ; 1065??
	PUBLIC MTPD11         ; 1066??
	PUBLIC MFPS11         ; 1067??
	PUBLIC MOVB11         ; 1100??
	PUBLIC CMPB11         ; 1200??
	PUBLIC BITB11         ; 1300??
	PUBLIC BICB11         ; 1400??
	PUBLIC BISB11         ; 1500??
	PUBLIC SUB11          ; 1600??
;
        PUBLIC HALT11   ;  0  Halt
        PUBLIC WAIT11   ;  1  Wait
        PUBLIC RTI11    ;  2  Return from interrupt
        PUBLIC BPT11    ;  3  Breakpoint trap.
        PUBLIC IOT11    ;  4  Input/Output trap.
        PUBLIC RESET11  ;  5  Reset something ???
        PUBLIC RTT11    ;  6  Return from trap.
        PUBLIC MFPT11   ;  7  Move from Previous ???
;
        PUBLIC RTS11       ;  20R  Return from Subroutine.
        PUBLIC SPL11       ;  23N  ???
        PUBLIC Clear_Codes ;  240 -
        PUBLIC Set_Codes   ;  260 -
;
        PUBLIC MAIN_LOOP
	PUBLIC GET_EA
        PUBLIC TRAP_ROUTINE
;
        PUBLIC NOLIMFLAG,CTRLCFLAG,PC_LIM_BPT,INSCNT,SP_SAVE
;
;
        PUBLIC INS0TAB
        PUBLIC INS2TAB
        PUBLIC MODETAB,FLAG1TAB,FLAG2TAB,INSTRTAB
        PUBLIC MODE0,MODE1,MODE2,MODE3,MODE4,MODE5,MODE6,MODE7
;
; END OF THIS FILE.
;
