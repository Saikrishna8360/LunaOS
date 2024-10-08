#include "syscall.h"
#include "print.h"
#include "process.h"
#include "debug.h"
#include "stddef.h"

static SYSTEMCALL system_calls[10];

static int sys_write(int64_t *argptr)
{    
    write_screen((char*)argptr[0], (int)argptr[1], 0xe);  
    return (int)argptr[1];
}

static int sys_sleep(int64_t* argptr)
{
    uint64_t old_ticks; 
    uint64_t ticks;
    uint64_t sleep_ticks = argptr[0];

    ticks = get_ticks();
    old_ticks = ticks;

    while (ticks - old_ticks < sleep_ticks) {
       sleep(-1);
       ticks = get_ticks();
    }

    return 0;
}

static int sys_exit(int64_t *argptr)
{
    exit();
    return 0;
}

static int sys_wait(int64_t *argptr)
{
    wait();
    return 0;
}

void init_system_call(void)
{
    system_calls[0] = sys_write;
    system_calls[1] = sys_sleep;
    system_calls[2] = sys_exit;
    system_calls[3] = sys_wait;
}

void system_call(struct TrapFrame *tf)
{
    int64_t i = tf->rax;
    int64_t param_count = tf->rdi;
    int64_t *argptr = (int64_t*)tf->rsi;

    if (param_count < 0 || i > 3 || i < 0) { 
        tf->rax = -1;
        return;
    }
    
    ASSERT(system_calls[i] != NULL);
    tf->rax = system_calls[i](argptr);
}