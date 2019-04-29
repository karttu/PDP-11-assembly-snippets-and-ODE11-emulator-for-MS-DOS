#define progname "pal2dep"

#include "stdio.h"
#include "ctype.h"
#include "mydefs.h"


/* Program to convert halfword octal dump (taken with FILDMP) of
    PALX BINARY FILE (output of the PALX PDP-11 cross-assembler,
    running in SAIL PDP-10) to deposit-file for RT-11.
    By Antti Karttunen, at 23.12.1990.
 */

/*
;PALX BINARY FILE FORMAT
;
;B => BYTE, W => WORD (LOW BYTE THEN HIGH BYTE)
;
;       .
;       .
;       .
;****************
;*B     1
;*B     0       (ERROR IF NOT 0)
;*W     # BYTES OF DATA + 6     (6 => JUMP BLOCK)
;*W     ADDRESS                 (JUMP ADDRESS)
;*B     DATA
;*      .
;*      .
;*      .
;*B     DATA
;*B     CHECKSUM (SUM FROM INITIAL 1 THROUGH CHECKSUM = 0 IN LOW 8 BITS)
;****************
;       REPEAT
;       .
;       .
;       .
;       2
;****************
;*      SIXBIT SYMBOL
;*      BITS,,VALUE
;****************
;       REPEAT
;       0
*/


#define output stdout

char *myfgets();
UINT get_byte();

UINT block_num=0;
UINT linecount=0;
BYTE sum=0;

#define MAXBUF 81
char buf[MAXBUF+3];


main(argc,argv)
int argc;
char **argv;
{
    char *s;
    UINT lc,prev_lc,byte_count,w,min_adr=0177777,max_adr=0;
    UINT min_adr_threshold=0;
    BYTE initial,second_byte,new_block,high_byte,low_byte;

    *buf = '\0';

    if(argc > 1)
     {
       sscanf(*(argv+1),"%o",&min_adr_threshold);
       fprintf(stderr,">>min_adr_threshold: %o\n",min_adr_threshold);
     }

    while(1)
     {
       sum = 0;

       initial = get_byte();
       if(initial == 2) { break; } /* Normal ending */
       second_byte = get_byte();
       if((initial != 1) || second_byte)
        { /* If first byte not 1 or 2, or second byte not zero: */
          fprintf(stderr,"\n**Invalid block header !");
          ertzu();
        }
       byte_count  = get_byte(); /* Low byte */
       byte_count += (get_byte() << 8); /* High byte */
       lc          = get_byte(); /* Low byte */
       lc         += (get_byte() << 8); /* High byte */

       fprintf(stderr,">>Block %u: %o %o <%06o/%05u.> %o\n",
                 block_num,initial,second_byte,byte_count,byte_count,lc);

       if(lc & 1)
        {
          fprintf(stderr,"\n**Odd LC encountered !");
          ertzu();
        }

       new_block = 1;
       byte_count -= 6; /* Subtract the length of the header */

       while(byte_count)
        {
          low_byte = get_byte();
/* If odd number of bytes in this block, and this is the last one of them: */
          if(!--byte_count) { high_byte = 0; }
          else /* Normal case */
           { high_byte = get_byte(); byte_count--; }

          w = (((UINT) high_byte) << 8) + low_byte;

          /* Max. 8 words with one deposit-command: */
          if(!(lc & 15) || (lc != (prev_lc+2)) || new_block)
           {
/* Start a new D-command if (lc mod 16) is 0 or this is not contiguous
    with previous or if first word of the new block: */
             fprintf(output,"\nD %06o=%06o",lc,w);
           }
          else /* After previous words */
           { fprintf(output,",%06o",w); }
          if((lc < min_adr) && (lc > min_adr_threshold)) { min_adr = lc; }
          if(lc > max_adr) { max_adr = lc; }

          prev_lc = lc;
          lc += 2;
          new_block = 0;
        }
       fprintf(output,"\n");

/* Read checksum byte which should make the sum zero: */
       low_byte = get_byte();
       if(sum) /* If checksum not zero */
        {
          fprintf(stderr,"\n**Cheksum mismatch: %o",sum);
          ertzu();
        }

       block_num++;
     } /* Outermost while */

/* Coming here if normal ending, i.e. 2 encountered at the start of
    the block header */
    fprintf(stderr,
"\n**No errors. Read %u lines, %u blocks. Min: %06o Max: %06o Next line:\n%s\n",
      linecount,block_num,min_adr,max_adr,
       ((s = myfgets(buf,MAXBUF,stdin)) ? s : "**END OF FILE !!!\n"));
    exit(0);
}


UINT get_byte()
{
    UINT arvo;

kala:
    if(!myfgets(buf,MAXBUF,stdin))
     {
       fprintf(stderr,
"\n**Premature EOF in source file ! Aborted.\n");
       ertzu();
     }
    linecount++;

    if(!isoctdigit(*buf)) { goto kala; }
    if(!streq("0,,",buf)) { ertzu(); }
    if(!isoctdigit(*(buf+3))) { ertzu(); }
    sscanf((buf+3),"%o",&arvo);
    if(arvo > 255) { ertzu(); }

    sum += arvo;
    return(arvo);
}


ertzu()
{
    fprintf(stderr,"\n**Block %u, Offending line (%u):\n%s\n",
      block_num,linecount,buf);
    exit(1);
}

