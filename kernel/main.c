#include "../trap/trap.h"
#include "../lib/print.h"
#include "../lib/debug.h"
#include "memory/memory.h"
#include "process/process.h"
#include "../lib/syscall.h"

void KMain(void)
{
    init_idt();
    init_memory();
    init_kvm();
    init_system_call();
    init_process();
    launch();
}