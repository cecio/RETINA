//==============================================================================
//                        RetroGameDev Library C64 v2.02
//==============================================================================
// Includes

#importonce

//==============================================================================
// Constants

// Misc
.label True  = 1
.label False = 0
.label Space = 32

// Zero Page
.label ZeroPage1 = $02
.label ZeroPage2 = $03
.label ZeroPage3 = $04
.label ZeroPage4 = $05
.label ZeroPage5 = $06
.label ZeroPage6 = $07
.label ZeroPage7 = $08
.label ZeroPage8 = $09
.label ZeroPage9 = $0A
.label ZeroPage10 = $0B
.label ZeroPage11 = $0C
.label ZeroPage12 = $0D
.label ZeroPage13 = $0E
.label ZeroPage14 = $0F
.label ZeroPage15 = $10

.label ZeroPageLow  = $FB
.label ZeroPageHigh = $FC 

// Character memory slots
.label CharacterSlot0000 = $00 // $0000 hex,     0 decimal
.label CharacterSlot0800 = $02 // $0800 hex,  2048 decimal
.label CharacterSlot1000 = $04 // $1000 hex,  4096 decimal
.label CharacterSlot1800 = $06 // $1800 hex,  6144 decimal
.label CharacterSlot2000 = $08 // $2000 hex,  8192 decimal
.label CharacterSlot2800 = $0A // $2800 hex, 10240 decimal
.label CharacterSlot3000 = $0C // $3000 hex, 12288 decimal
.label CharacterSlot3800 = $0E // $3800 hex, 14336 decimal

// Memory areas
.label SCREENRAM    = $0400
.label COLORRAM     = $D800
.label SPRITERAM    = 160 // 160 decimal * 64(sprite size) = 10240(hex $2800)
.label SPRITE0PTR   = SCREENRAM  + 1024 - 8 // $07F8, last 8 bytes of SCREENRAM are sprite ptrs

// Register names taken from 'Mapping the Commodore 64' book

// 6510 Registers
.label D6510        = $0000
.label R6510        = $0001

// VIC-II Registers
.label SP0X         = $D000
.label SP0Y         = $D001
.label MSIGX        = $D010
.label SCROLY       = $D011
.label RASTER       = $D012
.label SPENA        = $D015
.label SCROLX       = $D016
.label VMCSB        = $D018
.label SPMC         = $D01C
.label SPSPCL       = $D01E
.label EXTCOL       = $D020
.label BGCOL0       = $D021
.label BGCOL1       = $D022
.label BGCOL2       = $D023
.label BGCOL3       = $D024
.label SPMC0        = $D025
.label SPMC1        = $D026
.label SP0COL       = $D027

// IRQ Registers
.label VICIRQ       = $D019
.label IRQMSK       = $D01A

// CIA #1 Registers (Generates IRQ's)
.label CIAPRA       = $DC00
.label CIAPRB       = $DC01
.label CIAICR       = $DC0D

// CIA #2 Registers (Generates NMI's)
.label CI2PRA       = $DD00
.label CI2PRB       = $DD01
.label CI2ICR       = $DD0D

// Timer Registers
.label TIMALO       = $DC04
.label TIMAHI       = $DC05
.label TIMBHI       = $DC07

// Interrupt Vectors
.label IRQRAMVECTOR = $0314
.label IRQROMVECTOR = $FFFE
.label NMIRAMVECTOR = $0318
.label NMIROMVECTOR = $FFFA

// Interrupt Routines
.label IRQROMROUTINE = $EA31

// VIC-II BANK constants
.label BANK3_LOCATION = $C000
.label BANK2_LOCATION = $8000
.label BANK1_LOCATION = $4000
.label BANK0_LOCATION = $0000

.label VIC_BANK0 = $03                // bits 11 (Bank 0: $0000–$3FFF)
.label VIC_BANK1 = $02                // bits 10 (Bank 1: $4000–$7FFF)
.label VIC_BANK2 = $01                // bits 01 (Bank 2: $8000–$BFFF)
.label VIC_BANK3 = $00                // bits 00 (Bank 3: $C000–$FFFF)

// Data Direction Registers
.label CIDDRA       = $DC02
.label CIDDRB       = $DC03

// Sound related Registers
.label FRELO1       = $D400
.label FRELO2       = $D407
.label FRELO3       = $D40E

.label SIGVOL       = $D418

.label ATDCY1       = $D405
.label ATDCY2       = $D40C
.label ATDCY3       = $D413

.label SUREL1       = $D406
.label SUREL2       = $D40D
.label SUREL3       = $D414

.label FREHI1       = $D401
.label FREHI2       = $D408
.label FREHI3       = $D40F

.label PWHI1        = $D403
.label PWHI2        = $D40A
.label PWHI3        = $D411

.label PWLO1        = $D402
.label PWLO2        = $D409
.label PWLO3        = $D410

.label VCREG1       = $D404
.label VCREG2       = $D40B
.label VCREG3       = $D412