//
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
//

// ----------------------------------------------------------------------------
// Description of memory layout:
//
// >>>>> Prerequisite: 8 kB memory extension at $2000 <<<<<
//
// $0000-$00ff: pointer variables; see description below
// $0100-$01ff: stack
//
// $1000-$1225: screen buffer (extended to 25 rows * 22 columns)
// $1240-$13ff: read-only data section
// $1400-$1bff: code section, part 1
// $1c00-$1d1f: user-defined characters (position restricted by HW/ROM)
// $1dXX-$2fff: code section, part 2

// ----------------------------------------------------------------------------
// Main control flow:
//
// - $1400: game entry point from BASIC (SYS 5120)
// - main loop: chain of "jmp" starting at l1700 -> l1e08/l1e0d -> l2100
//   and finally back to tick_player
// - game is ended via "rts"

// P00 header
_start_data = $1240
.word _start_data

// variables
// $00-$01: player address
// $02-$03: first snake
// $04-$05: second snake
// $06-$07: third snake
// $08-$09: beam station
// $0a-$0b: stone
// $0c-$0d: digit under fire
// $0e-$0f: address dino foot
// $10-$11: temp pointer

// $fa

// $0340: saved color below player (companion to $0346)
// $0341: number of collected eggs; >$7f:wood
// $0342: counter snakes
// $0343: score BCD, lower nibbles
// $0344: score BCD, higher nibbles
// $0345: unused (planned for life counter)
// $0346: saved char below player (e.g. ladder)
// $0347: player direction
// $0348: on ladder? (0:no, else:yes)
// $0349: counter fire immunity
// $034a: loop counter
// $034b: power gain? 0:no else:yes
// $034c: counter until fire warning
// $034d: fire status: 0:burning 1:make 2:coming 3:attack 8:stamping
// $034e,$0350,$0352: snake: char under tail
// $034f,$0351,$0353: snake: column; $ff=dead (i.e. distance left border)
// $0354,$0356,$0358: snake: char under head
// $0355,$0357,$0359: snake egg delay until bursting
// $0384...$03dd: egg directory (for 4 bases, len=$16 each (see l1250)) bitmask:
//                mask $1f: egg count
//                mask $10: stone
//                mask $20: wood
//                mask $40: power gain
//                mask $80: ladder <-> blocked for content
// $03de: temporary


// address of levels on screen:
//  row    addr
// -------------------
//   3     $102c
//   6     $10ee
//  10     $10c6
//  14     $111e
//  18     $1176

.text
* = _start_data

// NOTE: screen buffer occupies $1000...$1225 (25 rows * 22 columns)

        // screen addresses of bases/levels
l1240   .word $102c             // top
        .word $1176             // bottom-most
        .word $111e             // 2nd from bottom
        .word $10c6             // 3rd from bottom
        .word $106e             // 2nd from top
        // numbers of gaps in middle levels (top and bottom have no gaps)
        // (dummy zero in-between to allow indexing with 2*X)
l124a   .byt $01,$00
        .byt $02,$00
        .byt $03,$00
        // egg directory = bases (see above)
l1250   .word $0384+$16+$16+$16
        .word $0384+$16+$16
        .word $0384+$16
        .word $0384
        // box for status messages (initially containing "----")
l1258   .byt $f0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$ee
l126e   .byt $dd,$20,$20,$20,$20,$20,$20,$20,$20,$ad,$ad,$ad,$ad,$20,$20,$20,$20,$20,$20,$20,$20,$dd
        .byt $ed,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$fd
        // boxes for egg count & score
        // "  --  " "DINO EGGS" ... "0"
        .byt $f0,$c0,$c0,$c0,$c0,$c0,$c0,$ee,$20,$20,$20,$20,$20,$20,$20,$20,$20,$f0,$c0,$c0,$c0,$ee
        .byt $dd,$20,$20,$ad,$ad,$20,$20,$dd,$84,$89,$8e,$8f,$20,$85,$87,$87,$93,$dd,$b0,$b0,$b0,$dd
        .byt $ed,$c0,$c0,$c0,$c0,$c0,$c0,$fd,$20,$20,$20,$20,$20,$20,$20,$20,$20,$ed,$c0,$c0,$c0,$fd
l1258_

        // carry status texts
l12da   .byt $20,$97,$8f,$8f,$84,$20    // " WOOD "
l12de   .byt $85,$87,$87,$20            // "EGG "
l12df   .byt $85,$87,$87,$93            // "EGGS"
        // zero-terminated message strings
l12e3   .byt $86,$89,$92,$85,$20        // "FIRE IS ON"
        .byt $89,$93,$20,$8f,$8e,$00
l12e4   .byt $86,$89,$92,$85,$20        // "FIRE IS OUT"
        .byt $89,$93,$20,$8f,$95,$94,$00
l12ed   .byt $8d,$81,$8b,$85,$20        // "MAKE A FIRE"
        .byt $81,$20
        .byt $86,$89,$92,$85,$00
l12f8   .byt $84,$89,$8e,$8f,$20        // "DINO MUM COMING"
        .byt $8d,$95,$8d,$20
        .byt $83,$8f,$8d,$89,$8e,$87,$00
l1307   .byt $84,$89,$8e,$8f,$20        // "DINO MUM ATTACK"
        .byt $8d,$95,$8d,$20
        .byt $81,$94,$94,$81,$83,$8b,$00
l130d   .byt $86,$89,$92,$85,$20,$89,$93,$20 // "FIRE IS GOING OUT"
        .byt $87,$8f,$89,$8e,$87,$20
        .byt $8f,$95,$94,$00
l1316   .byt $90,$8f,$97,$85,$92,$20    // "POWER GAIN"
        .byt $87,$81,$89,$8e,$00
l1317   .byt $94,$8f,$8f,$20            // "TOO HEAVY"
        .byt $88,$85,$81,$96,$99,$00

//l132f   .byt $00,$00,$00,$00,$00,$00    // "CONTERMINATION"
//        .byt $00,$00,$00,$00,$00,$00
//        .byt $00,$00

        // dino mum foot pattern
l133c   .byt $17,$18,$18,$18,$18,$18,$18,$18,$18,$19 // char codes: foot mid/{left,mid,right}
l1346   .byt $1a,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1c // char codes: foot low/{left,mid,right}

// ----------------------------------------------------------------------------
// fill up to next segment
.dsb $1400 - *, 0
* = $1400

l1400	lda #$0e
	sta $900f
	lda #$cf        // screen:$1000, color:$9400, user-def:$1C00
	sta $9005
	lda #$22        // adjust picture offset from top of screen for following increase in height
	sta $9001
	lda #$32        // set screen height to 25 lines
	sta $9003
	jsr $e55f       // clear screen
	jsr $e09b       // seed pseudo-random number generator (with VIA timer)

	ldx #$09        // copy pointers to bases on screen into ZP
l1419	lda l1240,x
	sta $00,x
	dex
	bpl l1419
	ldy #$15        // draw bases to all levels
	lda #$00        // char code for empty base
l1425	sta ($00),y
	sta ($02),y
	sta ($04),y
	sta ($06),y
	sta ($08),y
	dey
	bpl l1425

	ldx #$04
l1334	lda $04,x       // gaps in bases
	sta $fd
	lda $05,x
	sta $fe
	lda #$00
	sta $fa
	lda $8e         // get one RAND bit
	and #$01
	clc
	adc l124a,x
	sta $fb
	stx $00         // backup loop counter (X)
l144c	jsr $e094       // get RAND number
	lda $8d
	and #$0f
	cmp #$09
	bcs l144c
	adc #$01
	asl
	tay
	lda #$00
	sta $fc
	lda ($fd),y
	bne l144c
	dey
	dey
	dey
	lda ($fd),y
	beq l1470
	lda #$80
	ora $fc
	sta $fc
l1470	iny
	iny
	lda ($fd),y
	beq l147c
	lda #$20
	ora $fc
	sta $fc
l147c	iny
	iny
	iny
	lda ($fd),y
	beq l1489
l1483	lda #$08
	ora $fc
	sta $fc
l1489	iny
	iny
	lda ($fd),y
	beq l1495
l148f	lda #$02
	ora $fc
	sta $fc
l1495	dey
	dey
	dey
	dey
	lda $fc
	beq l14b7
l149d	and #$28
	beq l14b7
l14a1	lda $fc
	and #$a0
	cmp #$a0
	beq l14b7
l14a9	lda $fc
	and #$0a
	cmp #$0a
	beq l14b7
l14b1	lda $fa
	bne l144c
l14b5	sty $fa
l14b7	lda #$20
	sta ($fd),y
	iny
	sta ($fd),y
	dec $fb
	bpl l144c
	ldx $00
	ldy #$00
	dex
	dex
	bmi l14cd
	jmp l1334

l14cd	ldx #$00        // ladders
l13cf	lda $04,x       // get n-th base address from address list
	sta $fd
	lda $05,x
	sta $fe
	stx $00         // backup iteration counter
l14d9	jsr $e094       // get RAND number
	lda $8d
	and #$1f
	cmp #$14
	bcs l14d9
	adc #$01
	clc
        tay
	lda ($fd),y
	bne l14d9
	tya
	clc
	adc #$58
	tay
	lda ($fd),y
	bne l14d9
	ldx #$04        // loop to draw ladder across 4 rows
l14f6	tya
	sec
	sbc #$16        // one row up: Yoff-=23
	tay
	lda #$0a        // draw "ladder" char
	sta ($fd),y
	dex
	bne l14f6
	lda #$05        // top-most row: replace drawn char with "base with ladder"
	sta ($fd),y
	ldx $00         // loop for one more ladder?
	inx
	inx
	cpx #$06
	bcs l1511
l150e	jmp l13cf

l1511	ldx #$06        // --- egg directory ---
l1513	lda $02,x
	sta $fa
	lda $03,x
	sta $fb
	lda l1250,x     // get address of egg directory for current level
	sta $fc
	lda l1250+1,x
	sta $fd
	ldy #$15        // loop across all 22 columns of current base
l1527	lda ($fa),y     // read screen: is this an empty base? (i.e. no ladder)
	beq l152d
	lda #$80        // not empty -> block this position for eggs
l152d	sta ($fc),y     // initialize egg counter: 0 or BLOCKED
	dey
	bpl l1527
	dex
	dex
	bpl l1513

l15f3	jsr $e094       // --- place power gain at random position ---
	lda $8d
	and #$7f
	cmp #$58
	bcs l15f3
	tax
	lda $0384,x     // start of egg directory
	bne l15f3       // blocked -> try again
	lda #$40        // set flag for power gain in egg directory
	sta $0384,x

	lda #$04        // --- distribute 4 pieces of wood randomly ---
	sta $00
l1558	jsr $e094       // get RAND number
	lda $8d
	and #$7f
	cmp #$58
	bcs l1558
	tax
	lda $0384,x
	bne l1558       // try again if position blocked or used already
	lda #$20
	sta $0384,x     // store code for wood in egg directory
	dec $00
	bne l1558

	lda #$36         // --- distribute 54 eggs randomly across levels ---
	sta $00
l153a	jsr $e094       // get RAND number
	lda $8d
	and #$7f
	cmp #$58
	bcs l153a
	tax
	lda $0384,x     // start of egg directory
	cmp #$03
	bcs l153a       // already full or blocked -> try again
	inc $0384,x     // put an egg here
	dec $00
	bne l153a

	lda #$20        // --- distribute 32 stones randomly (possibly on top of items) ---
	sta $00
l1576	jsr $e094       // get RAND number
	lda $8d
	and #$7f
	cmp #$58
	bcs l1576
	tax
	lda $0384,x
	bmi l1576       // position blocked (ladder) -> try again
	ora #$10        // OR stone flag in egg directory (maybe on top of egg or wood)
	sta $0384,x
	dec $00
	bne l1576

	ldx #$06        // --- draw objects (eggs, stones, etc.) ---
l1592	lda $02,x
	sta $fa
	lda $03,x
	sta $fb
	lda l1250,x     // get address of egg directory for current level
	sta $fc
	lda l1250+1,x
	sta $fd

	ldy #$15        // first loop across all columns: draw in row below the base
l15a6	lda ($fc),y     // read egg directory of this pos
	and #$10        // stone?
	beq l15b4
	lda #$09        // char for "lower half of stone"
	bne l15bb
l15b4	lda ($fc),y
        cmp #$40
        bne l15b8
        lda #$0b        // char for "lower half of power gain"
        bne l15bb
l15b8   and #$0f
        cmp #$02        // two or more eggs?
        bcc l15cb
	clc
        adc #$07-2      // char code for one or two eggs
l15bb	sta $00         // backup A
	tya             // calculate screen address/offset in Y: one row below base: -22
	clc
	adc #$16
	tay
	lda $00         // restore A
	sta ($fa),y     // draw char on screen
	tya
	sec
	sbc #$16        // revert Y offset -22, plus decrement -1
	tay
l15cb	dey
	bpl l15a6

	ldy #$15        // second loop across all columns: draw in row of base itself
l15d0	lda ($fc),y
	and #$7f        // strip "blocked" flag
	beq l15ec       // nothing here -> skip
	and #$10        // stone?
	beq l15de
	lda #$02        // base with stone
	bne l15ea
l15de   lda ($fc),y
        cmp #$40        // power gain?
	bcc l15e0
	lda #$04        // base with power-gain
	bne l15ea
l15e0   cmp #$20        // wood?
	bcc l15e8
	lda #$03        // base with wood
	bne l15ea
l15e8	lda #$01        // base with egg
l15ea	sta ($fa),y     // draw selected char
l15ec	dey
	bpl l15d0       // next iteration of columns

l15ef	dex             // next iteration of levels
	dex
	bpl l1592

	ldx #(l1258_-l1258) // print initial status display
l1625	lda l1258-1,x
	sta $11a2-1,x
	lda #$01        // color code
	sta $95a2-1,x
	dex
	bne l1625

	ldy #$00        // reset Y: register is globally assumed to be zero, except for temporary use

	ldx #$16        // initialize player status variables
	tya
l1638	sta $0340,x
	dex
	bpl l1638
	lda #$20        // initialize char & color under player figure
	sta $0346
        lda #$00
	sta $0340
	lda #$a0
	sta $034c       // initialize timer for first warning "make a fire"
	lda #$01        // initialize fire status: not burning
	sta $034d

	ldx #$06        // initialize snake addresses: first column in each level
l164f	lda l1240+1,x
	sta $01,x
	lda l1240,x
	sec
	sbc #$16        // NOTE underflow does not happen for current level base addresses (unsafe)
	sta $00,x
	dex
	dex
	bne l164f

	ldx #$04        // initialize snake status
l1662	lda #$a0
	sta $0355,x     // snake egg delay until bursting
	lda #$ff
	sta $034f,x     // snake dead (i.e. past right screen border)
	dex
	dex
	bpl l1662

// ----------------------------------------------------------------------------
//                      // Place player home randomly

l1670	lda $8c         // --- select random start position for player ---
	and #$03        // random level 0..3
	asl
	tax
	lda l1240+2,x
	sta $fa
	lda l1240+3,x
	sta $fb
l1680	jsr $e094       // get RAND number
	lda $8d
	and #$1f
	cmp #$14
	bcs l1680
	adc #$01
	tay
	lda ($fa),y     // selected position blank?
	cmp #$20
	beq l1680       // no -> try another random position
	sty $fd
	lda $fb
	sta $09
	sta $01
	lda $fa
	clc
	adc $fd
	sec
	sbc #$2d
	bcs l16a8
	dec $09
l16a8	sta $08
	ldy #$18
l16ac	lda ($08),y     // home pos empty?
	cmp #$20
	bne l1680       // no -> try another random position
l16b2	dey
	cpy #$16
	bcs l16ac
l16b7	lda $fa
	clc
	adc $fd
	sec
	sbc #$16
	sta $00
	lda #$0c        // code for normal player" figure
	jsr draw_player
	ldy #$00
	lda #$14        // draw home
	sta ($08),y
	iny
	sta ($08),y
	iny
	sta ($08),y
	ldy #$16
	sta ($08),y
	iny
	iny
	sta ($08),y
	ldy #$00
        lda $08         // calc color address: +$9400 -$1000
        sta $10
        lda $09
        clc
        adc #$94-$10
        sta $11
        lda #$05        // color green
	sta ($10),y
	iny
	sta ($10),y
	iny
	sta ($10),y
	ldy #$16
	sta ($10),y
	iny
	iny
	sta ($10),y

// ----------------------------------------------------------------------------
//                      // Player actions

l1700	lda $0347
	and #$e0
	beq l1745
        jsr undraw_player // --- jump to the left ongoing ---
	lda $00         // move player one to the left
	bne l1719
	dec $01
l1719	dec $00
	lda #$0e
	jsr draw_player
	lda $0347       // determine next stage
	cmp #$40
	beq l172c
	lda #$40        // 1 -> stage 2
	bne l172e
l172c   lda #$00        // 2 -> jump done
l172e	sta $0347
	jmp l1e0d

l1745	lda $0347       // --- start jump to the right ---
	and #$0e
	beq l1786
	jsr undraw_player
	inc $00         // player pos one to the right
	bne l175e
	inc $01
l175e   lda #$0f
	jsr draw_player
	lda $0347       // determine next stage
	cmp #$04
	beq l176f
        lda #$04        // 2 -> stage 2
        bne l1771
l176f	lda #$00        // jump done
l1771	sta $0347
	jmp l1e0d

l1786	lda $0348       // player on ladder?
	beq l178e
	jmp l187f       // yes -> skip/disallow left or right movement

l178e	ldy #$16
	lda ($00),y     // read char in row directly below player
	cmp #$0a        // ladder?
	beq l17c9
	cmp #$07        // any kind of base?
	bcc l17c9
	ldy #$00        /// --- free fall ---
	jsr undraw_player
	lda $00         // move player one row down
	clc
	adc #$16
	bcc l17aa
	inc $01
l17aa	sta $00
	lda $0347       // select new player char depending on current direction
	bne l17ba
l17b6	lda #$0c        // standing still
	bne l17c4
l17ba	and #$0f
	bne l17c2
	lda #$0e        // player facing left
	bne l17c4
l17c2	lda #$0f        // player facing right
l17c4	jsr draw_player
	jmp l1e0d

l17c9   lda $0347
	cmp #$10        // player moving left?
	bne l1807
        //lda $cb
	//cmp #$11        // key 'A' (left)
	//bne l17d8
	lda $028d       // SHIFT key pressed?
	and #$01
	bne l17df
l17d8	lda $911f       // joystick left or fire?
	and #$30
	bne l1807
l17df	jsr undraw_player // --- trigger jump to the left ---
	lda $00         // moving one row up and one col to the left
	sec
	sbc #$17
	bcs l17f4
	dec $01
l17f4	sta $00
	lda #$0e
	jsr draw_player
	lda #$20        // store direction indicator (needed for allowing jump)
	sta $0347
	jmp l1e0d

l1807   lda $0347       // player moving right?
	cmp #$01
	bne l184f
        //lda $cb
	//cmp #$29        // key 'S' (right)
	//bne l1814
	lda $028d       // SHIFT key pressed?
	and #$01
	bne l1827
l1814	lda $911f       // joystick fire button?
	and #$20
	bne l184f
	lda #$7f
	sta $9122
	lda $9120       // joystick right?
	and #$80
	bne l184f
l1827   jsr undraw_player  // --- trigger jump to right ---
	lda $00         // moving one row up and one to the right
	sec
	sbc #$15
	bcs l183c
	dec $01
l183c	sta $00
	lda #$0f
	jsr draw_player
	lda #$02        // store jump status
	sta $0347
	jmp l1e0d

l184f	lda $cb
	cmp #$11        // key 'A' (note: allow SHIFT being pressed already)
	beq l1861
	lda $911f       // joystick left?
	and #$10
	bne l187f
l1861	jsr undraw_player
	lda $00         // player one to the right
	bne l186c
	dec $01
l186c	dec $00
	lda #$10
	sta $0347
	lda #$0e
	jsr draw_player
	jmp l1e0d

l187f	lda $cb
	cmp #$09        // key 'W' (up)
	beq l188c
	lda $911f       // joystick up?
	and #$04
	bne l18ba
l188c	lda $0346       // check char below player
	cmp #$0a        // ladder?
	beq l1897
	cmp #$05        // base with ladder?
	bne l18b3
l1897	sta $0348       // --- climbing ---
        jsr undraw_player
	lda $00         // move player up one row
	sec
	sbc #$16
	bcs l18a5
	dec $01
l18a5	sta $00
	lda #$0d        // draw climbing player figure
	jsr draw_player
	jmp l1e0d
l18b3	lda #$00
	sta $0348       // clear climbing status
	lda #$0c        // draw normal player figure
        ldy #$00
	sta ($00),y
	jmp l1e0d

l18ba	lda $0348
	bne l1903
	lda $cb
	cmp #$29        // key 'S' (note: allow SHIFT being pressed already)
	beq l18d6
	lda #$7f
	sta $9122
	lda $9120       // joystick right?
	and #$80
	bne l1903
l18d6	jsr undraw_player
	inc $00
	bne l18e1
	inc $01
l18e1	lda ($00),y
	cmp #$07        // wrapped at right screen border? (i.e. ran into base char)
	bcs l18f2
	lda $00         // yes -> move to left-most column, -1 row to (mimic inverse direction)
	sec
	sbc #22*2
	bcs l18f1
	dec $01
l18f1	sta $00
l18f2	lda #$0f
	jsr draw_player
	lda #$01
	sta $0347
	jmp l1e0d

l1903	lda $cb
	cmp #$21        // key 'Z' (descend ladder)
	beq l1910
	cmp #$0b        // key 'Y': equiv. 'Z' for German keyboard
	beq l1910
l1909	lda $911f       // joystick xxx?
	cmp #$76
	bne l1944
l1910	ldy #$16        // read char one row below player
	lda ($00),y
	cmp #$0a        // ladder in row below player?
	beq l191e
	cmp #$05
	bne l193d
l191e	sta $0348       // start descending
	jsr undraw_player
	lda $00         // move player one row down
	clc
	adc #$16
	bcc l192f
	inc $01
l192f	sta $00
	lda #$0d        // draw player; climbing form
	jsr draw_player
	jmp l1e0d
l193d	ldy #$00
	sty $0348       // reset climbing status
	lda #$0c        // draw player in normal form
	ldy #$00
        sta ($00),y
	jmp l1e0d

l1944	lda $cb
	cmp #$27        // key F1?
	beq l1951
	lda $911f       // joystick xxx?
	cmp #$5e
	bne l196e
l1951	lda $0346
	cmp #$0a        // ladder behind player?
	beq l196e
l1958	jsr undraw_player
	lda $00         // move player up by 2 rows
	sec
	sbc #$2c
	bcs l1963
	dec $01
l1963	sta $00
	lda #$0c        // draw player figure; normal form
	jsr draw_player
	jmp l1e0d

l196e	lda $cb
	cmp #$3f        // key F7?
	beq l197e
	cmp #55         // key F5?
	beq l197e
l1974	lda $911f       // joystick xxx?
	and #$28
	beq l197e
	jmp l1e08       // to "player no action"

                        // --- check F7 in home base? ---
l197e	ldy #$17        // check if player at home:
	lda ($08),y
	cmp #$0c        // player figure (any shape) at home position?
	bcc l19ae       // no -> abort
	cmp #$10
	bcs l19ae
        lda $0341       // carrying at least 3 eggs?
        and #$7f
        cmp #$03
        bcc l19ae       // no -> abort
	lda $034d
	cmp #$08        // player attacked by dino mum?
	bcs l19ae       // yes -> abort
	lda #$20        // blank behind player? (simplification)
	cmp $0346
	bne l19ae       // no -> abort
	ldy #$00
        sta ($08),y     // delete home
	iny
	sta ($08),y
	iny
	sta ($08),y
	ldy #$16
	sta ($08),y
	iny
	sta ($08),y
	iny
	sta ($08),y
        lda #$00        // clear power gain
	sta $034b
	lda $0341       // add number of carried eggs to score
	and #$7f
        beq l19a0
        jsr add_score
        lda #$00
        sta $0341       // reset egg counter
        jsr prt_egg_status
        lda $0343       // all eggs picked up? (assuming one point is scored per egg)
        cmp #$54        // binary $36 <=> decimal (BCD) 54 (ignore third nibble $0344)
        bne l19a0
        lda #$00        // yes -> game won!
        jmp post_game
l19a0   jmp l1670       // -> move player to random position

                        // --- F7 to pick up wood (& light fire)? ---
l19ae	ldy #$16        // read char one row below player
	lda ($00),y
	cmp #$03        // base with wood under player?
	bne l1a61
	lda $0341       // player already carrying eggs?
	and #$7f
	bne l1a20       // yes -> abort
	lda $0341       // player already carrying wood?
	and #$80
	bne l19d8       // yes -> try making a fire here
        lda #$00        // remove wood (i.e. draw empty base)
	sta ($00),y
	lda #$80        // remember carrying wood
	sta $0341
        jsr prt_egg_status
	jmp l1e0d

                        // --- try lighting a fire ---
l19d8	lda $034d       // fire already burning?
	beq l1a20       // yes -> abort
	lda $0346
	cmp #$20        // blank behind player?
	bne l1a20       // no -> cannot make fire here
	ldy #$16        // remove wood (i.e. draw empty base below player)
        lda #$00
	sta ($00),y
	lda #$15        // fire char behind player
	sta $0346
	lda #$07        // yellow
	sta $0340
	lda #$20        // start fire immunity counter
	sta $0349
	lda #$00        // clear carry status
	sta $0341
        jsr prt_egg_status
        lda #<l12e3     // print "FIRE IS ON"
        sta $10
        lda #>l12e3
        sta $11
        jsr prt_message
	lda #$00
	sta $034d       // fire status: burning
	lda $01         // store address of digit under fire
	sta $0d
	lda $00
	sta $0c
	ldy #$2c
	lda #$b9        // print inverted '9' below base below fire
	sta ($0c),y
        lda $0c         // calc color address: ($00) + $9400 -$1000
        sta $10
        lda $0d
        clc
        adc #$94-$10
        sta $11
        lda #$07
	sta ($10),y
l1a20	jmp l1e0d

                        // --- F7 to pick up eggs? ---
l1a61	ldy #$2c
	lda ($00),y     // read char 2 rows below player
	cmp #$08        // char for two eggs?
	bne l1a6d
	ldx #$07        // yes -> change to one egg
	bne l1a7f
l1a6d	cmp #$07        // char for one egg?
	bne l1a75
	ldx #$20        // yes -> change to empty
	bne l1a7f
l1a75	ldy #$16        // read char 1 row below player
	lda ($00),y
	cmp #$01        // char for base with egg?
	bne l1b2d       // no -> no eggs for picking up here
	ldx #$00        // yes -> change to empty base
l1a7f   lda $0341       // already carrying 3 eggs?
	cmp #$03
	bcc l1a80
	lda $034b       // power gain?
	bne l1a80
	lda #<l1317     // no -> print "TOO HEAVY"
        sta $10
	lda #>l1317
        sta $11
                        // TODO clear message after timer
        jsr prt_message
	jmp l1e0d
l1a80	txa
        sta ($00),y     // draw char with one egg less
	inc $0341       // increment player's egg counter
        jsr prt_egg_status
	jmp l1e0d

                        // --- F7 to pick up power-gain? ---
l1b2d	ldy #$16        // read char one row below player
	lda ($00),y
	cmp #$04        // base with power gain?
	bne l1b55
	sta $034b       // enable power gain
	lda #$00
	sta ($00),y     // remove power-gain from screen (two rows)
	lda #$20
	ldy #$2c
	sta ($00),y
	lda #<l1316     // print "POWER GAIN"
        sta $10
	lda #>l1316
        sta $11
        jsr prt_message
	lda #$30        // grant fire immunity
	sta $0349
l1b52	jmp l1e0d

l1b55	cmp #$02        // base with stone?
	bne l1a23
	jmp l1d08       // to stone fall

                        // --- F7 to drop carried egg or wood? ---
l1a23	cmp #$00        // empty base under player?
	bne l1b52       // no -> abort; cannot handle F7
	lda $0341       // player carrying wood?
	bpl l1a4e
	ldy #$16        // put down wood
	lda #$03
	sta ($00),y
	lda #$00        // clear carry status
	sta $0341
        jsr prt_egg_status
	jmp l1e0d

l1a4e	lda $0341       // player carrying any eggs?
	beq l1b52       // no -> abort
        lda #$01        // at least one egg -> replace empty base char with base with egg
        sta ($00),y
        dec $0341
        lda $0341
        beq l1af9       // no more eggs left -> done
        cmp #$02
        bcs l1af0       // goto >=2 eggs
        lda #$07        // char for one egg
        bne l1af8
l1af0   lda #$08        // char for two eggs
        dec $0341
l1af8	dec $0341
        ldy #$2c
        sta ($00),y     // write char below base
l1af9	jsr prt_egg_status
	jmp l1e0d


// ----------------------------------------------------------------------------
// Character generator data
// - 32 user-defined characters, 8x8 bit each
// - mapped to start at $1c00 (register $9005)

// fill up to next segment
.dsb $1c00 - *, 0
* = $1c00

l1c00	.byt $ff,$88,$55,$22,$00,$00,$00,$00    // #$00: Base
	.byt $ff,$88,$55,$22,$3e,$7f,$7f,$3e    // #$01: Base with egg
	.byt $ff,$88,$55,$22,$1c,$2a,$51,$43    // #$02: Base with stone
	.byt $ff,$88,$55,$22,$7f,$7f,$27,$60    // #$03: Base with wood
	.byt $ff,$88,$55,$22,$41,$22,$14,$5d    // #$04: Base with power gain
	.byt $ff,$88,$55,$22,$41,$7f,$41,$41    // #$05: Base with ladder
	.byt $ff,$88,$55,$22,$3a,$77,$73,$3e    // #$06: Base with cracked egg
	.byt $3e,$7f,$7f,$3e,$00,$00,$00,$00    // #$07: one egg
	.byt $3e,$7f,$7f,$3e,$3a,$7f,$7f,$3e    // #$08: two eggs
	.byt $65,$51,$43,$49,$61,$55,$26,$1c    // #$09: stone lower half (under base)
	.byt $41,$7f,$41,$41,$41,$7f,$41,$41    // #$0a: ladder
	.byt $3e,$36,$36,$3e,$5d,$14,$22,$41    // #$0b: power gain below
	.byt $1c,$1c,$08,$7f,$49,$dd,$14,$36    // #$0c: player normal
	.byt $dc,$5c,$49,$7f,$08,$3c,$64,$06    // #$0d: player upwards
	.byt $1c,$5c,$48,$7e,$0b,$3d,$22,$66    // #$0e: player left
	.byt $38,$3a,$12,$7e,$d0,$bc,$44,$66    // #$0f: player right
	.byt $00,$00,$00,$08,$95,$55,$55,$22    // #$10: snake tail (left)
	.byt $00,$00,$07,$8a,$67,$50,$50,$20    // #$11: snake head (right)
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // #$12: spider - UNUSED
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // #$13: dino - UNUSED
l1ca0	.byt $aa,$00,$55,$00,$aa,$00,$55,$00    // #$14: home - ROR'ed at run-time
l1ca8	.byt $00,$00,$00,$00,$00,$00,$00,$7e    // #$15: fire - switched at run-time
	.byt $00,$00,$00,$00,$1c,$2a,$51,$43    // #$16: stone above w/o base
	.byt $51,$64,$49,$54,$40,$6a,$54,$41    // #$17: foot mid/left
	.byt $20,$8a,$40,$09,$a0,$15,$40,$15    // #$18: foot mid/mid
	.byt $82,$22,$42,$12,$42,$02,$a2,$02    // #$19: foot mid/right
	.byt $64,$4a,$60,$50,$40,$41,$41,$3e    // #$1a: foot low/left
	.byt $42,$15,$80,$00,$00,$01,$81,$70    // #$1b: foot low/mid
	.byt $42,$12,$82,$02,$02,$02,$82,$7c    // #$1c: foot low/right
	.byt $20,$48,$53,$54,$54,$53,$48,$20    // #$1d: snake egg left
	.byt $02,$09,$e5,$15,$15,$e5,$09,$02    // #$1e: snake egg right
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // #$1f: unused
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // #$20: blank

l1ca8_0 .byt $08,$28,$69,$b9,$7f,$3c,$18,$7e    // #$15: fire v1
l1ca8_1 .byt $00,$00,$14,$59,$3a,$3c,$18,$7e    // #$15: fire v2

// fire v1         v2
// ....*...        ........
// ..*.*...        ........
// *.*.*..*        ...*.*..
// *.***..*        .*.**..*
// .******.        ..***.*.
// ..****..        ..****..
// ...**...        ...**...
// .******.        .******.

// ----------------------------------------------------------------------------
//                      // Stone fall

l1d08	lda $00         // determine which base/level player is on
	sta $0a
	lda $01
	sta $0b
l1d10	ldx #$06
l1d12	lda l1240+3,x
	cmp $0b
	bne l1d23
	lda l1240+2,x
	sec
	sbc $0a
	cmp #$18
	bcc l1d27
l1d23	dex
	dex
	bpl l1d12
l1d27	sta $fa         //  pos in level equiv. pos. in egg register
	lda l1250,x
	sta $fb
	lda l1250+1,x
	sta $fc
	lda #$16
	sec
	sbc $fa
	tay
	sty $fa
	lda ($fb),y     // query egg directory for this position
        cmp #$40
        bcc l1d40
	lda #$04        // char for base with power-gain
	bne l1d4d
l1d40	and #$23
	cmp #$10
	bcc l1d47
	lda #$03        // char for base with wood
	bne l1d4d
l1d47	cmp #$01
	bcc l1d4d
	lda #$01        // char for base with egg
l1d4d	ldy #$16
	sta ($0a),y     // draw new base char
	ldy #$2c        // offset to row below base
	lda #$16        // char for upper half of stone without base
	sta ($0a),y
	ldy #$42        // offset two rows below base
	lda ($0a),y
	cmp #$20        // room for lower half of stone?
	bne l1d63
	lda #$09        // draw lower half of stone
	sta ($0a),y

l1d63	ldy #$30        // time delay
l1d65	ldx #$ff
l1d67	dex
	bne l1d67
l1d6a	dey
	bne l1d65

	ldy $fa
	lda ($fb),y     // query egg register again
	cmp #$40        // power gain?
        bcc l1d70
        lda #$0b        // char for lower half of power gain
        bne l1d7d
l1d70	and #$03
	cmp #$02        // more than one egg?
	bcc l1d7b
	adc #$07-2-1    // char for one or two eggs (-2 for egg# >=2; -1 due to omitting CLC)
	bne l1d7d
l1d7b	lda #$20        // blank char
l1d7d	ldy #$2c        // stone address + 2 rows
	sta ($0a),y

	lda $0a
	clc
	adc #$42
	bcc l1d8a
	inc $0b
l1d8a	sta $0a
l1d8c	ldy #$00        // start loop
	lda ($0a),y     // read char below new base
	cmp #$09        // lower half of stone?
	beq l1dac
	cmp #$20
	beq l1dac
	cmp #$15        // fire hit by stone?
	bne l1dd8
	tya             // yes -> nearly extinguish fire
	clc
	adc #$2c
	tay
	lda #$b2        // set fire counter to '2'
	sta ($0a),y
	lda #$ff        // make fire counter decement immediately
	sta $034a
	bne l1dd8       // end stone fall
l1dac	lda #$16        // upper half of stone
	sta ($0a),y
	ldy #$16
	lda ($0a),y
	cmp #$20
	bne l1dbc
l1db8	lda #$09        // lower half of stone
	sta ($0a),y
l1dbc	ldy #$50        // time delay
l1dbe	ldx #$ff
l1dc0	dex
	bne l1dc0
l1dc3	dey
	bne l1dbe
	lda #$20        // remove upper half of stone
	sta ($0a),y
	lda $0a         // move stone pointer one row down
	clc
	adc #$16
	bcc l1dd3
	inc $0b
l1dd3	sta $0a
	clc
	bcc l1d8c       // loop while stone falling

l1dd8	lda ($0a),y
	cmp #$02        // base with stone?
	bne l1dec
l1dde	lda $0a         // yes -> new stone fall in lower level
	sec
	sbc #$16
	bcs l1de7
	dec $0b
l1de7	sta $0a
	jmp l1d10       // continue stone fall at current position
l1dec	jmp l1e0d

// ----------------------------------------------------------------------------
//                      // --- player status handling ---

l1e08	lda #$00        // no player action (i.e. no key/joystick input)
	sta $0347       // -> clear direction to "not moving"

l1e0d	ldy #$40        // time delay
l1e0f	ldx #$ff
l1e11	dex
	bne l1e11
l1e14	dey
	bne l1e0f

l1e17	lda #$ff        // configure $9120 for input (i.e. allow querying if joystick right)
	sta $9122

	lda $0348       // player on ladder?
	beq l1e2f
	lda $0346       // check char behind player
	cmp #$20
	bne l1e2f
	ldy #$00
	sty $0348       // blank -> clear ladder status
	lda #$0c        // change player figure to "normal"
        ldy #$00
	sta ($00),y

l1e2f	lda $0346
	cmp #$15        // player standing in fire?
	bne l1e44
	lda $0349       // fire immunity timer still running?
	bne l1e44
	ldy #$2c        // immunity timeout
	lda ($00),y
	cmp #$b2        // '2'
	bcc l1e44
        lda #$01
	jmp post_game   // burnt to death

l1e44	lda $0349       // immunity counter running?
	beq l1e59
	dec $0349       // decrement immunity counter
	bne l1e59
        jsr clr_message // clear display ("FIRE IS ON" et.al.)

l1e59	ldx #$08        // rotate home char definition by one bit right: shimmering effect
l1e5b	lda l1ca0-1,x
	lsr
	bcc l1e64
	ora #$80
l1e64	sta l1ca0-1,x
	dex
	bne l1e5b

	lda $034a       // toggle between fire chars
        and #$01
        bne l1e66
        ldx #$08
l1e65   lda l1ca8_0-1,x
        sta l1ca8-1,x
	dex
	bne l1e65
	beq l1e67
l1e66   ldx #$08
l1e68   lda l1ca8_1-1,x
        sta l1ca8-1,x
	dex
	bne l1e68

l1e67   inc $034a       // increment game loop counter
	bne l1ef1       // no overflow -> skip periodic action handler

	lda $034d       // fire burning?
	bne l1ef1
	ldy #$2c
	lda ($0c),y     // update fire status display: -1
	sec
	sbc #$01
	sta ($0c),y
	cmp #$b1        // '1'?
	bne l1eb4
	lda #<l130d     // print "FIRE IS GOING OUT"
        sta $10
	lda #>l130d
        sta $11
        jsr prt_message
        lda #$20
	sta $0349
l1eb1	jmp l2100
l1eb4	cmp #$b0        // '0'?
	bne l1eb1
l1eb8	lda $0346       // fire char behind player?
	cmp #$15
	bne l1ec6
	lda #$20        // replace player background with blank (i.e. clear fire char)
	sta $0346
	bne l1ecc
l1ec6	ldy #$00
	lda #$20        // clear digit below fire
	sta ($0c),y
l1ecc	ldy #$2c
	sta ($0c),y
	lda #$01        // new fire status: "make a fire"
	sta $034d
	lda #$fe        // timer for issuing next warning message
	sta $034c
	ldx #$0b-2
        lda #<l12e4     // print "FIRE IS OUT"
        sta $10
        lda #>l12e4
        sta $11
        jsr prt_message
        lda #$20
	sta $0349
	jmp l2100

l1ef1	lda $034d
	and #$f8
	beq l1efb
	jmp l1f9c       // to "dino mum actions"
l1efb	lda $034c       // timer running?
	bne l1f03
l1f00	jmp l2100       // to "snakes"
l1f03	dec $034c       // counter up to status message
	bne l1f00
l1f08	lda $034d
	beq l1f00       // fire burning -> nothing to do
l1f0d	cmp #$01        // fire status 1? (fire freshly out)
	bne l1f2e
	lda #<l12ed     // print "MAKE A FIRE"
        sta $10
	lda #>l12ed
        sta $11
        jsr prt_message
	lda #$02        // new fire status
	sta $034d
	lda #$f0        // counter up to next status message
	sta $034c
l1f26	lda #$20
	sta $0349
	jmp l2100

l1f2e	cmp #$02        // fire status 2?
	bne l1f49
	lda #<l12ed     // print "DINO MUM COMING"
        sta $10
	lda #>l12ed
        sta $11
        jsr prt_message
	lda #$d0
	sta $034c
	lda #$04
	sta $034d
	bne l1f26

l1f49	cmp #$04        // fire status 4?
	bne l1f9c
	lda #<l1307     // print "DINO MUM ATTACK"
        sta $10
	lda #>l1307
        sta $11
        jsr prt_message
	lda $01         // determine column pos of player
	sec
	sbc #$10        // MSB of player offset to screen base address $1000
	sta $0f
	lda #$00
	sta $fa
	lda $00         // get LSB of player address
l1f70	sec             // calc Yoff/22 via iteration
	sbc #$16
	bcs l1f79
	dec $0f
	bmi l1f7c
l1f79	clc
	bcc l1f70
l1f7c	clc
	adc #$16        // undo last subtraction: calc Yoff%22
	cmp #$0e        // check range, so that dino foot fits on screen (without wrap or cut-off)
	bcc l1f87
	lda #$0c
	bne l1f91
l1f87	cmp #$08
	bcc l1f8f
	lda #$06
	bne l1f91
l1f8f	lda #$00
l1f91	sta $0e         // store base address for dino foot
	lda #$10
	sta $0f
	lda #$08        // new fire status = 8
	sta $034d

// ----------------------------------------------------------------------------
//                      // --- dino mum actions ---

l1f9c	lda $034d       // attack ongoing?
	cmp #$10
	bcc l1fa0
	jmp l202b       // -> pull up foot

l1fa0	lda #$20        // counter for foot lowering (twice speed of player)
	sta $fa
l1faa	lda #$00        // foot down
	sta $fb
	ldy #$09
l1fb0	lda l1346,y     // foot pattern
	sta ($0e),y     // foot +1 row
	dey
	bpl l1fb0
l1fb8	lda $0e
	clc
	adc #$16
	bcc l1fc1
	inc $0f
l1fc1	sta $0e
	sta $22
	lda $0f
	sec
	sbc #$02
	sta $23
	ldy #$09        // store chars behind by foot
l1fce	lda ($0e),y
	sta ($22),y
	cmp #$0c        // stomping onto player figure? (in any shape, i.e. #$0c...#$0f)
	bcc l1fde
	cmp #$10
	bcs l1fde
	lda #$00        // yes -> player dead
	sta $01
l1fde	lda l133c,y     // foot pattern
	sta ($0e),y
	dey
	bpl l1fce
	ldy #$1f
l1ff2	lda ($0e),y
	cmp #$07        // foot over base?
	bcc l1fff
	dey
	cpy #$16        // no base
	bcs l1ff2
	bcc l201a
l1fff	lda $0f
	cmp $01
	bcc l200b
	lda $0e         // foot higher than player
	cmp $00
	bcs l2024
l200b	lda $0f
	cmp $01
	bcc l201a
	lda $00
	sec
	sbc $0e
	cmp #$16        // foot on same base as player
	bcc l2024

l201a	ldy #$20        // time delay
l2011	ldx #$ff
l2012	dex
	bne l2012
l2013	dey
	bne l2011
        dec $fa         // next iteration foot lowering
	bne l1faa

l2021	jmp l2100
l2024	lda #$10        // fire status $10
	sta $034d
	bne l2021
        // fall-through

//                      // --- foot raising ---
l202b	lda $01
	bne l2030
        lda #$02
	jmp post_game   // stomped to death
l2030	ldy #$09
	lda $0e
	sta $22
	lda $0f
	sec
	sbc #$02
	sta $23         // restore char behind foot
l203d	lda ($22),y
	sta ($0e),y     // foot pos -1 row
	dey
	bpl l203d
l2044	lda $0e
	sec
	sbc #$16
	bcs l204d
l204b	dec $0f         // foot back in first row
l204d	sta $0e
	lda $0f
	cmp #$10
	bne l207c
l2055	lda $0e
	cmp #$16
	bcs l207c
l205b	jsr $e094       // get RAND number
	lda $8d
	ora #$1f
	sta $034c       // time until next attack
	lda #$04        // fire status back to 4
	sta $034d
	ldx #$16        // clear first row
	lda #$20
l206e	sta $1000,x
	dex
	bpl l206e
	lda #$01
	sta $0349
	jmp l2100
l207c	ldy #$09        // clear "attack" display
l207e	lda l1320+10,y
	sta ($0e),y
	dey
	bpl l207e
	jmp l2100

// ----------------------------------------------------------------------------
// fill up to next segment
.dsb $2100 - *, $ea
* = $2100

l2100	jmp l1700

// ----------------------------------------------------------------------------
//                      // Sub-function for updating "carrying" status
//                      // called after picking up or dropping any item

prt_egg_status
	lda $0341
        bne l2210
	ldx #$08        // --- carrying nothing ---
l2211	lda l1258+4*$16-1,x  // clear status box: copy initial content
	sta $11a2+4*$16-1,x
	dex
	bne l2211
        rts
l2210   cmp #$80
        bcc l2220
	ldx #$06        // --- carrying wood ---
l2212	lda l12da-1,x   // print " WOOD "
	sta $11a2+4*$16+1-1,x
	dex
	bne l2212
	rts
l2220   cmp #10         // --- carrying 1 or more eggs ---
        bcs l2201
        ldx #$20        // single digit -> blank in higher digit's place
        bne l2203
l2201   ldx #$b0        // calc higher digit, starting with '0'
l2202   inx
        sbc #10
        cmp #10
        bcs l2202
l2203   stx $11a2+4*$16+1  // print higher digit
        clc
        adc #$b0        // calc lower digit: '0' plus value <10
        sta $11a2+4*$16+2  // print lower digit
	lda $0341
        cmp #1
        bne l2204
	ldx #$04
l2205	lda l12de-1,x   // print "EGG "
	sta $11a2+4*$16+3-1,x
	dex
	bne l2205
        rts
l2204	ldx #$04
l2206	lda l12df-1,x   // print "EGGS"
	sta $11a2+4*$16+3-1,x
	dex
	bne l2206
        rts

// ----------------------------------------------------------------------------
//                      Sub-function: draw player figure
//                      - Parameter: A = new player char code
//                      - implied: $00-$01: current player address
//                      - side-effect: stores char/color under player $0346/$0340
//                                     overwrites temp pointer $10-$11

draw_player
        tax
        lda $00         // calc color address: ($00) + $9400 -$1000
        sta $10
        lda $01
        clc
        adc #$94-$10
        sta $11

        ldy #$00        // backup char & color behind player
	lda ($00),y
	sta $0346
	lda ($10),y
	sta $0340
        txa
	sta ($00),y     // write player figure
        lda #$05        // color green
	sta ($10),y
        rts

undraw_player
	ldy #$00
        lda $0346
	sta ($00),y
        lda $00         // calc color address: ($00) + $9400 -$1000
        sta $10
        lda $01
        clc
        adc #$94-$10
        sta $11
        lda $0340
	sta ($10),y
        rts

// ----------------------------------------------------------------------------
//                      // Sub-function for adding points to score and display
//                      // Parameter: A = number of points to be added in BCD
add_score
        ldx #$00        // convert parameter to BCD
l2302   cmp #$0a        // calc X:=val/10
        bcc l2301
        sec
        sbc #$0a
        inx
        bne l2302
l2301   sta $03de       // BAK:=val%10
        txa
        asl
        asl
        asl
        asl
        clc
        adc $03de

        sed             // enable BCD mode for arithmetics
        clc
        adc $0343       // add to lower nibbles
        sta $0343
        lda #$00
        adc $0344       // add C-bit to higher nibble
        sta $0344
        cld

        lda $0343
        and #$0f
        clc
        adc #$b0
        sta $11a2+4*$16+$12+2
        lda $0343
        lsr
        lsr
        lsr
        lsr
        clc
        adc #$b0
        sta $11a2+4*$16+$12+1
        lda $0344
        and #$0f
        clc
        adc #$b0
        sta $11a2+4*$16+$12+0
        rts

// ----------------------------------------------------------------------------
//                      // Sub-function for printing a status message
//                      // - Parameter: $10-$11: message text address

prt_message
        ldx #22-2       // clear content
        lda #$20
l2501	sta $11a2+22+1-1,x
	dex
	bne l2501
        ldy #$00        // count message length
l2502   lda ($10),y
        beq l2503
        iny
        bne l2502
l2503   sty $03de       // calc message offset: 20-len/2
        lda #20
        sec
        sbc $03de
        lsr
        tax
        ldy #$00        // copy message until zero-byte
l2504   lda ($10),y
        beq l2505
        sta $11a2+22+1,x
        iny
        inx
        bne l2504
l2505   rts

// ----------------------------------------------------------------------------
//                      // Sub-function for clearing the status text

clr_message
        ldx #22
l2510   lda l126e-1,x
        sta $11a2+22-1,x
	dex
	bne l2510
        rts

// ----------------------------------------------------------------------------

l1320   .byt $82,$95,$92,$8e,$94,$20    // "BURNT TO DEATH"
        .byt $94,$8f,$20
        .byt $84,$85,$81,$94,$88,$00
l1321   .byt $93,$94,$8f,$8d,$90,$85,$84,$20    // "STOMPED TO DEATH"
        .byt $94,$8f,$20
        .byt $84,$85,$81,$94,$88,$00
l1322   .byt $83,$8f,$8e,$87,$92,$81,$94,$95    // "CONGRATULATIONS"
        .byt $8c,$81,$94,$89,$8f,$8e,$93,$00
l1323   .byt $94,$92,$99,$20            // "TRY AGAIN? (Y/N)"
        .byt $81,$87,$81,$89,$8e,$20
        .byt $a8,$99,$af,$8e,$a9,$00

post_game
        cmp #$01        // check reason for game end
        bne l2401
        lda #<l1320     // print "BURNT TO DEATH"
        sta $10
        lda #>l1320
        sta $11
        jsr prt_message
        clc
        bcc l2403
l2401   cmp #$02
        bne l2402
        lda #<l1321     // print "STOMPED TO DEATH"
        sta $10
        lda #>l1321
        sta $11
        jsr prt_message
        clc
        bcc l2403
l2402   lda #<l1322     // print "CONGRATULATIONS"
        sta $10
        lda #>l1322
        sta $11
        jsr prt_message

l2403   ldx #3*22       // overwrite status boxes with another message box
l2404	lda l1258-1,x
	sta $11a2+3*22-1,x
	dex
	bne l2404

        ldx #$0f
l2408	lda l1323-1,x   // print "TRY AGAIN?"
	sta $11a2+4*22+3,x
	dex
	bne l2408

l2410   lda $cb         // wait for any keypress or joystick
        cmp #$0b        // key 'Y'
        beq l2411
        cmp #$21        // key 'Z'
        beq l2411
        cmp #$1c        // key 'N'
        bne l2410
l2415   lda $cb         // wait for key release
        cmp #$40
        bne l2415
        jmp $e518
l2411   jmp l1400       // restart from scratch

// ----------------------------------------------------------------------------
