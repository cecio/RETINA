# R.E.T.I.N.A.
Real-time Electronic Threat &amp; Intrusion Neutralization Apparatus

RETINA is the very first Retro Videogame built for Reverse Engineers. Do you want to start the analysis of that sample, but are are not really in the mood? You can try RETINA for Commodore 64, which can be fully customized with your own sample so that during your game you will perform also the Malware Triage!

The basic idea behind it is that you can get any Malware sample, get it analyzed on a modern system and then create a custom version of the game that will contain the information extracted from the malware itself.
The analysis process relies on the well known `CAPA` tool (by Mandiant) which produce a Triage with the capabilities of an executable. The result will be merged and compiled in a custom game that you can play on your real Commodore 64 (or on an emulator obviously).
You can play it with keyboard, joystick or even paddles for more fun!

## HowTo

### Needed Tools

- `Java` runtime (able to run `java -jar`)
- [Kick Assembler](https://theweb.dk/KickAssembler/Main.html#frontpage)
- [CAPA](https://github.com/mandiant/capa)
- an `unrar` utility in the PATH

### How to build the Game

Quick steps:

```
git clone https://github.com/cecio/RETINA
cd RETINA
./build_retina.py <PATH_TO_MALWARE_FILE>
```

This is the expected result:

```
[+] Executing file analysis, may take a while...
[+] Parsing result
[+] Generating ASM file
[+] Processing music
   Using SID file ...
[+] Compiling R.E.T.I.N.A.
```

In `src` folder you'll find the resulting `main.prg` file you can use in your emulator or transfer to your real Commodore 64

### Game Music

Unfortunately I tried, but I really can't write music. So I decided to do this:
there is an awesome archive of SID music available at [https://www.hvsc.c64.org/](https://www.hvsc.c64.org/) (please [support](https://www.hvsc.c64.org/support) the project if you can).
The build script tries to download the archive and add a random compatible track choosen from it. So, you'll have a new soundtrack for any different malware.
You can also specify your own if you want (`--sid` option).

To be compatible the track should be in SID file format with the following settings:
- Load address: $1000
- Init address: $1000
- Play address: $1003
- Speed: $00000000
- Clock: PAL

## References

- [CAPA](https://github.com/mandiant/capa)
- [RetroGameDev](https://www.retrogamedev.com/)
- [HVSC](https://www.hvsc.c64.org/)
