@ECHO OFF

cd ".\tracks"
del *.bin
forfiles /s /m *.6502 /c "cmd /c BeebAsm.exe -i @path"

cd ..
BeebAsm.exe -i .\main.s.6502 -title SQUATM -do .\SquatM_Beeper_Engine.ssd -opt 3