#include "lib.h"
#include "stddef.h"
#include "debug.h"

#include <stdio.h>
#include <stdint.h>

void append_list_tail(struct HeadList *list, struct List *item)
{
    item->next = NULL;

    if (is_list_empty(list))
    {
        list->next = item;
        list->tail = item;
    }
    else
    {
        list->tail->next = item;
        list->tail = item;
    }
}

struct List *remove_list_head(struct HeadList *list)
{
    struct List *item;

    if (is_list_empty(list))
    {
        return NULL;
    }

    item = list->next;
    list->next = item->next;

    if (list->next == NULL)
    {
        list->tail = NULL;
    }

    return item;
}

bool is_list_empty(struct HeadList *list)
{
    return (list->next == NULL);
}



// Simple integer square root function
uint64_t own_sqrt(uint64_t x) {
    uint64_t res = 0;
    uint64_t bit = 1ULL << 62; // The highest bit in a 64-bit integer

    // Iterate through each bit of the result
    while (bit > x)
        bit >>= 2;

    while (bit != 0) {
        if (x >= res + bit) {
            x -= res + bit;
            res = (res >> 1) + bit;
        } else {
            res >>= 1;
        }
        bit >>= 2;
    }

    return res;
}

// Simple ceiling function
uint64_t own_ceil(double x) {
    uint64_t int_part = (uint64_t)x;
    double frac_part = x - int_part;

    if (frac_part > 0.0)
        int_part++;

    return int_part;
}