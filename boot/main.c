#include "lib.h"
#include "stdint.h"
#include "stdio.h"

int main(void)
{
    int64_t counter = 0;
    int64_t limit;

    printf("Enter the limit for the counter : ");
    scanf("%ld", &limit);

    while (counter < limit)
    {
        // if (counter % 10001 == 0)
        //     printf("process1 %d\n", counter);
        counter++;
    }
    return 0;
}