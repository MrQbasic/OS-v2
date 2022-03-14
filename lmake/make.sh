cd ..
clear

cd boot/
nasm bootsec.s -f bin -o bootsec.bin

cd ../kernel/
nasm kernel-PM.s -f bin -o kernel-PM.bin
nasm kernel.s -f bin -o kernel.bin
ls -lh
cd ..

cat boot/bootsec.bin kernel/kernel-PM.bin kernel/kernel.bin 1,44mb.img > tmp.img
dd if=tmp.img of=OS.img bs=512 count=2880

rm kernel/kernel-PM.bin
rm kernel/kernel.bin
rm boot/bootsec.bin
rm tmp.img

cd lmake/
