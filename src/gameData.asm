//==============================================================================
//                                  R.E.T.I.N.A.
//                                   Game Data
//==============================================================================
#importonce
#import "lib/libDefines.asm"

*= $0900 "Common Variables"

//==============================================================================
// Constants

// Game Sprites
.const BitsSpriteMax = 6    // May be in can be lowered to 3 if need more sprites

// Lives management
.const ExpLivesChar = $d9
.const ClearExpLivesChar = $d8

//==============================================================================
// Variables (global)

// Difficulty level: 2 (Easy) or 4 (Hard)
bDifficultyLevel:      .byte 2

// Lives management
bMaxNumberOfLives:     .byte 5
bExpLives:             .byte 5

// Joystick/Paddles management
bUsePaddle:     .byte 0
bPaddleX:       .byte 0   // Current X value
bPaddleXPrev:   .byte 0   // Previous X value
bPaddleXBtn:    .byte 0

// Game Sprite Coordinates, colors and hits
wBitsXHArray:            .byte   0,  0,  0,  0,  0,  0
wBitsXLArray:            .byte   0,  0,  0,  0,  0,  0
bBitsYArray:             .byte   0,  0,  0,  0,  0,  0
bBitsAssignedColorArray: .byte   0,  0,  0,  0,  0,  0
bBitsHitArray:           .byte   0,  0,  0,  0,  0,  0

// Index save vars
bSaveX:             .byte 0
bSaveY:             .byte 0

// Stop scrolling text (true/false)
bStopScrollingText:    .byte 0

//==============================================================================

*= $1000 "Sounds" // Add sound data at the $1000 memory location
gameDataSID:
    // $7E is the size of the header to be skipped
    .import binary "res/Death_Techno.sid", $7E

SFX_Fire:      .byte $0E,$00,$33,$D0,$21,$C8,$21,$C0,$21,$B8,$21,$B0,$21,$A8,$21,$A0,$11,$00

//==============================================================================

*= $2000 "Game Background Charset" // Add character data at the $2000 memory location
    .import binary "res/gameBackgroundCharset.bin"

*= $3000 "Interrupt Screen Charset"
    .import binary "res/mainCharset.bin"

*= BANK3_LOCATION + $2000 "Splash Screen Charset"
    .import binary "res/splashScreenCharset.bin"


//==============================================================================    

*= $2800 "Game Sprites" 
    .import binary "res/SpriteGunsight.bin"        // Frame 0-1 Animated
    .import binary "res/SpriteBits.bin"            // Frame 2-...

//==============================================================================    

*= $3300 "Game Screen" // Add background data at the $3080 memory location
gameDataBackground:
    .import binary "res/gameBackground.bin"
gameDataBackGroundCol:
    .import binary "res/gameBackgroundColorMap.bin"
interruptBackground:
    .import binary "res/interruptBackground.bin"
interruptBackgroundCol:
    .import binary "res/mainCharsetColorMap.bin"

*= BANK3_LOCATION + $2D00 "Splash Screen"
splashScreenBackground:
    .import binary "res/splashScreenBackground.bin"
splashScreenBackgroundCol:
    .import binary "res/splashScreenColorMap.bin"