

#include "stdio.h"
#include "mydefs.h"


/*
 Tries to allocate size bytes of memory and returns pointer to that
  if succesful. Pointer is aligned to paragraph boundary, so offset
  is zero. If there is not enough memory then error message is printed
  and program is aborted.
 This is used mainly to allocate big chunks of memory like 64K or 128K bytes
  for some special usage.
 Written by A.K. once upon a time.
 Note: This code is for Intel's processors which have awkward segment:offset
  system. Compiled with Aztec-C in large-data mode (option +LD).
 */
void *allocmem(size)
ULI size;
{
        void *abstoptr(),*sbrk();
	ULI ptrtoabs();
	int brk();
	void *muuliaasi; /* = track of heap pointer */

	muuliaasi = sbrk(0); /* Get current heap */

        /* Increment heap-pointer by 1 until we get one
         *  where offset part is zero, i.e. it is at
         *  paragraph boundary
         */
        do { /* Make sure that muuliaasi is in canonized format
	      *  (is this necessary ?, maybe sbrk returns as canonized) */
             /* Note: construction abstoptr(ptrtoabs(long_pointer)) just
                converts long pointer to canonical format if it's not already.
                getlow macro returns low word of long pointer (i.e. offset).
              */
	     muuliaasi = abstoptr(ptrtoabs(muuliaasi));
             /* If offset is zero, we have found it: */
	     if(!getlow(muuliaasi)) { break; }
	     muuliaasi = sbrk(1); /* Increment heap pointer by one */
	   } while(1);

	if(brk(abstoptr(ptrtoabs(muuliaasi)+size)))
	 {
	   fprintf(stderr,
"\n**FATAL ERROR in allocmem: Cannot allocate %lu bytes of core !\n",size);
	   fprintf(stderr,
            "muuliaasi: 0x%lx   sbrk(0): 0x%lx\n",muuliaasi,sbrk(0));
	   myexit(1);
         }

        return(muuliaasi);
}

