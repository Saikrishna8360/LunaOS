nasm -f bin -o boot.bin ../boot/boot.asm
nasm -f bin -o loader.bin ../boot/loader.asm
nasm -f elf64 -o kernela.o ../kernel/kernel.asm
nasm -f elf64 -o trapa.o ../trap/trap.asm
nasm -f elf64 -o liba.o ../lib/lib.asm
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../kernel/main.c -o main.o
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../trap/trap.c -o trap.o
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../lib/print.c -o print.o
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../lib/debug.c -o debug.o
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../kernel/memory/memory.c -o memory.o
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../kernel/process/process.c -o process.o
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../lib/syscall.c -o syscall.o
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../lib/lib.c 
ld -nostdlib -T link.lds -o kern kernela.o main.o trapa.o trap.o liba.o print.o debug.o memory.o process.o syscall.o lib.o
objcopy -O binary kern kernel.bin
dd if=boot.bin of=../boot.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=../boot.img bs=512 count=5 seek=1 conv=notrunc
dd if=kernel.bin of=../boot.img bs=512 count=100 seek=6 conv=notrunc
dd if=user1.bin of=../boot.img bs=512 count=10 seek=106 conv=notrunc
dd if=user2.bin of=../boot.img bs=512 count=10 seek=116 conv=notrunc
dd if=user3.bin of=../boot.img bs=512 count=10 seek=126 conv=notrunc