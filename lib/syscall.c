#include "syscall.h"
#include "print.h"
#include "debug.h"
#include "stddef.h"

// When print function is called in the user program, convert the message to the string, prepare the string as argument on the user stack and execute int instruction. When system_write function is called,  function write screen is called and string in print is passed to it.

static SYSTEMCALL system_calls[10];

// argptr - points to stack in user mode
static int sys_write(int64_t *argptr)
{
    write_screen((char *)argptr[0], (int)argptr[1], 0xe);
    // retrun count of characters
    return (int)argptr[1];
}

// saves system write function as first element of system calls arrays
void init_system_call(void)
{
    system_calls[0] = sys_write;
}

// The rax is used to hold the index number of system call, 0 in this case. By specifying the index number, find the correct system call. The rdi holds the parameters count. The rsi points to the arguments passed to the function.
void system_call(struct TrapFrame *tf)
{
    int64_t i = tf->rax;
    int64_t param_count = tf->rdi;
    int64_t *argptr = (int64_t *)tf->rsi;

    if (param_count < 0 || i != 0)
    {
        tf->rax = -1;
        return;
    }

    ASSERT(system_calls[i] != NULL);
    // return value to rax
    tf->rax = system_calls[i](argptr);
}