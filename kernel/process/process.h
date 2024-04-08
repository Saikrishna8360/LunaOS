#ifndef _PROCESS_H_
#define _PROCESS_H_

#include "../../trap/trap.h"

// Process Control Block
struct Process
{
    int pid;
    int state;
    uint64_t page_map; // Address of PML4 table, to switch to current_vm
    uint64_t stack;    // Two stacks - user mode and kernel mode - this is stack for kernel mode
    struct TrapFrame *tf;
    // int run_time;
};

// used for setting up stack pointer for ring 0
struct TSS
{
    uint32_t res0;
    uint64_t rsp0;
    uint64_t rsp1;
    uint64_t rsp2;
    uint64_t res1;
    uint64_t ist1;
    uint64_t ist2;
    uint64_t ist3;
    uint64_t ist4;
    uint64_t ist5;
    uint64_t ist6;
    uint64_t ist7;
    uint64_t res2;
    uint16_t res3;
    uint16_t iopb;
} __attribute__((packed));
// structure are stored without padding in it

#define STACK_SIZE (2 * 1024 * 1024) // 2 MB stack size
#define NUM_PROC 10                  // total up to 10 processes
#define PROC_UNUSED 0
#define PROC_INIT 1

void init_process(void);
void launch(void);
void pstart(struct TrapFrame *tf);

#endif