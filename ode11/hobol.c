

#include "stdio.h"
#include "ctype.h"
#include "mydefs.h"

#define MAXBUF 1025

main(argc,argv)
int argc;
char **argv;
{
    char *myfgets();
    UINT adr,prev_adr,max_adr,min_adr;
    UINT linecount,minlineno,maxlineno;
    UINT muuh=0;
    char buf[MAXBUF+3],maxline[MAXBUF+3],minline[MAXBUF+3];

    if(argc > 1)
     { muuh = atoi(*(argv+1)); fprintf(stderr,"\nmuuh=%o\n",muuh); }

    *buf = *maxline = *minline = '\0';
    min_adr = 0177777;
    prev_adr = max_adr = 0;
    linecount = minlineno = maxlineno = 0;

    
    while(myfgets(buf,MAXBUF,stdin))
     {
       linecount++;
       if(strlen(buf) < 14) { continue; }
       if((*buf != '\t') || (buf[7] != '\t')
           || !isoctdigit(buf[1])  || !isoctdigit(buf[2])
           || !isoctdigit(buf[3])  || !isoctdigit(buf[4])
           || !isoctdigit(buf[5])  || !isoctdigit(buf[6])
           || !isoctdigit(buf[11]) || !isoctdigit(buf[12])
           || !isoctdigit(buf[13]))
        { continue; }
       sscanf((buf+1),"%o",&adr);
       if(!muuh || !prev_adr || ((adr - prev_adr) > muuh)) { puts(buf); }
       if(adr > max_adr)
        {
          max_adr = adr;
          strcpy(maxline,buf);
          maxlineno = linecount;
        }
       if(adr < min_adr)
        {
          min_adr = adr;
          strcpy(minline,buf);
          minlineno = linecount;
        }
       prev_adr = adr;
     }

    fprintf(stderr,"\nRead %u lines. Max address %06o at line %u:\n",
              linecount,max_adr,maxlineno);
    fprintf(stderr,"%s\n",maxline);

    fprintf(stderr,"Min address %06o at line %u:\n",
              min_adr,minlineno);
    fprintf(stderr,"%s\n",minline);

}


