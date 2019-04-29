;
; E11.ASM - Executor part of ODE11 (Octal Debugger & Executor for PDP-11 code)
;
; Coded by Antti Karttunen at May - June 1990.
;
        include lmacros.h
;
MODELCODE EQU   123Q            ; What MFPT will return?
SUBCODE EQU     0
;
REGS    EQU     177700Q         ; This is an arbitrary place for registers.
SP_LOC  EQU     REGS+(6*2)      ; Location of SP (= R6)
PC_LOC  EQU     REGS+(7*2)      ; Location of PC (= R7)
;
CSR     EQU     177546Q         ; Clock Status Register
KBSTAT  EQU     177560Q         ; Keyboard status register
KBDATA  EQU     177562Q         ; Keyboard data register
PRSTAT  EQU     177564Q         ; Printer status register
PRDATA  EQU     177566Q         ; Printer data register
PSR     EQU     177776Q         ; Program Status Register (flags in low byte).
PRI     EQU     340Q            ; Mask for priority bits in PSR (7-5).
TBIT    EQU     20Q             ; Trace bit (4) in PSR.
CF      EQU     1               ; Carry flag in low byte of PSR
VF      EQU     2               ; Overflow flag
ZF      EQU     4               ; Zero flag
NF      EQU     8               ; Sign flag.
NZVC    EQU     15              ; All four.
; Condition bit-masks to FLAG2TAB:
NxorC   EQU     1               ; N xor C
NxorV   EQU     2               ; N xor V
READYBIT EQU    200Q            ; Ready Bit of the KBSTAT & PRSTAT (bit-7).
; Trap vectors:
ILLADRVEC  EQU   4              ; Illegal address trap vector.
ILLINSVEC  EQU  10Q             ; Illegal instruction trap vector.
BPTVEC  EQU     14Q
IOTVEC  EQU     20Q
PF_VEC  EQU     24Q		; Power Fail trap vector.
EMTVEC  EQU	30Q
TRAPVEC EQU	34Q
TTKBVEC EQU	60Q		; TTY Keyboard Interrupt Vector.
TTPRVEC EQU	64Q		; TTY Printer Interrupt Vector.
CLOCKVEC EQU   100Q		; Line Clock Interrupt Vector.
;
; Return codes for the OD:
HALTED     EQU   0              ; HALT-instruction encountered.
ODDVECTADR EQU   1              ; Tried to trap to ILLADRVEC because of
; odd address in PC, but trap vector contains also odd address.
INSCNTLIM  EQU   2              ; Instruction Count Limit reached.
CTRL_C     EQU   3              ; User pressed CTRL-C.
BRK_PNT    EQU   4              ; Break Point.
;
; Normal single-operand instructions should use this macro to get SEA to DI
GET_S   MACRO
        MOV     BX,DX           ;; Get the original instruction
        SHL     BX,1            ;; Shift left by one.
        CALL    GET_EA          ;; Get the EA of source (in bits 5-0)
        ENDM
;
;
; Normal double-operand instructions should use this macro to get SEA to SI
;  and DEA to DI:
GET_S_ET_D MACRO
        CALL    GET_EA          ;; Get the EA of source to DI.
;;                                  (BX = instr code shifted right 5 times).
        PUSH    DI              ;; Push it to stack.
        MOV     BX,DX           ;; Get the original instruction
        SHL     BX,1            ;; Shift left by one.
        CALL    GET_EA          ;; Get the EA of destination to DI.
        POP     SI              ;; Pop source address to SI.
        ENDM
;
;
; This sets all four flags to same as flags of i*86:
; (BH should be cleared before calling this).
SET_FLAGS1 MACRO                ;; ????
        LOCAL   $1
        LAHF                    ;; Load flags of i*86 to AH
        MOV     BL,AH
        MOV     AL,CS: BYTE PTR FLAG1TAB[BX] ;;Index FLAG1TAB w/ flags of i*86
        JNO     $1              ;; Overflow (86) flag should still be intact.
        OR      AL,VF           ;; If overflow then set V flag also.
$1:
        AND     BYTE PTR [PSR],(NOT NZVC) ;; First clear flags
        OR      BYTE PTR [PSR],AL ;; Then set those flags in mask.
        ENDM
;
; This sets: N & Z set conditionally, V cleared, C not affected
; Stuff to be conditioned should be in AX
SET_FLAGS2 MACRO                ;; ??0-
        TEST    AX,AX           ;; Condition AX to get flags.
        LAHF                    ;; Load flags of i*86 to AH
        MOV     CL,4            ;; Shift Sign Flag & Zero Flag (= N & Z)
        SHR     AH,CL           ;;  from bits 7 & 6 to bits 3 & 2.
        AND     AH,(NF + ZF)    ;; Clear bits 1 & 0.
        AND     BYTE PTR [PSR],(NOT (NF + ZF + VF)) ;; First clear N, Z and V.
        OR      BYTE PTR [PSR],AH
        ENDM
;
; This is alternative code to set flags: (starting just after TEST AX,AX)
; (and there should be that AND BYTE PTR [PSR],... before the TEST)
;       JNS     SIILI1
;       OR      BYTE PTR [PSR],SF
;       TEST    AX,AX
;SIILI1:
;       JNZ     SIILI2
;       OR      BYTE PTR [PSR],ZF
;SIILI2:
;
;
; This is like SET_FLAGS2 but stuff to be conditioned is in AL (not in AX)
;  because it is byte.
SET_FLAGS2B MACRO
        TEST    AL,AL           ;; Condition AL to get flags.
        LAHF                    ;; Load flags of i*86 to AH
        MOV     CL,4            ;; Shift Sign Flag & Zero Flag (= N & Z)
        SHR     AH,CL           ;;  from bits 7 & 6 to bits 3 & 2.
        AND     AH,(NF + ZF)    ;; Clear bits 1 & 0.
        AND     BYTE PTR [PSR],(NOT (NF + ZF + VF)) ;; First clear N, Z and V.
        OR      BYTE PTR [PSR],AH
        ENDM
;
; This sets: N & Z set conditionally, V cleared, C not affected
; This is like SET_FLAGS2, but flags are thought to be already conditioned.
SET_FLAGS3 MACRO                ;; ??0-
        LAHF                    ;; Load flags of i*86 to AH
        MOV     CL,4            ;; Shift Sign Flag & Zero Flag (= N & Z)
        SHR     AH,CL           ;;  from bits 7 & 6 to bits 3 & 2.
        AND     AH,(NF + ZF)    ;; Clear bits 1 & 0.
        AND     BYTE PTR [PSR],(NOT (NF + ZF + VF)) ;; First clear N, Z and V.
        OR      BYTE PTR [PSR],AH
        ENDM
;
; This sets: N & Z set conditionally, V and C cleared.
SET_FLAGS4 MACRO                ;; ??00
        LAHF                    ;; Load flags of i*86 to AH
        MOV     CL,4            ;; Shift Sign Flag & Zero Flag (= N & Z)
        SHR     AH,CL           ;;  from bits 7 & 6 to bits 3 & 2.
        AND     AH,(NF + ZF)    ;; Clear bits 1 & 0.
        AND     BYTE PTR [PSR],(NOT NZVC) ;; First clear all.
        OR      BYTE PTR [PSR],AH
        ENDM
;
;
; This sets: N, Z & V set conditionally, C not affected
SET_FLAGS5 MACRO                  ;; ???-
        LOCAL   $1, $2
        LAHF                      ;; Load flags of i*86 to AH
        JNO     $1
        OR      AH,(VF * 16)      ;; If overflow then set V flag also.
        JMP     SHORT $2
$1:                               ;; (* 16 because SHR AH,CL shifts it yet).
        AND     AH,(NOT (VF * 16)) ;; If no overflow set then clear bit-5
$2: ;; of AH because it's undefined bit in status reg of i*86.
        MOV     CL,4              ;; Shift S, Z and V flags
        SHR     AH,CL             ;;  from bits 7-5 to bits 3-1.
        AND     AH,(NF + ZF + VF) ;; Clear other bits of AH.
        AND     BYTE PTR [PSR],(NOT (NF + ZF + VF)) ;; First clear N, Z and V.
        OR      BYTE PTR [PSR],AH ;; Then or them.
        ENDM
;
;
; This sets flags N, Z & C same as flags of i*86, and V is set to (N xor C)
SET_FLAGS6 MACRO                ;; ??*?
        LOCAL   $1
        LAHF                    ;; Load flags of i*86 to AH
        XOR     BH,BH
        MOV     BL,AH
        MOV     BL,CS: BYTE PTR FLAG1TAB[BX] ;;Index FLAG1TAB w/ flags of i*86
        TEST    CS: BYTE PTR FLAG2TAB[BX],NxorC ;; Test if (N xor C) is 1.
        JZ      $1              ;; If not then don't set overflow flag.
        OR      BL,VF           ;; Else set it.
$1:
        AND     BYTE PTR [PSR],(NOT NZVC) ;; First clear flags
        OR      BYTE PTR [PSR],BL ;; Then set those flags in mask.
        ENDM
;
;
; This sets flags N, Z & C same as flags of i*86, and V is set in the way
;  it is set with ASH & ASHC instructions.
; (SI & DX should contain (upper words of) the original and new versions of
;   shifted register).
SET_FLAGS_ASH MACRO                ;; ??*?
        LOCAL   $1
        LAHF                    ;; Load flags of i*86 to AH
;;      XOR     BH,BH           ;; BH is already cleared   (AND     BX,0Eh)
        MOV     BL,AH
        MOV     AL,CS: BYTE PTR FLAG1TAB[BX] ;;Index FLAG1TAB w/ flags of i*86
        XOR     DX,SI           ;; Is sign bit of orig. different than of
        JNS     $1              ;;  result ?
        OR      AL,VF           ;; Set overflow flag if sign bits differ
$1:
        AND     BYTE PTR [PSR],(NOT NZVC) ;; First clear flags
        OR      BYTE PTR [PSR],AL ;; Then set those flags in mask.
        ENDM
;
;
TRAP    MACRO   TRAP_RTN
        MOV     BX,TRAP_RTN
        CALL    TRAP_ROUTINE
        ENDM
;
;
;CSEG	SEGMENT PARA PUBLIC 'CODE'
;	ASSUME	CS:CSEG
;
; Register usage:
;
;  AX	Work register.
;  BX   Ten most significant bits (15-6) of instruction shifted to 10-1
;       (bit-0 = 0) first, and after that mod & reg of source (bits 11-6)
;       multiplied by two. And in GET_EA routine BX contains register
;       multiplied by two.
;  BP   In GET_EA contains addressing mode multiplied by two.
;  CX   Work register, shift counts.
;  DX   Intact copy of instruction. DL is used by branches to compute the jump
;        address.
;  SI   PC (Program Counter), pointing to next word to be fetched. It must be
;        made sure that SI and PC_LOC in memory contain always the same value.
;       SI is also used to keep the source address in two-operand instructions
;        when PC is not longer needed.
;  DI   Effective address returned by GET_EA.
;
;
        procdef set_pc_bpt,<<brk_point,word>>
        MOV     AX,brk_point
        MOV     CS: WORD PTR [PC_LIM_BPT],AX
        pret
        pend    set_pc_bpt
;
;
        procdef get_pc_bpt
        MOV     AX,CS: WORD PTR [PC_LIM_BPT]
        pret
        pend    get_pc_bpt
;
        procdef brk_e11 ; Called from OD when CTRL C is pressed.
	MOV     CS: BYTE PTR [CTRLCFLAG],1     ; Set CTRLCFLAG on.
	pret
	pend    brk_e11
;
        procdef reset_ic
        MOV     CS: WORD PTR [INSCNT],0
        MOV     CS: WORD PTR [INSCNT+2],0
        pret
        pend    reset_ic
;
        procdef get_ic
        MOV     AX,CS: WORD PTR [INSCNT]   ; Return INSCNT in DX,AX
        MOV     DX,CS: WORD PTR [INSCNT+2]
        pret
        pend    get_ic
;
        procdef reset64k,<<segu,word>>
        CLD
        MOV     ES,segu
        MOV     CX,32768
        XOR     AX,AX
        REPE    STOSW           ; Write zero word 32768 times (= 65536 bytes).
        pret
        pend    reset64k
;
        procdef resetmem,<<segmentti,word>>
        PUSHF
        PUSH    DS
;
        MOV     DS,segmentti
        PUSH    DS
        CALL    reset64k_
        POP     DS
; Reset trap vectors from Illegal address vector (= 4) to TRAP vector (= 34)
        MOV     BX,ILLADRVEC
LOOPY:
        LEA     AX,WORD PTR [BX+2]
        MOV     WORD PTR [BX],AX ; Write A+2 to address A
;       MOV     WORD PTR [AX],0  ;Zero addr A+2 (unnecessary, cleared already)
        ADD     BX,4
        CMP     BX,TRAPVEC
        JBE     LOOPY      ; If BX below or equal to TRAPVEC then branch back.
;
        OR      BYTE PTR [PRSTAT],READYBIT ; Set readybit of PRSTAT.
;
        MOV     WORD PTR [SP_LOC],000776Q  ; Set stack pointer.
;
        POP     DS
        POPF
        pret
        pend    resetmem
;
; ULI execute(segment,inslim)
; UINT segment;
; ULI inslim;
;
; This is the execution routine of PDP-11 simulator.
; Argument segment is segment-part of starting address of 64K block of memory
;  reserved for "PDP-11". Offset part should be zero.
; inslim is doubleword limit of executed instructions. When it comes to zero
;  execution is handled back to octal debugger. E.g: if it is 1 then
;  program is single-stepped. If it is 0 then execution is never broken
;  even if more than 2^32 instructions are executed.
;  (Except for other reasons as HALT, etc.)
;
;
        procdef execute,<<ds_,word>,<inslim_lo,word>,<inslim_hi,word>>
;
        PUSHF
        PUSH    BP
        PUSH    BX
        PUSH    CX
        PUSH    DI
        PUSH    DS
        PUSH    ES
        PUSH    SI
;
        MOV     CS: BYTE PTR [CTRLCFLAG],0 ; Clear to zero.
        MOV     AX,inslim_lo
        MOV     DX,inslim_hi
        MOV     CS:WORD PTR [INSCNT],AX   ; Set instruction
        MOV     CS:WORD PTR [INSCNT+2],DX ;   count limit.
        OR      AX,DX ; Result of this is zero only if both are zero.
        OR      AL,AH ; Result of this is zero only if both halves of AX are 0
        MOV     CS:BYTE PTR [NOLIMFLAG],AL ; Set that to nolimflag
; I.e: If called with inslim = 0 then nolimflag is also 0, otherwise non-zero.
        MOV     CS:WORD PTR [SP_SAVE],SP
        MOV     DS,ds_          ; Load new DS from the stack.
        CLD                     ; Direction is forward with LODSW instruction.
        JMP     MAIN_LOOP
EXIT:
        MOV     SP,CS: WORD PTR [SP_SAVE]  ; Restore stack level.
;
        POP     SI
        POP     ES
        POP     DS
        POP     DI
        POP     CX
        POP     BX
        POP     BP
        POPF
;
        pret
        pend    execute
;
;
; Here is the main execution cycle:
MAIN_LOOP:
        OR      BYTE PTR [PRSTAT],READYBIT ; Set readybit of PRSTAT.
        MOV     SI,WORD PTR [PC_LOC] ; Get PC from its location.
        TEST    SI,1            ; Check if odd...
        JNZ     ODD_PC
        CMP     SI,CS: WORD PTR [PC_LIM_BPT] ; If PC >= PC_limit_breakpoint
        JAE     BREAK_POINT     ; then do the breakpoint.
BACK:
        CMP     CS: BYTE PTR [CTRLCFLAG],0   ; If CTRL-C pressed?
	JNZ     CTRLCPRESSED
        LODSW                   ; Fetch instruction to AX and add 2 to PC.
        MOV     WORD PTR [PC_LOC],SI ; Store changed PC back to its location.
        MOV     BX,AX           ; Copy of instruction to BX.
        MOV     DX,BX           ; And to DX.
        MOV     CL,5
        SHR     BX,CL           ; Shift BX 5 bits right...
        AND     BX,(NOT 1)      ;  and mask off bit-0, so that now it contains
        CALL    CS:INSTRTAB[BX] ;   10 highest significant bits of instruction
; (bits 15-6) multiplied by two (word-indexes) and that is used to index
; an instruction jump table.
        CMP     BYTE PTR [PRDATA],0 ; Is there something to be printed ?
        JZ      GO_AHEAD        ; Nope...
        MOV     DL,BYTE PTR [PRDATA] ; Get character to be output into DL.
        MOV     AH,2            ; Video output, the character in DL
        INT     21h             ;  is output to the video device.
        MOV     BYTE PTR [PRDATA],0 ; Make sure that it's not output 2nd time.
GO_AHEAD:
;
; This code decrements Instruction Count by one:
;
        SUB     CS: WORD PTR [INSCNT],1   ; Decrement low word.
        SBB     CS: WORD PTR [INSCNT+2],0 ; Subtr. borrow (= carry) from high.
        JNZ     MAIN_LOOP		  ; If high word not zero, then loop.
	CMP     CS: WORD PTR [INSCNT],0   ; Low word zero ?
        JNZ     MAIN_LOOP		  ; Loop back if not.
        NEG     CS: BYTE PTR [NOLIMFLAG]  ;Test if NoLimitFlag is on (= off) ?
        JZ      MAIN_LOOP                 ; If it is zero then loop anyway.
        MOV     AX,INSCNTLIM    ; Exit code.
        JMP     EXIT            ; If count limit exceeded then exit.
;
ODD_PC:
        TEST    WORD PTR [ILLADRVEC],1 ; Test if odd handler addr. in vector.
        JZ      BETONIA                ; Nope, jump to "normal" case.
        MOV     AX,ODDVECTADR          ; If odd handler addr. then exit from
        JMP     EXIT                   ;  execute with appropriate status code
; (without that ^ code we would loop here endlessly if odd handler addr. in 4)
BETONIA:
        TRAP    ILLADRVEC              ; It's so safe to be trapped here...
        JMP     MAIN_LOOP
;
BREAK_POINT:
; If PC_LIM_BPT is even, then PC must be excactly equal, but if it is odd,
;  then it must be equal (which is impossible !) or greater than.
        JE      JOE_POIKA                   ; If equal then do it anyway.
        TEST    CS: WORD PTR [PC_LIM_BPT],1 ; If PC_LIM_BPT is even,
        JZ      BACK			    ; then loop back, (false alarm)
JOE_POIKA:				; but if it is odd, then do the thing.
        MOV     AX,BRK_PNT
        JMP     EXIT
;
CTRLCPRESSED:
        MOV     AX,CTRL_C
	JMP     EXIT
;
ODD_ADR_ERR:
; If this odd address error comes with first (= source) operand of
;  double-operand instruction, then second operand's side-effects are
;   not effected at all. (How it is in real PDP-11 ???)
;
        TRAP    ILLADRVEC
        MOV     SP,CS: WORD PTR [SP_SAVE] ; Restore stack level.
        JMP     MAIN_LOOP
;
;
; Get Effective Address. It's returned in DI. DX should still contain
; the original instruction code. Mode & Reg is given in BX in bits 6-4 & 3-1.
GET_EA  PROC
        MOV     BP,BX
        AND     BX,0Eh          ; Register in BX (* 2 because of word-indexes)
        MOV     CL,3
        SHR     BP,CL
        AND     BP,0Eh          ; Mode in BP (* 2)
        CALL    CS:MODETAB[BP]
        MOV     SI,WORD PTR [PC_LOC] ;If auto-(in/de)crementing has changed PC
        TEST    DX,DX           ; Chek if byte-instruction...
        JS      GO_ON           ; If it is, then no need to check if odd addr.
        TEST    DI,1            ; If word-instruction, then check
        JNZ     ODD_ADR_ERR     ;  if odd address.
GO_ON:
        CMP     DI,KBSTAT       ; Is effective address keyboard status reg. ?
        JE      CHAR_IN
        RET
CHAR_IN: ; Code meddles with KBSTAT, so it probably wants to read character in
; Note that this code is executed even if code meddles KBSTAT in some other
;  way, e.g. sets the interrupt bit (bit-6), but that's not so fatal,
;  because code here just polls keyboard, and doesn't wait key to be pressed.
;
        PUSH    DX              ; Save orig. DX (= instruction code).
        MOV     DL,0FFh         ; Direct console I/O
        MOV     AH,06           ;  returns in AL keyboard input character
        INT     21h             ;   if one is ready, otherwise 00.
        MOV     BYTE PTR [KBDATA],AL
        TEST    AL,AL
        JNZ     SET_RBIT
        AND     BYTE PTR [KBSTAT],(NOT READYBIT) ; Clear ready-bit.
        JMP     SHORT SLEDGEHAMMER
SET_RBIT:
        OR      BYTE PTR [KBSTAT],READYBIT ; Set readybit.
SLEDGEHAMMER:
        POP     DX
        RET
;
;
MODE0: ; Rn	Register
        LEA     DI,[REGS+BX]    ; Get address of register.
        RET
MODE1: ; (Rn)	Register deferred (= indirect)
        MOV     DI,[REGS+BX]    ; Get the contents of register.
        RET

MODE2: ; (Rn)+	Autoincrement (like previous, but register is incremented by 2
; after the operand is fetched, except if byte-instruction and reg < R6).
        MOV     DI,[REGS+BX]    ; Get the contents of register.
        INC     [REGS+BX]       ; Increment register by 1.
        TEST    DX,DX           ;Check if byte-instruction (bit-15 of DX on ?)
        JNS     LUUTA1          ; If not byte-instruction then branch.
        CMP     BX,6*2          ; Is Reg < R6 ?
        JL      LUUTA2          ; If both conditions satisfied, then increment
LUUTA1:                         ;  only once.
        INC     [REGS+BX]       ; Otherwise increment second time.
LUUTA2:
        RET

MODE3: ; @(Rn)+ Autoincrement deferred (like previous but there is two levels
; of indirection, and register is always incremented by two).
        MOV     DI,[REGS+BX]    ; Get register contents.
        MOV     DI,[DI]         ; Get address from where that points.
        ADD     [REGS+BX],2     ; Increment register by 2.
        RET

MODE4: ; -(Rn)	Autodecrement (like mode 2 (Autoincrement), but register is
; decremented *before* the address is computed.)
        DEC     [REGS+BX]
        TEST    DX,DX           ; Check if byte instruction ???
        JNS     LAUTA1          ; If not then increment second time anyway.
        CMP     BX,6*2          ; Register not SP nor PC ?
        JL      LAUTA2          ; If so then decrement only once.
LAUTA1:
        DEC     [REGS+BX]
LAUTA2:
        MOV     DI,[REGS+BX]
        RET

MODE5: ; @-(Rn) Autodecrement deferred (like mode 3, Autoincrement deferred,
; but register is decremented before the address is computed.)
        SUB     [REGS+BX],2     ; Decrement one word.
        MOV     DI,[REGS+BX]
        MOV     DI,[DI]
        RET

MODE6: ; X(Rn)	Index.  Address of operand is X plus Rn, X is just after
; instruction. (or after source argument if this is destination argument
; and source mode was also 6 or 7).
        LODSW                   ; Fetch X to AX and increment PC past it.
        MOV     [PC_LOC],SI     ; Keep PC in memory same as SI.
        MOV     DI,[REGS+BX]    ; Get contents of register.
        ADD     DI,AX           ; Add X.
        RET

MODE7: ; @X(Rn) Index referred. Like above but one more level of indirection.
        LODSW                   ; Fetch X to AX and add 2 to PC. (= SI)
        MOV     [PC_LOC],SI     ; Update PC in memory.
        MOV     DI,[REGS+BX]    ; Contents of reg.
        ADD     DI,AX           ; Add X.
        MOV     DI,[DI]         ; And one indirection yet.
        RET
GET_EA  ENDP
;
;
; This is a general trapping routine. BX should contain the address of vector
;  and SI should still contain the PC.
TRAP_ROUTINE:
        PUSH    BX
        MOV     BX,WORD PTR [SP_LOC]
        SUB     BX,4                 ; Decrement BX already by 4. (two pushes)
        MOV     CX,WORD PTR [PSR]    ; Push PSR to
        MOV     WORD PTR [BX+2],CX   ;  system stack.
        MOV     WORD PTR [BX],SI     ; Push PC to system stack.
        MOV     WORD PTR [SP_LOC],BX ; Update SP in memory.
        POP     BX
        MOV     SI,WORD PTR [BX]     ;Get new PC from the first word of vector
        MOV     WORD PTR [PC_LOC],SI ;
        MOV     CX,WORD PTR [BX + 2] ; Get the new PSR from the second word.
        MOV     WORD PTR [PSR],CX
        RET
;
;
;
NEOP: ; Non-Existent Operation.
        TRAP    ILLINSVEC
        RET
;
;
INSTR0: ; Instruction codes 000000-000077 dispatch here.
; This generates some buggy code, I don't know why, but commented out:
;       CMP     AX,INS0CNT        ; If instruction code above or equivalent to
;       JAE     NEOP              ;  INS0CNT, then NEOP.
; Replaced by this:
        TEST    AX,(NOT 7)        ; If AX > 7 ?
	JNZ     NEOP              ; then it is non-existent instruction.
;
        MOV     BX,AX             ; Get 2 * Ins. code to BX
        SHL     BX,1
        JMP     CS:INS0TAB[BX]    ; And index jump table with it.
;
HALT11:
        MOV     AX,HALTED
        JMP     EXIT              ; Exit from execution.
;
WAIT11: ; Wait for interrupt.
        TRAP    ILLINSVEC         ; Not implemented.
        RET
RTI11: ; Return from Interrupt.
        MOV     SI,WORD PTR [SP_LOC] ; Get system stack pointer.
        LODSW                     ; Pop PC from the stack.
        MOV     WORD PTR [PC_LOC],AX
        LODSW                     ; Pop PSR from the stack.
        MOV     WORD PTR [PSR],AX
        MOV     WORD PTR [SP_LOC],SI ; Update SP in the memory.
        RET
BPT11: ; Breakpoint trap.
        TRAP    BPTVEC
        RET
IOT11: ; Input/Output trap.
        TRAP    IOTVEC
        RET
RESET11:
; Sends INIT on the BUS for 10 usec. All devices on the BUS are reset to their
; state at power-up. The processor remains in an idle state for 90 usec
; following issuance of INIT. (See: Programming 16-Bit Machines by William H.
; Jermann, page 368). How to emulate ??? (Delay of 100 ms ?)
        TRAP    ILLINSVEC
        RET
RTT11: ; Return from Trap.
        JMP     RTI11           ; Currently same as RTI11
;       RET
;
MFPT11: ; Move From Processor Type
; Load processor model code to low byte and processor subcode to high byte
; or R0. Flags not affected.
        MOV     WORD PTR [REGS+(0*2)],((SUBCODE*256)+MODELCODE)
        RET
;
;
INSTR2: ; Instruction codes 000200 - 000277 dispatch here.
        MOV     BX,DX
        MOV     CL,2
        SHR     BX,CL             ; Get Bits 5-3 of instr. code to bits 3-1.
        AND     BX,0Eh            ; Clear other bits than 3-1.
        JMP     CS:INS2TAB[BX] ; Index jump table with it.
;
;
; RTS   Ri
;  is equivalent to: (see also JSR)
; MOV   Ri,PC
; MOV   (SP)+,Ri
;
RTS11: ; Return from Subroutine
        MOV     BX,DX
        AND     BX,7                    ; Get bits 2-0
        SHL     BX,1                    ; Multiply by 2.
        MOV     AX,WORD PTR [REGS + BX] ; Get contents of Ri
        MOV     WORD PTR [PC_LOC],AX    ; Store to PC.
        MOV     BP,WORD PTR [SP_LOC]    ; Pop old value of Ri
        MOV     AX,DS: WORD PTR [BP]    ;  into AX
        ADD     WORD PTR [SP_LOC],2     ;   from system stack.
        MOV     WORD PTR [REGS + BX],AX ; And store it into Ri.
        RET
;
SPL11: ; Set Priority Level to N    00023N
; I haven't got enough documentation from this instruction, so I don't
; know whether it should affect flags, nor I dunno whether there is any
; restrictions in use of it.
        AND     AL,7		  ; Get N (AX should still contain instr.)
        MOV     CL,5              ; Shift to the
        SHL     AL,CL             ;  bits 7-5.
        AND     BYTE PTR [PSR],(NOT PRI) ; First clear the priority bits,
        OR      BYTE PTR [PSR],AL ; So that they can be set.
        RET
;
;
Clear_Codes: ; NOP, CLC, CLV, CLZ, CLN, CCC and combinations:
        AND     DL,0Fh            ; Get those flags to be cleared.
        NOT     DL                ; Complement them.
        AND     BYTE PTR [PSR],DL ; Clear corresponding bits from PSR.
        RET
;
Set_Codes: ; SEC, SEV, SEZ, SEN, SCC and combinations:
        AND     DL,0Fh            ; Get those flags to be set.
        OR      BYTE PTR [PSR],DL ; Or them into Program Status Register.
        RET
;
;
; /* ====================================================================== */
;                   NORMAL DOUBLE-OPERAND INSTRUCTIONS
;
;                   WORD-VERSIONS:
;
MOV11:
        GET_S_ET_D
        MOV     AX,[SI]         ; Move stuff from source...
        MOV     [DI],AX         ;   ...to destination.
        SET_FLAGS2
        RET
;
;
CMP11:
        GET_S_ET_D
        XOR     BH,BH           ; Clear BH here, because XOR changes flags.
        MOV     AX,[SI]         ; Get source.
        CMP     AX,[DI]         ; Compare to destination.
        SET_FLAGS1
        RET
;
;
BIT11: ; Bit Test = TEST S,D
        GET_S_ET_D
        MOV     AX,[SI]         ; Get source.
        TEST    AX,[DI]         ; And with destination (just condition it).
        SET_FLAGS3
        RET
;
;
BIC11: ; Bit Clear = AND D,~S
        GET_S_ET_D
        MOV     AX,[SI]         ; Get source.
        NOT     AX              ; Complement it.
        AND     [DI],AX         ; And it to destination.
        SET_FLAGS3
        RET
;
;
BIS11: ; Bit Set = OR D,S
        GET_S_ET_D
        MOV     AX,[SI]         ; Get source.
        OR      [DI],AX         ; Or it to destination.
        SET_FLAGS3
        RET
;
;
ADD11:
        GET_S_ET_D
        XOR     BH,BH           ; Clear BH here, because XOR changes flags.
        MOV     AX,[SI]         ; Get source.
        ADD     [DI],AX         ; Add to destination.
        SET_FLAGS1
        RET
;
;
;                   BYTE-VERSIONS:
;
;
MOVB11:
        GET_S_ET_D
MOVB_KALA:
        MOV     AL,BYTE PTR [SI] ; Move stuff from source...
; If destination is register (mode = 0), then source byte is sign-extended
;  to high byte of register. (See Programming 16-bit Machines, page 366).
        TEST    BP,BP       ; BP should be still mode of dst after last GET_EA
        JNZ     NORMAL
        CBW                 ; Sign extend byte.
        MOV     WORD PTR [DI],AX ; 
        JMP     SHORT JATKO
NORMAL:
        MOV     BYTE PTR [DI],AL ;   ...to destination.
JATKO:
        SET_FLAGS2B
        RET
;
;
CMPB11:
        GET_S_ET_D
        XOR     BH,BH           ; Clear BH here, because XOR changes flags.
        MOV     AL,[SI]         ; Get source.
        CMP     AL,[DI]         ; Compare to destination.
        SET_FLAGS1
        RET
;
;
BITB11: ; Bit Test = TEST S,D
        GET_S_ET_D
        MOV     AL,[SI]         ; Get source.
        TEST    AL,[DI]         ; And with destination (just condition it).
        SET_FLAGS3
        RET
;
;
BICB11: ; Bit Clear = AND D,~S
        GET_S_ET_D
        MOV     AL,[SI]         ; Get source.
        NOT     AL              ; Complement it.
        AND     [DI],AL         ; And it to destination.
        SET_FLAGS3
        RET
;
;
BISB11: ; Bit Set = OR D,S
        GET_S_ET_D
        MOV     AL,[SI]         ; Get source.
        OR      [DI],AL         ; Or it to destination.
        SET_FLAGS3
        RET
;
;
SUB11:
        AND     DX,7FFFh        ; Clear bit-15 of original instr. code (DX)
; so that GET_EA doesn't think that SUB is byte-instruction.
        GET_S_ET_D
        XOR     BH,BH           ; Clear BH here, because XOR changes flags.
        MOV     AX,[SI]         ; Get source.
        SUB     [DI],AX         ; Subtract from destination.
        SET_FLAGS1
        RET
;
; /* ====================================================================== */
;             EXTENDED INSTRUCTION SET (EIS)  070RSS - 077RNN
;
MUL11EVEN: ; Signed multiply on even register (2 regs for result).
        PUSH    BX
        GET_S                           ; Get destination address to DI.
        POP     BX
        AND     BX,0Eh                  ; BX now contains register * 2.
        MOV     AX,WORD PTR [REGS + BX] ; Get contents of register to AX.
        IMUL    WORD PTR [DI]           ; Multiply AX with Source Operand.
        MOV     WORD PTR [REGS + 2 + BX],AX ; Store low word of result to Rn+1
        SET_FLAGS3   ; MUISTA MEDITOIDA C flagin ASETUS !!!
        MOV     WORD PTR [REGS + BX],DX ; Store high word of result to Rn
        RET
;
;
MUL11ODD: ; Signed multiply on odd register (only one register for result).
        PUSH    BX
        GET_S                           ; Get destination address to DI.
        POP     BX
        AND     BX,0Eh                  ; BX now contains register * 2.
        MOV     AX,WORD PTR [REGS + BX] ; Get contents of register to AX.
        IMUL    WORD PTR [DI]           ; Multiply AX with Source Operand.
        MOV     WORD PTR [REGS + BX],AX ; Store low word of result to Rn.
        SET_FLAGS3   ; MUISTA MEDITOIDA C flagin ASETUS !!!
        RET
;
;
DIV11: ; Signed divide. Register should be even.
        PUSH    BX
        GET_S                           ; Get destination address to DI.
        POP     BX
        AND     BX,0Eh                  ; BX now contains register * 2.
        MOV     DX,WORD PTR [REGS + BX] ; Get most significant bits to DX
        MOV     AX,WORD PTR [REGS + 2 + BX] ; Get least significant bits to AX
        MOV     CX,WORD PTR [DI]	; Get source to CX
        JCXZ    DIV_BY_ZERO
        AND     BYTE PTR [PSR],(NOT CF) ; Clear Carry.
        MOV     DI,DX                   ; Get copy of high word to DI
        TEST    DI,DI                   ; Check if it is negative...
        JNS     TOPI1                   ; Skip negating if positive.
        NEG     DI                      ; Negate it. (get absolute value).
TOPI1:
        CMP     DI,CX                   ; Is high word >= source ?
        JGE     POSSIBLE_ERR
NO_ERR:
        IDIV    CX                      ; Divide by source.
        MOV     WORD PTR [REGS + BX],AX ; Store quotient to Rn.
        MOV     WORD PTR [REGS + 2 + BX],DX ; Store remainder to Rn+1
        TEST    AX,AX                   ; Make sure that flags are set
;                  according to quotient (I don't know what ever Intel does).
        SET_FLAGS4                      ; In normal case ??00
        RET
POSSIBLE_ERR:
        TEST    CX,CX           ; Check if source negative.
        JNS     SURE_ERR        ; If not, then previous comparison was correct
        MOV     SI,CX           ; Get copy of source to SI.
        NEG     SI              ; Get absolute value of SI.
        CMP     DI,SI           ; Make comparison again. If high word of
        JL      NO_ERR          ;  dividend is less than divisor, then it's ok
SURE_ERR:
        OR      BYTE PTR [PSR],VF ; Set overflow flag if quotient too big or
; if divisor zero.
        RET            ; I think that N & Z flags are left to undefined state.
DIV_BY_ZERO:
        OR      BYTE PTR [PSR],CF ; Set Carry.
        JMP     SHORT SURE_ERR
;
; MEDITATE THIS: When shift count is -32, does it mean that register(s)
;  is shifted right 32 or 0 times ??? Now this is impelemented so that
;  it is shifted 32 times. (both ASH11 & ASHC11EVEN)
;
ASH11:
        PUSH    BX
        GET_S                           ; Get destination address to DI.
        POP     BX
        AND     BX,0Eh                  ; BX now contains register * 2.
        MOV     DX,WORD PTR [REGS + BX] ; Get contents of register to DX.
        MOV     SI,DX			; Copy of the original to SI.
        MOV     CL,BYTE PTR [DI]        ; Get source (= shift count)
        AND     CL,77Q                  ; Get six lowest bits (5-0)
        CMP     CL,32
        JA      NEG_COUNT
        JE      LYPSY
        SAL     DX,CL
        JMP     SHORT JATKO2
LYPSY: ; If count is -32 then make sure that reg is shifted right 32 times
; and not 0 times ! (How it really should be ???)
        SAR     DX,1			; So first shift once,
        DEC     CL			;  and then 31 times more.
NEG_COUNT:
	OR      CL,300Q         ; Set bits 7 and 6 of CL.
        NEG     CL              ; Negate it to get the correct shift count.
        SAR     DX,CL			; i*86 does use only lowest 5 bits
; of CL for shifting, so bit-5 doesn't need to be cleared.
JATKO2:
        MOV     WORD PTR [REGS+BX],DX   ; Store result back to register.
        SET_FLAGS_ASH
        RET
;
;
;
ASHC11EVEN:
        PUSH    BX
        GET_S                           ; Get destination address to DI.
        POP     BX
        AND     BX,0Eh                  ; BX now contains register * 2.
        MOV     DX,WORD PTR [REGS + BX] ; Get high word to DX.
        MOV     AX,WORD PTR [REGS+BX+2] ; Get low word to AX.
        MOV     SI,DX			; Copy of the high word to SI.
        MOV     CX,WORD PTR [DI]        ; Get source (= shift count)
        AND     CX,77Q                  ; Get six lowest bits (5-0)
        JCXZ    JATKO3           ; What happens to carry when count is 0 ?
        CMP     CL,32
        JAE     NEG_COUNT3
NUUTTI:
        SAL     AX,1            ; Low word one left, high bit to carry.
        RCL     DX,1            ; High word one left, bit-0 from carry.
        LOOP    NUUTTI          ; = SOB CX,NUUTTI
        JMP     SHORT JATKO3
NEG_COUNT3:
        JE      TUUTTI          ; If count exactly 32, then let it be.
	OR      CL,300Q         ; Set bits 7 and 6 of CL.
        NEG     CL              ; Negate it to get the correct shift count.
TUUTTI:
        SAR     DX,1      ; High word one right (bit-15 kept same) bit-0 -> C
        RCR     AX,1      ; Low word one right, bit-15 from carry.
        LOOP    TUUTTI
; of CL for shifting, so bit-5 doesn't need to be cleared.
JATKO3:
        ADC     CL,0      ; CX should be now 0, so this saves carry to CL.
        MOV     WORD PTR [REGS+BX],DX   ; Store result back to reg. High
        MOV     WORD PTR [REGS+BX+2],AX ;  and low word.
        OR      AL,AH     ; AL is zero only if whole AX is zero.
        OR      DL,AL     ; DL will be zero only if DL and AX were zero.
        TEST    DX,DX     ; So DX is zero only if both DX & AX were zero,
;                         ;  but sign-bit (bit-15 of DX) is still retained.
        SET_FLAGS_ASH     ; (Note: TEST clears carry).
        OR      BYTE PTR [PSR],CL ; Finally move carry from CL to PSR.
	RET
;
; Not implemented yet!
ASHC11ODD:
        TRAP    ILLINSVEC
	RET
;
XOR11:
        PUSH    BX                      ; Save already shifted instr. code
        GET_S                           ; Get destination address to DI.
        POP     BX
        AND     BX,0Eh                  ; BX now contains register * 2.
        MOV     AX,WORD PTR [REGS + BX] ; Get contents of register to AX.
        XOR     WORD PTR [DI],AX        ; Xor it to destination.
        SET_FLAGS3                      ; Flags: ??0-
        RET
;
; FISUTAB: ; FADD, FSUB, FMUL, FDIV
        RET
;
SOB11: ; Subtract one and branch (if not zero).
        AND     BX,0Eh                  ; BX now contains regnum * 2.
        DEC     WORD PTR [REGS + BX]    ; Decrement register
        JZ      POISTU                  ; If register came zero, do nothing.
        AND     AX,077Q                 ; Get six-bit displacement from AX
        SHL     AX,1                    ;  and multiply by 2.
        SUB     WORD PTR [PC_LOC],AX    ; Subtract it from PC.
POISTU:
        RET
;
;
; /* ====================================================================== */
;
JMP11:
        GET_S
;       TEST    BP,BP
;       JZ      ERTZU ; Mode 0 (register) is illegal with JMP.
        MOV     WORD PTR [PC_LOC],DI
        RET
;
SWAB11: ; Swap Bytes, set flags according to low byte of result.
        GET_S
        MOV     AX,WORD PTR [DI] ; Get word from EA.
        XCHG    AL,AH            ; Swap bytes of AX.
        MOV     WORD PTR [DI],AX ; And put back to destination.
        TEST    AL,AL            ; Test low byte of result.      NZVC
        SET_FLAGS4               ; Set N & Z flags accordingly.  ??00
        RET
;
;
;
; JSR   Ri,SUB       ; Jump to subroutine SU and use Ri as linkage register.
;  is equivalent to: (see also RTS)
; MOV   #SUB,TEMP    ; Put effective address of SUB to some internal register.
; MOV   Ri,-(SP)     ; Push old Ri to system stack.
; MOV   PC,Ri        ; Move PC to Ri.
; MOV   TEMP,PC      ; Move internal register to PC.
;
;
JSR11: ; Jump to Subroutine.
        PUSH    BX
        GET_S                           ; Get destination address to DI.
        POP     BX
        AND     BX,0Eh                  ; BX now contains register * 2.
        MOV     AX,WORD PTR [REGS + BX] ; Get contents of register to AX.
        SUB     WORD PTR [SP_LOC],2     ; Push AX
        MOV     BP,WORD PTR [SP_LOC]    ;  to system
        MOV     DS:WORD PTR [BP],AX     ;   stack (= R6).
        MOV     WORD PTR [REGS + BX],SI ; Put old PC to Register.
        MOV     WORD PTR [PC_LOC],DI    ; Change PC to Destination Address.
        RET
;
;
; /* ====================================================================== */
;   STANDARD SINGLE-OPERAND INSTRUCTIONS FROM 005000 ONWARD (WORD-VERSIONS)
;
CLR11: ; Clear
        GET_S
        MOV     WORD PTR [DI],0           ; Clear destination.
        AND     BYTE PTR [PSR],(NOT NZVC) ; First clear flags    NZVC
        OR      BYTE PTR [PSR],ZF         ; Then set Zero Flag   0100
        RET
COM11: ; Complement             NZVC
;                               ??01
        GET_S
; Alternative 1:
;       NOT     WORD PTR [DI]   ; Don't use NOT because it doesn't set flags.
;       XOR     WORD PTR [DI],0 ; (Although this XOR would set them).
; Alternative 2: (6 + 6 = 12 cycles ?)
;       NEG     WORD PTR [DI]   ; One could use NEG & DEC instead, which is
;       DEC     WORD PTR [DI]   ;  effectively same but sets flags also.
; Alternative 3: But single XOR is enough ! (7 cycles ?)
        XOR     WORD PTR [DI],-1 ;Complement & set N&Z flags accordingly.
        SET_FLAGS3              ; Set N & Z according to N&Z of i*86, clear V
        OR      BYTE PTR [PSR],CF ; C flag is always set.
        RET
;
INC11: ; Increment
        GET_S
        INC     WORD PTR [DI]             ; NZVC
        SET_FLAGS5                        ; ???-
        RET
DEC11: ; Decrement
        GET_S
        DEC     WORD PTR [DI]             ; NZVC
        SET_FLAGS5                        ; ???-
        RET
NEG11: ; Negate
        GET_S
        XOR     BH,BH           ; Clear BH here, because XOR changes flags.
        NEG     WORD PTR [DI]             ; NZVC
        SET_FLAGS1                        ; ????
        RET
ADC11: ; Add carry flag.
        GET_S
        XOR     BH,BH           ; Clear BH here, because XOR changes flags.
        MOV     AL,BYTE PTR [PSR]
        SHR     AL,1                      ; Get carry of PSR to carry of i*86.
        ADC     WORD PTR [DI],0           ; NZVC
        SET_FLAGS1                        ; ????
        RET
SBC11: ; Subtract carry flag.
        GET_S
        XOR     BH,BH           ; Clear BH here, because XOR changes flags.
        MOV     AL,BYTE PTR [PSR]
        SHR     AL,1                      ; Get carry of PSR to carry of i*86.
        SBB     WORD PTR [DI],0           ; NZVC
        SET_FLAGS1                        ; ????
        RET
TST11: ; Condition flags.
        GET_S
;       MOV     AX,WORD PTR [DI] ; NZVC
;       TEST    AX,AX            ; ??00
        XOR     WORD PTR [DI],0  ;This XOR is probably faster than those above
        SET_FLAGS4
        RET
ROR11: ; Rotate right (through carry).
        GET_S
        MOV     AL,BYTE PTR [PSR]
        SHR     AL,1                      ; Get carry of PSR to carry of i*86.
        RCR     WORD PTR [DI],1           ; NZVC
        SET_FLAGS6                        ; ????
        RET
ROL11: ; Rotate left (through carry).
        GET_S
        XOR     BH,BH
        MOV     AL,BYTE PTR [PSR]
        SHR     AL,1                      ; Get carry of PSR to carry of i*86.
        RCL     WORD PTR [DI],1           ; NZVC
        SET_FLAGS1                        ; ????
        RET
ASR11: ; Arithmetic shift right. (bit-15 is kept same).
        GET_S
        SAR     WORD PTR [DI],1           ; NZVC
        SET_FLAGS6                        ; ????
        RET
ASL11: ; Arithmetic shift left.
        GET_S
        XOR     BH,BH
        SAL     WORD PTR [DI],1           ; NZVC
        SET_FLAGS1                        ; ????
        RET
;
; Some not so common instructions:
MARK11: ; 0064NN (flags unaffected)
; In "Programming 16-Bit Machines" this is described as:
;   SP <- updated PC + 2 + 2n
;   PC <- R5
;   R5 <- (SP)^     (Pop old R5 from stack).
; In KD11-EA central processor maintenance manual it is described as:
;   SP <- SP + 2n
;   PC <- R5
;   R5 <- (SP)^
;
; However, I believe that both ways are wrong. I think stack should be updated
;  as: SP <- SP + 2n + 2   or: SP <- updated PC + 2n.    (of course latter
;  works only if control is transferred to MARK instr. in stack with RTS R5).
; So, let's hope that this works correctly:
        AND     AX,77Q			; Get bits 5-0 (= NN)
        INC     AX                      ; Compute the
        SHL     AX,1                    ;   2*N + 2   (= 2*(N+1))
        MOV     SI,WORD PTR [SP_LOC]    ; Get SP.
        ADD     SI,AX                   ; Adjust with 2*N + 2
        MOV     AX,WORD PTR [REGS+(5*2)] ; PC <- R5
        MOV     WORD PTR [PC_LOC],AX
        LODSW                           ; MOV AX,[SI++]
        MOV     WORD PTR [REGS+(5*2)],AX ; R5 <- (SP)^
        MOV     WORD PTR [SP_LOC],SI    ; Update SP in memory.
        RET
;
;
MFPI11: ; Move from Previous Instruction space.
        RET
MTPI11: ; Move to Previous Instruction space.
        RET
SXT11:  ; Sign Extend Word.
        GET_S
        AND     BYTE PTR [PSR],(NOT VF) ; Clear Overflow flag.
        TEST    BYTE PTR [PSR],NF       ; Is N flag on ?
        JNZ     YEAH
        OR      BYTE PTR [PSR],ZF
        MOV     WORD PTR [DI],0
        RET
YEAH:
        AND     BYTE PTR [PSR],(NOT ZF)
        MOV     WORD PTR [DI],-1
        RET
;
CSM11: ;What the hell this should do ? Chastisement by our Satanic Majesties ?
; Actually, it is Call Supervisor Mode. Not implemented yet.
        TRAP    ILLINSVEC
        RET
;
;
; /* ====================================================================== */
;   STANDARD SINGLE-OPERAND INSTRUCTIONS FROM 105000 ONWARD (BYTE-VERSIONS)
;
CLRB11: ; Clear
        GET_S
        MOV     BYTE PTR [DI],0           ; Clear destination.
        AND     BYTE PTR [PSR],(NOT NZVC) ; First clear flags    NZVC
        OR      BYTE PTR [PSR],ZF         ; Then set Zero Flag   0100
        RET
;
COMB11: ; Complement             NZVC
;                                ??01
        GET_S
        XOR     BYTE PTR [DI],-1 ;Complement & set N&Z flags accordingly.
        SET_FLAGS3              ; Set N & Z according to N&Z of i*86, clear V
        OR      BYTE PTR [PSR],CF ; C flag is always set.
        RET
;
INCB11: ; Increment
        GET_S
        INC     BYTE PTR [DI]             ; NZVC
        SET_FLAGS5                        ; ???-
        RET
DECB11: ; Decrement
        GET_S
        DEC     BYTE PTR [DI]             ; NZVC
        SET_FLAGS5                        ; ???-
        RET
NEGB11: ; Negate
        GET_S
        XOR     BH,BH           ; Clear BH here, because XOR changes flags.
        NEG     BYTE PTR [DI]             ; NZVC
        SET_FLAGS1                        ; ????
        RET
ADCB11: ; Add carry flag.
        GET_S
        XOR     BH,BH           ; Clear BH here, because XOR changes flags.
        MOV     AL,BYTE PTR [PSR]
        SHR     AL,1                      ; Get carry of PSR to carry of i*86.
        ADC     BYTE PTR [DI],0           ; NZVC
        SET_FLAGS1                        ; ????
        RET
SBCB11: ; Subtract carry flag.
        GET_S
        XOR     BH,BH           ; Clear BH here, because XOR changes flags.
        MOV     AL,BYTE PTR [PSR]
        SHR     AL,1                      ; Get carry of PSR to carry of i*86.
        SBB     BYTE PTR [DI],0           ; NZVC
        SET_FLAGS1                        ; ????
        RET
TSTB11: ; Condition flags.
        GET_S
        XOR     BYTE PTR [DI],0
        SET_FLAGS4
        RET
RORB11: ; Rotate right (through carry).
        GET_S
        MOV     AL,BYTE PTR [PSR]
        SHR     AL,1                      ; Get carry of PSR to carry of i*86.
        RCR     BYTE PTR [DI],1           ; NZVC
        SET_FLAGS6                        ; ????
        RET
ROLB11: ; Rotate left (through carry).
        GET_S
        XOR     BH,BH
        MOV     AL,BYTE PTR [PSR]
        SHR     AL,1                      ; Get carry of PSR to carry of i*86.
        RCL     BYTE PTR [DI],1           ; NZVC
        SET_FLAGS1                        ; ????
        RET
ASRB11: ; Arithmetic shift right. (bit-15 is kept same).
        GET_S
        SAR     BYTE PTR [DI],1           ; NZVC
        SET_FLAGS6                        ; ????
        RET
ASLB11: ; Arithmetic shift left.
        GET_S
        XOR     BH,BH
        SAL     BYTE PTR [DI],1           ; NZVC
        SET_FLAGS1                        ; ????
        RET
;
;
MTPS11: ; Move byte To Processor Status word.
        GET_S
        MOV     AL,BYTE PTR [DI]          ; That' all
        MOV     BYTE PTR [PSR],AL         ;  folks !
        RET
;
MFPD11: ; Move from Previous Data Space
        RET
;
MTPD11: ; Move to Previous Data Space
        RET
;
MFPS11: ; Move byte From Processor Status word
        GET_S                             ; Get dest. EA to DI
        LEA     SI,BYTE PTR [PSR]         ; And address of PSR as src. to SI.
        JMP     MOVB_KALA                 ; Then use code of MOVB11
;
;
; /* ====================================================================== */
;                                 BRANCHES
;
; (Maybe these could be generated with some macro ???)
;
BR11:  ; Unconditional branch
;       MOV     AL,DL ; This is unnecessary, because instr is also still in AX
        CBW           ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; This is enough.
        RET
;
;
BNE11: ; Branch if not equal (Zero flag is 0).
        TEST    BYTE PTR [PSR],ZF
        JNZ     POIS1 ; Don't branch if ZF is set.
        CBW           ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS1:
        RET
;
;
BEQ11: ; Branch equal (Zero flag is 1).
        TEST    BYTE PTR [PSR],ZF
        JZ      POIS2 ; Don't branch if ZF is not set.
        CBW           ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS2:
        RET
;
;
BGE11: ; Branch if greater than or equal. (If N xor V is zero).
        MOV     BX,WORD PTR [PSR]
        AND     BX,NZVC         ; Clear other bits than flags.
        TEST    CS:BYTE PTR FLAG2TAB[BX],NxorV ; Test if N xor V is zero.
        JNZ     POIS3 ; Don't branch if it's not zero.
        CBW           ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS3:
        RET
;
BLT11: ; Branch if less than. (If N xor V = 1).
        MOV     BX,WORD PTR [PSR]
        AND     BX,NZVC         ; Clear other bits than flags.
        TEST    CS:BYTE PTR FLAG2TAB[BX],NxorV ; Test if N xor V is zero.
        JZ      POIS4 ; Don't branch if it's zero.
        CBW           ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS4:
        RET
;
;
BGT11: ; Branch if greater than. (If (Z or (N xor V)) = 0).
        MOV     BX,WORD PTR [PSR]
        AND     BX,NZVC         ; Clear other bits than flags.
        TEST    CS:BYTE PTR FLAG2TAB[BX],(ZF or NxorV) ; Test condition.
        JNZ     POIS5 ; Don't branch if it's not zero.
        CBW           ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS5:
        RET
;
BLE11: ; Branch if less than or equal. (If (Z or (N xor V)) = 1).
        MOV     BX,WORD PTR [PSR]
        AND     BX,NZVC         ; Clear other bits than flags.
        TEST    CS:BYTE PTR FLAG2TAB[BX],(ZF or NxorV) ; Test condition.
        JZ      POIS6 ; Don't branch if it's zero.
        CBW           ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS6:
        RET
;
;
BPL11: ; Branch if plus (N flag is 0).
        TEST    BYTE PTR [PSR],NF
        JNZ     POIS7 ; Don't branch if NF is set.
        CBW           ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS7:
        RET
;
;
BMI11: ; Branch if minus (N flag is 1).
        TEST    BYTE PTR [PSR],NF
        JZ      POIS8 ; Don't branch if NF is not set.
        CBW           ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS8:
        RET
;
;
BHI11: ; Branch if higher (C=0 and Z=0) (i.e. (C or Z) = 0)
        TEST    BYTE PTR [PSR],(CF + ZF)
        JNZ     POIS9 ; Don't branch if C or Z is set.
        CBW           ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS9:
        RET
;
;
BLOS11: ; Branch if lower or same (if (C or Z) = 1)
        TEST    BYTE PTR [PSR],(CF + ZF)
        JZ      POIS10 ; Don't branch if not C nor Z is set.
        CBW            ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS10:
        RET
;
;
BVC11: ; Branch if overflow is clear (V flag is 0).
        TEST    BYTE PTR [PSR],VF
        JNZ     POIS11 ; Don't branch if V is set.
        CBW            ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS11:
        RET
;
;
BVS11: ; Branch if overflow is set (V flag is 1).
        TEST    BYTE PTR [PSR],VF
        JZ      POIS12 ; Don't branch if V is not set.
        CBW            ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS12:
        RET
;
;
BCC11: ; Branch if carry is clear (Synonym: BHIS, branch if higher or same).
        TEST    BYTE PTR [PSR],CF
        JNZ     POIS13 ; Don't branch if C is set.
        CBW            ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS13:
        RET
;
;
BCS11: ; Branch if carry is set (Synonym: BLO, Branch if lower).
        TEST    BYTE PTR [PSR],CF
        JZ      POIS14 ; Don't branch if C is not set.
        CBW            ; Sign extend displacement in AL.
        SAL     AX,1  ; And multiply it with 2.
        ADD     WORD PTR [PC_LOC],AX ; Add to PC.
POIS14:
        RET
;
; /* ====================================================================== */
;
EMT11:
        TRAP    EMTVEC
        RET
;
TRAP11:
        TRAP    TRAPVEC
        RET
;
;
; /* ====================================================================== */
;                 VARIABLES AND ARRAYS KEPT IN CODE SEGMENT
;
NOLIMFLAG DB    0               ; If this is zero then execution is
;                                  not stopped even if INSCNT comes to zero.
CTRLCFLAG DB    0               ; 1 if CTRL-C pressed.
        EVEN                    ; Align the following stuff at word boundary.
;
PC_LIM_BPT DW  0FFFFh           ; Default Value of PC Limit Breakpoint.
;
INSCNT  DW      0               ; Doubleword counter of executed instructions.
        DW      0               ;  (for debugger statistics).
;
SP_SAVE DW      0               ; Saving location for SP of i*86.
;
MODETAB DW      OFFSET MODE0, OFFSET MODE1, OFFSET MODE2, OFFSET MODE3
        DW      OFFSET MODE4, OFFSET MODE5, OFFSET MODE6, OFFSET MODE7
;
INS0TAB LABEL WORD
        DW      OFFSET HALT11   ;  0  Halt
        DW      OFFSET WAIT11   ;  1  Wait
        DW      OFFSET RTI11    ;  2  Return from interrupt
        DW      OFFSET BPT11    ;  3  Breakpoint trap.
        DW      OFFSET IOT11    ;  4  Input/Output trap.
        DW      OFFSET RESET11  ;  5  Reset external bus.
        DW      OFFSET RTT11    ;  6  Return from trap.
        DW      OFFSET MFPT11   ;  7  Move From Processor Type.
; INS0CNT EQU     (($ - (OFFSET INS0TAB))/2) ; Fuck this!
;
;
INS2TAB LABEL WORD
        DW      OFFSET RTS11       ;  20R  Return from Subroutine.
        DW      OFFSET NEOP        ;  210 -
        DW      OFFSET NEOP        ;  227  = NEOP
        DW      OFFSET SPL11       ;  23N  ???
        DW      OFFSET Clear_Codes ;  240 -
        DW      OFFSET Clear_Codes ;  257 = Clear Condition Codes.
        DW      OFFSET Set_Codes   ;  260 -
        DW      OFFSET Set_Codes   ;  277 = Set Condition Codes.
INS2CNT EQU     ($ - (OFFSET INS2TAB))
;
        include instrtab.asm
;
        include flagtabs.asm
;
; Make (most of the) labels public, so that we can see them in debugger:
        include pubtab.asm
;
;CSEG   ENDS
;
;
        finish
        END 
