 
/* Program to convert octal dumps (taken with command E 0-somevalue in RT11)
   to binary files.
   Coded by Antti Karttunen at Friday night 13-MAR-92.
 */

#include "stdio.h"
#include "ctype.h"

/* This function should output binary bytes uncorrupted to stdout.
   This should work with Unix & Aztec-C of MS-DOS, but not with
   Turbo-C (In that case you must reopen output in binary mode):
 */
#define outchar(c) putc((c),stdout)

#define getlowbyte(X)   ((X) & 0xFF)
#define gethighbyte(X)  (((unsigned short int) (X)) >> 8)
/* is  C  '0' - '7' ? */
#define isoctdigit(C) (((C) & ~7) == 060) /* 060 = 0x30 = 48. = '0' */

#define MAXBUF 1025

char swap_bytes=0; /* Flag to tell whether there was -s on command line. */

char *skip_octals(),*skip_blankos();

main(argc,argv)
int argc;
char **argv;
{
    char *fgets();
    unsigned short int octnum;
    unsigned int wordcount=0,padcount=0,linecount=0;
    register char *p;
    char inbuf[MAXBUF+2];

    if(argc > 1) /* If arguments given */
     {
       if(!strcmp(*(argv+1),"-s")) { swap_bytes = 1; }
       else
        {
          fprintf(stderr,
"\nUsage: otob [-s] < octal.dmp > prog.sav\n");
          fprintf(stderr,
"Where octal.dmp is dump taken with command E 0-SomeOctalValue in RT11,\n");
          fprintf(stderr,
"and prog.sav is resulting binary file. Use option -s to swap the bytes.\n");
          fprintf(stderr,
"Below index 001000 (octal) all other words than those in locations\n");
          fprintf(stderr,
"40, 42, 50 and 360 are ignored. I.e. they are replaced by zeros.\n");
          fprintf(stderr,
"The end of output is padded with zeros until block boundary is reached,\n");
          fprintf(stderr,
"so that length of it will be divisible by 512 bytes.\n");
          fprintf(stderr,
"Program outputs statistical information to the stderr.\n");
          exit(1);
        }
     }


    while(fgets(inbuf,MAXBUF,stdin))
     {
       linecount++;
       p = skip_blankos(inbuf);
       /* If first non-blank character is not octal digit: */
       if(!isoctdigit(*p))
        {
          fprintf(stderr,"**Skipping line %u:\n%s",linecount,inbuf);
          continue;
        }

       while(*p) /* Browse the line. */
        {
          if(!isoctdigit(*p) || (sscanf(p,"%o",&octnum) != 1))
           {
             fprintf(stderr,
        "\n**Error: illegal octal number encountered at line %u:\n%s",
                linecount,inbuf);
             exit(1);
           }
/* Replace all words below 01000 with zeros, except those four locations.
   They are shifted right once, because those numbers are byte-indexes,
   and wordcount is word-index.
 */
          if((wordcount <  (01000>>1)) &&
             (wordcount != (040>>1))   &&
             (wordcount != (042>>1))   &&
             (wordcount != (050>>1))   &&
             (wordcount != (0360>>1))
            )
           { putw(0); }
          else { putw(octnum); }
          wordcount++;
          p = skip_octals(p);
          p = skip_blankos(p);
        }
     }

/*
 Write zero words until we get to block boundary (512 bytes, i.e. 256 words):
 */
    while(wordcount & 255)
     { putw(0); padcount++; wordcount++; }

    fprintf(stderr,
"\nRead %u. lines, wrote %06o (%u.) words, i.e. %06o (%u.) bytes.\n",
        linecount,(wordcount),(wordcount),(wordcount<<1),(wordcount<<1));
    fprintf(stderr,
"End of file was padded with %06o (%u.) zero-words, i.e. %06o (%u.) bytes.\n",
        padcount,padcount,(padcount<<1),(padcount<<1));
}


/* Output sixteen bit number x as binary. Low byte first, then high. */
/* But if flag swap_bytes is on, then the other way */
putw(x)
unsigned short int x;
{
    if(swap_bytes)  { outchar(gethighbyte(x)); }
    outchar(getlowbyte(x));
    if(!swap_bytes) { outchar(gethighbyte(x)); }
}


/* Returns pointer to first non-blank character: */
char *skip_blankos(s)
char *s;
{
     while(isascii(*s) && isspace(*s)) { s++; }

     return(s);
}

/* Returns pointer to first non-octal character: */
char *skip_octals(s)
char *s;
{
     while(isoctdigit(*s)) { s++; }

     return(s);
}

