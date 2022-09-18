cd ..
rm ./log.txt
clear
qemu-system-x86_64 \
    -drive id=disk,file=OS.img,if=none,index=0,media=disk,format=raw \
    -device ahci,id=ahci \
    -device ide-hd,drive=disk,bus=ahci.0 \
    -cpu max \
    -D log.txt \
    -d int \
    -m 4G
cd lmake
