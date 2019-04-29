

#include "/tl/tab3x3.h"
#include "/tl/listfuns.h"


int summary()
{
        extern PFSTR codetoascfun;
        int s1ummary(),summaraux();
        char *itoperc();
        char *o3sprintlist();

        extern char *morl_messages[],*pattern_type_string[];
        extern int pagecnt,lines_in_page;
        /* externals relating to collecting of statistical information: */
        extern int *old_cell_counts,*new_cell_counts;
        extern int *patt_counts,*childcounts,*m_or_l_counts;
        extern int outsiders_count,cc_count,total;
        extern LIST **child_parents;

        /* locals: */
        int  i,j,jj,total1,total2;
        char tmp1spc[KYPA],tmp2spc[KYPA];
        char tmp3spc[RUTOSTI+1],tmp4spc[RUTOSTI+1];


        printf("\n");
        s1ummary(old_cell_counts,new_cell_counts,total);
        
        PERINEUM;
        summaraux(morl_messages,m_or_l_counts,total);

        PERINEUM;
        summaraux(pattern_type_string,patt_counts,total);

        PERINEUM;

#define FORM1STR "%5d   --   %s %%\n"
        
        puts(
"Number of patterns which have grown out of the original 3x3 square:"
             );
        printf(FORM1STR,
                 outsiders_count,itoperc(tmp1spc,outsiders_count,total));
        PERINEUM;
        
        puts(
"Number of patterns which have the centre cell alive at the next generation:"
             );
        printf(FORM1STR,cc_count,itoperc(tmp1spc,cc_count,total));

        PAGEPRINT;
        
        puts(  "Patterns which have appeared as a child in this search:");
        printf("%-13s%3s%2s%s\n","Child Code","N","","percents");
        total1 = total2 = jj =0;
        /* jj = index to childcounts, i = what is get from there */
        while((i = *(childcounts+jj)) != -1)
              {
                if(i)
                   {                        /*123*/     
                     sprintf(tmp3spc,"%-13s%5d   %s%4s",
                             ((*codetoascfun)(tmp1spc,jj)),i,
                              itoperc(tmp2spc,i,total),"");
                     o3sprintlist(tmp4spc,*(child_parents+jj));
                     strcat(tmp3spc,tmp4spc);
                     puts(tmp3spc);
                     /* print the page header when total1 is divisible
                      *  by lines_in_page (but not when total1 is zero)
                      */
                     if((!(total1 % lines_in_page)) && total1) { PAGEPRINT; }
                     total1++;
                     total2 += i;
                   }
                jj++;
              }
        printf("\n"); /*123*/
        puts(
"Number of the 3x3-patterns which appear as the child of the 3x3-pattern:"
             );
        printf("%-13s%5d   %s %%\n","",total1,itoperc(tmp1spc,total1,total));
        puts(
"Number of the 3x3-patterns which have the 3x3-pattern as their child:"
             );
        printf("%-13s%5d   %s %%\n","",total2,itoperc(tmp2spc,total2,total));
        printf(
    "\n(By 3x3 pattern it is understood a pattern which wholly fits the %s.)\n",
               "3x3-square");
/*      PERINEUM; */
        printf("\n%29sEND OF THE SUMMARY.\n","");

        return(1);
}


int s1ummary(ints1,ints2,max)
int *ints1,*ints2;
int max;
{
        char *itoperc();
	int linecnt=0,total1=0,total2=0,jj=0;
	char tmp1spc[6],tmp2spc[6];
	int j,k;
              

        printf("            Originators             Results\n");
             /* 1234567890123456789012345678901234567890123456789012345 */
        printf("Cells          N  percents             N  percents\n");
             /*  0           zx1   ..0.2             xyz   abc.d   */

        while((j = *ints1++) != -1)
              {
                total1 += j;
                total2 += (k = *ints2++);
                printf(
              /*  12345678901234567890 56789012345678901234 */
                "%2d           %5d   %s             %5d   %s\n",
                  jj++,j,itoperc(tmp1spc,j,max),
                       k,itoperc(tmp2spc,k,max));
              }
              
              /*     34567890 56789012345678901234 */
        printf("%-12s %5d   %s             %5d   %s\n",
                  "Total:",
                  total1,itoperc(tmp1spc,total1,max),
                  total2,itoperc(tmp2spc,total2,max));

        return(linecnt); /* linecnt is currently incorrect, don't use it */
}





int summaraux(strings,ints,max)
char **strings;
int *ints;
int max;
{
        char *itoperc();
        int total=0,linecnt=0;
        char tmp1spc[6];
        char *tmpstr;
        char *format_string = "%-12s %5d   %s\n";
        
        while(tmpstr = *(strings++))
              {
              	int visva;
              	total += (visva = *(ints++));
              	printf(format_string,
              	         tmpstr,visva,itoperc(tmp1spc,visva,max));
              	linecnt++;
              }
        printf("\n");
        printf(format_string,"Total:",total,itoperc(tmp1spc,total,max));
        linecnt += 2;
        return(linecnt);
}


