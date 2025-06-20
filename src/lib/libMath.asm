//==============================================================================
//                        RetroGameDev Library C64 v2.02
//==============================================================================
// Includes

#importonce
#import "libDefines.asm"

//==============================================================================
// Constants

.const MathRandomMax = 64

//==============================================================================
// Variables

// Random numbers 0->255
bMathRandoms1:  .byte  39, 58, 89,239,  3,238,218,114
                .byte  79,152, 49, 93,152, 33,230,179
                .byte 146,192,221,109,241,197, 67, 98
                .byte 166,126, 55, 21, 71,248, 76,126
                .byte 115,166,225,127,162, 37,144, 35
                .byte 237, 73, 61,131,124, 39, 32, 19
                .byte 230,191,195, 92, 49, 47,116,222
                .byte 167, 93,190, 42, 54, 80, 62,113 

bMathRandomCurrent1: .byte 0

// Random numbers 0->5
bMathRandoms2:  .byte   5,  1,  2,  0,  3,  0,  1,  2
                .byte   1,  1,  3,  2,  1,  5,  4,  3
                .byte   2,  4,  4,  0,  3,  5,  3,  1
                .byte   3,  2,  4,  0,  5,  0,  3,  3
                .byte   2,  3,  2,  3,  3,  2,  5,  4
                .byte   0,  4,  0,  3,  2,  5,  1,  1
                .byte   4,  5,  1,  1,  0,  1,  2,  0
                .byte   2,  1,  2,  4,  2,  1,  5,  3

bMathRandomCurrent2: .byte 0

//==============================================================================
// Macros

// http://www.6502.org/source/integers/hex2dec-more.htm
.macro LIBMATH_8BITTOBCD_AA(bIn, wOut)
{
    ldy bIn
    sty ZeroPage13  // Store in a temporary variable
    sed 		    // Switch to decimal mode
	lda #0          // Ensure the result is clear
	sta wOut
	sta wOut+1
	ldx #8		    // The number of source bits
cnvBit:
    asl ZeroPage13	// Shift out one bit
	lda wOut        // And add into result
	adc wOut
	sta wOut
	lda wOut+1	    // propagating any carry
	adc wOut+1
	sta wOut+1
	dex		        // And repeat for next bit
	bne cnvBit
	cld		        // Back to binary
}

//==============================================================================

// http://www.6502.org/source/integers/hex2dec-more.htm
.macro LIBMATH_16BITTOBCD_AAA(wIn, wOut, bOut)
{
    ldy wIn         // Save
    lda wIn+1
    sta ZeroPage1
    sed		        // Switch to decimal mode
	lda #0		    // Ensure the result is clear
	sta wOut
	sta wOut+1
	sta bOut
	ldx #16		    // The number of source bits
cnvBit:
    asl wIn	        // Shift out one bit
	rol wIn+1
	lda wOut	    // And add into result
	adc wOut
	sta wOut
	lda wOut+1	    // propagating any carry
	adc wOut+1
	sta wOut+1
	lda bOut	    // ... thru whole result
	adc bOut
	sta bOut
	dex		        // And repeat for next bit
	bne cnvBit
	cld		        // Back to binary
    sty wIn         // Restore
    lda ZeroPage1
    sta wIn+1
}

//==============================================================================

.macro LIBMATH_ADD8BIT_AAA(bNum1, bNum2, bSum)
{
    clc             // Clear carry before add
    lda bNum1       // Get first number
    adc bNum2       // Add to second number
    sta bSum        // Store in bSum
}

//=============================================================================

.macro LIBMATH_ADD8BIT_AVA(bNum1, bNum2, bSum)
{
    clc             // Clear carry before add
    lda bNum1       // Get first number
    adc #bNum2      // Add to second number
    sta bSum        // Store in sum
}

//==============================================================================         

.macro LIBMATH_ADD16BIT_AVA(wNum1, wNum2, wSum)
{
    clc             // Clear carry before first add
    lda wNum1       // Get LSB of first number
    adc #<wNum2     // Add LSB of second number
    sta wSum        // Store in LSB of bSum
    lda wNum1+1     // Get MSB of first number
    adc #>wNum2     // Add carry and MSB of NUM2
    sta wSum+1      // Store bSum in MSB of sum
}

//==============================================================================

.macro LIBMATH_GREATEREQUAL8BIT_AA(bNum1, bNum2)
{
    lda bNum1       // Load Number 1
    cmp bNum2       // Compare with Number 2
} // Test with bcc on return

//==============================================================================

.macro LIBMATH_MAX8BIT_AV(bNum1, bNum2)
{
    lda #bNum2      // Load Number 2
    cmp bNum1       // Compare with Number 1
    bcc skip        // If Number 2 < Number 1 then skip
    sta bNum1       // Else replace Number1 with Number2
skip:
}

//==============================================================================

// Adapted from https://codebase64.org/doku.php?id=base:16-bit_comparison
.macro LIBMATH_MAX16BIT_AV(wNum1, wNum2)
{
    lda wNum1+1     // high bytes
    cmp #>wNum2
    bcc LsThan      // hiVal1 < hiVal2 --> Val1 < Val2
    bne GrtEqu      // hiVal1 ≠ hiVal2 --> Val1 > Val2
    lda wNum1       // low bytes
    cmp #<wNum2
    bcs GrtEqu      // loVal1 ≥ loVal2 --> Val1 ≥ Val2
LsThan:
    lda #>wNum2     // replace wNum1 with wNum2
    sta wNum1+1
    lda #<wNum2
    sta wNum1
GrtEqu:
}

//==============================================================================

.macro LIBMATH_MIN8BIT_AV(bNum1, bNum2)
{
    lda #bNum2      // Load Number 2
    cmp bNum1       // Compare with Number 1
    bcs skip        // If Number 2 >= Number 1 then skip
    sta bNum1       // Else replace Number1 with Number2
skip:
}

//==============================================================================

// Adapted from https://codebase64.org/doku.php?id=base:16-bit_comparison
.macro LIBMATH_MIN16BIT_AV(wNum1, wNum2)
{
    lda wNum1+1     // high bytes
    cmp #>wNum2
    bcc LsThan      // hiVal1 < hiVal2 --> Val1 < Val2
    bne GrtEqu      // hiVal1 ≠ hiVal2 --> Val1 > Val2
    lda wNum1       // low bytes
    cmp #<wNum2
    bcs GrtEqu      // loVal1 ≥ loVal2 --> Val1 ≥ Val2
LsThan:
    jmp End         // end
GrtEqu:
    lda #>wNum2     // replace wNum1 with wNum2
    sta wNum1+1
    lda #<wNum2
    sta wNum1
End:
}

//==============================================================================

.macro LIBMATH_RAND_AAA(bArray, bCurrent, bOut)
{
    ldy bCurrent    // Load the array index into Y
    lda bArray,y    // Get the value at index into A
    sta bOut        // Store A into bOut
    inc bCurrent    // Increment the array index
    
    // if bCurrent == MathRandomMax, reset to 0
    lda bCurrent    
    cmp #MathRandomMax  
    bne end
    lda #0
    sta bCurrent
end:    
}

//==============================================================================

.macro LIBMATH_GET_REALRAND_S_A(bMaxVal)
{
    // Returns in A a random value of MAX bMaxVal (0=255)
    lda bMaxVal
    sta ZeroPage1
    jsr libMathGetRealRand
}

.macro LIBMATH_GET_REALRAND_S_V(bMaxVal)
{
    // Returns in A a random value of MAX bMaxVal (0=255)
    lda #bMaxVal
    sta ZeroPage1
    jsr libMathGetRealRand
}
libMathGetRealRand:

    beq  fullRange          // if bMaxVal == 0 go directly in getting

    // Read low byte of timer, XOR with high byte for "scrambling."
    lda     TIMALO
    eor     TIMAHI           // A = seed
randLoop:
    // Repeated-subtraction loop to get (seed mod max)
    // Not very good for low numbers, may be to be fixed (FIXME)
    cmp     ZeroPage1
    bcc     done            // If A < X, remainder is A
    sec
    sbc     ZeroPage1       // A = A - X
    bcs     randLoop        // Loop until A < X
done:
    rts

fullRange:
    lda     TIMALO
    eor     TIMAHI           // A = seed
    rts

//==============================================================================

.macro LIBMATH_RANDSEED_AA(bCurrent, bSeed)
{ 
    lda bSeed               // Load seed value into A
    and #MathRandomMax-1    // Wrap around MathRandomMax
    sta bCurrent            // Store A into bCurrent
}

//==============================================================================

.macro LIBMATH_SUB8BIT_AAA(bNum1, bNum2, bSum)
{
    sec             // sec is the same as clear borrow
    lda bNum1       // Get first number
    sbc bNum2       // Subtract second number
    sta bSum        // Store in sum
}

//============================================================================== 

.macro LIBMATH_SUB8BIT_AVA(bNum1, bNum2, bSum)
{
    sec             // sec is the same as clear borrow
    lda bNum1       // Get first number
    sbc #bNum2      // Subtract second number
    sta bSum        // Store in sum
}

//==============================================================================        

.macro LIBMATH_SUB16BIT_AVA(wNum1, wNum2, wSum)
{
    sec             // sec is the same as clear borrow
    lda wNum1       // Get LSB of first number
    sbc #<wNum2     // Subtract LSB of second number
    sta wSum        // Store in LSB of bSum
    lda wNum1+1     // Get MSB of first number
    sbc #>wNum2     // Subtract borrow and MSB of NUM2
    sta wSum+1      // Store bSum in MSB of bSum
}

//==============================================================================

.macro LIBMATH_SUB16BIT_AAA(wNum1, wNum2, wSum)
{
    sec             // Set the carry flag (indicates no borrow initially)
    lda wNum1       // Load LSB of the first
    sbc wNum2       // Subtract LSB of the second
    sta wSum        // Store the result’s LSB
    lda wNum1+1     // Load MSB of the first number
    sbc wNum2+1     // Subtract MSB of the second number (with borrow)
    sta wSum+1      // Store the result’s MSB
}

//==============================================================================

.macro LIBMATH_ABS_SUB16BIT_AAA(wNum1, wNum2, wDiff)
{
                    // Subtract: wNum1 - wNum2
    sec             // Set carry: no borrow initially
    lda wNum1       // Load LSB of first number
    sbc wNum2       // Subtract LSB of second number
    sta wDiff       // Save LSB of result
    lda wNum1+1     // Load MSB of first number
    sbc wNum2+1     // Subtract MSB (with borrow)
    sta wDiff+1     // Store MSB of result

    // If no borrow occurred, the result was positive (or zero).
    // If a borrow occurred (carry clear), the result is negative.
    bcs _done       // Branch if carry set (result is positive)

    // Otherwise, take the two's complement of the 16-bit
    // result to get its absolute value
    lda wDiff
    eor #$FF
    sta wDiff
    lda wDiff+1
    eor #$FF
    sta wDiff+1
    clc            // Clear carry for addition of 1
    lda wDiff
    adc #$01
    sta wDiff
    lda wDiff+1
    adc #$00
    sta wDiff+1

_done:
    // Now wDiff holds the absolute difference.
}

//==============================================================================

.macro LIBMATH_CMP16BIT_AVLLL(wNum1, wconstValue, labelLess, labelEqual, labelGreater) {
    // Compare high bytes first
    lda wNum1+1
    cmp #>wconstValue    // #> takes the high byte of constValue
    bcc labelLess        // if memLabel+1 < high(constValue) => less
    bne labelGreater     // if memLabel+1 > high(constValue) => greater

    // If high bytes are equal, compare low bytes
    lda wNum1
    cmp #<wconstValue    // #< takes the low byte of constValue
    bcc labelLess        // if memLabel < low(constValue) => less
    beq labelEqual       // if memLabel == low(constValue) => equal
    bcs labelGreater     // if memLabel > low(constValue) => greater
}