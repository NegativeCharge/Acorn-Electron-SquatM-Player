\beebasm\beebasm.exe -v -i main.6502 -title SQUATM -do squatm.ssd -opt 3 > squatm-listing.txt
if %ERRORLEVEL% neq 0 pause & exit

