KENEL_BIN=./kernel/kernel.bin
KENEL_PM_BIN=./kernel/kernel-PM.bin
BOOT_BIN=./boot/bootsec.bin

cd ..
rm -rf ./bin
mkdir ./bin
clear

cd boot/
nasm bootsec.s -f bin -o bootsec.bin

cd ../kernel/
nasm kernel-PM.s -f bin -o kernel-PM.bin
nasm kernel.s -f bin -o kernel.bin
ls -lh *.bin
cd ..

cat boot/bootsec.bin kernel/kernel-PM.bin kernel/kernel.bin 1,44mb.img > tmp.img
dd if=tmp.img of=OS.img bs=512 count=2880

if [ -f "$KENEL_BIN" ]; then
    echo "$KENEL_BIN"
    mv "$KENEL_BIN" ./bin/
fi
if [ -f "$KENEL_PM_BIN" ]; then
    mv "$KENEL_PM_BIN" ./bin/
fi
if [ -f "$BOOT_BIN" ]; then
    mv "$BOOT_BIN" ./bin/
fi
rm tmp.img

cd lmake/
