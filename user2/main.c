#include "lib.h"

int main(void)
{
    char *p = (char *)0xffff800000200200;

    *p = 1;
    printf("process2\n");
    sleepu(100);

    return 0;
}