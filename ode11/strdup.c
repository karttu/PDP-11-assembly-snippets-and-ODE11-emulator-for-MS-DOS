
#include "stdio.h"

/* Make duplicate of s: */
char *strdup(s)
char *s;
{
    char *malloc();
    char *p;

    if(!(p = ((char *) malloc(strlen(s)+1))))
     {
       fprintf(stderr,
        "\nstrdup(%s): Memory exhausted!\n",s);
       exit(1);
     }
    strcpy(p,s);
    return(p);
}

