# Acorn Electron SquatM 1-bit Beeper Engine Player

- SquatM beeper music engine
- Originally written by Shiru 06'17 for ZX Spectrum 48K
- Ported to Atari 8-bit by Shiru 07'21
- Ported to the Acorn Electron by Negative Charge 11'22
- Optimisations of the Acorn Electron version by 0xC0DE 11'22

SquatM tracks can be composed in 1Tracker (https://shiru.untergrund.net/software.shtml) - you will need to export the track in Atari ca65 format, and manually convert to BeebAsm format (see samples for changes required).

SSD file for emulators/hardware: https://github.com/NegativeCharge/Acorn-Electron-SquatM-Player/blob/master/SquatM_Beeper_Engine.ssd?raw=true

Release Notes:

- v0.1 - Initial ca65 port.
- v0.2 - Fully converted to BeebAsm. Debug rasters now off by default as they waste cycles.
- v0.3 - Implement half resolution (32 sound loop iterations instead of 64) by default.  Full resolution can be enabled by setting HALF_RESOLUTION flag to FALSE, but then requires a turbo board for playback.
- v0.4 - Auto-detect Slogger/Jaffa Master RAM board in turbo mode. HALF_RESOLUTION flag removed.
- v0.5 - Cycle optimisation to sound loop by @0xC0DE6502.
- v0.6 - Further optimisation by @0xC0DE6502, negating the need for a turbo board.
- v0.7 - Initial implementation of dynamic loading of track and sample data
- v0.8 - Implement basic player that cycles through available tracks from disk