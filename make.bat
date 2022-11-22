@ECHO OFF
BeebAsm.exe -i .\tracks\shiru.lets_go.samples.6502
BeebAsm.exe -i .\tracks\shiru.lets_go.track.6502

BeebAsm.exe -i .\tracks\dj.h0ffman.squat_party.samples.6502
BeebAsm.exe -i .\tracks\dj.h0ffman.squat_party.track.6502

BeebAsm.exe -i .\tracks\shiru.geostorm.samples.6502
BeebAsm.exe -i .\tracks\shiru.geostorm.track.6502

BeebAsm.exe -i .\tracks\shiru.high_orbit.samples.6502
BeebAsm.exe -i .\tracks\shiru.high_orbit.track.6502

BeebAsm.exe -i .\main.s.6502 -title SQUATM -do .\SquatM_Beeper_Engine.ssd -opt 3