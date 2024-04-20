#include "../trap/trap.h"
#include "../lib/print.h"
#include "../lib/debug.h"

void KMain(void)
{
    char *string = "Hello and Welcome";
    int64_t value = 0x123456789ABCD;

    for (int i = 0; i < 50; i++)
    {
        printk("%d\n", i);
    }

    init_idt();

    printk("%s\n", string);
    printk("This value is equal to %x", value);
    // ASSERT(0);
}