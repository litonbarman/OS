#ifndef _GDT_ENTRY_H

#define _GDT_ENTRY_H

struct GDT_ENTRY {
   uint16_t   limit_low;
   uint16_t   base_low;
   uint8_t    base_middle;
   uint8_t    access;
   uint8_t    granuality;
   uint8_t    base_high;
} __attribute__((packed));

#endif
#warning __FILE__ include more then once