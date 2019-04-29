

/*
   Octal Debugger part of ODE11 (= Octal Debugger & Executor for PDP-11 code)
    Coded by A. Karttunen at May - June & October & December 1990.
   See ODE11.DOC for more information.

   Note that not all parts of this program are so braindamaged as input
    & parsing section. Actually, disassembling & label-handling functions
    are not so bad.
 */


#include "stdio.h"
#include "ctype.h"
#include "sgtty.h"
#include "signal.h"
#include "time.h"
#include "mydefs.h"

#define NIL NULL
#define nilp(X) (!(X))

/*
#include "lists.h"
#include "fundefs.h"
#include "globals.h"
 */
#include "grafuns.h"
#include "ansiesc.h"
#include "od.h"
#include "odfundef.h"


struct label_list
 {
   struct label_list *next_l;
   char *labelname;
   unsigned short int labelvalue;
   struct reference_list *reflist;
   char has_value_flag;
 };

struct reference_list
 {
   struct reference_list *next_r;
   unsigned short int _lc;
   unsigned short int _lilc;
   char *_prefixes;
 };

typedef struct label_list *LLIST;
typedef struct reference_list *RLIST;

#define getlnext(X)           ((X)->next_l)
#define getlname(X)           ((X)->labelname)
#define getlvalue(X)          ((X)->labelvalue)
#define getlreflist(X)        ((X)->reflist)
#define getlhasvalueflag(X)   ((X)->has_value_flag)
#define getrnext(X)           ((X)->next_r)
#define getrlc(X)             ((X)->_lc)
#define getrlilc(X)           ((X)->_lilc)
#define getrprefixes(X)       ((X)->_prefixes)

#define setlnext(X,Y)         (getlnext(X)      = (Y))
#define setlname(X,Y)         (getlname(X)      = (Y))
#define setlvalue(X,Y)        (getlvalue(X)     = (Y))
#define setlreflist(X,Y)      (getlreflist(X)   = (Y))
#define setlhasvalueflag(X,Y) (getlhasvalueflag(X) = (Y))
#define setrnext(X,Y)         (getrnext(X)      = (Y))
#define setrlc(X,Y)           (getrlc(X)        = (Y))
#define setrlilc(X,Y)         (getrlilc(X)      = (Y))
#define setrprefixes(X,Y)     (getrprefixes(X)  = (Y))

int _hrflag=0;

LLIST all_labels=NIL;

char *malloc(),*strdup();
LLIST intern(),lookup();
RLIST getnewreflist();

#define strequ(X,Y) (!strcmp((X),(Y)))

FILE *output=stdout;
FILE *null_output=stdout;

#define NULL_DEVICE "NUL"

#define out_char(c) { fputc(c,output); col++; }

#define terpri() { fprintf(output,"\n"); col = 0; }


#define get_progname() ("ODE11")

#define MAXBUF 257

#define CTRL(X) ((X) - 64)

#define isbit15on(X) ((int (X)) < 0)

/* Compiler doesn't accept this:
#define get_elem(X,STRNAME,ELEMNAME) (((struct STRNAME) (X)).ELEMNAME)
*/

/* But it accepts this: (i.e. take address of X and treat it as pointer
    to field structure: */
#define get_elem(X,STRNAME,ELEMNAME) (((struct STRNAME *) &(X))->ELEMNAME)

/* Status codes where fetch_word is getting it's input: */
#define FROM_MEM  0 /* Get word from memory */
#define FROM_USR  1 /* Asks word from user */
#define NO_BLANKS 2

UINT execute();
ULI get_ic();
char *hsecs2secs();
char *index(),*rindex(),*getenv();
FILE *myfopen();
int tolower(),toupper();
int f_isspace();

#define THE_COLUMN 49
#define PREF1CHAR '!'
/* Character put to start of buffer to indicate failure: */
#define FAILED   '\05'
#define FORWARD  '\06' /* Indicates forward reference */
#define MULTIPLE '\07' /* Indicates multiple values on the same line */

#define REGS 0177700
#define PSR  0177776

#define CSR     0177546         /* Clock Status Register */
#define KBSTAT  0177560         /* Keyboard status register */
#define KBDATA  0177562         /* Keyboard data register */
#define PRSTAT  0177564         /* Printer status register */
#define PRDATA  0177566         /* Printer data register */


void *allocmem();
char *PDP11MEM;
/* This contains segment part of 64K block of "PDP-11 memory": */
UINT PDP11SEG=0;

#define getreg(n)    (*(((UINT *) (PDP11MEM + REGS)) + (n)))
#define setreg(n,x)  ((*(((UINT *) (PDP11MEM + REGS)) + (n))) = (x))

#define getpsr()     (*(((UINT *) (PDP11MEM + PSR))))
#define setpsr(x)    ((*(((UINT *) (PDP11MEM + PSR)))) = (x))

#define getmem(a)    (*(((UINT *) (PDP11MEM + (a)))))
#define setmem(a,x)  ((*(((UINT *) (PDP11MEM + (a))))) = (x))

#define getbytemem(a)    (*(((BYTE *) (PDP11MEM + (a)))))
#define setbytemem(a,x)  ((*(((BYTE *) (PDP11MEM + (a))))) = (x))

#define getbyteptr(a)    ((((BYTE *) (PDP11MEM + (a)))))

char *CHAREG = "7";

/* Location Counters:
 LC:  continuously incremented. (corresponds to PC in runtime).
 LILC: points always to the start of the latest instruction being
 entered  (like . in MACRO-assembler of PDP-11).
 */
UINT LC,LILC,Next_LC;
UINT _mark=0;
BYTE intinp=0; /* Interactive Input ? (Supporting ANSI-codes) */
BYTE ctrl_c_pressed=0;
BYTE silent_flag=0;
FILE *fopen();
FILE *saveinput=NULL;
FILE *input=stdin;


UINT col=0; /* Column count */

char comma = ',';
/* char tab   = '\t'; */

static char *NEOP = "???"; /* Non-Existent Opcode */

static char *flags = "CVZN"; 


main(argc,argv)
int argc;
char **argv;
{
    extern char ctp_[];
    void brkhandler();
    ULI atol();
    char *itohex(),*lto2hex();
    char *s;
    char buf1[10],buf2[10];
    BYTE c;

    LC = 0;

    signal(SIGINT,brkhandler); /* catch ^C */


        /* Change character type table so that isalpha('_') returns true,
            (as underscore would be letter too): */
        ctp_['_'+1] = c = ctp_['A'+1];
        ctp_['$'+1] = c; /* Also dollar and period usable in label names, */
                         /* as in MACRO-11 (Radix-50) */
/*      ctp_['.'+1] = c;    After all, this is not so good idea, as .
                                 (LC) doesn't work anymore */

        init_default_labels();

        while(*++argv)
         {
           if(**argv == '-')
            {
              s = *argv;
              while(*++s)
               {
                 switch(*s)
                  {
                    /* Put screen to graphics-mode with -g option: */
                    case 'g': { INITHR; break; }
                    case 'm':
                     {
                       if(!*++s) { if(!(s = *++argv)) { goto ertzu; } }
                       if(sscanf(s,"%x",&PDP11SEG) != 1) { goto ertzu; }
                       PDP11MEM = (void *) (uli(PDP11SEG) << 16);
                       goto cont;
ertzu:
                       fprintf(stderr,"\n%s: Illegal format for option !\n",
                                  get_progname());
                       myexit(1);
                     }
		    case 's':
		     {
		       silent_flag=1;
		       null_output = myfopen(NULL_DEVICE,"w");
		       break;
		     }
                    default:
                     {
                       fprintf(stderr,"\n%s: unknown option -%c\n",
                                 get_progname(),*s);
                       fprintf(stderr,
"usage: %s [-s (for silent loading)] [-m segment_in_hex] [start_adr]\n",
                          get_progname());
                       fprintf(stderr,
"use -g option for graphics mode. For more information check ODE11.DOC\n");
                       myexit(1);
                     }
                  }
               }
            }
           else
            {
              LC = solve_expr(NULL,*argv,LC,LILC);
              if(**argv == FAILED) { myexit(1); }
              if(LC & 1)
               {
                 fprintf(stderr,
"\n%s: starting adress must be an even octal number !\n",get_progname());
                 myexit(1);
               }
            }
cont: ;
         }

        if(!PDP11SEG)
         {
           PDP11MEM = allocmem(65536L);    /* Exactly 64K */
           PDP11SEG = gethigh(PDP11MEM);
           resetmem(PDP11SEG);
         }

        intinp = isatty(fileno(input));

        LILC = LC;

        fprintf(stderr,
"\nODE11 -- Octal Debugger & Executor for PDP-11 Code. Segment: %s\n",
         itohex(buf2,PDP11SEG));

        reset_prevs();

/*
 Main loop: (fetch_word handles exiting if EOF encountered, or if user quits)
 */
        main_loop();
}


void brkhandler(sig)
int sig;
{
    void brkhandler();

    signal(SIGINT,brkhandler);
/*  fprintf(stderr,"Catching signal %d.\n",sig); */
    brk_e11();
    ctrl_c_pressed = 1;
}



main_loop()
{
    char *myfgets();
    register UINT z,l;
    char c;
    char buf[MAXBUF+2];

loop:
    unassemble(FROM_MEM);
hoop:
    LILC = LC;
    ctrl_c_pressed = 0;

    if(intinp && !saveinput)
     {
       c = get_n_chars(buf,MAXBUF,0xFF);
       delete_comment(buf);
     }
    else
     {
       if(!myfgets(buf,MAXBUF,input))
        { /* If EOF encountered, and that input was from file: */
          if(saveinput)
           {
             fclose(input); /* Close the input file (loaded with ^I) */
             input = saveinput; /* Restore the old input */
             saveinput = NULL;
/* Restore output too, if it was redirected to null_output (-s option used): */
	     output = stdout;
             intinp = 1; /* Set interactive input flag back to on */
	     /* Report unresolved labels: */
             if(!silent_flag) { report_unresolved(); }
           }
          else { c = CTRL('Z'); goto tuuba; }
        }
       delete_comment(buf);

       l = strlen(buf);
       if((l >= 2) && (*(buf + (l-2)) == '^'))
        {
          *(buf + (l-2)) = '\0';
          c = CTRL(toupper(*(buf + (l-1))));
        }
       else { c = CTRL('M'); }
     }
tuuba:

    switch(c)
     {
       case CTRL('_'):
        { 
          if(*buf) { HOME; } else { CLS; }
          goto loop;
        }
/*
       case CTRL('^'):
        {
          goto loop;
        }
 */
       case CTRL('\\'):
        {
          terpri();
          if(!*buf)
           {
             report_unresolved();
             goto loop;
           }

          print_matching_labels(buf);
          goto loop;
        }
       case CTRL('E'):
        {
          char *s;
          terpri();
          if(system(*buf ? buf : ((s = getenv("COMSPEC")) ? s : "COMMAND"))
               < 0)
           {
             fprintf(stderr,
"system() failed, memory exhausted or command.com not found ?");
           }
          terpri();
          goto loop;
        }
       /* case CTRL('C'): */
       case CTRL('Z'): { myexit(0); }
       case CTRL('B'): { LC -= 2; terpri(); goto loop; }
       case CTRL('L'): /* Set location counter */
        { /* Potential bug here: If user changes to location which is
              f.i. argument of relative jump (= 000167) and then
              enters !. then it refers location of this argument
              although it should refer the location of 000167 instruction:
              (That is: LILC is not necessarily correct before we
              have been in main loop at least once after CTRL-L)
           */
          z = get_word(buf);
          LILC = LC = z;
          terpri();
          goto loop;
        }
/*     case CTRL('I'): { help(); goto loop; } */
       case CTRL('R'):
        {
          terpri();
          print_regs();
          goto loop;
        }
       case CTRL('K'):
        {
          UINT get_pc_bpt();

          if(*buf)
	   { z = get_word(buf); if(*buf != FAILED) { set_pc_bpt(z); } }
          fprintf(output,"\nPC breakpoint: %6o",get_pc_bpt());
          terpri();
          goto loop;
        }
       case CTRL('V'):
        {
          if(*buf)
	   { z = get_word(buf); if(*buf != FAILED) { _mark = z; } }
          fprintf(output,"\nMark: %6o",_mark);
          terpri();
          goto loop;
        }
       case CTRL('T'):
        {
          terpri();
          setreg(7,LC);
          execute(PDP11SEG,1L);
          LC = getreg(7);
          print_regs();
          terpri();
          goto loop;
        }
       case CTRL('G'):
        {
          ULI t1,t2,time,inscnt,lz;
          UINT status;

          terpri();

          if(*buf == '=') /* Starting address of execution specified */
           {
             setreg(7,get_word(buf+1));
             z = 0;
             goto vompatti;
           }
          else /* Start from LC */ 
           { /* If instruction limit specified, then use that: */
             z = (*buf ? get_word(buf) : 0);
             setreg(7,LC);
vompatti:
             lz = uli(z);
             t1 = hsecs_of_year();
             status = execute(PDP11SEG,lz);
           }

          t2 = hsecs_of_year();
          LC = getreg(7);
          terpri();
          report_exit_reason(status);
          print_regs();

           {
             fprintf(stderr,
"**Executed %lu instructions in %s seconds\n",
                      (inscnt = (lz - get_ic())),hsecs2secs(time = (t2-t1)));
             fprintf(stderr,
"**One instruction in %f seconds, %f instructions in one second.\n",
               (((double) time)/inscnt)/100,(((double) inscnt)/time)*100);
           }
          goto loop;
        }
       case CTRL('I'):
        {
	  char *extension;
          unsigned char inbuf[2];

          saveinput = input;
          if(!(input = fopen(buf,"r")))
           {
             fprintf(stderr,"\n**Can't open file %s for input!",buf);
             terpri();
             input = saveinput;
             saveinput = NULL;
           }
          else
	   {
	     if(extension = rindex(buf,'.'))
	      {
	        convert_string(++extension,toupper);
		if(strequ(extension,"BIN") || strequ(extension,"OBJ") ||
		   strequ(extension,"SAV") || strequ(extension,"SYS") ||
		   strequ(extension,"TSK")) /* Binary input? */
		 { /* Read stuff in byte by byte. Maybe not the fastest
		       solution, but should work: */
		   UINT save_LC = LC;
		   while(fread(inbuf,sizeof(char),1,input)) 
                    {
		      setbytemem(LC++,*inbuf);
		    }
		   if(!silent_flag)
		    {
	              fprintf(stderr,
		        "\nLoaded %06o (%u.) bytes, from %06o to %06o.",
	                  (LC-save_LC),(LC-save_LC),save_LC,LC);
		    }
                   /* If LC was left odd, then put one zero more, so
                       that adr is adjusted to even address: */
		   if(LC & 1) { setbytemem(LC++,0); }
		   LILC = LC;
		   fclose(input);
                   input = saveinput;
                   saveinput = NULL;
		 }
	      }
	     else /* octal loading. */
	      {
/* If -s option specified, then don't show unassembled code when loading: */
	        if(silent_flag) { output = null_output; }
	      }
	     terpri(); /* intinp = 0; */
	   }
          goto loop;
        }
       case CTRL('W'): /* Write! */
        {
	  UINT begin,end,i;
          FILE *fp;

          if(!*buf)
	   {
	     fprintf(stderr,"\nPlease specify filename!");
	     goto takas;
	   }	
          if((fp = fopen(buf,"r")))
           {
             fprintf(stderr,"\n**File %s already exists! Overwrite? (y/n)",
	        buf);
	     if(toupper(getchar()) != 'Y')
	      {
		fclose(fp);
	        fprintf(stderr,"\nFile not overwritten.");
		goto takas;
	      }
           }

	  if(!(fp = fopen(buf,"w")))
	   {
             fprintf(stderr,"\n**Can't open file %s for output!",buf);
             goto takas;
           }

          i = begin = min(_mark,LC);
	  end = max(_mark,LC);

	  while(i < end)
           { /* Write stuff out byte by byte. Maybe not the fastest
		solution, but should work: */
             fwrite(getbyteptr(i++),sizeof(char),1,fp);
           }
          fclose(fp);
	  fprintf(stderr,"\nWrote %06o (%u.) bytes, from %06o to %06o.",
	    (end-begin),(end-begin),begin,end);
takas:
          terpri();
          goto loop;
        }
       case CTRL('U'): /* Unassemble! */
        {
	  UINT begin,end,save_LC;
          FILE *fp;

          fp = NULL;
          if(*buf) /* If filename specified? */
	   {
             if((fp = fopen(buf,"r")))
              {
                fprintf(stderr,"\n**File %s already exists! Append? (y/n)",
	                 buf);
	        if(toupper(getchar()) != 'Y')
	         {
		   fclose(fp);
	           fprintf(stderr,"\nFile not written.");
		   goto takas2;
	         }
              }
             if(!(fp = fopen(buf,"a")))
	      {
                fprintf(stderr,"\n**Can't open file %s for output!",buf);
                goto takas2;
              }
	     output = fp;
           }
          else { terpri(); }

          begin = min(_mark,LC);
	  end = max(_mark,LC);
	  save_LC = LC;
	  LC = begin;

	  while(LC < end)
           {
	     if(ctrl_c_pressed)
	      {
	        fprintf(stderr,"\n**Interrupted.");
		ctrl_c_pressed = 0;
		break;
	      }
	     unassemble((FROM_MEM|NO_BLANKS));
	     terpri();
             LILC = LC = Next_LC;
           }
	  LC = save_LC;
	  if(fp) /* If writing it into file... */
	   {
             fclose(output); /* Then close that file. */
	     output = stdout; /* And restore output to standard output. */
	   }
takas2:
          terpri();
          goto loop;
        }
       case CTRL('Y'): { z = get_word(buf); num_info(z); goto loop; }
       case CTRL('J'): case CTRL('M'): /* CR or LF */
        {
          if(!*buf) /* Just CR (= Unassemble the following instruction.) */
           { /* Don't unassemble with empty lines, when reading file: */
/*           if(saveinput) { terpri(); goto loop; } */
             if(saveinput) { goto hoop; }
bleep:
             terpri(); /* Emit newline */
             LC = Next_LC;
             goto loop;
           }
          else /* Enter the instruction */
           {
             z = get_word(buf);
             if(*buf == FAILED) { goto loop; }
             setmem(LC,z);
             if(*buf == MULTIPLE) { Next_LC = LC += 2; goto hoop; }
             fprintf(output,"\r%79s\r",""); col = 0; /* Clear this line */
             unassemble(FROM_USR);
             goto bleep;
           }
        } /* End of case CTRL('M'): */
       default:
        {
          fprintf(stderr,"  **Unknown command: ^%c !",(c + 64));
          terpri();
          goto loop;
        }
     } /* End of switch */
}


unassemble(from)
BYTE from;
{
        UINT save_LC,z;

        col = 0; /* Make some things sure */
        save_LC = LC;
        /* Print the location counter (8 chars) */
        out_oct(LC,6);
        output_stuff(": ");
        /* Print the instruction code in octal: */
        out_oct((z = fetch_word(0,FROM_MEM)),6);
/* LC is incremented by two after fetch_word */
        output_stuff("  ");
        emit_instr(z,(from&1));
        if(!(from & NO_BLANKS)) { to_nth_col(THE_COLUMN); }
        Next_LC = LC;
        LC = save_LC;
}


/* Convert stuff in buf to word, i.e. 16 bit integer */
UINT get_word(orig_buf)
char *orig_buf;
{
        register char *buf,*rest_of;
        UINT z;

        buf = orig_buf;
        rest_of = NULL;

        if(*buf == ':') /* Label definition */
         {
           buf = equate_label((buf+1),LC);
           buf = skip_blankos(buf);
 /* If there is only label-definition on line, e.g. :KALA then jump to ertzu.
    This is not really an error, but it just signals to calling function
     that this location should be asked again:
  */
           if(!*buf) { terpri(); goto ertzu; }
         }
        else if(*buf == '=') /* Equate label, like =LABELX EXPR */
         {
           char *s,*t; /* Temporary char pointers */
           buf = skip_blankos(buf+1); /* Get the label name */
           if(!(s = check_label(buf))) /* Get the pointer to the end */
            { /* of the label name, NULL is returned if not valid name */
balalaikka:
              fprintf(stderr,"\n**Invalid equate: %s",orig_buf);
              goto ertzu;
            } /* Get the pointer to the start of expr: */
           if(!(t = fun_index_not(s,f_isspace))) { goto balalaikka; }
           else /* If no expr, then print error message ^ */
            {
              *s = '\0'; /* Overwrite the char after label name */
               z = solve_expr(NULL,t,LC,LILC); /* Compute EXPR */
               if(*t == FAILED) { goto balalaikka; } /* If EXPR erroneous */
            }
           equate_label(buf,z); /* If above stuff ok, then do equating */
           terpri(); goto ertzu; /* Not really an error */
         }

        if(*buf == '"') /* string encountered */
         {
           Next_LC = LC = str_to_mem(buf,LC);
           terpri();
           goto ertzu;
         }

        /* If deposit command: */
        if((toupper(*buf) == 'D') && isspace(*(buf+1)))
         {
           char *equsign;

           if(!(equsign = index((buf+2),'=')))
            { /* If no equal sign at the line: */
              fprintf(stderr,"\n**INVALID DEPOSIT COMMAND: %s",orig_buf);
              goto ertzu;
            }
           else
            {
              *equsign = '\0'; /* Overwrite an = and get the address: */
              z = solve_expr(NULL,(buf = skip_blankos(buf+2)),LC,LILC);
              if(*buf == FAILED) { goto ertzu; }
              else { LC = z; }
              /* Get pointer to first value after equal sign: */
              buf = skip_blankos(equsign+1);
              goto bodhisattva; /* And go to loop */
/* Ei olla tiukkapipoja:
              if(LC & 1)
               {
                 fprintf(stderr,
"\nStarting adress must be an even octal number:\n%s",orig_buf);
                 goto ertzu;
               }
 */
            }
         }

        if(toupper(*buf) == 'B') /* Symbolic branch ? */
         {
           if(!(z = get_branch_code(buf))) { goto ertzu; }
         }
        else if(toupper(*buf) == 'S') /* Symbolic SOB ? */
         {
           if(!(z = get_sob_code(buf))) { goto ertzu; }
           else if(z == 1) { goto bodhisattva; } /* Not a SOB */
         }
        else /* it should be just a crude octal number, or label or expr. */
         {
bodhisattva:
           z = solve_expr(&rest_of,buf,LC,LILC);
           if(*buf == FAILED) { goto ertzu; }
/* Note that in this loop, the last one is not put here to memory yet: */
           if(buf = rest_of)
            {
              *orig_buf = MULTIPLE;
              setmem(LC,z);
              LC += 2;
              goto bodhisattva;
            }
         }
        return(z);
ertzu:
        *orig_buf = FAILED;
        return(0);
}


/* Fetch next word (= 16 bit integer) from somewhere. (I don't know where)
 */
UINT fetch_word(code,from)
BYTE code; /* 0 = from main, 1 = from emit_operand */
BYTE from; /* Ask from user or directly from memory */
{
    char *myfgets();
    char *s,c;
    UINT z;
    char buf[MAXBUF+2];


    if(from == FROM_USR)
     {
turpea:
       if(code)
        {
          /* If calling from emit_operand and interactive input, then get
            the attention of user for this special case by emitting some fancy
            ANSI-codes: 1 = Bold, 4 = Underscore, 5 = Blink, 7 = Inverse On */
            if(intinp) { fprintf(stderr,"\033[1m"); }
            /* Print the location counter (8 chars) */
            fprintf(output,"%06o: ",LC);
            if(intinp) { fprintf(stderr,"\033[0m"); } /* All attributes off */
        }

       *buf = '\0';
       if(intinp)
        { /* Koodi rumenee. */
          if(saveinput) { myfgets(buf,MAXBUF,input); }
          else
           {
             get_n_chars(buf,MAXBUF,0xFF);
             /* Delete the stuff user typed: */
             print_n_dels(strlen(buf));
           }
          /* If calling from emit_operand then delete the inversed
              location counter (used as prompt for user): */
          if(code) { print_n_dels(8); }
        }
       else { myfgets(buf,MAXBUF,input); }

       delete_comment(buf);

       z = get_word(buf);
       if(*buf == FAILED) { goto turpea; }
       setmem(LC,z); /* Put that stuff to memory */
     }
    else if(from == FROM_MEM)
     {
       z = getmem(LC);
     }
/*
    else
     {
       z = getw(input);
       if(feof(input)) { myexit(0); }
       if(ferror(input))
        {
          fprintf(stderr,"\n**ERROR on input !\n");
          myexit(1);
        }
     }
 */

    LC += 2;    /* Advance Location Counter one word */
    return(z);
}


UINT str_to_mem(string,adr)
register BYTE *string;
register UINT adr;
{
        BYTE *parse_char();
        BYTE quote,charac;

        quote = *string++; /* skip first quote, and save it to quote */

        /* Go through string until '\0' or second quote met: */
        while(*string && (*string != quote))
         {
           string = parse_char(&charac,string);
           setbytemem(adr++,charac);
         }
        /* If odd number of characters, then put one zero more, so
            that adr is adjusted to even address: */
        if(adr & 1) { setbytemem(adr++,0); }
        return(adr);
}


/* 
   This finds the end of the string. First char. of string should
    be an opening quote. Returns pointer to the first character
    after closing quote.
 */
char *find_string_end(string)
register BYTE *string;
{
        BYTE *parse_char();
        BYTE quote,charac;

        quote = *string++; /* skip first quote, and save it to quote */

        /* Go through string until '\0' or second quote met: */
        while(*string && (*string != quote))
         {
           string = parse_char(&charac,string);
         }

        return((char *) (*string ? (string+1) : string));
}



help()
{
        fprintf(stdout,
"\nHELP:\n");
        fprintf(stdout,
"Enter 16-bit octal numbers for instructions (0 - 177777).\n");
        fprintf(stdout,
"Octal numbers can be preceded by a various prefixes. Prefixes are:\n");
        fprintf(stdout,
" +          Plus. No effect.\n");
        fprintf(stdout,
" -          Negated.\n");
        fprintf(stdout,
" ~          Complemented.\n");
        fprintf(stdout,
" <          Shift left (logical).\n");
        fprintf(stdout,
" >          Shift right (logical).\n");
        fprintf(stdout,
" [          Shift left (arithmetic), synonymous to <.\n");
        fprintf(stdout,
" ]          Shift right (arithmetic).\n");
        fprintf(stdout,
" .          Location Counter is added to number. Examples: .6  .+12  .-4  .\n");
        fprintf(stdout,
" %c          LC+2 is subtracted from number. Useful with\n",PREF1CHAR);
        fprintf(stdout,
"             relative and relative deferred addressing (= modes 67 & 77).\n");
        fprintf(stdout,
" *          Word is fetched from location, i.e. indirection at assembly time\n");
        fprintf(stdout,
"             Single * fetches from current location, i.e. keeps it intact.\n");
        fprintf(stdout,
"Prefixes can be combined in arbitrary order. Examples:\n");
        fprintf(stdout,
" -~num      num incremented by one.     <<<num     num multiplied by 8.\n");
        fprintf(stdout,
" %c.         Relative reference to the location of this instruction.\n",
                 PREF1CHAR);
        fprintf(stdout,
"Special commands:\n");
        fprintf(stdout,
" octnum^L   Set new location counter to be octnum.\n");
        fprintf(stdout,
" octnum^Y   Show octal number in various formats.\n");
        fprintf(stdout,
" ^B         Go one word backward, i.e. decrement location counter by 2.\n");
        fprintf(stdout,
" ^C or ^Z   Exit.\n");
        fprintf(stdout,
" ^I or ?    This help screen.\n");
        fprintf(stdout,
"Branches can also be entered symbolically (e.g: BHIS 003274) Branches are:\n");
        list_branches();
}



/* Main disassembly routine. */
/* Note that when this is entered, LC is already incremented to next word,
    i.e. it corresponds to PC in runtime.
 */
emit_instr(inscode,from)
/* register */ UINT inscode;
BYTE from;
{
    register UINT op_code;
    register char *opname;
    char tmp_buf[81];

    op_code = get_elem(inscode,instr2,opcode);

    /* If name is found from opcodes2 then it is standard two argument
        instruction. (MOV, CMP, ADD, etc.):
     */
    if(opname = opcodes2[op_code])
     {
       output_with_tab(opname);
       emit_operand(get_elem(inscode,instr2,opr1mod),
                    get_elem(inscode,instr2,opr1reg),
                    from);
       out_char(comma);
       emit_operand(get_elem(inscode,instr2,opr2mod),
                    get_elem(inscode,instr2,opr2reg),
                    from);
     }
    else /* It is something else */
     {
       switch(op_code)
        {

 /* --------------------------------------------------------------------- */

          case 0:
           {
             op_code = get_elem(inscode,instr1,opcode);
             if(!op_code)
              {
                output_stuff(((inscode <= 7) ? opcodes0000[inscode] : NEOP));
              }
             else if(op_code == 2)
              {
                if(inscode <= 000207)
                 {
                   output_with_tab("RTS");
                   emit_operand(0,get_elem(inscode,instr2,opr2reg),from);
                 }
                else if(/* (inscode >= 000210) && */ (inscode <= 000227))
                 {
                   output_stuff(NEOP);
                 }
                else if(/* (inscode >= 000230) && */ (inscode <= 000237))
                 {
                   output_with_tab("SPL");
/*                 fprintf(output,"%o",get_elem(inscode,instr2,opr2reg)); */
                   out_char(('0' + get_elem(inscode,instr2,opr2reg)));
                 }
                else /* inscode = 000240 - 000277 */
                 {
                   emit_clear_or_set_codes(get_elem(inscode,instr3,bits5_0));
                 }
              }
             else if(op_code <= 3) /* It is 1 (= JMP) or 3 (= SWAB) */
              {
                emit_instr1(inscode,opcodes_jmp_swab[op_code],from);
              }
             else if(/* (op_code >= 0004) && */ (op_code <= 0037))
              { /* Branches 1 */
                output_with_tab(opcodes_br1[get_elem(inscode,two_bytes,hi)]);
                emit_displacement(get_elem(inscode,two_bytes,lo));
              }
             else if(/* (op_code >= 0040) && */ (op_code <= 0047))
              {
                output_with_tab("JSR");
                goto print_xor;
              }
             else /* if((op_code >= 0050) && (op_code <= 0077)) */
              { /* Standard one argument instructions, word versions. */
                if(op_code == 0064)
                 { /* MARK instruction, exception in this series */
                   output_with_tab(opcodes0050[op_code - 0050]);
                   sprintf(tmp_buf,"%o",get_elem(inscode,instr3,bits5_0));
                   output_stuff(tmp_buf);
                 }
                else /* CLR, NEG, COM, etc. */
                 {
                   emit_instr1(inscode,opcodes0050[op_code - 0050],from);
                 }
              }
             break;
           }

 /* --------------------------------------------------------------------- */

          case 7:
           {
             op_code = get_elem(inscode,instr2,opr1mod);

             if(op_code == 5)
              { /* FIS - Floating Instruction Set */
                if((op_code = get_elem(inscode,instr2,opr2mod)) < 4)
                 { /* FADD, FSUB, FMUL, FDIV */
                   output_with_tab(opcodes_FIS[op_code]);
                   emit_operand(0,get_elem(inscode,instr2,opr2reg),from);
                 }
                else { output_stuff(NEOP); }
              }
             else if(opname = opcodes070[op_code])
              { /* If name found from table, then it is one of the
                    instructions in EIS (= Extended Instruction Set)
                   (two arguments, but another is always register) */
                output_with_tab(opname);
                if(op_code <= 3)
                 { /* MUL, DIV, ASH, ASHC */
                   emit_operand(get_elem(inscode,instr2,opr2mod),
                                get_elem(inscode,instr2,opr2reg),
                                from);
                   out_char(comma);
                   emit_operand(0,get_elem(inscode,instr2,opr1reg),from);
                 }
                else if(op_code == 4) /* XOR */
                 { /* Like previous four, but arguments in opposite order */
print_xor: /* JSR also uses this */
                   emit_operand(0,get_elem(inscode,instr2,opr1reg),from);
                   out_char(comma);
                   emit_operand(get_elem(inscode,instr2,opr2mod),
                                get_elem(inscode,instr2,opr2reg),
                                from);
                 }
                else /* op_code == 7  SOB */
                 { /* Like XOR, but bits 5-0 are displacement backward
                       instead of normal mode & reg. */
                   emit_operand(0,get_elem(inscode,instr2,opr1reg),from);
                   out_char(comma);
                   emit_SOB_displ(get_elem(inscode,instr3,bits5_0));
                 }
              }
             else
              {
                output_stuff(NEOP);
              }
             break;
           }

 /* --------------------------------------------------------------------- */

          case 010:
           {
             op_code = get_elem(inscode,instr1,opcode);
             if(/* (op_code >= 01000) && */ (op_code <= 01047))
              { /* Branches 2 (& two traps) */
                output_with_tab(opcodes_br2[get_elem(inscode,two_bytes,hi) &
                                  ~0200]);
                if(op_code >= 01040) /* EMT or TRAP instruction */
                 { out_oct(get_elem(inscode,two_bytes,lo),3); }
                else { emit_displacement(get_elem(inscode,two_bytes,lo)); }
              }
             else /* if((op_code >= 01050) && (op_code <= 01077)) */
              { /* One arg. instructions, byte-versions (CLRB, INCB, etc.) */
                emit_instr1(inscode,opcodes1050[op_code - 01050],from);
              }
             break;
           }

 /* --------------------------------------------------------------------- */

          case 017:
           { output_stuff("FP11-???"); break; } /* Unknown opcodes */

 /* --------------------------------------------------------------------- */

        } /* Switch */
     } /* Else */

}



/* This is used to emit instructions of one argument of standard format
   (i.e. from 005000 onward and 105000 onward, and some others too).
 */
emit_instr1(inscode,opname,from)
UINT inscode;
char *opname;
BYTE from;
{
        if(opname)
         {
           output_with_tab(opname);
           emit_operand(get_elem(inscode,instr2,opr2mod),
                        get_elem(inscode,instr2,opr2reg),
                        from);
         }
        else { output_stuff(NEOP); }
}


/* This is used to emit NOP's and clear and set flags instructions: 
   (and combinations of them)
 */
emit_clear_or_set_codes(bits)
register UINT bits;
{
        register UINT set_flag;

        set_flag = (bits & 020);
        bits &= 017; /* Clear all other than flag bits */

        if(!bits)
         { /* Use symbol NoP for that other, undocumented NOP,
               which sets no flags at all */
           output_stuff((set_flag ? "NoP" : "NOP"));
         }
        else if(bits == 017) /* All bits on */
         {
           out_char(set_flag ? 'S' : 'C');
           output_stuff("CC");
         }
        else
         {
           register UINT cnt,index,bit_index;
           char *ptr,buf[25],buf2[29];

           cnt = index = 0;
           bit_index = 1;
           ptr = buf;

           do
            {
              if(bits & bit_index)
               {
                 cnt++;
                 if(set_flag) { *ptr++ = 'S'; *ptr++ = 'E'; }
                 else         { *ptr++ = 'C'; *ptr++ = 'L'; }
                 *ptr++ = flags[index];
                 *ptr++ = '!';
               }
              bit_index <<= 1;
            } while(++index <= 3);

           *--ptr = '\0'; /* Overwrite the last ! with zero */

           /* If there was just one flag to be cleared or set then use
               single corresponding opcode, but if there were more, then
               print corresponding opcodes inside angles and separated
               by !'s:
            */
           sprintf(buf2,((cnt == 1) ? "%s" : "<%s>"),buf);
           output_stuff(buf2);
         }
}


/* This emits displacement for standard branches: */
emit_displacement(displ)
char displ; /* Signed byte */
{       /* displ should be sign-extended to word before doubling and adding:
           (be sure that your compiler will do that) */
        out_oct((LC+(2*displ)),6);
}


/*
 This emits displacement for SOB instruction: (only backward branch possible)
 */
emit_SOB_displ(displ)
BYTE displ; /* Unsigned, only six lowest bits (5-0) are significant */
{
        out_oct((LC-(2*displ)),6);
}


/* This emits standard operand, when mode is from 0 to 7 and reg is also from
    0 to 7.
   Also outputs PC-adressing modes with their own symbols.
   If one more word is needed (when PC-adressing mode, or mode is 6 or 7)
    then one word is input with fetch_word.
 */
emit_operand(mode,reg,from)
int mode,reg;
BYTE from;
{
        UINT x;
        char buf[41],buf2[41];

        /* If PC addressing: */
        if((reg == 7) && (mode & 2)) /* mode must be 2, 3, 6 or 7 */
         {
           x = fetch_word(1,from);
           switch(mode)
            {
              case 3: { out_char('@'); } /* Absolute */
              case 2: { out_char('#'); goto attila; } /* Immediate */
              case 7: { out_char('@'); } /* Relative indirect */
              case 6: /* Relative */
               {
                 x += LC;
attila:
                 out_oct(x,6);
               }
            }
         }
        else
         {
           if(mode < 6)
            {
              sprintf(buf,mode_strings[mode],reg_names[reg]);
              output_stuff(buf);
            }
           else /* Modes 6 & 7 require index to be fetched after instruction*/
            {
              sprintf(buf,"%06o",fetch_word(1,from));
              sprintf(buf2,mode_strings[mode],buf,reg_names[reg]);
              output_stuff(buf2);
            }
         }
}




print_n_dels(n)
int n;
{
        while(n--) { fputs("\b \b",output); }
/*      fprintf(output,"\033[%uD",n); This moves cursor back n cols */
}

/* Print blankos until column n reached.
   (but at least one blanko, if over that column already) */
to_nth_col(n)
UINT n;
{
        do { out_char(' '); } while(col < n);
}


out_oct(x,prec) /* Output octal number x with precision prec */
UINT x,prec; /* Currently prec must be between 1 - 9 */
{
        static char *out_oct_format = "%00o";

        out_oct_format[2] = ('0' + prec); /* Set precision */
        fprintf(output,out_oct_format,x);
        col += prec;
}


output_with_tab(s)
char *s;
{
/* Let's hope that s is not longer than 8 chars: (does it matter at all ?) */
        fprintf(output,"%-8s",s); /* Print s left justified */
        col += 8;
}


output_stuff(s)
char *s;
{
        fputs(s,output);
        col += strlen(s);
}



list_branches()
{
        BYTE flag=0;
        register char **ptr;

        ptr = opcodes_br1;

suuttimet:
        while(*ptr)
         { /* Don't print ??? nor EMT or TRAP instructions from tables: */
           if(**ptr == 'B') { fprintf(stderr,"%s ",*ptr); }
           ptr++;
         }

        if(!flag) { flag = 1; ptr = opcodes_br2; goto suuttimet; }

        fprintf(stderr,"BHIS BLO SOB"); /* These are not in branch tables */
        terpri();
}


/* Return register code between 0 and 7 corresponding to regname.
   -1 is returned if it is unrecognized register name.
 */
UINT get_regcode(regname)
char *regname;
{
        register UINT i;
        register char **p;

        /* If regname of the form R0 - R7 (or %0 - %7): */
        if(((toupper(*regname) == 'R') || (*regname == '%'))
             && isoctdigit(*(regname+1)) && !*(regname+2))
         { return(*(regname+1) - '0'); }

        for(p = reg_names, i = 0; *p; p++, i++)
         {
           if(!strcmp(regname,*p)) { return(i); }
         }

/* Not found from reg_names table (illegal register name), return error code:
 */
        return(-1);
}


UINT get_branch_code(buf)
char *buf;
{
          UINT z;
          char brop[MAXBUF+2],adrbuf[MAXBUF+2];

          *brop = *adrbuf = '\0';
          if(sscanf(buf,"%s %s",brop,adrbuf) < 2)
           {
             fprintf(stderr,"\n**Format: branch octal_address");
             terpri();
             return(0);
           }
          z = solve_expr(NULL,adrbuf,LC,LILC);
          if(*adrbuf == FAILED) { return(0); }
          return(_get_branch_code(brop,z));
}


UINT get_sob_code(buf)
char *buf;
{
        int f_isspace(),toupper();
        int r,z;
        char reg[MAXBUF+2],adrbuf[MAXBUF+2];

        if(!streq("SOB",buf)) { return(1); }

        *reg = *adrbuf = '\0';
        if((z = sscanf((buf+3),"%[^,]%*c%s",reg,adrbuf)) != 2)
         {
           fprintf(stderr,
"\n**Format: SOB reg,octal_address  (matched: %d  reg: %s/%d  adrbuf: %s/%d)",
               z,reg,strlen(reg),adrbuf,strlen(adrbuf));
           terpri();
           return(0);
         }

        /* Overwrite the first blanko after last non-blanko char. in reg: */
        if(buf = fun_rindex_not(reg,f_isspace)) { *(buf+1) = '\0'; }

        if((r = get_regcode(reg)) & ~7) /* If r not 0-7 */
         {
           fprintf(stderr,"\n**Invalid register: %s/%d",reg,strlen(reg));
           terpri();
           return(0);
         }

        z = solve_expr(NULL,adrbuf,LC,LILC);
        if(*adrbuf == FAILED) { return(0); }

        /* Add reg*64 and diff to SOB base code: */
        return(compute_sob_code((077000 + (r << 6)),z,LC));
}



UINT compute_sob_code(base_et_reg,dest,lc)
UINT base_et_reg,dest,lc;
{
        UINT diff;

        if(dest & 1)
         {
           fprintf(stderr,"\n**SOB address must be even, not %6o !",
                    dest);
           terpri();
           return(0);
         }

        /* Note that LC is not yet incremented when this is called: */
        diff = ((((int) (lc+2)) - dest)/2);

        if(diff > 077)
         {
           fprintf(stderr,
"\n**Can't branch to %06o from %06o  --  low lim: %06o   up lim: %06o",
             dest,lc,(lc+2-(2 * 077)),(lc+2));
           terpri();
           return(0);
         }

        /* Add displacement to SOB base code et register: */
        return(base_et_reg + diff);
}




/* Assembles branch opcode & destination address given, to corresponding
    16-bit instruction.
 */
UINT _get_branch_code(brop,addr)
char *brop;
int addr;
{
        int toupper();
        UINT branch_code;
        register char **ptr;

        /* Handle two synonyms which are not in tables: */
             if(!strcmp(brop,"BHIS")) { brop = "BCC"; }
        else if(!strcmp(brop,"BLO"))  { brop = "BCS"; }

        /* Search first branch opcode table: */
        for(ptr = opcodes_br1; *ptr; ptr++)
         {
           if(!strcmp(brop,*ptr))
            { /* Multiply index to opcode array by 000400 (= 256.): */
              branch_code = ((ptr - opcodes_br1) << 8);
              goto lihamakkara;
            }
         }

        /* Search the second array: */
        for(ptr = opcodes_br2; *ptr; ptr++)
         {
           if(!strcmp(brop,*ptr))
            { /* Like in previous loop,
                  but also add 100000 (base code of BPL): */
              branch_code = (((ptr - opcodes_br2) << 8) + 0100000);
              goto lihamakkara;
            }
         }

        fprintf(stderr,
         "\n**Unrecognized branch opcode: %s   Branches are:\n",brop);
        list_branches();
        return(0); /* Return zero to signal invalid branch opcode */

lihamakkara:
        return(compute_branch(branch_code,addr,LC));
}


UINT compute_branch(branch_code,dest_addr,lc)
UINT branch_code,dest_addr,lc;
{
        register int diff;


        if(dest_addr & 1)
         {
           fprintf(stderr,"\n**Branch address must be even, not %6o !",
                    dest_addr);
           terpri();
           return(0);
         }

        /* Note that LC is not yet incremented when this is called: */
        diff = ((((int) dest_addr) - ((int) (lc+2)))/2);

        if((diff < -128) || (diff > 127))
         {
           fprintf(stderr,
"\n**Can't branch to %06o from %06o  --  low lim: %06o   up lim: %06o",
             dest_addr,lc,(lc+2+(2 * -128)),(lc+2+(2*127)));
           terpri();
           return(0);
         }

        /* Add low byte of diff as unsigned to branch base code: */
        return(branch_code + ((BYTE) diff));
}



/* Solve expression containing prefixes and an octal number or label: */
UINT solve_expr(rest,start,_LC,_LILC)
char **rest,*start;
UINT _LC,_LILC;
{
        int f_isoctdigit(),f_isalnum();
        UINT result,len;
        register char *srcbuf;

        /* Skip all prefix-characters: */
        if(!(srcbuf = fun_index(start,f_isalnum)))
         { srcbuf = (start + strlen(start)); }

        len = strlen(srcbuf);

/*
  If there is no digits nor label after prefixes, but the rightmost
   prefix is a dot then treat is as zero were at the end of buffer.
   I.e. buffer "." is same as ".0"
   and "some_prefixes." is same as "some_prefixes.0"
 */
        if(!len && (srcbuf > start))
         {
           if(*(srcbuf-1) == '.')      { result = 0;    goto opossumi; }
/* Also if expression ends in * then that is understood as contents of
   this location: */
           else if(*(srcbuf-1) == '*') { result = _LC;  goto opossumi; }
         }
        else if(isdigit(*srcbuf) || !*srcbuf)
         {
           result = atoo(rest,srcbuf,start,len);
	   if(*start == FAILED) { return(0); }
         }
        else /* First of srcbuf is letter, i.e. there is a label: */
         {
           result = handle_label_ref(srcbuf,start,_LC,_LILC);
           /* If forward reference, then don't compute the prefixes yet: */
           if(*start == FORWARD) { return(result); }
         }

opossumi:
        *srcbuf = '\0'; /* Overwrite the first digit or letter */
        return(compute_prefixes(start,result,_LC,_LILC));

}


/* Prefix-operators in buffer start are applied successively to result
   from right to left, and final result is returned:
 */
UINT compute_prefixes(start,result,_LC,_LILC)
char *start;
register UINT result;
UINT _LC,_LILC;
{
        register char *prefptr;

        /* Set prefptr to the string end (so that it points to '\0') */
        prefptr = (start + strlen(start));

        /* Compute prefix-operators from right to left: */
        while(--prefptr >= start)
         {
           switch(*prefptr)
             {
            /* case ' ': case '\t': { break; } */ /* Ignore white spaces */
               case '+': { break; } /* Do nothing with plus */

               case '-': { result = -result; break; } /* Negate */

               case '~': { result = ~result; break; } /* Complement */

               case '<': { result <<= 1; break; }  /* Left shift (logical) */

               case '>': { result >>= 1; break; }  /* Right shift (logical) */

               /* Left shift (arithmetic) */
               case '[': { ((int) result) <<= 1; break; }

               /* Right shift (arithmetic) */
               case ']': { ((int) result) >>= 1; break; }

               /* If number is preceded by a dot then add LC to it: */
               case '.': { result += _LILC; break; }

               /* If number is preceded by a ! then it is understood
                 as PC-relative address, so subtract Location Counter from it.
                 (LC+2) is used because LC is not incremented until after
                 call to this solve_expr is made from fetch_word: */
               case PREF1CHAR: { result -= (_LC+2); break; }

               /* Fetch, i.e. indirection at the assembly time: */
               case '*': { result = getmem(result); break; }

               default:
                {
                  fprintf(stderr,
"\n**Invalid prefix-operator %c in prefix-group: %s\n",*prefptr,start);
                }
             }
         }

        return(result);
}


/* Ascii to Octal: */
/* Beware, some braindamaged code ahead ! */
UINT atoo(rest,srcbuf,orig_srcbuf,len)
char **rest,*srcbuf,*orig_srcbuf;
UINT len;
{
        UINT high_byte,result;
        char *first_blank,*first_comma;

        high_byte = 0;

/* If there is the blanko after digits, then overwrite it with '\0',
    note that there SHOULDN'T be any blankos before the digits,
    when atoo is called, otherwise this doesn't work ! */
luuppi:

        if(first_blank = fun_index(srcbuf,f_isspace))
         {
           *first_blank = '\0';
           first_comma = index((first_blank+1),',');
         }
        else
         {
           if(first_comma = index(srcbuf,',')) { *first_comma = '\0'; }
         }

        if(first_comma && rest)
         { *rest = fun_index_not((first_comma+1),f_isspace); }
        else if(first_blank && rest)
         { *rest = fun_index_not((first_blank+1),f_isspace); }
        else if(rest) { *rest = NULL; }

/* argument len can be anyway incorrect at this stage, so compute it
    again: (this code is from @*#$%& !!!) */
        len = strlen(srcbuf);

        /* Check that buffer contains valid octal number: */
        if((len > 6) /* More than six digits ? */
            || !len                     /* Empty line ? */
            || !all_charsp(srcbuf,f_isoctdigit) /* Not all chars are 0-7 ? */
            || ((len == 6) && (*srcbuf > '1'))) /* If length is just 6, but */
         {                               /* ...first digit is not 0 or 1 ? */
           fprintf(stderr,"\n**INVALID OCTAL NUMBER !");
ertzu:
           terpri();
           *orig_srcbuf = FAILED; /* Store FAILED to the */
                         /* beginning of srcbuf to indicate error condition */
           return(0);
         }

        sscanf(srcbuf,"%o",&result);

        if(first_comma && (*++first_comma == ',')) /* adjacent commas ,, */
         { /* I.e. high_byte,,low_byte */
           if(result > 255)
            {
              fprintf(stderr,"\n**INVALID OCTAL BYTE !");
              goto ertzu;
            }
           high_byte = result;
           srcbuf = skip_blankos(first_comma+1);
           goto luuppi;
         }

        return((high_byte << 8) + result);
}


invalid_label(label_buf)
char *label_buf;
{
	terpri();
	fprintf(stderr,"**Invalid label: %s !",label_buf);
	terpri();
}


char *check_label(label)
char *label;
{
        char *s;

        s = label;

/* C-like names: First character must be letter, rest of characters can be
    letters or numbers. Underscore (_) is counted as letter too.
   Case is significant ?
 */
	if(!isalpha(*s)) { return(NULL); }
        while(isalnum(*++s)) {}
        return(s);
}


UINT handle_label_ref(label_buf,prefixes,lc,lilc)
char *label_buf,*prefixes;
UINT lc,lilc;
{
        LLIST label;

        if(nilp(label = intern(strdup(label_buf))))
         {
           invalid_label(label_buf);
           *prefixes = FORWARD;
	   return(-1);
	 }

        /* Old label, i.e. equated label or backward reference */
        if(getlhasvalueflag(label))
         { /* Return the value of the label: */
           return(getlvalue(label));
         }
        else /* New label, i.e. forward reference */
         {
           /* By overwriting the first character of the label we separate
               prefixes from the label name, so that prefixes can be interned:
            */
           *label_buf = '\0';

           setlreflist(label,
	     getnewreflist(lc,lilc,strdup(prefixes),getlreflist(label)));

           /* Tell the solve_expr that this was forward label: */
           *prefixes = FORWARD;

/* If lc is equal to lilc, then this is one word instruction,
    i.e. branch or SOB (what about EMT or TRAP ?), so return
    LC+2, so that branch or SOB without any displacement is
    compiled to location LC. (= base code of corresponding branch)
   Otherwise return -1, so that is put to that location (lc), until
    that label is resolved later. If that unresolved reference is
    accidentally used, then it generates "odd address error" if
    there is word-instruction.
 */ 
           return((lc == lilc) ? (lc+2) : -1);
         }
}


char *equate_label(label_buf,val)
char *label_buf;
UINT val;
{
	LLIST label;
	char *rest_of_buf,save_char;

        if(!(rest_of_buf = check_label(label_buf)))
         {
           invalid_label(label_buf);
           return(label_buf);
         }

        save_char = *rest_of_buf;
        *rest_of_buf = '\0';

        if(nilp(label = intern(strdup(label_buf))))
         {
           invalid_label(label_buf);
           *rest_of_buf = save_char;
	   return(rest_of_buf);
	 }

        /* If that label has value already, then print warning message: */
        if(getlhasvalueflag(label))
         {
           printf("\n**Label %s redefined. Old value: %6o New value: %6o\n",
                     getlname(label),getlvalue(label),val);
         }

        setlvalue(label,val);
	setlhasvalueflag(label,1);
        resolve_forwards(label,val);

        *rest_of_buf = save_char;
        return(rest_of_buf);
}



resolve_forwards(label,val)
LLIST label;
UINT val;
{
    register RLIST ref_list;

    ref_list = getlreflist(label);

    while(!nilp(ref_list))
     {
       fill_the_hole(val,getrlc(ref_list),
	                 getrlilc(ref_list),getrprefixes(ref_list));
       ref_list = getrnext(ref_list);
     }
}


/* Fill the forward reference in address adr with the value got by
    applying the prefix-operators in expr to val_of_label:
 */
fill_the_hole(val_of_label,adr,ilc,expr)
register UINT val_of_label,adr,ilc;
char *expr;
{
/* ilc is instruction location counter (.) at the time of forward reference,
    i.e. it is address of first instruction before adr, so if ilc == adr,
    then that instruction is branch or SOB
 */
        /* Apply prefix-operators to val_of_label: */
 	val_of_label = compute_prefixes(expr,val_of_label,adr,ilc);

        if(adr == ilc) /* Branch or SOB (what about EMT, TRAP, SPL & MARK ?)*/
         {
           ilc = getmem(adr); /* Get the base code */
           /* If base code is between 077000 and 077777 then it is SOB: */
           if((ilc & 0177000) == 077000)
            { val_of_label = compute_sob_code(ilc,val_of_label,adr); }
           else /* It is some branch code */
            { val_of_label = compute_branch(ilc,val_of_label,adr); }

 /* If compute_sob_code or compute_branch returned zero (indicating error),
     then don't change the contents of adr: (keep base code intact) */
             if(!val_of_label) { val_of_label = ilc; }
         }

        setmem(adr,val_of_label);
}

print_matching_labels(pattern)
char *pattern;
{
    LLIST lista;

    for(lista=all_labels; !nilp(lista); lista = getlnext(lista))
     {
       if(wildcard(pattern,getlname(lista)))
        {
	  printlabelinfo(lista);
	}
     }
}

printlabelinfo(label)
LLIST label;
{
    fprintf(output,"%s\t",getlname(label));
    if(getlhasvalueflag(label))
     {
       fprintf(output,"%06o",getlvalue(label));
     }
    else { fprintf(output,"******"); }
    if(getlreflist(label))
     {
       fprintf(output,"\t");
       printreflist(getlreflist(label));
     }
    fprintf(output,"\n");
}

report_unresolved()
{
        register LLIST lista;
        BYTE flag=0;

	for(lista = all_labels; !nilp(lista); lista = getlnext(lista))
         {
	   if(!getlhasvalueflag(lista))
            {
              if(!flag)
               {
                 terpri();
                 fprintf(output,"**Unresolved references:\n");
                 flag = 1;
               }
              fprintf(output,"%s\t\t",getlname(lista));
              printreflist(getlreflist(lista));
	      fprintf(output,"\n");
            }
         }

}

printreflist(lista)
RLIST lista;
{
    if(!nilp(lista))
     {
       do
        {
          fprintf(output,"%06o %06o %s",
            getrlc(lista),getrlilc(lista),getrprefixes(lista));
          lista = getrnext(lista);
	  if(nilp(lista)) { break; }
	  putc(' ',output);
        } while(1);
     }
}
           

delete_comment(bufferi)
char *bufferi;
{
        int f_isspace();
        char *pupu;

        /* Convert buffer to uppercase, but don't convert stuff
            inside the doublequotes (string): */
        if(pupu = index(bufferi,'"'))
         { *pupu = '\0'; }
/* Convert only to the first doublequote, if there's any: */
        convert_string(bufferi,toupper);
        if(pupu) { *pupu = '"'; } /* Restore doublequote */
/* Cut line from the first comment character (usually ;), if there is any: */
/* (If there's a string, then don't cut that, if it contains semicolon ;) */
	if(pupu =
            index((pupu ? find_string_end(pupu) : bufferi),COMMENT_CHAR))
         { *pupu = '\0'; }
/* Strip blankos from the end: */
        if(pupu = fun_rindex_not(bufferi,f_isspace))
	 {
           *(pupu+1) = '\0';
         }
/* If there is nothing but blankos, then make it empty line: */
        else { *bufferi = '\0'; }
}


/* ====================================================================== */
/* Hoehaa: */

init_default_labels()
{
    LLIST tmp;

    setlvalue(tmp=intern("PSR"),PSR); setlhasvalueflag(tmp,1);
    setlvalue(tmp=intern("PSW"),PSR); setlhasvalueflag(tmp,1);
    setlvalue(tmp=intern("CSR"),CSR); setlhasvalueflag(tmp,1);
    setlvalue(tmp=intern("KBSTAT"),KBSTAT); setlhasvalueflag(tmp,1);
    setlvalue(tmp=intern("KBDATA"),KBDATA); setlhasvalueflag(tmp,1);
    setlvalue(tmp=intern("PRSTAT"),PRSTAT); setlhasvalueflag(tmp,1);
    setlvalue(tmp=intern("PRDATA"),PRDATA); setlhasvalueflag(tmp,1);

    init_reg_labels();
}


init_reg_labels()
{
    register char **p;
    register reg_adr = REGS;
    LLIST tmp;

    for(p = reg_names; *p; p++, reg_adr += 2)
     {
       setlvalue((tmp=intern(*p)),reg_adr);
       setlhasvalueflag(tmp,1);
     }
}



num_info(x)
UINT x;
{
        char *itohex();
        char buf[15];

        fprintf(stderr,
/* 042120 135657 104,120 -56351. 27345. 0x1234 'PD' */
"\nOCTAL  COMPL  BYTPAIR DECIM   UDEC   HEX         FEDCBA9876543210\n");
        fprintf(stderr,
  "%06o %06o %03o,%03o %6d. %5u. 0x%s '%c%c' ",
         x,~x, get_elem(x,two_bytes,hi), get_elem(x,two_bytes,lo),
          x,x,itohex(buf,x),
           kamara(get_elem(x,two_bytes,lo)),kamara(get_elem(x,two_bytes,hi)));

        print_bits(x,stderr);
        terpri();
}


kamara(c)
BYTE c;
{
        return(((c < ' ') || (c > '~')) ? '.' : c);
}


/* Print bits 15 - 0 so that every second group of three bits is inversed.
   E.g: 123456 -> 1010011100101110
                   ^^^   ^^^   ^^^
   Those bits marked with ^ are printed inversed.
 */
print_bits(x,fp)
UINT x;
FILE *fp;
{
        register UINT bit_index = 0x8000,i=0;
        register BYTE flag=0;

        while(bit_index)
         {
           fputc(('0' + !!(x & bit_index)),fp);
           if(!(i++ % 3))
            {
              if(!flag) { fputs("\033[7m",fp); flag = 1; }
              else      { fputs("\033[0m",fp); flag = 0; }
            }
           bit_index >>= 1;
         }

        if(flag) { fputs("\033[0m",fp); }
}


UINT prev_regs[9];
UINT prev_flags[9]; /* This is indexed with indexes 8, 4, 2 and 1 */


reset_prevs()
{
        register UINT i;

        for(i=0; i < 8; i++) { prev_regs[i]  = getreg(i); }
        for(i=8; i; i >>= 1) { prev_flags[i] = (getpsr() & i); }
}



/* This prints registers R0-PC in octal plus flags N, Z, V & C from PSR.
    All registers/flags which have changed since previously printed are
    printed inversed.
 */

print_regs()
{
        register UINT i,x;
        BYTE flag=0;

        for(i=0; i < 8; i++)
         { printf("%-8s",reg_names[i]); }
        printf("N Z V C\n");

        for(i=0; i < 8; i++)
         {
           if((x = getreg(i)) != prev_regs[i])
            {
              printf("\033[%sm",CHAREG);
              prev_regs[i] = x;
              flag = 1;
            }
           else { flag = 0; }
           printf("%06o",x);
           if(flag) { fputs("\033[0m",stdout); }
           printf("  ");
         }

        for(x=getpsr(),i=8;;)
         {
           if((x & i) != prev_flags[i])
            {
              printf("\033[%sm",CHAREG);
              prev_flags[i] = (x & i);
              flag = 1;
            }
           else { flag = 0; }
           putchar('0' + !!(x & i));
           if(flag) { fputs("\033[0m",stdout); }
           if(!(i >>= 1)) { break; }
           putchar(' ');
         }

        terpri();
}



/* Seconds since beginning of this year */
ULI seconds_of_year()
{
        struct tm buf;
        ULI z;

        dostime(&buf);
        
        z = ((buf.tm_yday * 86400L) + (buf.tm_hour * 3600L)
             + (buf.tm_min * 60) + (buf.tm_sec));
        return(z);
}


/* Hundredths of seconds since beginning of this year */
ULI hsecs_of_year()
{
        struct tm buf;
        ULI z;

        dostime(&buf);
        
        z = (uli((buf.tm_yday * 86400L) + (buf.tm_hour * 3600L)
             + (buf.tm_min * 60) + (buf.tm_sec)) * 100) + buf.tm_hsec;
        return(z);
}


char *hsecs2secs(hsecs)
ULI hsecs; /* Hundredths of seconds */
{
        register UINT len;
        static char resbuf[21];

        sprintf(resbuf,"%lu",hsecs);

        len = strlen(resbuf);

        if(len == 1) /* If just one digit */
         {
           resbuf[4] = '\0';
           resbuf[3] = resbuf[0];
           resbuf[2] = '0';
           resbuf[1] = '.';
           resbuf[0] = '0';
         }
        else if(len == 2) /* If two digits */
         {
           resbuf[4] = '\0';
           resbuf[3] = resbuf[1];
           resbuf[2] = resbuf[0];
           resbuf[1] = '.';
           resbuf[0] = '0';
         }
        else /* Three or more digits */
         {
           resbuf[len+1] = '\0'; /* Put ending zero */
           resbuf[len]   = resbuf[len-1]; /* Move hundredths one */
           resbuf[len-1] = resbuf[len-2]; /*      place forward. */
           resbuf[len-2] = '.'; /* So that decimal point can be put here */
         }

        return(resbuf);
}

char *skip_blankos(buf)
char *buf;
{
        int f_isspace();
        char *aux;

        return((aux = fun_index_not(buf,f_isspace)) ? aux
                  : (buf + strlen(buf)));
}


/* Return codes from E11: */
#define HALTED     0
#define ODDVECTADR 1
#define INSCNTLIM  2
#define CTRL_C     3
#define BRK_PNT    4

report_exit_reason(status)
UINT status;
{
    switch(status)
     {
       case HALTED:
        {
          fprintf(output,"Halted.");
          break;
        }
       case ODDVECTADR:
        {
          fprintf(output,"Odd vector address.");
          break;
        }
       case INSCNTLIM:
        {
          fprintf(output,"Instruction count limit reached.");
          break;
        }
       case CTRL_C:
        {
	  fprintf(output,"Ctrl-C pressed.");
	  break;
	}
       case BRK_PNT:
        {
          fprintf(output,"Breakpoint triggered.");
          break;
        }
       default:
        {
          fprintf(output,"Unknown exit code: %u.",status);
          break;
        }
     }

    terpri();
}


LLIST lookup(name)
char *name;
{
    register LLIST lista;

    for(lista=all_labels; !nilp(lista); lista = getlnext(lista))
     {
       if(strequ(getlname(lista),name)) { return(lista); }
     }

    return(NIL);
}



LLIST intern(name)
char *name;
{
    LLIST lista;

    if(!nilp(lista = lookup(name))) { return(lista); } /* Already in list. */
    if(nilp(lista = ((LLIST) malloc(sizeof(struct label_list)))))
     {
       fprintf(stderr,
        "\n%s: memory exhausted when called intern(\40%s\40). Sorry...\n",
	 get_progname(),name);
       exit(1);
     }

    /* Initialize fields: */
    setlnext(lista,all_labels); /* Set next to point to all_labels. */
    setlname(lista,name);
    setlvalue(lista,0);
    setlreflist(lista,NIL);
    setlhasvalueflag(lista,0);
    /* And replace all_labels with this, i.e. insert this one as first: */
    all_labels = lista;

    return(lista);
}

RLIST getnewreflist(lc,lilc,prefixes,ptr_to_next)
unsigned short int lc,lilc;
char *prefixes;
RLIST ptr_to_next;
{
    RLIST lista;

    if(nilp(lista = ((RLIST) malloc(sizeof(struct reference_list)))))
     {
       fprintf(stderr,
  "\n%s: memory exhausted when called getnewrlist(%06o,%06o,%s). Sorry...\n",
	 get_progname(),lc,lilc,prefixes);
       exit(1);
     }

    setrnext(lista,ptr_to_next);
    setrlc(lista,lc);
    setrlilc(lista,lilc);
    setrprefixes(lista,prefixes);

    return(lista);
}

