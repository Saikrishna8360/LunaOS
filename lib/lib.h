#ifndef _LIB_H_
#define _LIB_H_

#include "stdbool.h"
#include "stdint.h"


struct List
{
    struct List *next;
};

struct HeadList
{
    struct List *next;
    struct List *tail;
};

void memset(void *buffer, char value, int size);
void memmove(void *dst, void *src, int size);
void memcpy(void *dst, void *src, int size);
int memcmp(void *src1, void *src2, int size);
void append_list_tail(struct HeadList *list, struct List *item);
struct List *remove_list_head(struct HeadList *list);
bool is_list_empty(struct HeadList *list);

uint64_t own_sqrt(uint64_t x);
uint64_t own_ceil(double x);

#endif