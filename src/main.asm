//==============================================================================
//                                  R.E.T.I.N.A.
//        Real-time Electronic Threat & Intrusion Neutralization Apparatus
//                         a Malware Analysis retro game
//==============================================================================
// Basic Loader

*= $0801 "Basic Loader" 
    BasicUpstart(gameMainInit)

//==============================================================================
// Includes

    #import "gameData.asm"
*= $4120 "Code"
    #import "lib/libIncludes.asm"
    #import "splashScreen.asm"
    #import "gunSight.asm"
    #import "bitsFlow.asm"
    #import "malwareData.asm"
    #import "gameOver.asm"

//==============================================================================
// Constants

.const IrqFast = true
.const Irq1Scanline = 0
.const bScrollDelay = 4

//==============================================================================
// Variables

bScrollDelayCount:     .byte 0

//============================================================================== 
// Initialize

gameMainInit:
    LIBUTILITY_DISABLEBASICANDKERNAL()          // Disable BASIC and Kernal ROMs
    LIBUTILITY_SET1000_AV(SCREENRAM, Space, BANK3_LOCATION)     // Clear the screen
    LIBSCREEN_SETSCREENCOLOR_V(BLACK)           // Set the screen color
    LIBSCREEN_SET_VIC_BANK_V(VIC_BANK3)
    LIBRASTERIRQ_INIT_VAV(Irq1Scanline, gameMainIRQ1, IrqFast) // Initialize the irq
    LIBSOUND_INIT_A(gameDataSID)                               // Initialize the sound

    jsr splashPressStart
    lda #$00                                    // Reset feature number
    sta mdCurrentFeature
    jsr splashInitScrolling
//==============================================================================
// Update

gameMainSplashScreen:
    LIBINPUT_P_PRESSED()
    bcc noPaddleSelected
    lda #$01                             // Select Paddle
    sta bUsePaddle
noPaddleSelected:
    LIBINPUT_J_PRESSED()
    bcc noJoystickSelected
    lda #$00                             // Select Joystick
    sta bUsePaddle
noJoystickSelected:
    LIBINPUT_E_PRESSED()
    bcc noEasySelected
    lda #$02                             // Select Easy mode
    sta bDifficultyLevel
noEasySelected:
    LIBINPUT_H_PRESSED()
    bcc noHardSelected
    lda #$04                             // Select Hard mode
    sta bDifficultyLevel
noHardSelected:
    LIBINPUT_SPACE_PRESSED()             // Start game
    bcc gameMainSplashScreen
    
    lda #$01                             // Stop the scrolling text update
    sta bStopScrollingText
    
    // Set the background
    LIBSCREEN_SETMULTICOLORMODE_V(true)             // Set the background multicolor mode
    LIBSCREEN_SETMULTICOLORS_VV(mdBckgrndColor1, mdBckgrndColor2)  // Set the background multicolor
    LIBSCREEN_SET_VIC_BANK_V(VIC_BANK0)
    LIBSCREEN_SETCHARMEMORY_V(CharacterSlot2000)
    LIBSCREEN_SETBACKGROUND_AA(gameDataBackground, gameDataBackGroundCol, BANK0_LOCATION) // Set the background screen

    LIBSPRITE_MULTICOLORENABLEALL_V(false)        // Set the sprite multicolor mode
    LIBSPRITE_MULTICOLORENABLEONE_VV(gsSpriteNum,true)   // Set multicolor only for the pointer
    LIBSPRITE_SETMULTICOLORS_VV(GRAY, RED)        // Set the sprite multicolors

    LIBMATH_RANDSEED_AA(bMathRandomCurrent1, TIMALO) // Seed the random number lists
    LIBMATH_RANDSEED_AA(bMathRandomCurrent2, TIMALO)

    LIBSCREEN_DRAWTEXT_VVA(4, 24, mdMD5, BANK0_LOCATION)           // Display malware MD5
    LIBSCREEN_DRAW_N_CHAR_VVVA(4, 0, ExpLivesChar, bExpLives, BANK0_LOCATION)    // Display lives

    jsr gunSightInit
    jsr bitsFlowInit

gameMainLoop:
    LIBSCREEN_WAIT_V(250)   // Wait for scanline 250
    LIBSPRITE_UPDATE()      // Update the sprites

    jsr gunSightUpdate     // Update gunsight sprite
    jsr bitsFlowUpdate     // Update the bits sprites

    lda bExpLives          // Check for Game Over
    cmp #$00
    beq gameOver

    jmp gameMainLoop       // Jump back, infinite loop
gameOver:
    jsr gameOverScreen
    lda bMaxNumberOfLives  // Restore number of lives
    sta bExpLives
    jmp gameMainInit

//==============================================================================


//==============================================================================
// Interrupt Handlers

gameMainIRQ1:
    LIBRASTERIRQ_START_V(IrqFast)       // Start the irq
    LIBSOUND_UPDATE_A(gameDataSID)      // Update the sound player

    lda bStopScrollingText              // Check if the scrolling text need to be stopped
    cmp #$01
    beq gameNoScrollUpdate

    lda bScrollDelayCount               // Use a delay to set the speed of scrolling text
    cmp #bScrollDelay
    bcc gameNoScrollUpdate
    jsr splashTextLooper
    lda #$00
    sta bScrollDelayCount
gameNoScrollUpdate:
    inc bScrollDelayCount
    LIBRASTERIRQ_END_V(IrqFast)         // End the irq

//============================================================================