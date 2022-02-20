@echo off
cd ..
cls

cd boot/
nasm bootsec.s -f bin -o bootsec.bin

cd ../kernel/
nasm kernel-preload.s -f bin -o kernel-preload.bin
nasm kernel.s -f bin -o kernel.bin
ls -lh *.bin
cd ..
if not exist kernel/kernel-preload.bin goto error
if not exist kernel/kernel.bin goto error
if not exist boot/bootsec.bin goto error

cat boot/bootsec.bin kernel/kernel-preload.bin kernel/kernel.bin 1,44mb.img> tmp.img
dd if=tmp.img of=OS.img bs=512 count=2880
del *.bin /s
del tmp.img
cd wmake/
echo OK
goto exit

:error
    echo ERROR
    cd wmake/

:exit