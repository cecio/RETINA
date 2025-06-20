//==============================================================================
//                                  R.E.T.I.N.A.
//                                    GameOver
//==============================================================================

// Includes
#import "gameData.asm"
#import "lib/libIncludes.asm"

//==============================================================================
// Variables

tGameOver:              .text "g a m e    o v e r "
                        .byte 0

//==============================================================================
// Subroutines

gameOverScreen:
    LIBSPRITE_ENABLEALL_V(false)                                 // Disable all sprites
    LIBSCREEN_SETCHARMEMORY_V(CharacterSlot2000)                 // Set the custom character set
    LIBSCREEN_SET_VIC_BANK_V(VIC_BANK3)
    LIBSCREEN_SETSCREENCOLOR_V(BLACK)

    LIBSCREEN_SETBACKGROUND_AA(interruptBackground, interruptBackgroundCol, BANK3_LOCATION)
    LIBUTILITY_SET1000_AV(SCREENRAM, Space, BANK3_LOCATION)     // Clear the screen

    LIBSCREEN_DRAWTEXT_VVA(10, 7, tGameOver, BANK3_LOCATION)

    lda bUsePaddle                       // Check if using paddle or joystick
    cmp #$01
    beq gGOWaitFirePaddle

gGOWaitFireJoystick:
    LIBINPUT_GET_V(GameportFireMask)     // Check Joystick Fire
    bne gGOWaitFireJoystick              // Wait fire press to start
    LIBINPUT_WAIT_FOR_FIRE_RELEASE()     // Debounce - May be we'll remove this

    lda #$00                             // Reset scrolling text flag
    sta bStopScrollingText
    rts

gGOWaitFirePaddle:
    LIBINPUT_GET_PADDLE_X_AA(ZeroPage1, ZeroPage2)
    lda ZeroPage2
    and #%00000100
    bne gGOWaitFirePaddle

    lda #$00                             // Reset scrolling text flag
    sta bStopScrollingText
    rts