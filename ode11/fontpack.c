
#define BIG_RUN_COUNT      0

#define SINGLE_COUNT_LIM  12
#define RUN_COUNT_LIM     (SINGLE_COUNT_LIM + 1 + 255)

#define BITMAP_TOGGLE     13
#define REPEAT_COUNT      14
#define REPEAT_ONELINE    15


#define get_high_nybble(X) (uint(X) >> 4)
#define get_low_nybble(X)  ((X) & 0x0F)


UINT srclen_in_bytes; /* Length of src buf in bytes */
UINT dstlen_in_bytes; /* Length of dst buf in bytes */
UINT width_in_bytes; /* Width of src image in bytes */
UINT width_in_bits;  /* Width of src image in bits (pixels) */
UINT width_of_image; /* Width of cornered image */
UINT heigth_of_image;
UINT size_of_image;  /* width_of_image * heigth_of_image */
int min_x,max_x,min_y,max_y; /* Extents of src image */


UINT run_counts[1024];
UINT image_sizes[1024];
UINT bit_counts[1024];


UINT lihaa(dst,src)
register BYTE **dst;
BYTE *src;
{
        UINT count;
        register UINT j;

        count =
         expand_bits(dst_buf,src);
        if(!count) { heigth_of_image = width_of_image = 0; *dst = NULL; }
        else
         {
           BYTE *uplimus;

           width_of_image  = ((max_x - min_x) + 1);
           heigth_of_image = ((max_y - min_y) + 1);
           uplimus = (src + (max_y * width_in_bits) + min_x);
           src = (src + (min_y * width_in_bits) + min_x);
           for(;src <= uplimus; src += width_in_bits)
            {
              *dst++ = src;
            }
           *dst = NULL;
         }

        size_of_image = (width_of_image * heigth_of_image);

        image_sizes[size_of_image]++;
        bit_counts[count]++;

        return(count);
}


/* Expand bits in buffer src to buffer dst. src is srclen bytes long,
    and dst is eight times bigger.
   Also determines the extents of bit_image, i.e. sets values to
    min_x, max_x, min_y and max_y.
   Returns count of 1-bits as value.
 */
UINT expand_bits(dst,src)
register BYTE *dst;
BYTE *src;
{
        UINT i,count;
        /* register */ BYTE j;
        BYTE byytti;
        register int x_index;

        min_x = 32767; /* Biggest positive integer */
        max_x = min_y = max_y = -1;

        for(x_index=count=i=0; i < srclen_in_bytes; i++)
         {
           byytti = *(src+i);
           for(j=0x80; j; j >>= 1) /* From MSB to LSB */
            {
              if(*dst++ = !!(byytti & j)) /* Only 0's or 1's to dst */
               { /* If 1-bit: */
                 count++;
                 /* If this is first 1-bit encountered, then set min_y: */
                 if(min_y == -1) { min_y = i; }
                 max_y = i;
                 if(x_index < min_x) { min_x = x_index; }
                 if(x_index > max_x) { max_x = x_index; }
               }
              if(++x_index == width_in_bits) { x_index = 0; }
            }
         }

        /* If min_y and max_y were set (count is not zero), then divide
            them by width of bytes of bit_image to get correct values:
         */
        if(min_y != -1) { min_y /= width_in_bytes; }
        if(max_y != -1) { max_y /= width_in_bytes; }

        return(count);
}







pack_bytebuf(dst,src)
BYTE *dst,**src;
{
    register UINT prev_index=0;
    register UINT index;
    UINT run_count;

    do {
         index = get_next_diff_bit(src);
         dst = sput_run_count((run_count = (index-prev_index)),dst);
         prev_index = index;
         run_counts[run_count]++;
       } while(index < size_of_image);
}

static BYTE new_image_flag=1;
static BYTE **ptr;
static UINT i;


UINT get_repeat_count(bytebuf)
register BYTE **bytebuf;
{
        register BYTE **next;

        if(new_image_flag)
         {
           ptr = bytebuf;
           i = 0;
           new_image_flag = 0;
         }

        do {
             next = (ptr+1);
             if(!next) { return(count); }
             if(!memcmp(*ptr,*next,width_of_image)) { count++; }
             else { return(count); }
             ptr paskaa !


/* Get index to next different bit: */
UINT get_next_diff_bit(bytebuf)
register BYTE **bytebuf;
{
        register BYTE c;

        if(new_image_flag)
         {
           ptr = bytebuf;
           i = 0;
           new_image_flag = 0;
         }

        c = *((*ptr)+i);
        do {
             if(++i == width_of_image)
              {
                i = 0;
                if(!*++ptr)
                 {
                   new_image_flag = 1;
                   goto palaa;
                 }
              }

             if(*((*ptr)+i) ^ c)
              {
palaa:
                return(((ptr - bytebuf)*width_of_image)+i);
              }
           } while(1);
}






put_nybble(nybble,out)
UINT nybble;
FILE *out;
{
        static BYTE high_flag=1;
        static BYTE high_nybble=0;

        if(high_flag)
         {
           high_nybble = nybble;
           high_flag = 0;
         }
        else
         {
           fputc(((high_nybble << 4) | nybble),out);
           high_nybble = 0;
           high_flag = 1;
         }
}

BYTE *sput_run_count(run_count,buf)
UINT run_count;
BYTE *buf;
{
        if(!run_count || (run_count > run_count_uplim))
         {
            /* proot */
         }

        if(run_count <= single_count_lim)
         { return(sput_nybble(run_count,buf)); }
        else
         {
           buf = sput_nybble(0,buf);
           run_count -= single_count_lim;
           run_count -= 1;
           buf = sput_nybble(get_high_nybble(run_count),buf);
           return(sput_nybble(get_low_nybble(run_count),buf));
         }
}



BYTE *sput_nybble(nybble,buf)
UINT nybble;
BYTE *buf;
{
        static BYTE high_flag=1;
        static BYTE high_nybble=0;

        if(high_flag)
         {
           high_nybble = nybble;
           high_flag = 0;
           return(buf);
         }
        else
         {
           *buf = ((high_nybble << 4) | nybble);
           high_nybble = 0;
           high_flag = 1;
           return(buf+1);
         }
}



UINT get_nybble(in)
FILE *in;
{
        static BYTE _high_flag=1;
        static UINT c;

        if(_high_flag)
         {
           c = fgetc(in);
           if(c == EOF) { return(EOF); }
           _high_flag = 0;
           return(c >> 4);
         }
        else
         {
           _high_flag = 1;
           return(c & 0x0F);
         }
}

