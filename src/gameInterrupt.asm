//==============================================================================
//                                  R.E.T.I.N.A.
//                                 Interrupt Page
//==============================================================================

// Includes
#import "gameData.asm"
#import "malwareData.asm"
#import "lib/libIncludes.asm"

//==============================================================================
// Constants


//==============================================================================
// Variables

bSaveSpriteStatus:  .byte 0

// Arrays

//==============================================================================
// Jump Tables


//==============================================================================
// Subroutines

interruptMain:
    pha                                  // PUSH accumulator
    stx bSaveX
    sty bSaveY

    lda SPENA                           // Save status of Sprites
    sta bSaveSpriteStatus
    LIBSPRITE_ENABLEALL_V(false)        // Disable all sprites
    
    LIBSCREEN_SETCHARMEMORY_V(CharacterSlot3000)       // Set the custom character set
    LIBUTILITY_SET1000_AV(SCREENRAM, Space, BANK0_LOCATION)
    LIBSCREEN_SETMULTICOLORS_VV(GRAY, DARK_GRAY)       // Set the background multicolor
    LIBSCREEN_SETBACKGROUND_AA(interruptBackground, interruptBackgroundCol, BANK0_LOCATION)

    // Display Malware Info
    jsr gIDisplayMalwareInfo
    inc mdCurrentFeature                 // Go to next info
    inc mdCurrentFeature                 // +2 since index is word

    LIBUTILITY_WAITLOOP_V(20000)         // Delay for stabilize fire press

    lda bUsePaddle                       // Check if using paddle or joystick
    cmp #$01
    beq gIMWaitFirePaddle

    LIBINPUT_WAIT_FOR_FIRE_RELEASE()     // Debounce
gIMWaitFireJoystick:
    LIBINPUT_GET_V(GameportFireMask)
    bne gIMWaitFireJoystick              // Wait fire press to start
    LIBINPUT_WAIT_FOR_FIRE_RELEASE()     // Debounce - May be we'll remove this
    jmp gIMRestoreScreen

gIMWaitFirePaddle:
    LIBINPUT_GET_PADDLE_X_AA(ZeroPage1, ZeroPage2)
    lda ZeroPage2
    and #%00000100
    bne gIMWaitFirePaddle

gIMRestoreScreen:
    // Restore game screen
    LIBSCREEN_SETCHARMEMORY_V(CharacterSlot2000)
    LIBSCREEN_SETMULTICOLORS_VV(mdBckgrndColor1, mdBckgrndColor2) 
    LIBSCREEN_SETBACKGROUND_AA(gameDataBackground, gameDataBackGroundCol, BANK0_LOCATION) // Set the background screen
    LIBSCREEN_DRAWTEXT_VVA(4, 24, mdMD5, BANK0_LOCATION)      // Display malware MD5
    LIBSCREEN_DRAW_N_CHAR_VVVA(4, 0, ExpLivesChar, bExpLives, BANK0_LOCATION)    // Display lives

    lda bSaveSpriteStatus               // Restore Sprites status
    sta SPENA
    lda SPSPCL                          // Clear collision register

    ldx bSaveX
    ldy bSaveY
    pla                                 // POP accumulator
    rts

//==============================================================================

gIDisplayMalwareInfo:
    ldx mdCurrentFeature            // Load current info index

    // Display Rule
    lda mdRulesPtrs,x               // Low byte of string address
    sta ZeroPage10
    lda mdRulesPtrs+1,x             // high byte of string address
    sta ZeroPage11
    LIBSCREEN_DRAWTEXT_INDIRECT_VVA(3, 8, ZeroPage10, BANK0_LOCATION)

    // Display Scope
    lda mdScopePtrs,x               // Low byte of string address
    sta ZeroPage10
    lda mdScopePtrs+1,x             // high byte of string address
    sta ZeroPage11
    LIBSCREEN_DRAWTEXT_INDIRECT_VVA(3, 10, ZeroPage10, BANK0_LOCATION)

    // Display Matches
    lda mdMatchesPtrs,x               // Low byte of string address
    sta ZeroPage10
    lda mdMatchesPtrs+1,x             // high byte of string address
    sta ZeroPage11
    LIBSCREEN_DRAWTEXT_INDIRECT_VVA(3, 12, ZeroPage10, BANK0_LOCATION)

    rts