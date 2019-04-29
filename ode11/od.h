
/* Order of these bit fields in these struct's should be probably changed
    if compiled in some other machine (or with some other compiler ???),
    (see page 196 of K/R first edition (Structure and union declarations))

   This order works at least with Aztec-C 3.40 of IBM-PC:
 */

#define DEFAULT_MEM  50000L
#define COMMENT_CHAR ';'

struct instr1
 {
   unsigned opr1reg : 3;   /*  2-0  */
   unsigned opr1mod : 3;   /*  5-3  */
   unsigned opcode  : 10;  /* 15-6  */
 };


struct instr2
 {
   unsigned opr2reg : 3;   /*  2-0  */
   unsigned opr2mod : 3;   /*  5-3  */
   unsigned opr1reg : 3;   /*  8-6  */
   unsigned opr1mod : 3;   /* 11-9  */
   unsigned opcode  : 4;   /* 15-12 */
 };


struct instr3
 {
   unsigned bits5_0 : 6;   /*  5-0  */
   unsigned opr1reg : 3;   /*  8-6  */
   unsigned opcode  : 7;   /* 15-9  */
 };


struct two_bytes
 {
   BYTE lo;
   BYTE hi;
 };



static char *reg_names[] =
 {
   "R0",
   "R1",
   "R2",
   "R3",
   "R4",
   "R5",
   "SP", /* R6 is Stack Pointer */
   "PC", /* R7 is Program Counter */
   NULL  /* End Marker */
 };


/* Addressing modes 0-7: */
static char *mode_strings[] =
 {
   "%s",         /* 0   Register */
   "(%s)",       /* 1   Register referred */
   "(%s)+",      /* 2   Autoincrement */
   "@(%s)+",     /* 3   Autoincrement deferred */
   "-(%s)",      /* 4   Autodecrement */
   "@-(%s)",     /* 5   Autodecrement deferred */
   "%s(%s)",     /* 6   Index */
   "@%s(%s)"     /* 7   Index deferred */
 };


/* Opcodes by first 4 bits of instruction, i.e. bits 15-12: */
static char *opcodes2[] =
 {
   NULL,         /* 00 */
   "MOV",        /* 01 */
   "CMP",        /* 02 */
   "BIT",        /* 03 */
   "BIC",        /* 04 */
   "BIS",        /* 05 */
   "ADD",        /* 06 */
   NULL,         /* 07 */
   NULL,         /* 10 */
   "MOVB",       /* 11 */
   "CMPB",       /* 12 */
   "BITB",       /* 13 */
   "BICB",       /* 14 */
   "BISB",       /* 15 */
   "SUB",        /* 16 */
   NULL,         /* 17 */
 };
  

static char *opcodes_jmp_swab[] =
 {
   NULL,     /* 0000 */
   "JMP",    /* 0001 */
   NULL,     /* 0002 */
   "SWAB",   /* 0003 */
 };


static char *opcodes0050[] =
 {
   "CLR",    /* 0050 */
   "COM",    /* 0051 */
   "INC",    /* 0052 */
   "DEC",    /* 0053 */
   "NEG",    /* 0054 */
   "ADC",    /* 0055 */
   "SBC",    /* 0056 */
   "TST",    /* 0057 */
   "ROR",    /* 0060 */
   "ROL",    /* 0061 */
   "ASR",    /* 0062 */
   "ASL",    /* 0063 */
   "MARK",   /* 0064 */
   "MFPI",   /* 0065 */
   "MTPI",   /* 0066 */
   "SXT",    /* 0067 */
   "CSM",    /* 0070 */
   NULL,     /* 0071 */
   NULL,     /* 0072 */
   NULL,     /* 0073 */
   NULL,     /* 0074 */
   NULL,     /* 0075 */
   NULL,     /* 0076 */
   NULL      /* 0077 */
 };



static char *opcodes1050[] =
 {
   "CLRB",    /* 1050 */
   "COMB",    /* 1051 */
   "INCB",    /* 1052 */
   "DECB",    /* 1053 */
   "NEGB",    /* 1054 */
   "ADCB",    /* 1055 */
   "SBCB",    /* 1056 */
   "TSTB",    /* 1057 */
   "RORB",    /* 1060 */
   "ROLB",    /* 1061 */
   "ASRB",    /* 1062 */
   "ASLB",    /* 1063 */
   "MTPS",    /* 1064 */
   "MFPD",    /* 1065 */
   "MTPD",    /* 1066 */
   "MFPS",    /* 1067 */
   NULL,      /* 1070 */
   NULL,      /* 1071 */
   NULL,      /* 1072 */
   NULL,      /* 1073 */
   NULL,      /* 1074 */
   NULL,      /* 1075 */
   NULL,      /* 1076 */
   NULL       /* 1077 */
 };




static char *opcodes0000[] =
 {
   "HALT",  /* 000000 */
   "WAIT",  /* 000001 */
   "RTI",   /* 000002 */
   "BPT",   /* 000003 */
   "IOT",   /* 000004 */
   "RESET", /* 000005 */
   "RTT",   /* 000006 */
   "MFPT"   /* 000007 */
/* Rest 000010 - 000077 are nonexistent opcodes (???) */
 };


static char *opcodes070[] =
 {
   "MUL",   /* 070 */
   "DIV",   /* 071 */
   "ASH",   /* 072 */
   "ASHC",  /* 073 */
   "XOR",   /* 074 */
   NULL,    /* 075 */
   NULL,    /* 076 */
   "SOB"    /* 077 */
 };


static char *opcodes_br1[] =
 {
   "???",  /* 0000 - 0003 */
   "BR",   /* 0004 - 0007 */
   "BNE",  /* 0010 - 0013 */
   "BEQ",  /* 0014 - 0017 */
   "BGE",  /* 0020 - 0023 */
   "BLT",  /* 0024 - 0027 */
   "BGT",  /* 0030 - 0033 */
   "BLE",  /* 0034 - 0037 */
   NULL    /* End Marker */
 };


static char *opcodes_br2[] =
 {
   "BPL",  /*  0  1000 - 1003 */
   "BMI",  /*  1  1004 - 1007 */
   "BHI",  /*  2  1010 - 1013 */
   "BLOS", /*  3  1014 - 1017 */
   "BVC",  /*  4  1020 - 1023 */
   "BVS",  /*  5  1024 - 1027 */
   "BCC",  /*  6  1030 - 1033  Synonym: BHIS */
   "BCS",  /*  7  1034 - 1037  Synonym: BLO  */
   "EMT",  /*  8  1040 - 1043 */ /* Of course these are */
   "TRAP", /*  9  1044 - 1047 */ /*  not branches.      */
   NULL    /* End Marker */
 };



static char *opcodes_FIS[] =
 {
   "FADD",
   "FSUB",
   "FMUL",
   "FDIV"
 };

