#ifndef _TRAP_H_
#define _TRAP_H_

#include "stdint.h"

// structure of IdtEntry - refer to kernel.asm old / image
struct IdtEntry
{
    uint16_t low;
    uint16_t selector;
    uint8_t res0;
    uint8_t attr;
    uint16_t mid;
    uint32_t high;
    uint32_t res1;
};

// Structure of IdtPr - refer to kernel.asm old
struct IdtPtr
{
    uint16_t limit;
    uint64_t addr;
} __attribute__((packed));

// TrapFrame holds all values for a trap - registers (pushed and popped by Trap and Trap return routines), trapno, error code (both pushed by vector routines), remaining values pushed by processor(rflags, rip, cs, rsp, ss)
struct TrapFrame
{
    int64_t r15;
    int64_t r14;
    int64_t r13;
    int64_t r12;
    int64_t r11;
    int64_t r10;
    int64_t r9;
    int64_t r8;
    int64_t rbp;
    int64_t rdi;
    int64_t rsi;
    int64_t rdx;
    int64_t rcx;
    int64_t rbx;
    int64_t rax;
    int64_t trapno;
    int64_t errorcode;
    int64_t rip;
    int64_t cs;
    int64_t rflags;
    int64_t rsp;
    int64_t ss;
};

// All vectors defined here
void vector0(void);
void vector1(void);
void vector2(void);
void vector3(void);
void vector4(void);
void vector5(void);
void vector6(void);
void vector7(void);
void vector8(void);
void vector10(void);
void vector11(void);
void vector12(void);
void vector13(void);
void vector14(void);
void vector16(void);
void vector17(void);
void vector18(void);
void vector19(void);
void vector32(void);
void vector39(void);

// All codes defined in asm and also previously covered in old kernel.asm file
// initialize idt
void init_idt(void);

// endOfInterrupt
void eoi(void);

// Load Idt
void load_idt(struct IdtPtr *ptr);

// read ISR
unsigned char read_isr(void);

#endif