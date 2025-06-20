//==============================================================================
//                                  R.E.T.I.N.A.
//                              Splash Screen Mgmt
//==============================================================================

//==============================================================================
// Includes

#importonce
#import "lib/libIncludes.asm"
#import "gameData.asm"

//==============================================================================
// Constants

.const splashPressColumn            = 10
.const splashPressRow               = 22

//==============================================================================
// Variables

tSplashTitle1:              .text "realtime electronic threat"
                            .byte 0

tSplashTitle2:              .text "and intrusion neutralization apparatus"
                            .byte 0

tSplashPressFire:          .text "press space to start"
                           .byte 0 

tTextToScroll:
                           .text "coded by cesare pizzi - graphics by bpegu - "
                           .text "press 'j' (default) for joystick or 'p' for paddle - "
                           .text "press 'e' (default) for easy mode or 'h' for hard mode - "
                           .text "v0.9"
                           .text "                                            "
                           .byte 0

//==============================================================================

splashPressStart:
    LIBSCREEN_SETCHARMEMORY_V(CharacterSlot2000)          // Set the custom character set
    LIBSCREEN_SETMULTICOLORMODE_V(true)                   // Set the background multicolor mode
    LIBSCREEN_SETMULTICOLORS_VV(DARK_GRAY, GRAY)          // Set the background multicolor
    LIBSCREEN_SETBACKGROUND_AA(splashScreenBackground, splashScreenBackgroundCol, BANK3_LOCATION)

    LIBSCREEN_DRAWTEXT_VVA(8, 14, tSplashTitle1, BANK3_LOCATION)
    LIBSCREEN_DRAWTEXT_VVA(2, 15, tSplashTitle2, BANK3_LOCATION)

    LIBSCREEN_DRAWTEXT_VVA(splashPressColumn, splashPressRow, tSplashPressFire, BANK3_LOCATION)
    rts

//============================================================================

splashInitScrolling:
    ldy #<tTextToScroll      // Low byte of TEXTToScroll
    sty sTextLoader+1
    ldy #>tTextToScroll      // High byte of TEXTToScroll
    sty sTextLoader+2
    rts

splashTextLooper:
    ldx #0

sTextMover:
    lda $C7C1,x             // Read from bottom row +1 column
    sta $C7C0,x             // Shift left into bottom row
    inx
    cpx #$27                // 39 decimal columns (0..39)
    bne sTextMover

sTextLoader:
    lda tTextToScroll        // Self-modifying: opcode $AD, then LOW/HIGH
    cmp #$00                 // Check end of string
    beq EndOfText
    sta $C7E7                // Place new character in last column of bottom row
    clc
    lda sTextLoader+1        // Increment LOW byte of text address
    adc #1
    sta sTextLoader+1
    lda sTextLoader+2        // Increment HIGH byte if needed
    adc #0
    sta sTextLoader+2

    rts
EndOfText:
    jmp splashInitScrolling
    rts
    
//============================================================================