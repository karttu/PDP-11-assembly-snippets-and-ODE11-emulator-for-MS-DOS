

/*
  This throw-away program generates flagtables FLAG1TAB & FLAG2TAB
   for the PDP-11 simulator.

  FLAG1TAB is used to convert i*86 flags got with LAHF to PDP-11 flags in PSR.
   Note that because there is no Overflow flag in byte returned by LAHF,
   it must be set separately.

  FLAG2TAB is used to test various flag combinations quickly, and it's indexed
   by PDP-11 flags NZVC in PSR. Macro SET_FLAGS6 and some branches use it.
   (BGE, BLT, BGT, BLE). Note that it can be well only 16 bytes long, because
   it's sure that it's not ever indexed with bigger values than 15.

  Coded by Antti Karttunen at 10th June 1990.
 */

#include "stdio.h"
#include "ctype.h"
#include "mydefs.h"


#define SF86 0x80
#define ZF86 0x40
#define CF86 0x01

#define CF   1
#define VF   2
#define ZF   4
#define NF   8

#define NxorC   1
#define NxorV   2


main(argc,argv)
int argc;
char **argv;
{

        printf(";\n; This file was generated by the program creatabl.\n");

        if(argc > 1)
         {
           if(atoi(*(argv+1)) == 2) { goto taulu2; }
         }

        printf(
";\nFLAG1TAB LABEL\tBYTE\t;%9sN Z x x x x x C%3sx x x x N Z V C\n",
           "","");
        gen_flag1tab();
        printf(";\n");

        if(argc > 1)
         {
           if(atoi(*(argv+1)) == 1) { exit(0); }
         }

taulu2:

        printf(
";\nFLAG2TAB LABEL\tBYTE\t;%9sx x x x N Z V C\n",
           "");
        gen_flag2tab();
        printf(";\n");
}



gen_flag1tab()
{
        UINT i,r;

        for(i=0 ; i < 256; i++)
         {
           r = 0;
           if(i & SF86) { r |= NF; }
           if(i & ZF86) { r |= ZF; }
           if(i & CF86) { r |= CF; }
           print_stuff(i,r);
         }
}


gen_flag2tab()
{
        UINT i,r;

        for(i=0 ; i < 16; i++)
         {
           r = 0;
           if(!!(i & NF) ^ !!(i & CF)) { r |= NxorC; }
           if(!!(i & NF) ^ !!(i & VF)) { r |= NxorV; }
           if(i & ZF) { r |= ZF; }
           print_stuff(i,r);
         }
}




print_stuff(x,y)
UINT x,y; /* X = index, Y = corresponding value */
{
        printf("\tDB\t0%02oQ\t; %03o%5s",y,x,"");
        print_bits(x,stdout);
        printf("%3s","");
        print_bits(y,stdout);
        printf("\n");
}



print_bits(x,fp) /* Print bits of byte separated by colons (:) */
register UINT x;
FILE *fp;
{
        register UINT bit_index = 0x80;

        while(1)
         {
           fputc(('0' + !!(x & bit_index)),fp);
           if(!(bit_index >>= 1)) { break; }
           fputc(':',fp);
         }
}

