;
; Coded by Antti Karttunen at 1990.
; Version for Aztec-C assembler: (19th May)
;
        include  lmacros.h
;
; ***************************************************************************
;
; Equates:
;
CTRL       EQU  -64             ; E.g. CTRL+'A' = -64 + 65 = 65-64 = 1;
;
BS         EQU  08h             ; BackSpace
TAB	   EQU	09H		; Tab
LF	   EQU	0AH		; Line feed
CR	   EQU	0DH		; Carriage return
ESC_       EQU  1BH             ; Escape
BLANKO     EQU  20H             ; Blanko
DEL        EQU  7Fh             ; Delete character.
;
;
;
; ***************************************************************************
;
;CSEG	SEGMENT PARA PUBLIC 'CODE'
;	ASSUME	CS:CSEG
;
; /* Reads max characters to buf, and echoes echochar to screen for
;     every character read in. If echochar is 0 then nothing is echoed,
;     and if it is 0xFF, then characters read in are echoed back.
;    Doesn't fill more than n characters to buf, but doesn't stop
;     reading until some control character is pressed (usually CR).
;    Then final zero is put to buf, and that control char (which is NOT
;     put to that buf) is returned as result in AX.
;    Note that buf must be defined to be one bigger than max, so that
;     end zero fits in too.
;
;    Supports also:
;     DEL and BS (backspace = ^H)  delete last typed character from buf.
;     ESC and ^X                   wipe the whole buffer.
;
;    Future prospects: Some F3-like system ???
;
;  */
; int get_n_chars(buf,max,echochar)
; char *buf;
; int  max;
; int  echochar;
;
        procdef get_n_chars,<<buf,ptr>,<max,word>,<echochar,byte>>
        PUSH    DI
        pushds
        ldptr   BX,buf,DS       ; Get address of buffer.
        MOV     CX,max          ; Get max count.
        XOR     DI,DI           ; Zero index to buf.
LOOP96:
        MOV     DL,echochar     ; Get echochar.
        MOV     AH,7            ; Direct console input without echo
        INT     21h
        TEST    AL,AL           ; If 0, then it is extended code...
        JNZ     VEIJO
        INT     21h             ; ...so get second part
        OR      AL,80h          ; and set bit-7.
VEIJO:
        CMP     AL,BS           ; If backspace or del...
        JE      DELCHAR
        CMP     AL,DEL
        JNE     MERSU
DELCHAR:
        TEST    DI,DI           ; Don't try to delete char. if index is zero.
        JZ      LOOP96
        DEC     DI              ; "Delete" one char from buf.
        CALL    IS_NPRINT       ; Don't try to delete character from screen,
        JZ      LOOP96		;  if nothing has been echoed.
        CALL    DELCHR
        JMP     SHORT LOOP96
MERSU:
        CMP     AL,ESC_         ; If Esc or ^X then delete the whole buffer.
        JE      ESC_LOOP
        CMP     AL,CTRL+'X'
        JNE     PEPSI
ESC_LOOP:
        TEST    DI,DI           ; Stop when at beginning
        JZ      LOOP96          ;   of buffer.
        DEC     DI              ; "Delete" one char from buf.
        CALL    IS_NPRINT       ; Don't try to delete character from screen,
        JZ      ESC_LOOP        ;  if nothing has been echoed.
        CALL    DELCHR
        JMP     SHORT ESC_LOOP
PEPSI:
;       CMP     AL,TAB             ; (Don't understand TAB as control char).
;       JE      MARSU              ; Commented out. TAB is also ctrl char (^I)
        CMP     AL,BLANKO          ; Stop reading if any other control char.
        JB      ULOS
MARSU:
        CMP     DI,CX              ; If index >= max, then buf
        JAE     LOOP96             ;  is full, don't fill nor echo anymore.
        MOV     [BX+DI],AL         ; Otherwise put to buf.
        INC     DI                 ; And increment index.
        TEST    DL,DL              ; If echochar is zero,
        JZ      LOOP96             ;  then echo nothing.
        CMP     DL,0FFh            ; If echochar is FF, then...
        JNE     LELU
        MOV     DL,AL              ; ...echo character just read.
LELU:
        MOV     AH,06           ; Direct console I/O, output DL
        INT     21h
        JMP     SHORT LOOP96
ULOS:
        MOV     BYTE PTR [BX+DI],0 ; Put terminator zero to string.
        XOR     AH,AH           ; Zero high byte of AX. (AL = last read char).
        popds
        POP     DI
        pret
        pend    get_n_chars
;
;
; This is auxiliary funtion for GET_N_CHARS:
; Returns ZF=1 if DL is BELL or '\0', otherwise ZF=0.
IS_NPRINT PROC ;Is DL Non-printable character ? (i.e. nothing comes to screen)
        CMP     DL,CTRL+'G'     ; Bell should just beep,
        JZ      TUBORG          ;  and not excrete any stuff to screen.
        TEST    DL,DL
TUBORG:
        RET
IS_NPRINT ENDP
;
DELCHR  PROC
        PUSH    AX
        PUSH    DX
        MOV     AH,2
        MOV     DL,BS
        INT     21h
        MOV     DL,BLANKO
        INT     21h
        MOV     DL,BS
        INT     21h
        POP     DX
        POP     AX
        RET
DELCHR  ENDP
;
;
        finish
        END 
