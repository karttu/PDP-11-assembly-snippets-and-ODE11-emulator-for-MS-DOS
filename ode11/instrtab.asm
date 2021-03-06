;
; Written by Antti Karttunen at May 1990.
;
; Here is the main jump table which contains corresponding emulating routines
;  for all instructions in PDP-11. Table is indexed by ten most significant
;  bits (15-6) of the fetched instruction (shifted left once of course).
; Note that codes 0000??, 0002?? and 0750?? (= FIS-instructions) are the only
;  cases where further bit-fiddling is needed to resolve the opcode.
;  NEOP stands for "Non-Existent Operation", i.e. illegal instruction.
; Of course there is little redundancy in some places, e.g. all normal
;  two-operand instructions (MOV,CMP,ADD, etc.) are 64 times in this table,
;  but I have sacrificed memory space for the execution time.
;  (Size of this table: 2*1024 = 2048 bytes).
;
INSTRTAB LABEL WORD
	DW OFFSET INSTR0         ; 0000?? HALT,WAIT,RTI,BPT,IOT,RESET,RTT,MFPT
	DW OFFSET JMP11          ; 0001??
	DW OFFSET INSTR2         ; 0002?? RTS, SPL, Clear/Set condition codes.
	DW OFFSET SWAB11         ; 0003??
	DW OFFSET BR11           ; 0004??
	DW OFFSET BR11           ; 0005??
	DW OFFSET BR11           ; 0006??
	DW OFFSET BR11           ; 0007??
	DW OFFSET BNE11          ; 0010??
	DW OFFSET BNE11          ; 0011??
	DW OFFSET BNE11          ; 0012??
	DW OFFSET BNE11          ; 0013??
	DW OFFSET BEQ11          ; 0014??
	DW OFFSET BEQ11          ; 0015??
	DW OFFSET BEQ11          ; 0016??
	DW OFFSET BEQ11          ; 0017??
	DW OFFSET BGE11          ; 0020??
	DW OFFSET BGE11          ; 0021??
	DW OFFSET BGE11          ; 0022??
	DW OFFSET BGE11          ; 0023??
	DW OFFSET BLT11          ; 0024??
	DW OFFSET BLT11          ; 0025??
	DW OFFSET BLT11          ; 0026??
	DW OFFSET BLT11          ; 0027??
	DW OFFSET BGT11          ; 0030??
	DW OFFSET BGT11          ; 0031??
	DW OFFSET BGT11          ; 0032??
	DW OFFSET BGT11          ; 0033??
	DW OFFSET BLE11          ; 0034??
	DW OFFSET BLE11          ; 0035??
	DW OFFSET BLE11          ; 0036??
	DW OFFSET BLE11          ; 0037??
	DW OFFSET JSR11          ; 0040??
	DW OFFSET JSR11          ; 0041??
	DW OFFSET JSR11          ; 0042??
	DW OFFSET JSR11          ; 0043??
	DW OFFSET JSR11          ; 0044??
	DW OFFSET JSR11          ; 0045??
	DW OFFSET JSR11          ; 0046??
	DW OFFSET JSR11          ; 0047??
	DW OFFSET CLR11          ; 0050??
	DW OFFSET COM11          ; 0051??
	DW OFFSET INC11          ; 0052??
	DW OFFSET DEC11          ; 0053??
	DW OFFSET NEG11          ; 0054??
	DW OFFSET ADC11          ; 0055??
	DW OFFSET SBC11          ; 0056??
	DW OFFSET TST11          ; 0057??
	DW OFFSET ROR11          ; 0060??
	DW OFFSET ROL11          ; 0061??
	DW OFFSET ASR11          ; 0062??
	DW OFFSET ASL11          ; 0063??
	DW OFFSET MARK11         ; 0064??
	DW OFFSET MFPI11         ; 0065??
	DW OFFSET MTPI11         ; 0066??
	DW OFFSET SXT11          ; 0067??
	DW OFFSET CSM11          ; 0070??
	DW OFFSET NEOP           ; 0071??
	DW OFFSET NEOP           ; 0072??
	DW OFFSET NEOP           ; 0073??
	DW OFFSET NEOP           ; 0074??
	DW OFFSET NEOP           ; 0075??
	DW OFFSET NEOP           ; 0076??
	DW OFFSET NEOP           ; 0077??
	DW OFFSET MOV11          ; 0100??
	DW OFFSET MOV11          ; 0101??
	DW OFFSET MOV11          ; 0102??
	DW OFFSET MOV11          ; 0103??
	DW OFFSET MOV11          ; 0104??
	DW OFFSET MOV11          ; 0105??
	DW OFFSET MOV11          ; 0106??
	DW OFFSET MOV11          ; 0107??
	DW OFFSET MOV11          ; 0110??
	DW OFFSET MOV11          ; 0111??
	DW OFFSET MOV11          ; 0112??
	DW OFFSET MOV11          ; 0113??
	DW OFFSET MOV11          ; 0114??
	DW OFFSET MOV11          ; 0115??
	DW OFFSET MOV11          ; 0116??
	DW OFFSET MOV11          ; 0117??
	DW OFFSET MOV11          ; 0120??
	DW OFFSET MOV11          ; 0121??
	DW OFFSET MOV11          ; 0122??
	DW OFFSET MOV11          ; 0123??
	DW OFFSET MOV11          ; 0124??
	DW OFFSET MOV11          ; 0125??
	DW OFFSET MOV11          ; 0126??
	DW OFFSET MOV11          ; 0127??
	DW OFFSET MOV11          ; 0130??
	DW OFFSET MOV11          ; 0131??
	DW OFFSET MOV11          ; 0132??
	DW OFFSET MOV11          ; 0133??
	DW OFFSET MOV11          ; 0134??
	DW OFFSET MOV11          ; 0135??
	DW OFFSET MOV11          ; 0136??
	DW OFFSET MOV11          ; 0137??
	DW OFFSET MOV11          ; 0140??
	DW OFFSET MOV11          ; 0141??
	DW OFFSET MOV11          ; 0142??
	DW OFFSET MOV11          ; 0143??
	DW OFFSET MOV11          ; 0144??
	DW OFFSET MOV11          ; 0145??
	DW OFFSET MOV11          ; 0146??
	DW OFFSET MOV11          ; 0147??
	DW OFFSET MOV11          ; 0150??
	DW OFFSET MOV11          ; 0151??
	DW OFFSET MOV11          ; 0152??
	DW OFFSET MOV11          ; 0153??
	DW OFFSET MOV11          ; 0154??
	DW OFFSET MOV11          ; 0155??
	DW OFFSET MOV11          ; 0156??
	DW OFFSET MOV11          ; 0157??
	DW OFFSET MOV11          ; 0160??
	DW OFFSET MOV11          ; 0161??
	DW OFFSET MOV11          ; 0162??
	DW OFFSET MOV11          ; 0163??
	DW OFFSET MOV11          ; 0164??
	DW OFFSET MOV11          ; 0165??
	DW OFFSET MOV11          ; 0166??
	DW OFFSET MOV11          ; 0167??
	DW OFFSET MOV11          ; 0170??
	DW OFFSET MOV11          ; 0171??
	DW OFFSET MOV11          ; 0172??
	DW OFFSET MOV11          ; 0173??
	DW OFFSET MOV11          ; 0174??
	DW OFFSET MOV11          ; 0175??
	DW OFFSET MOV11          ; 0176??
	DW OFFSET MOV11          ; 0177??
	DW OFFSET CMP11          ; 0200??
	DW OFFSET CMP11          ; 0201??
	DW OFFSET CMP11          ; 0202??
	DW OFFSET CMP11          ; 0203??
	DW OFFSET CMP11          ; 0204??
	DW OFFSET CMP11          ; 0205??
	DW OFFSET CMP11          ; 0206??
	DW OFFSET CMP11          ; 0207??
	DW OFFSET CMP11          ; 0210??
	DW OFFSET CMP11          ; 0211??
	DW OFFSET CMP11          ; 0212??
	DW OFFSET CMP11          ; 0213??
	DW OFFSET CMP11          ; 0214??
	DW OFFSET CMP11          ; 0215??
	DW OFFSET CMP11          ; 0216??
	DW OFFSET CMP11          ; 0217??
	DW OFFSET CMP11          ; 0220??
	DW OFFSET CMP11          ; 0221??
	DW OFFSET CMP11          ; 0222??
	DW OFFSET CMP11          ; 0223??
	DW OFFSET CMP11          ; 0224??
	DW OFFSET CMP11          ; 0225??
	DW OFFSET CMP11          ; 0226??
	DW OFFSET CMP11          ; 0227??
	DW OFFSET CMP11          ; 0230??
	DW OFFSET CMP11          ; 0231??
	DW OFFSET CMP11          ; 0232??
	DW OFFSET CMP11          ; 0233??
	DW OFFSET CMP11          ; 0234??
	DW OFFSET CMP11          ; 0235??
	DW OFFSET CMP11          ; 0236??
	DW OFFSET CMP11          ; 0237??
	DW OFFSET CMP11          ; 0240??
	DW OFFSET CMP11          ; 0241??
	DW OFFSET CMP11          ; 0242??
	DW OFFSET CMP11          ; 0243??
	DW OFFSET CMP11          ; 0244??
	DW OFFSET CMP11          ; 0245??
	DW OFFSET CMP11          ; 0246??
	DW OFFSET CMP11          ; 0247??
	DW OFFSET CMP11          ; 0250??
	DW OFFSET CMP11          ; 0251??
	DW OFFSET CMP11          ; 0252??
	DW OFFSET CMP11          ; 0253??
	DW OFFSET CMP11          ; 0254??
	DW OFFSET CMP11          ; 0255??
	DW OFFSET CMP11          ; 0256??
	DW OFFSET CMP11          ; 0257??
	DW OFFSET CMP11          ; 0260??
	DW OFFSET CMP11          ; 0261??
	DW OFFSET CMP11          ; 0262??
	DW OFFSET CMP11          ; 0263??
	DW OFFSET CMP11          ; 0264??
	DW OFFSET CMP11          ; 0265??
	DW OFFSET CMP11          ; 0266??
	DW OFFSET CMP11          ; 0267??
	DW OFFSET CMP11          ; 0270??
	DW OFFSET CMP11          ; 0271??
	DW OFFSET CMP11          ; 0272??
	DW OFFSET CMP11          ; 0273??
	DW OFFSET CMP11          ; 0274??
	DW OFFSET CMP11          ; 0275??
	DW OFFSET CMP11          ; 0276??
	DW OFFSET CMP11          ; 0277??
	DW OFFSET BIT11          ; 0300??
	DW OFFSET BIT11          ; 0301??
	DW OFFSET BIT11          ; 0302??
	DW OFFSET BIT11          ; 0303??
	DW OFFSET BIT11          ; 0304??
	DW OFFSET BIT11          ; 0305??
	DW OFFSET BIT11          ; 0306??
	DW OFFSET BIT11          ; 0307??
	DW OFFSET BIT11          ; 0310??
	DW OFFSET BIT11          ; 0311??
	DW OFFSET BIT11          ; 0312??
	DW OFFSET BIT11          ; 0313??
	DW OFFSET BIT11          ; 0314??
	DW OFFSET BIT11          ; 0315??
	DW OFFSET BIT11          ; 0316??
	DW OFFSET BIT11          ; 0317??
	DW OFFSET BIT11          ; 0320??
	DW OFFSET BIT11          ; 0321??
	DW OFFSET BIT11          ; 0322??
	DW OFFSET BIT11          ; 0323??
	DW OFFSET BIT11          ; 0324??
	DW OFFSET BIT11          ; 0325??
	DW OFFSET BIT11          ; 0326??
	DW OFFSET BIT11          ; 0327??
	DW OFFSET BIT11          ; 0330??
	DW OFFSET BIT11          ; 0331??
	DW OFFSET BIT11          ; 0332??
	DW OFFSET BIT11          ; 0333??
	DW OFFSET BIT11          ; 0334??
	DW OFFSET BIT11          ; 0335??
	DW OFFSET BIT11          ; 0336??
	DW OFFSET BIT11          ; 0337??
	DW OFFSET BIT11          ; 0340??
	DW OFFSET BIT11          ; 0341??
	DW OFFSET BIT11          ; 0342??
	DW OFFSET BIT11          ; 0343??
	DW OFFSET BIT11          ; 0344??
	DW OFFSET BIT11          ; 0345??
	DW OFFSET BIT11          ; 0346??
	DW OFFSET BIT11          ; 0347??
	DW OFFSET BIT11          ; 0350??
	DW OFFSET BIT11          ; 0351??
	DW OFFSET BIT11          ; 0352??
	DW OFFSET BIT11          ; 0353??
	DW OFFSET BIT11          ; 0354??
	DW OFFSET BIT11          ; 0355??
	DW OFFSET BIT11          ; 0356??
	DW OFFSET BIT11          ; 0357??
	DW OFFSET BIT11          ; 0360??
	DW OFFSET BIT11          ; 0361??
	DW OFFSET BIT11          ; 0362??
	DW OFFSET BIT11          ; 0363??
	DW OFFSET BIT11          ; 0364??
	DW OFFSET BIT11          ; 0365??
	DW OFFSET BIT11          ; 0366??
	DW OFFSET BIT11          ; 0367??
	DW OFFSET BIT11          ; 0370??
	DW OFFSET BIT11          ; 0371??
	DW OFFSET BIT11          ; 0372??
	DW OFFSET BIT11          ; 0373??
	DW OFFSET BIT11          ; 0374??
	DW OFFSET BIT11          ; 0375??
	DW OFFSET BIT11          ; 0376??
	DW OFFSET BIT11          ; 0377??
	DW OFFSET BIC11          ; 0400??
	DW OFFSET BIC11          ; 0401??
	DW OFFSET BIC11          ; 0402??
	DW OFFSET BIC11          ; 0403??
	DW OFFSET BIC11          ; 0404??
	DW OFFSET BIC11          ; 0405??
	DW OFFSET BIC11          ; 0406??
	DW OFFSET BIC11          ; 0407??
	DW OFFSET BIC11          ; 0410??
	DW OFFSET BIC11          ; 0411??
	DW OFFSET BIC11          ; 0412??
	DW OFFSET BIC11          ; 0413??
	DW OFFSET BIC11          ; 0414??
	DW OFFSET BIC11          ; 0415??
	DW OFFSET BIC11          ; 0416??
	DW OFFSET BIC11          ; 0417??
	DW OFFSET BIC11          ; 0420??
	DW OFFSET BIC11          ; 0421??
	DW OFFSET BIC11          ; 0422??
	DW OFFSET BIC11          ; 0423??
	DW OFFSET BIC11          ; 0424??
	DW OFFSET BIC11          ; 0425??
	DW OFFSET BIC11          ; 0426??
	DW OFFSET BIC11          ; 0427??
	DW OFFSET BIC11          ; 0430??
	DW OFFSET BIC11          ; 0431??
	DW OFFSET BIC11          ; 0432??
	DW OFFSET BIC11          ; 0433??
	DW OFFSET BIC11          ; 0434??
	DW OFFSET BIC11          ; 0435??
	DW OFFSET BIC11          ; 0436??
	DW OFFSET BIC11          ; 0437??
	DW OFFSET BIC11          ; 0440??
	DW OFFSET BIC11          ; 0441??
	DW OFFSET BIC11          ; 0442??
	DW OFFSET BIC11          ; 0443??
	DW OFFSET BIC11          ; 0444??
	DW OFFSET BIC11          ; 0445??
	DW OFFSET BIC11          ; 0446??
	DW OFFSET BIC11          ; 0447??
	DW OFFSET BIC11          ; 0450??
	DW OFFSET BIC11          ; 0451??
	DW OFFSET BIC11          ; 0452??
	DW OFFSET BIC11          ; 0453??
	DW OFFSET BIC11          ; 0454??
	DW OFFSET BIC11          ; 0455??
	DW OFFSET BIC11          ; 0456??
	DW OFFSET BIC11          ; 0457??
	DW OFFSET BIC11          ; 0460??
	DW OFFSET BIC11          ; 0461??
	DW OFFSET BIC11          ; 0462??
	DW OFFSET BIC11          ; 0463??
	DW OFFSET BIC11          ; 0464??
	DW OFFSET BIC11          ; 0465??
	DW OFFSET BIC11          ; 0466??
	DW OFFSET BIC11          ; 0467??
	DW OFFSET BIC11          ; 0470??
	DW OFFSET BIC11          ; 0471??
	DW OFFSET BIC11          ; 0472??
	DW OFFSET BIC11          ; 0473??
	DW OFFSET BIC11          ; 0474??
	DW OFFSET BIC11          ; 0475??
	DW OFFSET BIC11          ; 0476??
	DW OFFSET BIC11          ; 0477??
	DW OFFSET BIS11          ; 0500??
	DW OFFSET BIS11          ; 0501??
	DW OFFSET BIS11          ; 0502??
	DW OFFSET BIS11          ; 0503??
	DW OFFSET BIS11          ; 0504??
	DW OFFSET BIS11          ; 0505??
	DW OFFSET BIS11          ; 0506??
	DW OFFSET BIS11          ; 0507??
	DW OFFSET BIS11          ; 0510??
	DW OFFSET BIS11          ; 0511??
	DW OFFSET BIS11          ; 0512??
	DW OFFSET BIS11          ; 0513??
	DW OFFSET BIS11          ; 0514??
	DW OFFSET BIS11          ; 0515??
	DW OFFSET BIS11          ; 0516??
	DW OFFSET BIS11          ; 0517??
	DW OFFSET BIS11          ; 0520??
	DW OFFSET BIS11          ; 0521??
	DW OFFSET BIS11          ; 0522??
	DW OFFSET BIS11          ; 0523??
	DW OFFSET BIS11          ; 0524??
	DW OFFSET BIS11          ; 0525??
	DW OFFSET BIS11          ; 0526??
	DW OFFSET BIS11          ; 0527??
	DW OFFSET BIS11          ; 0530??
	DW OFFSET BIS11          ; 0531??
	DW OFFSET BIS11          ; 0532??
	DW OFFSET BIS11          ; 0533??
	DW OFFSET BIS11          ; 0534??
	DW OFFSET BIS11          ; 0535??
	DW OFFSET BIS11          ; 0536??
	DW OFFSET BIS11          ; 0537??
	DW OFFSET BIS11          ; 0540??
	DW OFFSET BIS11          ; 0541??
	DW OFFSET BIS11          ; 0542??
	DW OFFSET BIS11          ; 0543??
	DW OFFSET BIS11          ; 0544??
	DW OFFSET BIS11          ; 0545??
	DW OFFSET BIS11          ; 0546??
	DW OFFSET BIS11          ; 0547??
	DW OFFSET BIS11          ; 0550??
	DW OFFSET BIS11          ; 0551??
	DW OFFSET BIS11          ; 0552??
	DW OFFSET BIS11          ; 0553??
	DW OFFSET BIS11          ; 0554??
	DW OFFSET BIS11          ; 0555??
	DW OFFSET BIS11          ; 0556??
	DW OFFSET BIS11          ; 0557??
	DW OFFSET BIS11          ; 0560??
	DW OFFSET BIS11          ; 0561??
	DW OFFSET BIS11          ; 0562??
	DW OFFSET BIS11          ; 0563??
	DW OFFSET BIS11          ; 0564??
	DW OFFSET BIS11          ; 0565??
	DW OFFSET BIS11          ; 0566??
	DW OFFSET BIS11          ; 0567??
	DW OFFSET BIS11          ; 0570??
	DW OFFSET BIS11          ; 0571??
	DW OFFSET BIS11          ; 0572??
	DW OFFSET BIS11          ; 0573??
	DW OFFSET BIS11          ; 0574??
	DW OFFSET BIS11          ; 0575??
	DW OFFSET BIS11          ; 0576??
	DW OFFSET BIS11          ; 0577??
	DW OFFSET ADD11          ; 0600??
	DW OFFSET ADD11          ; 0601??
	DW OFFSET ADD11          ; 0602??
	DW OFFSET ADD11          ; 0603??
	DW OFFSET ADD11          ; 0604??
	DW OFFSET ADD11          ; 0605??
	DW OFFSET ADD11          ; 0606??
	DW OFFSET ADD11          ; 0607??
	DW OFFSET ADD11          ; 0610??
	DW OFFSET ADD11          ; 0611??
	DW OFFSET ADD11          ; 0612??
	DW OFFSET ADD11          ; 0613??
	DW OFFSET ADD11          ; 0614??
	DW OFFSET ADD11          ; 0615??
	DW OFFSET ADD11          ; 0616??
	DW OFFSET ADD11          ; 0617??
	DW OFFSET ADD11          ; 0620??
	DW OFFSET ADD11          ; 0621??
	DW OFFSET ADD11          ; 0622??
	DW OFFSET ADD11          ; 0623??
	DW OFFSET ADD11          ; 0624??
	DW OFFSET ADD11          ; 0625??
	DW OFFSET ADD11          ; 0626??
	DW OFFSET ADD11          ; 0627??
	DW OFFSET ADD11          ; 0630??
	DW OFFSET ADD11          ; 0631??
	DW OFFSET ADD11          ; 0632??
	DW OFFSET ADD11          ; 0633??
	DW OFFSET ADD11          ; 0634??
	DW OFFSET ADD11          ; 0635??
	DW OFFSET ADD11          ; 0636??
	DW OFFSET ADD11          ; 0637??
	DW OFFSET ADD11          ; 0640??
	DW OFFSET ADD11          ; 0641??
	DW OFFSET ADD11          ; 0642??
	DW OFFSET ADD11          ; 0643??
	DW OFFSET ADD11          ; 0644??
	DW OFFSET ADD11          ; 0645??
	DW OFFSET ADD11          ; 0646??
	DW OFFSET ADD11          ; 0647??
	DW OFFSET ADD11          ; 0650??
	DW OFFSET ADD11          ; 0651??
	DW OFFSET ADD11          ; 0652??
	DW OFFSET ADD11          ; 0653??
	DW OFFSET ADD11          ; 0654??
	DW OFFSET ADD11          ; 0655??
	DW OFFSET ADD11          ; 0656??
	DW OFFSET ADD11          ; 0657??
	DW OFFSET ADD11          ; 0660??
	DW OFFSET ADD11          ; 0661??
	DW OFFSET ADD11          ; 0662??
	DW OFFSET ADD11          ; 0663??
	DW OFFSET ADD11          ; 0664??
	DW OFFSET ADD11          ; 0665??
	DW OFFSET ADD11          ; 0666??
	DW OFFSET ADD11          ; 0667??
	DW OFFSET ADD11          ; 0670??
	DW OFFSET ADD11          ; 0671??
	DW OFFSET ADD11          ; 0672??
	DW OFFSET ADD11          ; 0673??
	DW OFFSET ADD11          ; 0674??
	DW OFFSET ADD11          ; 0675??
	DW OFFSET ADD11          ; 0676??
	DW OFFSET ADD11          ; 0677??
	DW OFFSET MUL11EVEN      ; 0700??  Multiple with even register.
	DW OFFSET MUL11ODD       ; 0701??  Multiple with odd register.
	DW OFFSET MUL11EVEN      ; 0702??
	DW OFFSET MUL11ODD       ; 0703??
	DW OFFSET MUL11EVEN      ; 0704??
	DW OFFSET MUL11ODD       ; 0705??
	DW OFFSET MUL11EVEN      ; 0706??  Multiple with SP+PC (These are not)
	DW OFFSET MUL11ODD       ; 0707??  Multiple with PC    (very sensible)
	DW OFFSET DIV11          ; 0710??
	DW OFFSET DIV11          ; 0711??
	DW OFFSET DIV11          ; 0712??
	DW OFFSET DIV11          ; 0713??
	DW OFFSET DIV11          ; 0714??
	DW OFFSET DIV11          ; 0715??
	DW OFFSET DIV11          ; 0716??
	DW OFFSET DIV11          ; 0717??
	DW OFFSET ASH11          ; 0720??
	DW OFFSET ASH11          ; 0721??
	DW OFFSET ASH11          ; 0722??
	DW OFFSET ASH11          ; 0723??
	DW OFFSET ASH11          ; 0724??
	DW OFFSET ASH11          ; 0725??
	DW OFFSET ASH11          ; 0726??
	DW OFFSET ASH11          ; 0727??
	DW OFFSET ASHC11EVEN     ; 0730??
	DW OFFSET ASHC11ODD      ; 0731??
	DW OFFSET ASHC11EVEN     ; 0732??
	DW OFFSET ASHC11ODD      ; 0733??
	DW OFFSET ASHC11EVEN     ; 0734??
	DW OFFSET ASHC11ODD      ; 0735??
	DW OFFSET ASHC11EVEN     ; 0736??
	DW OFFSET ASHC11ODD      ; 0737??
	DW OFFSET XOR11          ; 0740??
	DW OFFSET XOR11          ; 0741??
	DW OFFSET XOR11          ; 0742??
	DW OFFSET XOR11          ; 0743??
	DW OFFSET XOR11          ; 0744??
	DW OFFSET XOR11          ; 0745??
	DW OFFSET XOR11          ; 0746??
	DW OFFSET XOR11          ; 0747??
	DW OFFSET NEOP ; FISUTAB        ; 0750?? FADD, FSUB, FMUL, FDIV
	DW OFFSET NEOP           ; 0751??
	DW OFFSET NEOP           ; 0752??
	DW OFFSET NEOP           ; 0753??
	DW OFFSET NEOP           ; 0754??
	DW OFFSET NEOP           ; 0755??
	DW OFFSET NEOP           ; 0756??
	DW OFFSET NEOP           ; 0757??
	DW OFFSET NEOP           ; 0760??
	DW OFFSET NEOP           ; 0761??
	DW OFFSET NEOP           ; 0762??
	DW OFFSET NEOP           ; 0763??
	DW OFFSET NEOP           ; 0764??
	DW OFFSET NEOP           ; 0765??
	DW OFFSET NEOP           ; 0766??
	DW OFFSET NEOP           ; 0767??
	DW OFFSET SOB11          ; 0770??
	DW OFFSET SOB11          ; 0771??
	DW OFFSET SOB11          ; 0772??
	DW OFFSET SOB11          ; 0773??
	DW OFFSET SOB11          ; 0774??
	DW OFFSET SOB11          ; 0775??
	DW OFFSET SOB11          ; 0776??
	DW OFFSET SOB11          ; 0777??
	DW OFFSET BPL11          ; 1000??
	DW OFFSET BPL11          ; 1001??
	DW OFFSET BPL11          ; 1002??
	DW OFFSET BPL11          ; 1003??
	DW OFFSET BMI11          ; 1004??
	DW OFFSET BMI11          ; 1005??
	DW OFFSET BMI11          ; 1006??
	DW OFFSET BMI11          ; 1007??
	DW OFFSET BHI11          ; 1010??
	DW OFFSET BHI11          ; 1011??
	DW OFFSET BHI11          ; 1012??
	DW OFFSET BHI11          ; 1013??
	DW OFFSET BLOS11         ; 1014??
	DW OFFSET BLOS11         ; 1015??
	DW OFFSET BLOS11         ; 1016??
	DW OFFSET BLOS11         ; 1017??
	DW OFFSET BVC11          ; 1020??
	DW OFFSET BVC11          ; 1021??
	DW OFFSET BVC11          ; 1022??
	DW OFFSET BVC11          ; 1023??
	DW OFFSET BVS11          ; 1024??
	DW OFFSET BVS11          ; 1025??
	DW OFFSET BVS11          ; 1026??
	DW OFFSET BVS11          ; 1027??
	DW OFFSET BCC11          ; 1030??
	DW OFFSET BCC11          ; 1031??
	DW OFFSET BCC11          ; 1032??
	DW OFFSET BCC11          ; 1033??
	DW OFFSET BCS11          ; 1034??
	DW OFFSET BCS11          ; 1035??
	DW OFFSET BCS11          ; 1036??
	DW OFFSET BCS11          ; 1037??
	DW OFFSET EMT11          ; 1040??
	DW OFFSET EMT11          ; 1041??
	DW OFFSET EMT11          ; 1042??
	DW OFFSET EMT11          ; 1043??
	DW OFFSET TRAP11         ; 1044??
	DW OFFSET TRAP11         ; 1045??
	DW OFFSET TRAP11         ; 1046??
	DW OFFSET TRAP11         ; 1047??
	DW OFFSET CLRB11         ; 1050??
	DW OFFSET COMB11         ; 1051??
	DW OFFSET INCB11         ; 1052??
	DW OFFSET DECB11         ; 1053??
	DW OFFSET NEGB11         ; 1054??
	DW OFFSET ADCB11         ; 1055??
	DW OFFSET SBCB11         ; 1056??
	DW OFFSET TSTB11         ; 1057??
	DW OFFSET RORB11         ; 1060??
	DW OFFSET ROLB11         ; 1061??
	DW OFFSET ASRB11         ; 1062??
	DW OFFSET ASLB11         ; 1063??
	DW OFFSET MTPS11         ; 1064??
	DW OFFSET MFPD11         ; 1065??
	DW OFFSET MTPD11         ; 1066??
	DW OFFSET MFPS11         ; 1067??
	DW OFFSET NEOP           ; 1070??
	DW OFFSET NEOP           ; 1071??
	DW OFFSET NEOP           ; 1072??
	DW OFFSET NEOP           ; 1073??
	DW OFFSET NEOP           ; 1074??
	DW OFFSET NEOP           ; 1075??
	DW OFFSET NEOP           ; 1076??
	DW OFFSET NEOP           ; 1077??
	DW OFFSET MOVB11         ; 1100??
	DW OFFSET MOVB11         ; 1101??
	DW OFFSET MOVB11         ; 1102??
	DW OFFSET MOVB11         ; 1103??
	DW OFFSET MOVB11         ; 1104??
	DW OFFSET MOVB11         ; 1105??
	DW OFFSET MOVB11         ; 1106??
	DW OFFSET MOVB11         ; 1107??
	DW OFFSET MOVB11         ; 1110??
	DW OFFSET MOVB11         ; 1111??
	DW OFFSET MOVB11         ; 1112??
	DW OFFSET MOVB11         ; 1113??
	DW OFFSET MOVB11         ; 1114??
	DW OFFSET MOVB11         ; 1115??
	DW OFFSET MOVB11         ; 1116??
	DW OFFSET MOVB11         ; 1117??
	DW OFFSET MOVB11         ; 1120??
	DW OFFSET MOVB11         ; 1121??
	DW OFFSET MOVB11         ; 1122??
	DW OFFSET MOVB11         ; 1123??
	DW OFFSET MOVB11         ; 1124??
	DW OFFSET MOVB11         ; 1125??
	DW OFFSET MOVB11         ; 1126??
	DW OFFSET MOVB11         ; 1127??
	DW OFFSET MOVB11         ; 1130??
	DW OFFSET MOVB11         ; 1131??
	DW OFFSET MOVB11         ; 1132??
	DW OFFSET MOVB11         ; 1133??
	DW OFFSET MOVB11         ; 1134??
	DW OFFSET MOVB11         ; 1135??
	DW OFFSET MOVB11         ; 1136??
	DW OFFSET MOVB11         ; 1137??
	DW OFFSET MOVB11         ; 1140??
	DW OFFSET MOVB11         ; 1141??
	DW OFFSET MOVB11         ; 1142??
	DW OFFSET MOVB11         ; 1143??
	DW OFFSET MOVB11         ; 1144??
	DW OFFSET MOVB11         ; 1145??
	DW OFFSET MOVB11         ; 1146??
	DW OFFSET MOVB11         ; 1147??
	DW OFFSET MOVB11         ; 1150??
	DW OFFSET MOVB11         ; 1151??
	DW OFFSET MOVB11         ; 1152??
	DW OFFSET MOVB11         ; 1153??
	DW OFFSET MOVB11         ; 1154??
	DW OFFSET MOVB11         ; 1155??
	DW OFFSET MOVB11         ; 1156??
	DW OFFSET MOVB11         ; 1157??
	DW OFFSET MOVB11         ; 1160??
	DW OFFSET MOVB11         ; 1161??
	DW OFFSET MOVB11         ; 1162??
	DW OFFSET MOVB11         ; 1163??
	DW OFFSET MOVB11         ; 1164??
	DW OFFSET MOVB11         ; 1165??
	DW OFFSET MOVB11         ; 1166??
	DW OFFSET MOVB11         ; 1167??
	DW OFFSET MOVB11         ; 1170??
	DW OFFSET MOVB11         ; 1171??
	DW OFFSET MOVB11         ; 1172??
	DW OFFSET MOVB11         ; 1173??
	DW OFFSET MOVB11         ; 1174??
	DW OFFSET MOVB11         ; 1175??
	DW OFFSET MOVB11         ; 1176??
	DW OFFSET MOVB11         ; 1177??
	DW OFFSET CMPB11         ; 1200??
	DW OFFSET CMPB11         ; 1201??
	DW OFFSET CMPB11         ; 1202??
	DW OFFSET CMPB11         ; 1203??
	DW OFFSET CMPB11         ; 1204??
	DW OFFSET CMPB11         ; 1205??
	DW OFFSET CMPB11         ; 1206??
	DW OFFSET CMPB11         ; 1207??
	DW OFFSET CMPB11         ; 1210??
	DW OFFSET CMPB11         ; 1211??
	DW OFFSET CMPB11         ; 1212??
	DW OFFSET CMPB11         ; 1213??
	DW OFFSET CMPB11         ; 1214??
	DW OFFSET CMPB11         ; 1215??
	DW OFFSET CMPB11         ; 1216??
	DW OFFSET CMPB11         ; 1217??
	DW OFFSET CMPB11         ; 1220??
	DW OFFSET CMPB11         ; 1221??
	DW OFFSET CMPB11         ; 1222??
	DW OFFSET CMPB11         ; 1223??
	DW OFFSET CMPB11         ; 1224??
	DW OFFSET CMPB11         ; 1225??
	DW OFFSET CMPB11         ; 1226??
	DW OFFSET CMPB11         ; 1227??
	DW OFFSET CMPB11         ; 1230??
	DW OFFSET CMPB11         ; 1231??
	DW OFFSET CMPB11         ; 1232??
	DW OFFSET CMPB11         ; 1233??
	DW OFFSET CMPB11         ; 1234??
	DW OFFSET CMPB11         ; 1235??
	DW OFFSET CMPB11         ; 1236??
	DW OFFSET CMPB11         ; 1237??
	DW OFFSET CMPB11         ; 1240??
	DW OFFSET CMPB11         ; 1241??
	DW OFFSET CMPB11         ; 1242??
	DW OFFSET CMPB11         ; 1243??
	DW OFFSET CMPB11         ; 1244??
	DW OFFSET CMPB11         ; 1245??
	DW OFFSET CMPB11         ; 1246??
	DW OFFSET CMPB11         ; 1247??
	DW OFFSET CMPB11         ; 1250??
	DW OFFSET CMPB11         ; 1251??
	DW OFFSET CMPB11         ; 1252??
	DW OFFSET CMPB11         ; 1253??
	DW OFFSET CMPB11         ; 1254??
	DW OFFSET CMPB11         ; 1255??
	DW OFFSET CMPB11         ; 1256??
	DW OFFSET CMPB11         ; 1257??
	DW OFFSET CMPB11         ; 1260??
	DW OFFSET CMPB11         ; 1261??
	DW OFFSET CMPB11         ; 1262??
	DW OFFSET CMPB11         ; 1263??
	DW OFFSET CMPB11         ; 1264??
	DW OFFSET CMPB11         ; 1265??
	DW OFFSET CMPB11         ; 1266??
	DW OFFSET CMPB11         ; 1267??
	DW OFFSET CMPB11         ; 1270??
	DW OFFSET CMPB11         ; 1271??
	DW OFFSET CMPB11         ; 1272??
	DW OFFSET CMPB11         ; 1273??
	DW OFFSET CMPB11         ; 1274??
	DW OFFSET CMPB11         ; 1275??
	DW OFFSET CMPB11         ; 1276??
	DW OFFSET CMPB11         ; 1277??
	DW OFFSET BITB11         ; 1300??
	DW OFFSET BITB11         ; 1301??
	DW OFFSET BITB11         ; 1302??
	DW OFFSET BITB11         ; 1303??
	DW OFFSET BITB11         ; 1304??
	DW OFFSET BITB11         ; 1305??
	DW OFFSET BITB11         ; 1306??
	DW OFFSET BITB11         ; 1307??
	DW OFFSET BITB11         ; 1310??
	DW OFFSET BITB11         ; 1311??
	DW OFFSET BITB11         ; 1312??
	DW OFFSET BITB11         ; 1313??
	DW OFFSET BITB11         ; 1314??
	DW OFFSET BITB11         ; 1315??
	DW OFFSET BITB11         ; 1316??
	DW OFFSET BITB11         ; 1317??
	DW OFFSET BITB11         ; 1320??
	DW OFFSET BITB11         ; 1321??
	DW OFFSET BITB11         ; 1322??
	DW OFFSET BITB11         ; 1323??
	DW OFFSET BITB11         ; 1324??
	DW OFFSET BITB11         ; 1325??
	DW OFFSET BITB11         ; 1326??
	DW OFFSET BITB11         ; 1327??
	DW OFFSET BITB11         ; 1330??
	DW OFFSET BITB11         ; 1331??
	DW OFFSET BITB11         ; 1332??
	DW OFFSET BITB11         ; 1333??
	DW OFFSET BITB11         ; 1334??
	DW OFFSET BITB11         ; 1335??
	DW OFFSET BITB11         ; 1336??
	DW OFFSET BITB11         ; 1337??
	DW OFFSET BITB11         ; 1340??
	DW OFFSET BITB11         ; 1341??
	DW OFFSET BITB11         ; 1342??
	DW OFFSET BITB11         ; 1343??
	DW OFFSET BITB11         ; 1344??
	DW OFFSET BITB11         ; 1345??
	DW OFFSET BITB11         ; 1346??
	DW OFFSET BITB11         ; 1347??
	DW OFFSET BITB11         ; 1350??
	DW OFFSET BITB11         ; 1351??
	DW OFFSET BITB11         ; 1352??
	DW OFFSET BITB11         ; 1353??
	DW OFFSET BITB11         ; 1354??
	DW OFFSET BITB11         ; 1355??
	DW OFFSET BITB11         ; 1356??
	DW OFFSET BITB11         ; 1357??
	DW OFFSET BITB11         ; 1360??
	DW OFFSET BITB11         ; 1361??
	DW OFFSET BITB11         ; 1362??
	DW OFFSET BITB11         ; 1363??
	DW OFFSET BITB11         ; 1364??
	DW OFFSET BITB11         ; 1365??
	DW OFFSET BITB11         ; 1366??
	DW OFFSET BITB11         ; 1367??
	DW OFFSET BITB11         ; 1370??
	DW OFFSET BITB11         ; 1371??
	DW OFFSET BITB11         ; 1372??
	DW OFFSET BITB11         ; 1373??
	DW OFFSET BITB11         ; 1374??
	DW OFFSET BITB11         ; 1375??
	DW OFFSET BITB11         ; 1376??
	DW OFFSET BITB11         ; 1377??
	DW OFFSET BICB11         ; 1400??
	DW OFFSET BICB11         ; 1401??
	DW OFFSET BICB11         ; 1402??
	DW OFFSET BICB11         ; 1403??
	DW OFFSET BICB11         ; 1404??
	DW OFFSET BICB11         ; 1405??
	DW OFFSET BICB11         ; 1406??
	DW OFFSET BICB11         ; 1407??
	DW OFFSET BICB11         ; 1410??
	DW OFFSET BICB11         ; 1411??
	DW OFFSET BICB11         ; 1412??
	DW OFFSET BICB11         ; 1413??
	DW OFFSET BICB11         ; 1414??
	DW OFFSET BICB11         ; 1415??
	DW OFFSET BICB11         ; 1416??
	DW OFFSET BICB11         ; 1417??
	DW OFFSET BICB11         ; 1420??
	DW OFFSET BICB11         ; 1421??
	DW OFFSET BICB11         ; 1422??
	DW OFFSET BICB11         ; 1423??
	DW OFFSET BICB11         ; 1424??
	DW OFFSET BICB11         ; 1425??
	DW OFFSET BICB11         ; 1426??
	DW OFFSET BICB11         ; 1427??
	DW OFFSET BICB11         ; 1430??
	DW OFFSET BICB11         ; 1431??
	DW OFFSET BICB11         ; 1432??
	DW OFFSET BICB11         ; 1433??
	DW OFFSET BICB11         ; 1434??
	DW OFFSET BICB11         ; 1435??
	DW OFFSET BICB11         ; 1436??
	DW OFFSET BICB11         ; 1437??
	DW OFFSET BICB11         ; 1440??
	DW OFFSET BICB11         ; 1441??
	DW OFFSET BICB11         ; 1442??
	DW OFFSET BICB11         ; 1443??
	DW OFFSET BICB11         ; 1444??
	DW OFFSET BICB11         ; 1445??
	DW OFFSET BICB11         ; 1446??
	DW OFFSET BICB11         ; 1447??
	DW OFFSET BICB11         ; 1450??
	DW OFFSET BICB11         ; 1451??
	DW OFFSET BICB11         ; 1452??
	DW OFFSET BICB11         ; 1453??
	DW OFFSET BICB11         ; 1454??
	DW OFFSET BICB11         ; 1455??
	DW OFFSET BICB11         ; 1456??
	DW OFFSET BICB11         ; 1457??
	DW OFFSET BICB11         ; 1460??
	DW OFFSET BICB11         ; 1461??
	DW OFFSET BICB11         ; 1462??
	DW OFFSET BICB11         ; 1463??
	DW OFFSET BICB11         ; 1464??
	DW OFFSET BICB11         ; 1465??
	DW OFFSET BICB11         ; 1466??
	DW OFFSET BICB11         ; 1467??
	DW OFFSET BICB11         ; 1470??
	DW OFFSET BICB11         ; 1471??
	DW OFFSET BICB11         ; 1472??
	DW OFFSET BICB11         ; 1473??
	DW OFFSET BICB11         ; 1474??
	DW OFFSET BICB11         ; 1475??
	DW OFFSET BICB11         ; 1476??
	DW OFFSET BICB11         ; 1477??
	DW OFFSET BISB11         ; 1500??
	DW OFFSET BISB11         ; 1501??
	DW OFFSET BISB11         ; 1502??
	DW OFFSET BISB11         ; 1503??
	DW OFFSET BISB11         ; 1504??
	DW OFFSET BISB11         ; 1505??
	DW OFFSET BISB11         ; 1506??
	DW OFFSET BISB11         ; 1507??
	DW OFFSET BISB11         ; 1510??
	DW OFFSET BISB11         ; 1511??
	DW OFFSET BISB11         ; 1512??
	DW OFFSET BISB11         ; 1513??
	DW OFFSET BISB11         ; 1514??
	DW OFFSET BISB11         ; 1515??
	DW OFFSET BISB11         ; 1516??
	DW OFFSET BISB11         ; 1517??
	DW OFFSET BISB11         ; 1520??
	DW OFFSET BISB11         ; 1521??
	DW OFFSET BISB11         ; 1522??
	DW OFFSET BISB11         ; 1523??
	DW OFFSET BISB11         ; 1524??
	DW OFFSET BISB11         ; 1525??
	DW OFFSET BISB11         ; 1526??
	DW OFFSET BISB11         ; 1527??
	DW OFFSET BISB11         ; 1530??
	DW OFFSET BISB11         ; 1531??
	DW OFFSET BISB11         ; 1532??
	DW OFFSET BISB11         ; 1533??
	DW OFFSET BISB11         ; 1534??
	DW OFFSET BISB11         ; 1535??
	DW OFFSET BISB11         ; 1536??
	DW OFFSET BISB11         ; 1537??
	DW OFFSET BISB11         ; 1540??
	DW OFFSET BISB11         ; 1541??
	DW OFFSET BISB11         ; 1542??
	DW OFFSET BISB11         ; 1543??
	DW OFFSET BISB11         ; 1544??
	DW OFFSET BISB11         ; 1545??
	DW OFFSET BISB11         ; 1546??
	DW OFFSET BISB11         ; 1547??
	DW OFFSET BISB11         ; 1550??
	DW OFFSET BISB11         ; 1551??
	DW OFFSET BISB11         ; 1552??
	DW OFFSET BISB11         ; 1553??
	DW OFFSET BISB11         ; 1554??
	DW OFFSET BISB11         ; 1555??
	DW OFFSET BISB11         ; 1556??
	DW OFFSET BISB11         ; 1557??
	DW OFFSET BISB11         ; 1560??
	DW OFFSET BISB11         ; 1561??
	DW OFFSET BISB11         ; 1562??
	DW OFFSET BISB11         ; 1563??
	DW OFFSET BISB11         ; 1564??
	DW OFFSET BISB11         ; 1565??
	DW OFFSET BISB11         ; 1566??
	DW OFFSET BISB11         ; 1567??
	DW OFFSET BISB11         ; 1570??
	DW OFFSET BISB11         ; 1571??
	DW OFFSET BISB11         ; 1572??
	DW OFFSET BISB11         ; 1573??
	DW OFFSET BISB11         ; 1574??
	DW OFFSET BISB11         ; 1575??
	DW OFFSET BISB11         ; 1576??
	DW OFFSET BISB11         ; 1577??
	DW OFFSET SUB11          ; 1600??
	DW OFFSET SUB11          ; 1601??
	DW OFFSET SUB11          ; 1602??
	DW OFFSET SUB11          ; 1603??
	DW OFFSET SUB11          ; 1604??
	DW OFFSET SUB11          ; 1605??
	DW OFFSET SUB11          ; 1606??
	DW OFFSET SUB11          ; 1607??
	DW OFFSET SUB11          ; 1610??
	DW OFFSET SUB11          ; 1611??
	DW OFFSET SUB11          ; 1612??
	DW OFFSET SUB11          ; 1613??
	DW OFFSET SUB11          ; 1614??
	DW OFFSET SUB11          ; 1615??
	DW OFFSET SUB11          ; 1616??
	DW OFFSET SUB11          ; 1617??
	DW OFFSET SUB11          ; 1620??
	DW OFFSET SUB11          ; 1621??
	DW OFFSET SUB11          ; 1622??
	DW OFFSET SUB11          ; 1623??
	DW OFFSET SUB11          ; 1624??
	DW OFFSET SUB11          ; 1625??
	DW OFFSET SUB11          ; 1626??
	DW OFFSET SUB11          ; 1627??
	DW OFFSET SUB11          ; 1630??
	DW OFFSET SUB11          ; 1631??
	DW OFFSET SUB11          ; 1632??
	DW OFFSET SUB11          ; 1633??
	DW OFFSET SUB11          ; 1634??
	DW OFFSET SUB11          ; 1635??
	DW OFFSET SUB11          ; 1636??
	DW OFFSET SUB11          ; 1637??
	DW OFFSET SUB11          ; 1640??
	DW OFFSET SUB11          ; 1641??
	DW OFFSET SUB11          ; 1642??
	DW OFFSET SUB11          ; 1643??
	DW OFFSET SUB11          ; 1644??
	DW OFFSET SUB11          ; 1645??
	DW OFFSET SUB11          ; 1646??
	DW OFFSET SUB11          ; 1647??
	DW OFFSET SUB11          ; 1650??
	DW OFFSET SUB11          ; 1651??
	DW OFFSET SUB11          ; 1652??
	DW OFFSET SUB11          ; 1653??
	DW OFFSET SUB11          ; 1654??
	DW OFFSET SUB11          ; 1655??
	DW OFFSET SUB11          ; 1656??
	DW OFFSET SUB11          ; 1657??
	DW OFFSET SUB11          ; 1660??
	DW OFFSET SUB11          ; 1661??
	DW OFFSET SUB11          ; 1662??
	DW OFFSET SUB11          ; 1663??
	DW OFFSET SUB11          ; 1664??
	DW OFFSET SUB11          ; 1665??
	DW OFFSET SUB11          ; 1666??
	DW OFFSET SUB11          ; 1667??
	DW OFFSET SUB11          ; 1670??
	DW OFFSET SUB11          ; 1671??
	DW OFFSET SUB11          ; 1672??
	DW OFFSET SUB11          ; 1673??
	DW OFFSET SUB11          ; 1674??
	DW OFFSET SUB11          ; 1675??
	DW OFFSET SUB11          ; 1676??
	DW OFFSET SUB11          ; 1677??
	DW OFFSET NEOP           ; 1700??
	DW OFFSET NEOP           ; 1701??
	DW OFFSET NEOP           ; 1702??
	DW OFFSET NEOP           ; 1703??
	DW OFFSET NEOP           ; 1704??
	DW OFFSET NEOP           ; 1705??
	DW OFFSET NEOP           ; 1706??
	DW OFFSET NEOP           ; 1707??
	DW OFFSET NEOP           ; 1710??
	DW OFFSET NEOP           ; 1711??
	DW OFFSET NEOP           ; 1712??
	DW OFFSET NEOP           ; 1713??
	DW OFFSET NEOP           ; 1714??
	DW OFFSET NEOP           ; 1715??
	DW OFFSET NEOP           ; 1716??
	DW OFFSET NEOP           ; 1717??
	DW OFFSET NEOP           ; 1720??
	DW OFFSET NEOP           ; 1721??
	DW OFFSET NEOP           ; 1722??
	DW OFFSET NEOP           ; 1723??
	DW OFFSET NEOP           ; 1724??
	DW OFFSET NEOP           ; 1725??
	DW OFFSET NEOP           ; 1726??
	DW OFFSET NEOP           ; 1727??
	DW OFFSET NEOP           ; 1730??
	DW OFFSET NEOP           ; 1731??
	DW OFFSET NEOP           ; 1732??
	DW OFFSET NEOP           ; 1733??
	DW OFFSET NEOP           ; 1734??
	DW OFFSET NEOP           ; 1735??
	DW OFFSET NEOP           ; 1736??
	DW OFFSET NEOP           ; 1737??
	DW OFFSET NEOP           ; 1740??
	DW OFFSET NEOP           ; 1741??
	DW OFFSET NEOP           ; 1742??
	DW OFFSET NEOP           ; 1743??
	DW OFFSET NEOP           ; 1744??
	DW OFFSET NEOP           ; 1745??
	DW OFFSET NEOP           ; 1746??
	DW OFFSET NEOP           ; 1747??
	DW OFFSET NEOP           ; 1750??
	DW OFFSET NEOP           ; 1751??
	DW OFFSET NEOP           ; 1752??
	DW OFFSET NEOP           ; 1753??
	DW OFFSET NEOP           ; 1754??
	DW OFFSET NEOP           ; 1755??
	DW OFFSET NEOP           ; 1756??
	DW OFFSET NEOP           ; 1757??
	DW OFFSET NEOP           ; 1760??
	DW OFFSET NEOP           ; 1761??
	DW OFFSET NEOP           ; 1762??
	DW OFFSET NEOP           ; 1763??
	DW OFFSET NEOP           ; 1764??
	DW OFFSET NEOP           ; 1765??
	DW OFFSET NEOP           ; 1766??
	DW OFFSET NEOP           ; 1767??
	DW OFFSET NEOP           ; 1770??
	DW OFFSET NEOP           ; 1771??
	DW OFFSET NEOP           ; 1772??
	DW OFFSET NEOP           ; 1773??
	DW OFFSET NEOP           ; 1774??
	DW OFFSET NEOP           ; 1775??
	DW OFFSET NEOP           ; 1776??
	DW OFFSET NEOP           ; 1777??
;
; END OF THIS FILE.
;
