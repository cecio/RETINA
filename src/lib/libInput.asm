//==============================================================================
//                        RetroGameDev Library C64 v2.02
//==============================================================================
//Includes

#importonce
#import "libDefines.asm"

//==============================================================================
// Constants

// Port Masks
.label GameportUpMask       = %00000001
.label GameportDownMask     = %00000010
.label GameportLeftMask     = %00000100
.label GameportRightMask    = %00001000
.label GameportFireMask     = %00010000

//==============================================================================
// Variables

oldCIDDRA:    .byte   0
oldCIAPRA:    .byte   0
storeY:       .byte   0

//==============================================================================
// Macros

.macro LIBINPUT_GET_V(bPortMask)
{
    lda CIAPRA      // Load joystick 2 state to A
    and #bPortMask  // Mask out direction/fire required
} // Test with bne immediately after the call

//==============================================================================

.macro LIBINPUT_WAIT_FOR_FIRE_RELEASE()
{
_waitForFireRelease:
    lda CIAPRA               // Load joystick 2 state to A
    and #GameportFireMask
    beq _waitForFireRelease  // Loop until fire is no longer pressed
}

//==============================================================================

.macro LIBINPUT_GET_PADDLE_X_AA(bPaddleX, bButtonX)
{
    pha
    sty storeY

    sei
    lda CIDDRA              // Get current value and save it
    sta oldCIDDRA
    lda CIAPRA              // FIXME: may be we can remove this if joystick is disabled
    sta oldCIAPRA

	lda #$c0
	sta CIDDRA              // Set porta A for input

	lda #$80
	sta CIAPRA              // Address 1st pair of paddle
	ldy #$80
loopDelay:
    nop
    dey
    bpl loopDelay           // Wait a while

    lda $d419               // Get X value
    sta bPaddleX

    lda CIAPRA             // Time to read fire button
    ora #$80
    sta bButtonX           // Bit 2 is Paddle X, bit 3 Paddle Y

    lda oldCIDDRA          // Restore saved value
    sta CIDDRA
    lda oldCIAPRA          // FIXME: may be we can remove this if joystick is disabled
    sta CIAPRA

    cli

    ldy storeY
    pla
}

//==============================================================================

.macro LIBINPUT_J_PRESSED()
{
    clc              // Clear carry
    lda #$EF         // row 4 = 0, other rows = 1 (J)
    sta CIAPRA
    lda CIAPRB
    and #%00000100   // test bit 2
    bne noKeyJ       // no carry
    sec              // C=1 => key pressed
noKeyJ:
}

//==============================================================================

.macro LIBINPUT_P_PRESSED()
{
    clc              // Clear carry
    lda #$DF         // row 5 = 0, other rows = 1 (P)
    sta CIAPRA
    lda CIAPRB
    and #%00000010   // test bit 1
    bne noKeyP       // no carry
    sec              // C=1 => key pressed
noKeyP:
}

//==============================================================================

.macro LIBINPUT_H_PRESSED()
{
    clc               // Clear carry
    lda #$F7          // row=3 => bit5=0
    sta CIAPRA
    lda CIAPRB
    and #%00100000    // test bit5
    bne noKeyH        // if not zero => bit4=1 => no key
    sec               // C = 1 => key pressed
noKeyH:
}

//==============================================================================

.macro LIBINPUT_E_PRESSED()
{
    clc              // Clear carry
    lda #$FD         // row 1 = 0, other rows = 6 (E)
    sta CIAPRA
    lda CIAPRB
    and #%01000000   // test bit 6
    bne noKeyE       // if bit set -> no key
    sec              // C = 1 => key pressed
noKeyE:
}

//==============================================================================

.macro LIBINPUT_SPACE_PRESSED()
{
    clc              // Clear carry
    lda #$7F         // row 7 = 0, other rows = 1 (space)
    sta CIAPRA
    lda CIAPRB
    and #%00010000   // test bit 4
    bne noKeySpace   // no carry
    sec              // C=1 => key pressed
noKeySpace:
}

//==============================================================================