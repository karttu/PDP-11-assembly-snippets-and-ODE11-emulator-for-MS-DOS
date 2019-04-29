/* CONVERT: a program to convert a text file containing Swedish
 * characters a la IBM brain damage 8-bit code to Swedish Standard
 * 7-bit code, and vice versa. The program figures out which way to
 * convert by itself. You invoke it by either of:
 *   CONVERT file
 *   CONVERT file1 file2
 *   CONVERT <file1 >file2
 *
 * This program is written 1984-12-19 by Per Lindberg, QZ
 * (The mad programmer strikes again!) for the Lattice C compiler.
 * Copyright (c) 1984 by QZ, Stockholm University Computing Center.
 * You may copy and use it as much as you like, but not sell it for
 * profit. Happy hacking! --PL
 *
 */

#include "stdio.h"

main(argc, argv) int argc; char *argv[]; {
  char arg;

  int  i,		/* Counter, of course				   */
       c;		/* Not char, because EOF == -1 and char is 0..255  */
  char xlate[256];	/* Conversion lookup table (neat, eh?)		   */
  char *ifn, *ofn;	/* InFileName, OutFileName			   */
  FILE *ifp, *ofp;	/* InFilePointer, OutFilePointer		   */
      
  usrmsg("Character conversion program, Swedish Standard <----> IBM code\n");

  if (argc == 1) {	/* I like this user! */
    ifp = stdin;
    ofp = stdout;
  }
  if (argc >= 2) {
    ifn = argv[1];
    ofn = "convert.tmp";
    ifp = fopen(ifn,"r");
    if (ifp == NULL) {
      usrmsg("Can't find file '%s'\n",ifn);
      exit(1);
    }
    if (argc >= 3) ofn = argv[2];
    ofp = fopen(ofn,"w");
    if (ofp == NULL) {
      usrmsg("Can't write file '%s'\n",ifn);
      exit(1);
    }
  }

  for (i = 0; i <= 255; i++) xlate[i] = i;		/* Pascal sucks! */
  xlate[''] = ']';  xlate['†'] = '}'; xlate[']'] = '';  xlate['}'] = '†';
  xlate['Ž'] = '[';  xlate['„'] = '{'; xlate['['] = 'Ž';  xlate['{'] = '„';
  xlate['™'] = '\\'; xlate['”'] = '|'; xlate['\\'] = '™'; xlate['|'] = '”';

  while ((c = getc(ifp)) != EOF ) putc(xlate[c],ofp);	/* Main lupe */

  if (argc >= 2) {
    if (fclose(ifp)) usrmsg("Could not close input file!");
    if (fclose(ofp)) usrmsg("Could not close output or temporary file!");
  }
  if (argc == 2) {
    ifp = fopen(ofn,"r");
    ofp = fopen(ifn,"w");
    while ((c = getc(ifp)) != EOF) putc(c,ofp);	/* Aarrgh! */
    if (fclose(ifp)) usrmsg("Could not close temporary file!");
    if (fclose(ofp)) usrmsg("Could not close resulting file!");
    if (unlink(ofn) == -1) usrmsg("Could not delete temporary file!");
  }
}
usrmsg(s) char *s; {
  fprintf(stderr,s);
}