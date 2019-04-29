

#include "stdio.h"
#include "ctype.h"
#include "time.h"
#include "mydefs.h"


static char datebuf[27];

char *date_et_time()
{
        char *asctime();
        struct tm buf;

        dostime(&buf);
        strcpy(datebuf,asctime(&buf));
        if(GETLASTCHAR(datebuf) == '\n') { SETLASTCHAR(datebuf,'\0'); }
        return(datebuf);
}

/* Seconds since 00:00 or 12:00, because there is 86400 seconds in the day,
    and that doesn't fit to sixteen bits. */
UINT seconds_of_day()
{
        struct tm buf;
        UINT z;

        dostime(&buf);
        
        z = (buf.tm_hour);
        if(z >= 12) { z -= 12; }
        z *= 3600; /* 3600 seconds in one hour */
        z += ((60 * (buf.tm_min)) + (buf.tm_sec));
        return(z);
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


static ULI previous_seconds = 0L;

char *timestring(dst_str)
char *dst_str;
{
	char *date_et_time();
	ULI seconds_of_year();
	ULI new_seconds;

	new_seconds = seconds_of_year();

	strcpy(dst_str,date_et_time());
	/* Concatenate more stuff to end of dst_str: */
	sprintf((dst_str + strlen(dst_str)),
         "   %8ld - %8ld   =   %6ld   ",
         new_seconds, previous_seconds, (new_seconds - previous_seconds));

        previous_seconds = new_seconds;
	return(dst_str);
}


timetovid(loc)
UINT loc;
{
	extern FILE *output;
	char bufferi[81];
        char *ptr,*s;
	ULI puntari;

	s = bufferi;

	puntari = (0xB8000000L + loc);
	ptr = (char *) puntari;

	timestring(bufferi);
	if(output != stdout)
	 { fprintf(output,"# %s\n",bufferi); }

	while(*s)
	 {
	   *ptr++ = *s++;
	   ptr++;
	 }
}


