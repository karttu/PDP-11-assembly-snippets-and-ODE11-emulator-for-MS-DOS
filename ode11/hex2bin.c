
#define progname "hex2bin"

#include "stdio.h"
#include "ctype.h"
#include "mydefs.h"

/* Program to convert *.HEX files to binary (e.g: .SAV) files of RT-11.
    By Antti Karttunen, at 28.12.1990.
 */

FILE *myfopen();
FILE *input,*output;

char *myfgets();
UINT get_byte();

UINT linecount=0;
ULI bytecount=0l;
UINT sum=0;

#define MAXBUF 81
char buf[MAXBUF+3];


main(argc,argv)
int argc;
char **argv;
{
    UINT byte;

    *buf = '\0';
    input = stdin;
    output = stdout;

    if(argc > 1)
     {
       input = myfopen(*(argv+1),"r");
     }
    if(argc > 2)
     { /* If Turbo-C, then use "wb" (binary) mode: */
       output = myfopen(*(argv+2),"w");
     }


    while((byte = get_byte()) != EOF)
     {
       fputc(byte,output);
       bytecount++;
     }

    fclose(output);
    fprintf(stderr,
"\n**No errors. Read %u lines, %lu./%0lo bytes.\n",
      linecount,bytecount,bytecount);
    exit(0);
}

char static *p=NULL;

UINT get_byte()
{
    int f_isxdigit();
    UINT arvo,checksum;
    char savechar;

    if(!p) /* Read the new line */
     {
kala:
       if(!myfgets(buf,MAXBUF,input))
        {
          return(EOF); /* Should be -1, i.e. 0xFFFF */
        }
       linecount++;

       if(!*buf) { goto kala; } /* If null line, then try again */
/* Whole length of the line must be 71 characters: */
       if(strlen(buf) != 71) { goto ertzu; }
/* First 64 must hexadecimal digits, and then colon: */
       if(!(p = fun_index_not(buf,f_isxdigit))
            || ((p - buf) != 64) || (*p != ':'))
        { goto ertzu; }
/* Remaining 6 characters must also be hexadecimal digits */
       if(fun_index_not(p+1,f_isxdigit)) { goto ertzu; }
       
       p = buf; /* Set p pointer to start of the buffer */
       sum = 0; /* Initialize checksum sum */
     }

    savechar = *(p+2); /* Save third hex digit, */
    *(p+2) = '\0';     /* so that we can overwrite it with '\0' */
    sscanf(p,"%x",&arvo); /* so that sscanf can read the first two digits */
    p += 2;            /* Update pointer to the next two digits */
    *p = savechar;     /* Restore first of them. */

    sum += arvo;       /* Update checksum sum */

    if(savechar == ':')
     { /* Last byte of this line was just read, check checksum */
       sscanf(p+1,"%x",&checksum);
       if(checksum != sum)
        {
          fprintf(stderr,"\n%s: Illegal checksum (%x) at line (%u,%u):\n%s\n",
                   progname,sum,linecount,strlen(buf),buf);
          exit(1);
        }
       else
        { p = NULL; } /* This forces get_byte to read new line next time */
     }

    return(arvo);

ertzu:
    fprintf(stderr,"\n%s: Illegal line (%u,%u):\n%s\n",
              progname,linecount,strlen(buf),buf);
    exit(1);
}

