// ----------------------------------------------------------------------------
// Copyright 1982-1984,2019 by T.Zoerner (tomzo at users.sf.net)
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ----------------------------------------------------------------------------

_load_base = $1200  // start of BASIC RAM
_game_base = $1400  // start of ML

        // P00 header: used by loader to determine destination address; not copied into RAM
        .word _load_base

        // Following code is copied into RAM; align PC "*" with that base
        * = _load_base

        // Single-line BASIC program: "SYS5120"
        .byt $00,$0b,$12,$0a,$00,$9e,$35,$31,$32,$30

        // Fill space until start of ML program
        .dsb _game_base-*, 0
        .text

// ----------------------------------------------------------------------------
// Description of data in ZP
//
// $00-$01: 16-bit address of enemy figure on screen
// $02-$03: 16-bit address of player figure on screen
// $04:     0:moving to the right; !0: to the left
// $05:     screen column of player projectile
// $06-$07  16-bit address of player projectile on screen
// $08:     screen column of enemy projectile
// $09-$0a  16-bit address of enemy projectile on screen
// $0b:     screen column of enemy
// $0c:     screen column of player

#define MEM_EXTENSION
#ifdef MEM_EXTENSION
#define ADR_SCREEN $1000        /* screen buffer base address with >= 8kB extension */
#else
#define ADR_SCREEN $1e00        /* screen buffer base address without extension */
#endif

// ----------------------------------------------------------------------------
// Game entry point
// - must be mapped to fixed address so that BSIC can jump to it
//
	lda #$40        // initialize game speed factor
	sta l14dd
	nop
// ----------------------------------------------------------------------------
// Initialization
//
l138e	jsr $e518       // call ROM function E518: system initialization
	lda #$08        // bit 4-7: background=black; 3:non-reverse mode; 0-2: border=black
	sta $900f       // set colors in VIC ($900F)
	lda #<ADR_SCREEN+$15
	sta $00
	lda #>ADR_SCREEN+$15  // MSB of screen address
	sta $01
	sta $03
	ldy #$00
	sty $02
//                      // ----- draw borders on screen on all sides -----
	ldx #$00
l13a6	lda #$66        // "block" character code: border character
	sta ADR_SCREEN+0,x      // write into top row on screen
	sta ADR_SCREEN+22*22,x  // write into bottom row on screen
	inx
	nop
	sta ($00),y     // write left border
	sta ($02),y     // write right border
	sty $04
l13b6	inc $00         // increment pointer to left border (16-bit)
	bne l13bc
	inc $01
l13bc	inc $02         // increment pointer to right border (16-bit)
	bne l13c2
	inc $03
l13c2	inc $04
	lda $04
	cmp #$16
	bcc l13b6
	cpx #$16        // loop until row complete (22 characters wide)
	bcc l13a6
//                      // ----- initialize enemy and player status -----
	sty $04
	sty $05
	sty $08
	lda #<ADR_SCREEN+1*22+1  // enemy start position (1st column of 1st row within borders)
	sta $00
	lda #>ADR_SCREEN+1*22+1
	sta $01
	lda #<ADR_SCREEN+21*22+11  // player start position: middle of bottom row
	sta $02
	lda #$01
	sta $0b
	lda #$0b
	sta $0c
	lda #$51        // draw player figure at initial position
	sta ($02),y
//                      // ----- wait for the player to start the game -----
l13ec	lda $cb         // poll for key-press
	cmp #$40        // any key pressed?
	bcc l13fc       // yes -> start game
l13f2	lda $911f       // poll joystick port
	nop
	and #$08        // extract bit paddle/fire
	cmp #$08        // paddle moved?
	beq l13ec       // no -> keep waiting; else start game
//                      // yes -> fall-through into main loop
// ----------------------------------------------------------------------------
// main loop: event dispatcher
//
//                      // ----- check for keyboard input -----
l13fc	lda $cb         // poll for key-press
	cmp #$11        // key 'a'
	bne l1405
l1402	jsr l151c
l1405	cmp #$29        // key 's'
	bne l140c
l1409	jsr l1504
//l140c	cmp #$27        // key F1: fire new projectile
l140c	cmp #$20        // space key: fire new projectile (F1 is not mapped well in VICE)
	bne l1424
l1410	lda $05
	cmp #$00
	bne l142a       // skip if player projectile already moving
//                      // initialize status of player projectile
l1416	lda $02
	sta $06
	lda $03
	sta $07
	sta $05
	jsr l1564
	nop
l1424	lda $05         // player projectile in the air?
	cmp #$00
	beq l142e       // skip if not in the air
l142a	jsr l1560
	nop
//                      // ----- handle enemy projectile -----
l142e	lda $08
	cmp #$00        // enemy projectile in the air?
	bne l144e       // skip if enemy projectile already in the air
l1434	lda $0b         // compare enemy with player column
	cmp $0c
	bne l1452       // skip if enemy is not above player figure
//                      // fire new enemy projectile: initialize projectile status
l143a	lda $00
	sta $09
	lda $01
	sta $0a
	sta $08
	jsr l153c
	nop
	lda $08
	cmp #$00        // enemy projectile in the air?
	beq l1452
l144e	jsr l1538       // yes -> handle projectie motion
	nop
//                      // ----- check for joystick input -----
l1452	lda #$7f        // configure VIA-B register: allow for polling joystick
	sta $9122
	lda $9120       // poll joystick status
	and #$80
	cmp #$80        // joystick pointing "east"?
	beq l1464
l1460	jsr l1504
	nop
l1464	lda #$ff
	sta $9122
	lda $05
	cmp #$00
	bne l1479       // skip if player projectile already in the air
l146f	lda $911f
	and #$20
	cmp #$20        // joystick fire button pressed?
	bne l1416
l1478	nop
l1479	lda $911f
	and #$10
	cmp #$10        // joystick pointing "west"?
	beq l1486
l1482	jsr l151c
	nop
l1486	lda $04         // get current direction of enemy movement
	cmp #$00        
	bne l14ae
//                      // ----- enemy moving to the right -----
l148c	lda #$20        // clear enemy figure at old position: print SPACE character
	sta ($00),y
l1490	inc $00         // update enemy position +1: to the right
	bne l1496
	inc $01
l1496	inc $0b
	lda ($00),y
	cmp #$66        // hit the screen border?
	beq l14a6       // yes -> reverse direction (to left-wards)
	lda #$5a        // draw enemy figure at new position
	sta ($00),y
	clc
	nop
	bcc _delay
l14a6	sta $04         // invert direction indicator
	jsr l14f4       // add 22 to enemy address
	clc
	bcc l14b2       // and move figure by one to the left
//
//                      // ----- enemy moving to the left -----
l14ae	lda #$20        // clear enemy figure at old position: print SPACE character
	sta ($00),y
l14b2	dec $00         // update enemy position -1: to the left
	lda $00
	cmp #$ff
	bne l14bc
	dec $01
l14bc	dec $0b
	lda ($00),y
	cmp #$66        // hit the screen border?
	beq l14cc       // yes -> reverse direction (to right-wards)
	lda #$5a        // draw enemy figure at new position
	sta ($00),y
	clc
	nop
	bcc _delay
l14cc	sty $04         // invert direction indicator
	jsr l14f4       // add 22 to enemy address
	clc
	bcc l1490       // and move figure by one to the right
//                      // ----- delay loop -----
_delay	ldx #$00
l14d6	inx
	cpx #$7f        // inner delay loop: 127 cycles
	bcc l14d6
	iny
	l14dd = * + 1   // game speed is modified by code
	cpy #$30        // outer delay loop: WARNING: self-modified code! ($14dd)
	bcc _delay
//                      //
	ldy #$00        // reset Y register (for use in indirect 16-bit access)
//                      //
//                      // ----- check if enemy reached end of last row (above player) -----
	lda $00         // LSB of enemy address
	cmp #<ADR_SCREEN+19*22+20  // compare LSB
	bcc l14f0
	lda $01         // compare MSB of enemy address
	cmp #>ADR_SCREEN+19*22+20
	bcc l14f0
l14ee	rts             // hard & ugly exit of game (screen is not cleared)
	nop             // never reached (instead "READY" for BASIC)
l14f0	jmp l13fc       // back to start of main loop (infinite loop)
	nop
// ----------------------------------------------------------------------------
// sub-function: add 22 to enemy address
//
l14f4	ldx #$00        // loop for adding 22 to enemy address
l14f6	inc $00
	bne l14fc
	inc $01
l14fc	inx
	nop
	cpx #$16        // loop 22 times
	bcc l14f6
	rts
	nop
// ----------------------------------------------------------------------------
// Sub-function: Handle player key 's'
//
l1504	lda #$20
	sta ($02),y
l1508	inc $02
	bne l150e
l150c	inc $03
l150e	inc $0c
	lda ($02),y
	cmp #$66        // hit the screen border?
	beq l1520
l1516	lda #$51
	sta ($02),y
	rts
	nop
// ----------------------------------------------------------------------------
// Sub-function: Handle player key 'a'
//
l151c	lda #$20
	sta ($02),y
l1520	dec $02
	lda $02
	cmp #$ff
	bne l152a
l1528	dec $03
l152a	dec $0c
	lda ($02),y
	cmp #$66        // hit the screen border?
	beq l1508
l1532	lda #$51
	sta ($02),y
	rts
	nop
// ----------------------------------------------------------------------------
// Sub-function: handle enemy projectile
//
l1538	lda #$20        // SPACE character code
	sta ($09),y     // clear projectile at old screen position
l153c	ldx #$00
l153e	inc $09         // increment projectile address (16-bit)
	bne l1544
	inc $0a
l1544	inx
	nop
	cpx #$16        // loop 22 times (i.e. add 22 to address in total)
	bcc l153e
	lda ($09),y
	cmp #$51        // hit player figure?
	bne l1554
l1550	jsr _game_base  // yes -> player lost; restart game
	nop
l1554	cmp #$66        // hit the screen border?
	bne l155b
l1558	sty $08         // yes -> clear projectile status
	rts
l155b	lda #$42        // draw enemy projectile at new position
	sta ($09),y
	rts
// ----------------------------------------------------------------------------
// Sub-function: handle player projectile
//
l1560	lda #$20        // SPACE character code
	sta ($06),y     // clear projectile at old screen position
l1564	ldx #$00
l1566	dec $06         // decrement player projectile address (16-bit)
	lda $06
	cmp #$ff
	bne l1570
	dec $07
l1570	inx
	nop
	cpx #$16        // loop 22 times (i.e. subtract 22 from address in total)
	bcc l1566
	lda ($06),y
	cmp #$5a        // hit the enemy figure?
	beq l1588
l157c	cmp #$66        // hit the screen border?
	beq l1585
l1580	lda #$42        // draw player projectile at new position
	sta ($06),y
	rts
l1585	sty $05         // hit border -> clear projectile status
	rts
//                      // ----- enemy figure was hit: game won by player! -----
l1588	ldx #$00        // delay loop: 16*127*127 iterations
l158a	sty $00
l158c	inc $00
	lda $00
	cmp #$7f
	bcc l158c
	inx
	nop
	cpx #$7f
	bcc l158a
	iny
	nop
	cpy #$10        // most-outer loop of nested delay loops
	bcc l1588
	dec l14dd       // reduce event loop delay -> increase speed for next level of game
	jmp l138e       // restart (hopefully sub $e518 resets the stack pointer?)
// ----------------------------------------------------------------------------
