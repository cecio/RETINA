//==============================================================================
//                                  R.E.T.I.N.A.
//                             Bits Sprite Management
//==============================================================================
// Includes

#import "lib/libIncludes.asm"
#import "gameInterrupt.asm"
#import "gameData.asm"

//==============================================================================
// Constants

.const BitsMoveRight       = 0
.const BitsMoveLeft        = 1
.const BitsMoveUp          = 2
.const BitsMoveDown        = 3
.const BitsMoveRightStart  = 20
.const BitsMoveRightStop   = 125
.const BitsMoveLeftStart   = 330
.const BitsMoveLeftStop    = 230
.const BitsMoveDownStart   = 0
.const BitsMoveDownStop    = 85
.const BitsMoveUpStart     = 240
.const BitsMoveUpStop      = 170

.const BitsTimerDistance   = 10         // Used to avoid overlapping bits sprites

//==============================================================================
// Variables

// Arrays
bBitsMoveDirArray:       .byte   0,  0,  0,  0,  0,  0
bBitsTimerHArray:        .byte   0,  0,  0,  0,  0,  0
bBitsTimerLArray:        .byte   0,  0,  0,  0,  0,  0

bBitsSpriteFrameArray:   .byte   2,  3,  4,  5,  6,  7
bBitsSpriteColorArray:   .byte   BLUE, GREEN, RED

// current element values
bBitsSprite:         .byte 0
wBitsX:              .word 0
bBitsY:              .byte 0
bBitsMoveDir:        .byte 0     // 0 = Right, 1 = Left, 2 = Up, 3 = Down
bBitsElement:        .byte 0
wBitsTimer:          .word 0
bBitsTimerIsZero:    .byte 0
bBitsHit:            .byte 0

bBitsSpriteFrame:    .byte 0
bBitsSpriteColor:    .byte 0

wBitsTimerTemp:      .word 0
wBitsTimerDiff:      .word 0

//==============================================================================
// Subroutines

bitsFlowInit:
    ldx #$00
    stx bBitsSprite

gBILoop:
    // Set up Sprite and color
    inc bBitsSprite                         // x+1
    jsr bitsFlowInitSingleSprite

    inx
    cpx #BitsSpriteMax
    bne gBILoopNear

    rts
gBILoopNear:
    jmp gBILoop

//==============================================================================

bitsFlowUpdate:
    ldx #$00
    stx bBitsSprite

gBULoop:
    inc bBitsSprite // x+1
    
    jsr bitsFlowGetVariables
    jsr bitsFlowUpdateState
    jsr bitsFlowSetVariables

    inx
    cpx #BitsSpriteMax
    bne gBULoop

    rts

//==============================================================================

bitsFlowGetVariables:
    // Read this element's variables
    lda wBitsXHArray,x
    sta wBitsX+1
    lda wBitsXLArray,x
    sta wBitsX
    lda bBitsYArray,x
    sta bBitsY
    lda bBitsMoveDirArray,x
    sta bBitsMoveDir
    lda bBitsTimerHArray,x
    sta wBitsTimer+1
    lda bBitsTimerLArray,x
    sta wBitsTimer
    lda bBitsHitArray,x
    sta bBitsHit
   
    // Save X register
    stx bBitsElement

    rts

//==============================================================================

bitsFlowSetVariables:
    // Restore X register
    ldx bBitsElement

    // Store this element's variables
    lda wBitsX+1
    sta wBitsXHArray,x
    lda wBitsX
    sta wBitsXLArray,x
    lda bBitsY
    sta bBitsYArray,x
    lda bBitsMoveDir
    sta bBitsMoveDirArray,x
    lda wBitsTimer+1
    sta bBitsTimerHArray,x
    lda wBitsTimer
    sta bBitsTimerLArray,x
    lda bBitsHit
    sta bBitsHitArray,x

    rts

//==============================================================================

bitsFlowUpdateState:

    lda bBitsHit               // Check if the sprite has been hit
    cmp #$01
    beq gLUSSpriteHit
    jmp gLUSFlowUpdateStateTimer

gLUSSpriteHit:
    ldy bBitsSprite                         // Load the array to check bits color
    dey                                     // Array is starting from 0, so -1 is required
    lda bBitsAssignedColorArray,y
    cmp #RED                                // Sprite hit, if RED display info
    bne gLUSResetSpriteEndPivot
    //
    // Call to the Interrupt Screen
    //
    jsr interruptMain
    jmp gLUSResetSpriteEnd

gLUSResetSpriteEndPivot:
    jmp gLUSResetSpriteEnd

gLUSFlowUpdateStateTimer:
    jsr bitsFlowUpdateStateTimer

    lda bBitsTimerIsZero       // If bBitsTimerIsZero = true, then zero flag = false
    bne gLUSWTimerIsZero       // If zero flag not set, jump to gLUSWTimerIsZero
    jmp gLUSWEnd
gLUSWTimerIsZero:

    // Update Sprites and check for position
    LIBSPRITE_ENABLE_AV(bBitsSprite,true)
    LIBSPRITE_SETPOSITION_AAA(bBitsSprite, wBitsX, bBitsY)
    lda bBitsMoveDir

    cmp #BitsMoveRight
    beq gLUSRight
    cmp #BitsMoveLeft
    beq gLUSLeft
    cmp #BitsMoveUp
    beq gLUSUp
    jmp gLUSDown

gLUSRight:
    LIBMATH_ADD16BIT_AVA(wBitsX, 1, wBitsX)
    LIBMATH_CMP16BIT_AVLLL(wBitsX, BitsMoveRightStop, gLUSWEnd, gLUSWEnd, gLUSResetSprite)
gLUSLeft:
    LIBMATH_SUB16BIT_AVA(wBitsX, 1, wBitsX)
    LIBMATH_CMP16BIT_AVLLL(wBitsX, BitsMoveLeftStop, gLUSResetSprite, gLUSWEnd, gLUSWEnd)
gLUSUp:
    dec bBitsY
    lda bBitsY
    cmp #BitsMoveUpStop
    bcs gLUSWEnd
    jmp gLUSResetSprite
gLUSDown:
    inc bBitsY
    lda bBitsY
    cmp #BitsMoveDownStop
    bcc gLUSWEnd
gLUSResetSprite:
    //
    // The bits reached the CPU, decide
    // what to do
    //
    ldy bBitsSprite                         // Load the array to check bits color
    dey                                     // Array is starting from 0, so -1 is required
    lda bBitsAssignedColorArray,y
    cmp #RED                                // if RED decrements lives
    bne gLUSResetSpriteEnd
    dec bExpLives
    jsr bitsDisplayLives                    // Update display HUD

gLUSResetSpriteEnd:
    LIBSPRITE_ENABLE_AV(bBitsSprite,false)
    jsr bitsFlowInitSingleSprite

gLUSWEnd:
    rts

//==============================================================================

bitsFlowUpdateStateTimer:

    lda #False
    sta bBitsTimerIsZero

    lda wBitsTimer+1
    bne gLUSTimerHighNotZero
    lda wBitsTimer
    beq gLUSTimerIsZero
gLUSTimerHighNotZero:
    // decrement the timer
    LIBMATH_SUB16BIT_AVA(wBitsTimer, 1, wBitsTimer)
    rts
gLUSTimerIsZero:
    lda #True
    sta bBitsTimerIsZero

    rts

//==============================================================================

bitsFlowInitSingleSprite:

    LIBMATH_GET_REALRAND_S_V(6)                  // Set a random sprite
    tay
    lda bBitsSpriteFrameArray,y
    sta bBitsSpriteFrame
    LIBSPRITE_SETFRAME_AA(bBitsSprite, bBitsSpriteFrame)
    LIBMATH_GET_REALRAND_S_V(3)                  // Set a random color
    tay
    lda bBitsSpriteColorArray,y
    sta bBitsSpriteColor

    sta bBitsAssignedColorArray,x

    LIBSPRITE_SETCOLOR_AA(bBitsSprite, bBitsSpriteColor)

    jsr bitsFlowGetVariables

    lda #$00
    sta bBitsHit                 // Reset the hit check

    // Set the MoveDir
    //lda bDifficultyLevel
    LIBMATH_GET_REALRAND_S_A(bDifficultyLevel)
    //lda #BitsMoveRight         // FIXME: used for debugging to force direction
    sta bBitsMoveDir

    cmp #BitsMoveRight
    beq gBIRight
    cmp #BitsMoveLeft
    beq gBILeft
    cmp #BitsMoveUp
    beq gBIUp
    jmp gBIDown

gBIRight:
    lda #<BitsMoveRightStart     // Low byte
    sta wBitsX
    lda #>BitsMoveRightStart     // High byte
    sta wBitsX+1
    LIBMATH_GET_REALRAND_S_V($53)    // Randomly place Y
    adc #$50
    sta bBitsY
    jmp gBIDirectionEnd

gBILeft:
    lda #<BitsMoveLeftStart     // Low byte
    sta wBitsX
    lda #>BitsMoveLeftStart     // High byte
    sta wBitsX+1
    LIBMATH_GET_REALRAND_S_V($53)   // Randomly place Y
    adc #$50
    sta bBitsY
    jmp gBIDirectionEnd

gBIUp:
    lda #BitsMoveUpStart
    sta bBitsY
    LIBMATH_GET_REALRAND_S_V($50)   // Randomly place X
    adc #$82
    sta wBitsX
    jmp gBIDirectionEnd

gBIDown:
    lda #BitsMoveDownStart
    sta bBitsY
    LIBMATH_GET_REALRAND_S_V($50)   // Randomly place X
    adc #$82
    sta wBitsX
    jmp gBIDirectionEnd

gBIDirectionEnd:
    // Get a random timerhigh wait time (0->5)
    LIBMATH_RAND_AAA(bMathRandoms2, bMathRandomCurrent2, wBitsTimer+1)
    // Get a random timerlow wait time (0->255)
    LIBMATH_RAND_AAA(bMathRandoms1, bMathRandomCurrent1, wBitsTimer)

    // Avoid overlapping sprites, checking difference between timers
    ldy #BitsSpriteMax
gBICheckTimerLoop:
    cpy #00                     // Check only from element 1 (0 is the first)
    beq gBICheckTimerEnd
    dey                         // Go to previous element
    lda bBitsTimerLArray,y      // Store element in temp
    sta wBitsTimerTemp
    lda bBitsTimerHArray,y
    sta wBitsTimerTemp+1

    LIBMATH_ABS_SUB16BIT_AAA(wBitsTimer, wBitsTimerTemp, wBitsTimerDiff)
                               // Compare numbers (unsigned)
    lda wBitsTimerDiff+1       // Load MSB of result
    cmp #>BitsTimerDistance    // Compare with min distance MSB
    bcc gBICheckTimerDelay     // If Carry Clear, --> result < target, recompute another random

    lda wBitsTimerDiff         // Load LSB of result
    cmp #<BitsTimerDistance    // Compare with min distance LSB
    bcc gBICheckTimerDelay     // If result LSB < target LSB, then result < target, recompute another random
    jmp gBICheckTimerLoop

gBICheckTimerDelay:
    LIBMATH_ADD16BIT_AVA(wBitsTimer,10,wBitsTimer)   // Add a value to dinstance sprites
    ldy #BitsSpriteMax
    jmp gBICheckTimerLoop

gBICheckTimerEnd:
    LIBSPRITE_ENABLE_AV(bBitsSprite,false)              // Make sprite invisible and set the initial position
    LIBSPRITE_SETPOSITION_AAA(bBitsSprite, wBitsX, bBitsY)

    jsr bitsFlowSetVariables

    rts

//==============================================================================

bitsDisplayLives:
    stx ZeroPage5          // Saves X/Y registers
    sty ZeroPage6
    LIBSCREEN_DRAW_N_CHAR_VVVA(4, 0, ClearExpLivesChar, bMaxNumberOfLives, BANK0_LOCATION)    // Clear lives
    LIBSCREEN_DRAW_N_CHAR_VVVA(4, 0, ExpLivesChar, bExpLives, BANK0_LOCATION)    // Display new lives
    ldx ZeroPage5          // Restore X/Y registers
    ldy ZeroPage6
    rts

//==============================================================================