#include "process.h"
#include "../../trap/trap.h"
#include "../memory/memory.h"
#include "../../lib/print.h"
#include "../../lib/lib.h"
#include "../../lib/debug.h"

extern struct TSS Tss;
static struct Process process_table[NUM_PROC]; // like process queue
static int pid_num = 1;
static struct ProcessControl pc;

// assign the top of the kernel stack to rsp0 in the tss. So when we jump from ring3 to ring0, the kernel stack is used. The tss is defined in the kernel file.
static void set_tss(struct Process *proc)
{
    Tss.rsp0 = proc->stack + STACK_SIZE;
}

// loop through process table for an unused process (state = PROC_UNUSED), if found return address and exit
static struct Process *find_unused_process(void)
{
    struct Process *process = NULL;

    for (int i = 0; i < NUM_PROC; i++)
    {
        if (process_table[i].state == PROC_UNUSED)
        {
            process = &process_table[i];
            break;
        }
    }

    return process;
}

// Sets PCB
static void set_process_entry(struct Process *proc, uint64_t addr)
{
    uint64_t stack_top;

    proc->state = PROC_INIT;
    proc->pid = pid_num++;

    proc->stack = (uint64_t)kalloc(); // allocates page for kernel stack
    ASSERT(proc->stack != 0);

    memset((void *)proc->stack, 0, PAGE_SIZE); // zeros the page
    stack_top = proc->stack + STACK_SIZE;      // Sets stack top to base address of next page (since stack grows downwards)
    // so it will decrement the pointer when data is pushed onto stack

    proc->context = stack_top - sizeof(struct TrapFrame) - 7 * 8;
    *(uint64_t *)(proc->context + 6 * 8) = (uint64_t)TrapReturn;

    // In our system, the top of the kernel stack is set to the rsp0 in tss. Meaning that, when the interrupt or exception handler is called, the stack used in this case is actually the kernel stack we set up in the process.

    // when we execute interrupt return (in trap.asm), we will be jumping to address 400000 and running in ring3. The top of the stack we use in the process is set to 600000, so if we push data on the stack, the first one will be pushed on the top address of the same page and so on

    proc->tf = (struct TrapFrame *)(stack_top - sizeof(struct TrapFrame));
    proc->tf->cs = 0x10 | 3;
    proc->tf->rip = 0x400000;
    proc->tf->ss = 0x18 | 3;
    proc->tf->rsp = 0x400000 + PAGE_SIZE;
    proc->tf->rflags = 0x202;

    // The rip is set to 400000 and rsp is 400000 plus page size. So the code and stack of the program are in the same page.

    // setup Kernel virtual memory
    proc->page_map = setup_kvm(); // page_map stores PML4 table
    ASSERT(proc->page_map != 0);
    ASSERT(setup_uvm(proc->page_map, P2V(addr), 5120)); // setup uvm - arguments are PML4 table, address of start of user program and size of program which is the page size
    proc->state = PROC_READY;
}

static struct ProcessControl *get_pc(void)
{
    return &pc;
}

// Initialize new process
// Find unused process slot in process table
// check if it is the first entry in process table
void init_process(void)
{
    struct ProcessControl *process_control;
    struct Process *process;
    struct HeadList *list;
    uint64_t addr[2] = {0x20000, 0x30000};

    process_control = get_pc();
    list = &process_control->ready_list;

    for (int i = 0; i < 2; i++)
    {
        process = find_unused_process();
        set_process_entry(process, addr[i]);
        append_list_tail(list, (struct List *)process);
    }
}

// start process
void launch(void)
{
    struct ProcessControl *process_control;
    struct Process *process;

    process_control = get_pc();
    process = (struct Process *)remove_list_head(&process_control->ready_list);
    process->state = PROC_RUNNING;
    process_control->current_process = process;

    set_tss(process);
    switch_vm(process->page_map);
    pstart(process->tf);
    // now we are at the process virtual space and we have copied the main function in the address 400000
    // jump to trap return to get to ring3 and run the main function.

    // change rsp register to point to the start of the trap frame when we at trap return.
}

static void switch_process(struct Process *prev, struct Process *current)
{
    set_tss(current);
    switch_vm(current->page_map);
    swap(&prev->context, current->context);
}

static void schedule(void)
{
    struct Process *prev_proc;
    struct Process *current_proc;
    struct ProcessControl *process_control;
    struct HeadList *list;

    process_control = get_pc();
    prev_proc = process_control->current_process;
    list = &process_control->ready_list;
    ASSERT(!is_list_empty(list));

    current_proc = (struct Process *)remove_list_head(list);
    current_proc->state = PROC_RUNNING;
    process_control->current_process = current_proc;

    switch_process(prev_proc, current_proc);
}

void yield(void)
{
    struct ProcessControl *process_control;
    struct Process *process;
    struct HeadList *list;

    process_control = get_pc();
    list = &process_control->ready_list;

    if (is_list_empty(list))
    {
        return;
    }

    process = process_control->current_process;
    process->state = PROC_READY;
    append_list_tail(list, (struct List *)process);
    schedule();
}
