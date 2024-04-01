nasm -f bin -o boot.bin ../boot/boot.asm
nasm -f bin -o loader.bin ../boot/loader.asm
nasm -f elf64 -o kernela.o ../kernel/kernel.asm
nasm -f elf64 -o trapa.o ../trap/trap.asm
nasm -f elf64 -o liba.o ../lib/lib.asm
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../kernel/main.c -o main.o
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../trap/trap.c -o trap.o
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../lib/print.c -o print.o
gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c ../lib/debug.c -o debug.o
ld -nostdlib -T link.lds -o kern kernela.o main.o trapa.o trap.o liba.o print.o debug.o
objcopy -O binary kern kernel.bin
dd if=boot.bin of=../boot.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=../boot.img bs=512 count=5 seek=1 conv=notrunc
dd if=kernel.bin of=../boot.img bs=512 count=100 seek=6 conv=notrunc