cd ..
rm ./log.txt
clear
qemu-system-x86_64 -hda OS.img -cpu max -D log.txt -d int
cd lmake
