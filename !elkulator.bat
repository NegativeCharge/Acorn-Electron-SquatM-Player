@echo off
copy elk.cfg \Elkulator
cd \Elkulator
@set "__COMPAT_LAYER=~ HIGHDPIAWARE" & start "" "Elkulator.exe"
