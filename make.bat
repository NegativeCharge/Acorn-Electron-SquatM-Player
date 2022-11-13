ca65 --debug-info --ignore-case --target none --cpu 6502 -o main.o --listing main.txt main.s
ld65 -C BBC.cfg -o main.bin main.o 
del main.o

@beebasm.exe -i create-disk.asm -do ca65-squatm-player.ssd -opt 3

del main.bin