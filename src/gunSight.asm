//==============================================================================
//                                  R.E.T.I.N.A.
//                                GunSight Sprite
//==============================================================================
// Includes

#import "lib/libIncludes.asm"
#import "gameData.asm"

//==============================================================================
// Constants

.const gsSpriteNum  = 0
.const gsStartFrame = 0
.const gsXStart     = 110
.const gsYStart     = 63
.const gsSpeed      = 5
.const gsAnimDelay  = 7
.const gsAnimIdle   = 0

// Constants for the RETINA CPU boundaries
.const gsLeftEdge      = 110
.const gsRightEdge     = 245
.const gsTopEdge       = 63
.const gsBottomEdge    = 185

.const  X_THRESHOLD   = 8              // Horizontal "closeness" for sprite collision
.const  Y_THRESHOLD   = 10             // Vertical "closeness" for sprite collision

//==============================================================================
// Paddle Tables
// These are pre-computed X,Y coordinates to place the sprite around the CPU.
// This takes 512 bytes

XTable:
// 1) TOP edge: 66 points, x=110..240
.for (var i=0; i<66; i++) {
    .byte 110 + 2*i
}

// 2) RIGHT edge: 62 points, x=240 constant
.for (var i=0; i<62; i++) {
    .byte 245
}

// 3) BOTTOM edge: 66 points, x=240..110 (step -2)
.for (var i=0; i<66; i++) {
    .byte 245 - 2*i
}

// 4) LEFT edge: 62 points, x=110 constant
.for (var i=0; i<62; i++) {
    .byte 110
}

YTable:
// 1) TOP edge: 66 points, y=63 constant
.for (var i=0; i<66; i++) {
    .byte 63
}

// 2) RIGHT edge: 62 points, y=63..185
.for (var i=0; i<62; i++) {
    .byte 63 + 2*i
}

// 3) BOTTOM edge: 66 points, y=185 constant
.for (var i=0; i<66; i++) {
    .byte 185
}

// 4) LEFT edge: 62 points, y=185..63
.for (var i=0; i<62; i++) {
    .byte 185 - 2*i
}

//==============================================================================
// Variables

bgsSprite:      .byte 0
wgsX:           .word gsXStart
bgsY:           .byte gsYStart
bgsAnim:        .byte gsAnimIdle

bSpriteSide:    .byte 0   // which side of the square is the gun sight on
                          //   0 = top edge
                          //   1 = right edge
                          //   2 = bottom edge
                          //   3 = left edge

bCollisionIndex:   .byte   0     // Index of the collided sprite or $FF
bTmpXL:            .byte   0     // Temporary storage for sprite X low
bTmpXH:            .byte   0     // Temporary storage for sprite X high
bTmpY:             .byte   0     // Temporary storage for sprite Y
bDiffY:            .byte   0
bDiffXLo:          .byte   0
bDiffXHi:          .byte   0

//==============================================================================
// Subroutines

gunSightInit:
    LIBSPRITE_ENABLE_AV(bgsSprite,true)                // Enable the sprite
    // Set sprite animation frame, position, and color
    LIBSPRITE_SETFRAME_AV(bgsSprite, gsStartFrame)
    LIBSPRITE_SETPOSITION_AAA(bgsSprite, wgsX, bgsY)
    LIBSPRITE_SETCOLOR_AV(bgsSprite, LIGHT_GRAY)

    LIBSPRITE_PLAYANIM_AVVVV(bgsSprite, 0, 1, 25, true)

    lda bUsePaddle                              // Check if using paddle or joystick    
    cmp #$01
    beq gISetPaddle

    lda #<gunSightUpdatePositionJoystick        // Set Joystick
    sta ZeroPage14
    lda #>gunSightUpdatePositionJoystick
    sta ZeroPage15
    jmp gIEnd

gISetPaddle:
    lda #<gunSightUpdatePositionPaddle         // Set Paddle
    sta ZeroPage14
    lda #>gunSightUpdatePositionPaddle
    sta ZeroPage15
gIEnd:    
    rts

//==============================================================================

gunSightUpdate:
    jmp (ZeroPage14)                         // Jump to the proper control routine
                                             // gunSightUpdatePosition<device>

gUPExitFromControl:

    // DEBUG INFO
    //LIBSCREEN_DEBUG16BIT_VVA(0, 1, wgsX) // Print coordinates
    //LIBSCREEN_DEBUG8BIT_VVA(2, 2, bgsY)
    //LIBSCREEN_DEBUG8BIT_VVA(0, 1, bPaddleX) // Print paddle
    //LIBSCREEN_DEBUG8BIT_VVA(2, 2, bPaddleXBtn)
    rts

//==============================================================================

gunSightUpdatePositionJoystick:
    LIBINPUT_GET_V(GameportLeftMask) // Check left
    bne gPUPJRight // If left not pressed, skip to right check
    jsr MoveCounterClockwise

gPUPJRight:
    LIBINPUT_GET_V(GameportRightMask) // Check right
    bne gPUPJEndmove // If right not pressed, skip to up check
    jsr MoveClockwise
      
gPUPJEndmove:
    // clamp the player x position
    LIBMATH_MIN16BIT_AV(wgsX, gsRightEdge)
    LIBMATH_MAX16BIT_AV(wgsX, gsLeftEdge)

    // clamp the player y position
    LIBMATH_MIN8BIT_AV(bgsY, gsBottomEdge)
    LIBMATH_MAX8BIT_AV(bgsY, gsTopEdge)

    // Set the player's sprite position
    LIBSPRITE_SETPOSITION_AAA(bgsSprite, wgsX, bgsY)

    // Check fire button
    LIBINPUT_GET_V(GameportFireMask)         // Check if fire is pressed
    bne gPUPJNoFire
    lda SPSPCL                               // Load Sprite collision reg
    and #%11111110                           // Mask out bit 0 (sprite 0, gunSight)
    beq gPUPJNoFire
    jsr gunSightSpriteHit                    // Got the bits!!

gPUPJNoFire:
    jmp gUPExitFromControl

//==============================================================================

gunSightUpdatePositionPaddle:
    lda bPaddleX
    sta bPaddleXPrev                    // Store previous read for stabilizing
    LIBINPUT_GET_PADDLE_X_AA(bPaddleX, bPaddleXBtn)
    lda bPaddleXPrev
    sec
    sbc bPaddleX
    bcs gPUPPositive
    eor #$FF                           // two's complement to get ABS
    adc #1

gPUPPositive:
    cmp #3                             // If differrence <2 no update
    bcc gPUPNoUpd
    jmp gPUPUpd

gPUPNoUpd:
    lda bPaddleXPrev                   // Restore previous read
    sta bPaddleX

gPUPUpd:
    lda bPaddleX
    tax

    lda XTable,x
    sta wgsX               // We don't need to update the high byte, always 0 in our case
    lda YTable,x
    sta bgsY    

    // Set the player's sprite position
    LIBSPRITE_SETPOSITION_AAA(bgsSprite, wgsX, bgsY)

    // Check fire button
    lda bPaddleXBtn
    and #%00000100
    beq gPUPPFire
    jmp gPUPPNoFire

gPUPPFire:
    lda SPSPCL                               // Load Sprite collision reg
    and #%11111110                           // Mask out bit 0 (sprite 0, gunSight)
    beq gPUPPNoFire
    jsr gunSightSpriteHit                    // Got the bits!!

gPUPPNoFire:
    jmp gUPExitFromControl

//==============================================================================

MoveClockwise:
    lda bSpriteSide
    cmp #0
    beq MoveTopEdgeClockwise
    cmp #1
    beq MoveRightEdgeClockwise
    cmp #2
    beq MoveBottomEdgeClockwise
    cmp #3
    beq MoveLeftEdgeClockwise
    rts

MoveTopEdgeClockwise:
    // If sprite is on the TOP edge
    // Increase X until we hit RightEdge
    LIBMATH_ADD16BIT_AVA(wgsX, gsSpeed, wgsX)
    LIBMATH_CMP16BIT_AVLLL(wgsX, gsRightEdge, doneTopCw, changeTopToRight, changeTopToRight)
changeTopToRight:
    // we are exactly at the corner, switch side to 'right edge'
    lda #1                  // 1 = right edge
    sta bSpriteSide
doneTopCw:
    rts

MoveRightEdgeClockwise:
    // If sprite is on the RIGHT edge
    // Increase Y until we hit BottomEdge
    LIBMATH_ADD8BIT_AVA(bgsY, gsSpeed, bgsY) 
    lda bgsY
    cmp #gsBottomEdge
    bcc doneRightCw
    // Reached bottom-right corner, switch side
    lda #2                  // 2 = bottom edge
    sta bSpriteSide
doneRightCw:
    rts

MoveBottomEdgeClockwise:
    // If sprite is on the BOTTOM edge
    // Decrease X until we hit LeftEdge
    LIBMATH_SUB16BIT_AVA(wgsX, gsSpeed, wgsX)
    LIBMATH_CMP16BIT_AVLLL(wgsX, gsLeftEdge, changeBottomToLeft, changeBottomToLeft, doneBottomCw)
changeBottomToLeft:
    // Reached bottom-left corner
    lda #3                  // 3 = left edge
    sta bSpriteSide
doneBottomCw:
    rts

MoveLeftEdgeClockwise:
    // If sprite is on the LEFT edg
    // Decrease Y until we hit TopEdge
    LIBMATH_SUB8BIT_AVA(bgsY, gsSpeed, bgsY) 
    lda bgsY
    cmp #gsTopEdge
    bcs doneLeftCw
    // Reached top-left corner
    lda #0                  // 0 = top edge
    sta bSpriteSide
doneLeftCw:
    rts

//==============================================================================

MoveCounterClockwise:
    lda bSpriteSide
    cmp #0
    beq MoveTopEdgeCCw
    cmp #1
    beq MoveRightEdgeCCw
    cmp #2
    beq MoveBottomEdgeCCw
    cmp #3
    beq MoveLeftEdgeCCw
    rts

MoveTopEdgeCCw:
    // Top edge (move left if going CCW)
    LIBMATH_SUB16BIT_AVA(wgsX, gsSpeed, wgsX)
    LIBMATH_CMP16BIT_AVLLL(wgsX, gsLeftEdge, changeTopToLeft, changeTopToLeft, doneTopCcw)
changeTopToLeft:
    // If we've reached top-left corner, change side
    lda #3                      // 3 = left edge
    sta bSpriteSide
doneTopCcw:
    rts

MoveRightEdgeCCw:
    // Right edge (move up CCW)
    LIBMATH_SUB8BIT_AVA(bgsY, gsSpeed, bgsY) 
    lda bgsY
    cmp #gsTopEdge
    bcs doneRightCcw
    // Reached top-right corner
    lda #0                      // 0 = top edge
    sta bSpriteSide
doneRightCcw:
    rts

MoveBottomEdgeCCw:
    // Bottom edge (move right CCW)
    LIBMATH_ADD16BIT_AVA(wgsX, gsSpeed, wgsX)
    LIBMATH_CMP16BIT_AVLLL(wgsX, gsRightEdge, doneBottomCcw, moveBottomToRight, moveBottomToRight)
moveBottomToRight:
    // bottom-right corner
    lda #1                      // 1 = right edge
    sta bSpriteSide
doneBottomCcw:
    rts

MoveLeftEdgeCCw:
    // Left edge (move down CCW)
    LIBMATH_ADD8BIT_AVA(bgsY, gsSpeed, bgsY) 
    lda bgsY
    cmp #gsBottomEdge
    bcc doneLeftCcw
    // bottom-left corner
    lda #2                      // 2 = bottom edge
    sta bSpriteSide
doneLeftCcw:
    rts

//==============================================================================

gunSightSpriteHit:
    pha                       // PUSH accumulator
    stx bSaveX
    sty bSaveY

    lda #$FF                  // Default "no collision found"
    sta bCollisionIndex

    ldy #0                    // Y will be our loop counter: 0..BitsSpriteMax-1

gSSHLoopCheck:
    lda wBitsXLArray, y       // Load Sprite position
    sta bTmpXL
    lda wBitsXHArray, y
    sta bTmpXH
    lda bBitsYArray, y
    sta bTmpY

    // Compute 16‐bit absolute difference in X:
    // diffX = | wgsX - spriteX |
    lda wgsX             // gunSight X low
    sec
    sbc bTmpXL
    sta bDiffXLo
    lda wgsX+1           // gunSight X high
    sbc bTmpXH
    sta bDiffXHi

    bpl gSSHSkipNegX        // If diffXHi bit7=0, it’s already positive
    
    lda bDiffXLo            // 2's complement if negative (make it absolute)
    eor #$FF
    clc
    adc #1
    sta bDiffXLo

    lda bDiffXHi
    eor #$FF
    adc #0
    sta bDiffXHi
gSSHSkipNegX:
    // Check if X difference < X_THRESHOLD
    // (If diffXHi != 0, difference >= 256, so definitely >= threshold)
    lda bDiffXHi
    bne gSSHNoCollision
    lda bDiffXLo
    cmp #X_THRESHOLD
    bcs gSSHNoCollision

    // Compute 8‐bit absolute difference in Y:
    // diffY = | bgsY - spriteY |
    lda bgsY
    sec
    sbc bTmpY
    sta bDiffY

    bpl gSSHKkipNegY
    lda bDiffY            // if negative, 2’s complement
    eor #$FF
    clc
    adc #1
    sta bDiffY

gSSHKkipNegY:
    lda bDiffY
    cmp #Y_THRESHOLD        // Check if Y difference < Y_THRESHOLD
    bcs gSSHNoCollision

    // If we get here, a collision was detected
    lda #$01
    sta bBitsHitArray, y    // Set the sprite as hit
    iny                     // The sprite number is Y + 1
    tya                     // Transfer Y to accumulator
    sta bCollisionIndex     // Also put that index in A for final return
    jmp gSSHDone

gSSHNoCollision:
    iny
    cpy #BitsSpriteMax
    bne gSSHLoopCheck

gSSHDone:
    ldx bSaveX
    ldy bSaveY
    pla                                 // POP accumulator
    
    rts

//==============================================================================