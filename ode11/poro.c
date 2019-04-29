

/*
   poro - poromiesten oma ohjelma, muunmuassa oktaalidumppien ulostukseen.
   Kirjoittanut Repa J. Kyrsamaki armon vuonna 1990.
   
   Repair corrupted PDP-11/34 RT-11 files, (and dump them in octal if needed)
   And do everything else too.
   Multipurpose "throw once, use many times"-program.
 */


#define progname "poro"

#include "stdio.h"
#include "ctype.h"
#include "mydefs.h"

BYTE swap_flag=0;
BYTE oct_flag=0;
BYTE depo_flag=0;
BYTE hex_flag=0;
BYTE dec_flag=0;
BYTE udec_flag=0;
BYTE byte_rem_flag=0;
BYTE lopeta=0;
UINT remov_cnt=0;
UINT check_value=0;

UINT start_adr=0;
UINT end_adr=0;


FILE *myfopen();
FILE *input=NULL,*output=NULL;

UINT lue_luku(),swap_bytes();
UINT read_high_byte();

main(argc,argv)
int argc;
char **argv;
{
    UINT w;
    ULI count=0L;
    UINT byte_count=0,prev_count=-1;
    char *s;
    BYTE huba=0;

    while(s = *++argv)
     {
       char c;

       if((*s == '-') || (*s == '+'))
        {
          while(c = *++s)
           {
             switch(c)
              {
                case 's': { swap_flag = 1; break; }
                case 'u': { udec_flag = 1; break; }
                case 'd': { dec_flag  = 1; break; }
                case 'o': { oct_flag++;    break; }
                case 'x': { hex_flag  = 1; break; }
                case 'O': { depo_flag = 1; break; }
                case 'S':
                 {
                   if(!*++s)
                    { if(!(s = *++argv)) { goto ertzu; } }
                   sscanf(s,"%o",&start_adr);
                   fprintf(stderr,"start_adr = %06o\n",start_adr);
                   goto isompi_luuppi;
                 }
                case 'E':
                 {
                   if(!*++s)
                    { if(!(s = *++argv)) { goto ertzu; } }
                   sscanf(s,"%o",&end_adr);
                   fprintf(stderr,"end_adr = %06o\n",end_adr);
                   goto isompi_luuppi;
                 }
                case 'r':
                 { /* If +r instead of -r then remove bytes, not words: */
                   byte_rem_flag = (*(s-1) == '+');
                   if(!*++s)
                    { if(!(s = *++argv)) { goto ertzu; } }
                   remov_cnt   = lue_luku(s);

                   if(!(s = *++argv)) { goto ertzu; }
                   check_value = lue_luku(s);

                   if(*s == 'E') { goto ertzu; }

                   goto isompi_luuppi;
                 }
                default:
                 {
ertzu:
                   fprintf(stderr,
"\n**%s: illegal option -%c or illegal format for option !\n",
                    progname,c);
                   fprintf(stderr,
"usage: %s input_file output_file [-s] [-{duoxO}] [-r remove_nth check_value]\n",
                    progname);
                   fprintf(stderr,
"-s option swaps the lower & the upper byte, -o prints in octal, -x in hex.\n");
                   fprintf(stderr,
"-d in decimal, -u in unsigned dec, -O is special RT-11 deposit-mode\n");
                   fprintf(stderr,
"-S octnum -E octnum override the default start & end-addresses in deposit-mode\n");
                   fprintf(stderr,
"-r 256 0x0A0D removes every 256th word, if those words are 0A0D (CRLF's).\n");
                   fprintf(stderr,
"+r 256 0x0A   removes every 512th byte, if those bytes are 0A (LF's).\n");
                   exit(1);
                 }
              } /* Switchin loppusulku */
           } /* Whilen loppusulku */
        } /* If:fin loppusulku */
       else
        {
          if(input) { output = myfopen(s,"w"); }
          else      { input  = myfopen(s,"r"); }
        }

isompi_luuppi: ;
     } /* Uloimman whilen loppusulku */

    if(!input)  { input = stdin; }
    if(!output) { output = stdout; }

        while(!lopeta &&
               ((w = fgetc(input)),(!feof(input) && !ferror(input))))
         {
           if(huba && remov_cnt && count && !(count % remov_cnt))
            {
              if(!byte_rem_flag) { w = read_high_byte(w,input); }
              if(w != check_value)
               {
                 fprintf(stderr,
"\n**Warning, %s %u/0x%04x/%06o at index %u is not %u/0x%04x, ignored.\n",
                  (byte_rem_flag ? "byte" : "word"),
                  w,w,w,byte_count,check_value,check_value);
               }
/* Set huba flag to zero, so that we won't come to this check next time: */
              else { huba = 0; continue; }
            }
           else
            {
              huba = 1;
              w = read_high_byte(w,input);
            }

           if(swap_flag) { w = swap_bytes(w); }

           if(depo_flag)
            {
              /* Set starting addr if not set at command line with option */
              if((byte_count == 040) && !start_adr)
               { start_adr = w; }
              if((byte_count == 050) && !end_adr) /* Ending address */
               { end_adr = w; }
              if(start_adr && (byte_count == start_adr)) { depo_flag = 2; }
              if(end_adr && (byte_count == end_adr)) { depo_flag = 1; }
/* Between start address and end address depo_flag is 2 and everything
    is put to D commands.
   Outside of [start - end] depo_flag is 1 and only non-zero values are put
    to D commands.
 */
              if((depo_flag == 2) || w)
               { /* 8 words with one deposit-command: */
               	 if(!(byte_count & 15) || (byte_count != (prev_count+2)))
               	  { /* mod 16 is 0 or this is not contiguous with previous */
               	  	fprintf(output,"\nD %06o=%06o",byte_count,w);
               	  } /* ...so start the new D-cmd on new line. */
               	 else /* After previous words */
               	  {
               	  	fprintf(output,",%06o",w);
               	  }
               	 prev_count = byte_count;
               }
            }               
           else if(dec_flag) { fprintf(output,"%d\n",w); }
           else if(udec_flag) { fprintf(output,"%u\n",w); }
           else if(oct_flag)
            {
              if(oct_flag > 1) { fprintf(output,"%06o: ",byte_count); }
              fprintf(output,"%06o",w);
              if(oct_flag > 1)
               {
               	 fprintf(output,"   >%06o   >>%06o   <%06o   <<%06o",
               	   (w>>1),(w>>2),(w<<1),(w<<2));
               }
              putchar('\n');
            }
           else if(hex_flag) { fprintf(output,"%04x\n",w); }
           else { putw(w,output); }

           count++;
           byte_count += 2;

         }


        if(depo_flag) { fprintf(output,"\n"); } /* Final newline */
         
        if(((huba = 0),ferror(input)) || ((huba = 1),ferror(output)))
         {
           fprintf(stderr,"\nFatal error in %sput, at index: %lu\n",
                     (huba ? "out" : "in"),count);
           exit(1);
         }

        exit(0);
}


UINT swap_bytes(x)
UINT x;
{
/* This is pedantic way to do this, there is also other, maybe better ways */
        union
         {
           UINT word;
           struct { BYTE byte0; BYTE byte1; } bytes;
         } viritys;

        BYTE kala;

        viritys.word = x;
        /* Swap the upper & the lower byte: */
        kala = viritys.bytes.byte0;
        viritys.bytes.byte0 = viritys.bytes.byte1;
        viritys.bytes.byte1 = kala;

        return(viritys.word);
}


UINT lue_luku(s)
char *s;
{
        UINT x=0;

        if((*s == '0') && (tolower(*(s+1)) == 'x'))
         {
           sscanf(s+2,"%x",&x);
         }
        else if(isdigit(*s)) { x = atoi(s); }
        else { *s = 'E'; }

        return(x);
}


UINT read_high_byte(low_byte,input)
UINT low_byte;
FILE *input;
{
       UINT x;

       x = fgetc(input);
       if(feof(input) || ferror(input))
/* If eof or error then switch lopeta flag on to tell the while at the
    top of the main loop that it should stop the reading: */
        { lopeta = 1; return(low_byte); }
       else { return((x << 8) + low_byte); }
}

