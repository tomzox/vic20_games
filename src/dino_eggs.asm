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
_game_base = $1240  // start of ML

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
// $1dXX-$2fff: code section, part 2 (including some read-only data)
//              followed by variable definitions

// ----------------------------------------------------------------------------
// Main control flow:
//
// - $1400: game entry point from BASIC (SYS 5120)
// - main loop: chain of "jmp" starting at tick_player -> tick_stone_fall -> ...
//   and finally back to tick_player
// - game is ended via "rts"

// ----------------------------------------------------------------------------
// Description of data / variables:
//
// $00-$01: player address
// $02-$03: snake address, temp copy of l0358
// $04-$05: -unused- (except during initialization)
// $06-$07: -unused- (except during initialization)
// $08-$09: beam station address
// $0a-$0b: falling stone address, temp copy of l03e4
// $0c-$0d: -unused-
// $0e-$0f: address dino foot
// $10-$11: temp pointer

// $fa-$fe: temp var/pointer

// address of levels on screen:
//  row    addr
// -------------------
//   3     $102c
//   6     $10ee
//  10     $10c6
//  14     $111e
//  18     $1176

// ----------------------------------------------------------------------------
// Enhancement ideas:
// - add sound effects
// - snakes hatching at random times from snake eggs below bases
// - allow picking up eggs from ceiling via F1
// - add spiders crawling above top level, randomly lowering themselves to a level
// - improve dino foot stomping by lifting one row and back
//   OR make async and give player chance to escape
//   OR replace by dino stampede through the level (3x3 chars each)
// - add eggs piled above bases
// - increase difficulty level after won game (e.g. more/faster snake)

// ----------------------------------------------------------------------------
//      Read-only data

        // screen addresses of bases/levels
l1240   .word $1000 + 2*22      // top
        .word $1000 +17*22      // bottom-most
        .word $1000 +13*22      // 2nd from bottom
        .word $1000 + 9*22      // 3rd from bottom
        .word $1000 + 5*22      // 2nd from top
        // numbers of gaps in middle levels (top and bottom have no gaps); one more may be added randomly
        // (dummy zero in-between to allow indexing with 2*X)
l124a   .byt 2,0
        .byt 3,0
        .byt 4,0
        // address of egg directory per base/level, excluding "top" (see above)
l1250   .word v_egg_dir+$16+$16+$16
        .word v_egg_dir+$16+$16
        .word v_egg_dir+$16
        .word v_egg_dir
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

        // carry-status texts
l12da   .byt $20,$97,$8f,$8f,$84,$20    // " WOOD "
l12de   .byt $85,$87,$87,$20            // "EGG "
l12df   .byt $85,$87,$87,$93            // "EGGS"

        // dino mum foot pattern
l133c   .byt $17,$18,$18,$18,$18,$18,$18,$18,$18,$19 // char codes: foot mid/{left,mid,right}
l1346   .byt $1a,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1b,$1c // char codes: foot low/{left,mid,right}

// ----------------------------------------------------------------------------
// fill up to next segment (so that program starts on well-defined address)
// ATTENTION: assembler "xa" will not generate error if the gap has negative size
.dsb $1400 - *, 0
* = $1400

//                      // Program start
l1400	lda #$0e
	sta $900f
	lda #$cf        // screen:$1000, color:$9400, user-def:$1C00
	sta $9005
	lda #$22        // adjust picture offset from top of screen for following increase in height
	sta $9001
	lda #$32        // set screen height to 25 lines
	sta $9003
	jsr $e55f       // clear screen
        jsr init_rand_gen // seed random number generator
        lda #<key_int   // set dummy keyboard interrupt hook
        sta $028f
        lda #>key_int
        sta $0290

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

	ldx #$04        // ---- place gaps in bases ---
l1334	lda $04,x       // get n-th base address from address list
	sta $10         // (starting with 2nd lowest, as lowest must not have gaps)
	lda $05,x
	sta $11
	lda #$00
	sta $fa
	stx $fd         // backup loop counter (X)
        jsr get_rand
	and #$01        // get one RAND bit
        ldx $fd
	clc
	adc l124a,x     // number of gaps in this level from table + random 0 or 1
	sta $fb
l144c	lda #$09        // -- start of loop across number of gaps --
        jsr get_rand_lim  // calc random X-offset in range 2..18
        clc
	adc #$01
	asl
	tay
	lda #$00
	sta $fc
	lda ($10),y     // empty base and no gap yet at this X-off?
	bne l144c       // no -> try again
	dey
	dey
	dey
        bmi l1470
	lda ($10),y
	beq l1470
	lda #$80        // mark there's already a gap 2 to left
	ora $fc
	sta $fc
l1470	iny
	iny
	lda ($10),y
	beq l147c
	lda #$20        // mark there's already a gap 1 to left
	ora $fc
	sta $fc
l147c	iny
	iny
	iny
	lda ($10),y
	beq l1489
	lda #$08        // mark there's already a gap 1 to right
	ora $fc
	sta $fc
l1489	iny
	iny
        cpy #$16
        bcs l1495
	lda ($10),y
	beq l1495
	lda #$02        // mark there's already a gap 2 to right
	ora $fc
	sta $fc
l1495	dey
	dey
	dey
	dey
	lda $fc
	beq l14b7       // no gaps in vincinity -> OK
	and #$28
	beq l14b7       // no directly adjacent gaps -> OK
	lda $fc
	and #$a0
	cmp #$a0
	beq l14b7       // double-wide gap on left side -> OK (i.e. allow enlarging that gap)
	lda $fc
	and #$0a
	cmp #$0a
	beq l14b7       // double-wide gap on right side -> OK (i.e. allow enlarging that gap)
        lda $fa
	bne l144c       // allow ignoring above rules once (i.e. allow one double-wide gap)
        sty $fa
l14b7	lda #$20        // finally create the gap
	sta ($10),y
	iny
	sta ($10),y
	dec $fb         // loop for next gap on this level
	bne l144c
	ldx $fd         // loop for next level
	dex
	dex
	bmi l14cd
	jmp l1334

l14cd	ldx #$00        // --- place ladders between all levels  ---
l13cf	lda $04,x       // get n-th base address from address list
	sta $fd         // this is address of the level containing top of the ladder
	lda $05,x
	sta $fe
	stx $00         // backup iteration counter
l14d9	lda #$16-2      // get random X-offset within the level (1..20)
        jsr get_rand_lim
	clc
	adc #$01
        tay
	lda ($fd),y     // location of ladder-top still empty and no gap?
	bne l14d9
	tya
	clc
	adc #$58
	tay
	lda ($fd),y     // location of ladder-bottom still empty and no gap?
	bne l14d9
	ldx #$04        // loop to draw ladder across 4 rows
l14f6	tya
	sec
	sbc #$16        // one row up: Xoff-=22
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

l1511	ldx #$06        // --- populate egg directory ---
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
	bpl l1527       // next column
	dex
	dex
	bpl l1513       // next level

l15f3	lda #$58        // --- place power gain at random position ---
        jsr get_rand_lim
	tax
	lda v_egg_dir,x     // start of egg directory
	bne l15f3       // blocked -> try again
	lda #$40        // set flag for power gain in egg directory
	sta v_egg_dir,x

	lda #$04        // --- distribute 4 pieces of wood randomly ---
	sta $00
l1558	lda #$58
        jsr get_rand_lim
	tax
	lda v_egg_dir,x
	bne l1558       // try again if position blocked or used already
	lda #$20
	sta v_egg_dir,x     // store code for wood in egg directory
	dec $00
	bne l1558

	lda #$04        // --- distribute 4 snake eggs randomly ---
	sta $00
l155a	lda #$58-$16    // exclude highest base
        jsr get_rand_lim
        clc
        adc #$16
	tax
	lda v_egg_dir,x
	bne l155a       // try again if position blocked or used already
	lda #$08
	sta v_egg_dir,x     // store code for snake egg in egg directory
	dec $00
	bne l155a

	lda #$36         // --- distribute 54 eggs randomly across levels ---
	sta $00
l153a	lda #$58
        jsr get_rand_lim
	tax
	lda v_egg_dir,x     // start of egg directory
	bne l153a       // already used or blocked -> try again
        stx $01
        jsr get_rand
        and #$03
        clc
        adc #$01
        cmp #$03+1      // 3 eggs have P=50%, 1 and 2 P=25% each
        bcc l153c
        lda #$03
l153c   cmp $00
        bcc l153d
        lda $00
l153d   ldx $01
        sta v_egg_dir,x     // put up to 3 eggs here
        eor #$ff
        sec
        adc $00
        sta $00
	bne l153a

	lda #$20        // --- distribute 32 stones randomly (possibly on top of items) ---
	sta $00
l1576	lda #$58
        jsr get_rand_lim
	tax
	lda v_egg_dir,x
	bmi l1576       // position blocked (ladder) -> try again
	ora #$10        // OR stone flag in egg directory (maybe on top of egg or wood)
	sta v_egg_dir,x
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
l15b8   and #$03
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
	bcc l15e4
	lda #$03        // base with wood
	bne l15ea
l15e4   cmp #$08        // snake egg?
	bcc l15e8
	lda #$06        // base with snake egg
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

	ldx #_var_sect_end-_var_sect_start+1  // initialize status variables
	lda #$00        // preset all variables to zero
l1638	sta _var_sect_start+1,x
	dex
	bne l1638

	lda #$20        // initialize char & color under player figure
	sta v_plr_bg_char
        lda #$00
	sta v_plr_bg_col
	lda #$a0
	sta v_fire_timer       // initialize timer for first warning "make a fire"
	lda #$01        // initialize fire status: not burning
	sta v_fire_state

	ldx #$04        // initialize snake addresses
l164f   lda l1240+2,x   // base address
	sec
	sbc #$16        // subtract one row
	sta l0358,x
        lda l1240+2+1,x
        sbc #$00
        sta l0358+1,x
	dex
	dex
	bpl l164f

        lda #$40        // initialize keypress buffers
        sta v_key_prev
        sta v_key_next

        sei             // disable interrupts to get consistent values
        lda $a0         // initial copy of clock counter
        sta v_timestamp
        lda $a1
        sta v_timestamp+1
        lda $a2
        sta v_timestamp+2
        cli

        lda #$00        // create initial snake on lowest level, Xoff=0
        ldx #$00        // base level index
        jsr spawn_snake

        jsr place_player_home

        jmp tick_player // enter main loop (which is a chain of jumps)

// ----------------------------------------------------------------------------
//                      // Sub-function: Place player home at random position

place_player_home
l1670	jsr get_rand    // get RAND number
	and #$03<<1     // select random level (0..3)*2
	tax
	lda l1240+2,x
	sta $fa
	lda l1240+3,x
	sta $fb
        lda #$14
	jsr get_rand_lim  // select random X offset
        clc
	adc #$01
	tay
	lda ($fa),y     // selected position blank?
	cmp #$20
	beq l1670       // no -> try another random position
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
	bne l1670       // no -> try another random position
	dey
	cpy #$16
	bcs l16ac
        lda $fa
	clc
	adc $fd
	sec
	sbc #$16
	sta $00
	lda #$0c        // code for normal player" figure
	jsr draw_player
	ldy #$00
	lda #$1d        // char for home base
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
        rts

        // FIXME do not delete snake char; delete home from snake background
remove_player_home
        lda #$20        // blank character
	ldy #$00
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
        rts

// ----------------------------------------------------------------------------
//                      // Player actions

tick_player
        lda v_plr_jumps
	and #$60
	beq l1745
        jsr undraw_player // --- jump to the left ongoing ---
        jsr get_player_xoff
        cmp #$00        // get current column
        bne l1710
        lda $00         // col 0 -> movement will wrap at left border
        clc
        adc #$16-1
        sta $00
        bne l171a
        inc $01
        bne l171a
l1710	lda $00         // move player one to the left
	bne l1719
	dec $01
l1719	dec $00
l171a	lda #$0e        // char for player facing left side
	jsr draw_player
	lda v_plr_jumps       // determine next stage
	cmp #$40
	beq l172c
	lda #$40        // 1 -> stage 2
	bne l172e
l172c   lda #$00        // 2 -> jump done
l172e	sta v_plr_jumps
	jmp player_status_check

l1745	lda v_plr_jumps
	and #$06
	beq l1780
	jsr undraw_player // --- jump to the right ongoing ---
	inc $00         // player pos one to the right
	bne l175e
	inc $01
l175e   jsr get_player_xoff
        cmp #$00        // column zero, i.e. wrapped at right border?
        bne l1761
        lda $00         // yes -> move one row up
        sec
        sbc #$16
        bcs l1760
        dec $01
l1760   sta $00
l1761   lda #$0f        // char for player facing right side
	jsr draw_player
	lda v_plr_jumps       // determine next stage
	cmp #$04
	beq l176f
        lda #$04        // 2 -> stage 2
        bne l1771
l176f	lda #$00        // jump done (but only sideways part of jump; next: falling)
l1771	sta v_plr_jumps
	jmp player_status_check

l1780	lda v_plr_jumps
	and #$80
	beq l1786
	jsr undraw_player // --- jump upwards ongoing ---
        lda $00         // move player one row up
        sec
        sbc #$16
        bcs l1781
        dec $01
l1781   sta $00
        lda #$0c        // char for player normal shape
	jsr draw_player
        lda #$00        // jump done (but only of jumping stage; next stage: falling)
        sta v_plr_jumps
	jmp player_status_check

l1786   lda v_plr_ladder       // player on ladder?
	bne l17c9       // -> never fall (i.e. even if snake crawls below)
        ldy #$16
	lda ($00),y     // read char in row directly below player
	cmp #$07        // any kind of base?
	bcc l17c9       // yes -> don't fall
        cmp #$11        // any part of a snake?
        bcc l1790
        cmp #$15+1
        bcs l1790
        tya             // yes -> kill snake, then fall into its place
        jsr stomp_snake_player
l1790   ldy #$00        // --- free fall ---
	jsr undraw_player
	lda $00         // move player one row down
	clc
	adc #$16
	bcc l17aa
	inc $01
l17aa	sta $00
        lda #$10        // char for falling player
        jsr draw_player
        inc v_plr_fall_h
        jmp player_status_check

l17c9   lda v_plr_fall_h
        beq l17cb
        cmp #4*2+2      // fallen more than two levels?
        bcc l17ca
        lda #$03        // yes -> fallen to death
	jmp post_game
l17ca   lda #$00        // clear falling row counter
        sta v_plr_fall_h
        jsr activate_snake_player

//                      // ---- actions depending on key-press ----
l17cb   sei
        lda v_key_next       // any key-press detected since action handler?
        cmp #$40
        bne l17cc       // yes -> use that buffered key-press
        lda $cb         // no -> poll currently pressed key
l17cc   sta v_key_cur       // buffer for following processing
        lda #$40
        sta v_key_next
        cli

        lda v_plr_ladder       // player on ladder?
	beq l178e
	jmp l184f       // yes -> skip/disallow jumps
l178e
        lda v_plr_jumps
	cmp #$10        // player moving left?
	bne l1807
        //lda v_key_cur
	//cmp #$11        // key 'A' (left)
	//bne l17d8
	lda $028d       // SHIFT key pressed?
	and #$01
	bne l17df
l17d8	lda $911f       // joystick left or fire?
	and #$30
	bne l1807
l17df	jsr undraw_player // --- trigger jump to the left ---
        jsr get_player_xoff
        cmp #$00        // currently in col 0?
        bne l17f0
        lda $00
	sec             // col-1 will wrap -> subtract one row less from pos
	sbc #$01
	bcc l17f3
	bcs l17f4
l17f0	lda $00         // moving one row up and one col to the left
	sec
	sbc #$17
	bcs l17f4
l17f3	dec $01
l17f4	sta $00
	lda #$0e
	jsr draw_player
	lda #$20        // store direction indicator (needed for allowing jump)
	sta v_plr_jumps
	jmp player_status_check

l1807   lda v_plr_jumps       // player moving right?
	cmp #$01
	bne l184f
        //lda v_key_cur
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
        jsr get_player_xoff
        cmp #$16-1
        bcc l1830
        lda $00
	sec             // col+1 will wrap -> subtract 2 rows
	sbc #$16*2-1
	bcc l1831
	bcs l183c
l1830	lda $00         // moving one row up and one to the right
	sec
	sbc #$16-1
	bcs l183c
l1831	dec $01
l183c	sta $00
	lda #$0f
	jsr draw_player
	lda #$02        // store jump status
	sta v_plr_jumps
	jmp player_status_check

l184f	lda v_plr_ladder       // on ladder
        beq l1851
        lda v_plr_bg_char
        cmp #$0a        // yes -> allow left/right only on middle part of ladder
        bne l187f

l1851	lda v_key_cur
	cmp #$11        // key 'A' (note: allow SHIFT being pressed already)
	beq l1861
	lda $911f       // joystick left?
	and #$10
	bne l18ba
l1861	jsr undraw_player
	lda $00         // player one to the right
	bne l186c
	dec $01
l186c	dec $00
	lda #$10
	sta v_plr_jumps
	lda #$0e
	jsr draw_player
	jmp player_status_check

l18ba	lda v_key_cur
	cmp #$29        // key 'S' (note: allow SHIFT being pressed already)
	beq l18d6
	lda #$7f
	sta $9122
	lda $9120       // joystick right?
	and #$80
	bne l187f
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
	sta v_plr_jumps
	jmp player_status_check

l187f	lda v_key_cur
	cmp #$09        // key 'W' (up)
	beq l188c
	lda $911f       // joystick up?
	and #$04
	bne l1903
l188c	lda v_plr_bg_char       // check char below player
	cmp #$0a        // ladder?
	beq l1897
	cmp #$05        // base with ladder?
	bne l193d       // neither -> stop climbing
l1897	lda #$01        // --- climbing up ---
        sta v_plr_ladder
        jsr undraw_player
	lda $00         // move player up one row
	sec
	sbc #$16
	bcs l18a5
	dec $01
l18a5	sta $00
	lda #$0d        // draw climbing player figure
	jsr draw_player
l18b3   jmp player_status_check

l1903	lda v_key_cur
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
	bne l193d       // neither -> stop climbing
l191e	lda #$01        // --- climbing down ---
        sta v_plr_ladder
	jsr undraw_player
	lda $00         // move player one row down
	clc
	adc #$16
	bcc l192f
	inc $01
l192f	sta $00
        lda #$0d        // draw player; climbing form
        jsr draw_player

        ldy #$16        // check char one row below player
        lda ($00),y
        cmp #$06+1      // any kind of base?
        bcs l1930
l193d   ldy #$00        // stop climbing
	sty v_plr_ladder       // clear ladder status
	lda #$0c        // change already drawn player figure to "normal"
	sta ($00),y
        jsr activate_snake_player
l1930   jmp player_status_check

l1944	lda v_key_cur
	cmp #$27        // key F1?
	beq l1951
	lda $911f       // joystick xxx?
	cmp #$5e
	bne l196e
l1951	lda v_plr_ladder       // player climbing up/down ladder?
        bne l196e       // yes -> do not allow jump
        lda v_plr_bg_char
	cmp #$0a        // ladder behind player?
	bne l1958
        jmp l1897       // yes -> handle equiv. regular "up" movement
l1958   lda $00         // --- trigger jump upwards ---
        sta $10         // determine on which level player is standing
        lda $01
        sta $11
        jsr get_base_idx_and_xoff
        bcc l196e       // not standing on a base -> abort
        cpx #$03*2      // in top-most level?
        bcs l1961       // yes -> jump only one row (height is one less than in other levels)
        lda #$80        // no -> set jump status to continue upwards movement in next iteration
	sta v_plr_jumps
l1961   jsr undraw_player
	lda $00
        sec
	sbc #$16        // move player up only by one row
	bcs l1963
        dec $01
l1963	sta $00
	lda #$0c        // draw player figure; normal form
	jsr draw_player
        jmp player_status_check

l196e	lda v_key_cur
        cmp v_key_prev       // skip if F7 key not released since last processed
        beq l196f
	cmp #$3f        // key F7?
	beq l197e
	cmp #$20        // space key? (added for emulator)
	beq l197e
l196f   lda $911f       // joystick xxx?
	and #$28
	beq l197e
	jmp player_no_action

                        // --- check F7 in home base? ---
l197e	ldy #$17        // check if player at home:
	lda ($08),y
	cmp #$0c        // player figure (any shape) at home position?
	bcc l19ae       // no -> abort
	cmp #$11
	bcs l19ae
                        // FIXME must allow less eggs left overall
        lda v_plr_carry       // carrying at least 6 eggs?
        and #$7f
        cmp #$06
        bcc l19ae       // no -> abort
	lda v_fire_state
	cmp #$08        // player attacked by dino mum?
	bcs l19ae       // yes -> abort
        jsr undraw_player
        jsr remove_player_home
        lda #$00        // clear power gain
	sta v_plr_power
	lda v_plr_carry       // add number of carried eggs to score
	and #$7f
        beq l19a0
        jsr add_score
        lda #$00
        sta v_plr_carry       // reset egg counter
        jsr prt_egg_status
        lda v_plr_score       // all eggs picked up? (assuming one point is scored per egg)
        cmp #$54        // binary $36 <=> decimal (BCD) 54 (ignore third nibble in v_plr_score+1)
        bne l19a0
        lda #$00        // yes -> game won!
        jmp post_game
l19a0   jsr place_player_home // -> move home & player to random position
        jmp player_status_check

                        // --- F7 to pick up wood (& light fire)? ---
l19ae	ldy #$16        // read char one row below player
	lda ($00),y
	cmp #$03        // base with wood under player?
	bne l1a61
	lda v_plr_carry       // get player carry status
	bmi l19b2       // already carrying wood -> try making a fire here
	and #$7f        // player already carrying eggs?
	bne l19b1       // yes -> abort
        lda #$00        // remove wood (i.e. draw empty base)
	sta ($00),y
	lda #$80        // remember carrying wood
	sta v_plr_carry
        jsr prt_egg_status
l19b1	jmp player_status_check
l19b2	jmp l19d8

                        // --- F7 to pick up eggs? ---
l1a61	ldy #$16        // read char 1 row below player
	lda ($00),y
	cmp #$01        // char for base with egg?
	bne l1b2d       // no -> no eggs for picking up here
        lda v_plr_carry
        bmi l1a80       // carrying wood -> abort
	lda v_plr_power       // power gain?
	beq l1a65
        lda #24         // yes -> max higher
        bne l1a66
l1a65   lda #$06        // no -> max lower
l1a66   sec
        sbc v_plr_carry       // subtract number of already carried eggs
        beq l1a80
        bcs l1a90
l1a80   lda #<l1317     // zero or negative -> print "TOO HEAVY"
        sta $10
	lda #>l1317
        sta $11
        jsr prt_message
	jmp player_status_check
l1a90   tax
l1a91   ldy #$2c
	lda ($00),y     // read char 2 rows below player
	cmp #$08        // char for two eggs?
	bne l1a6d
	lda #$07        // yes -> change to one egg
	bne l1a7f
l1a6d	cmp #$07        // char for one egg?
	bne l1a75
	lda #$20        // yes -> change to empty
	bne l1a7f
l1a75	lda #$00        // yes -> change to empty base
        ldy #$16
l1a7f   sta ($00),y     // draw char with one egg less
	inc v_plr_carry       // increment player's egg counter
        ldy #$16
	lda ($00),y
	cmp #$01        // char for base with egg?
        bne l1a81       // no eggs left -> done
        dex
        bne l1a91       // iterate until max. no. of carried eggs reached
l1a81   jsr prt_egg_status
	jmp player_status_check

                        // --- F7 to pick up power-gain? ---
l1b2d	ldy #$16        // read char one row below player
	lda ($00),y
	cmp #$04        // base with power gain?
	bne l1b55
	sta v_plr_power       // enable power gain
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
l1b52	jmp player_status_check

l1b55	cmp #$02        // base with stone?
	bne l1b58
        jsr start_stone_fall
	jmp player_status_check

l1b58	cmp #$06        // base with snake egg?
	bne l1a23
        lda #$04
	jmp post_game   // death by snake bite

                        // --- F7 to drop carried egg or wood? ---
l1a23	cmp #$00        // empty base under player?
	bne l1b52       // no -> abort; cannot handle F7
	lda v_plr_carry       // player carrying wood?
	bpl l1a4e
	ldy #$16        // put down wood
	lda #$03
	sta ($00),y
	lda #$00        // clear carry status
	sta v_plr_carry
        jsr prt_egg_status
	jmp player_status_check

l1a4e	lda v_plr_carry       // player carrying any eggs?
	beq l1b52       // no -> abort
        lda #$01        // at least one egg -> replace empty base char with base with egg
        sta ($00),y
        dec v_plr_carry
        lda v_plr_carry
        beq l1af9       // no more eggs left -> done
        cmp #$02
        bcs l1af0       // goto >=2 eggs
        lda #$07        // char for one egg
        bne l1af8
l1af0   lda #$08        // char for two eggs
        dec v_plr_carry
l1af8	dec v_plr_carry
        ldy #$2c
        sta ($00),y     // write char below base
l1af9	jsr prt_egg_status
	jmp player_status_check

                        // --- try lighting a fire ---
l19d8	lda v_plr_bg_char
	cmp #$20        // blank behind player?
	bne l1a20       // no -> cannot make fire here
        ldx #$00        // determine index for storing fire address
        lda v_fire_adr+1     // fire #1 active?
        beq l19e0
        lda v_fire_adr+1+2   // fire #2 active?
        bne l1a20       // yes -> two fires already active -> cannot make another fire
        ldx #$02        // no; use fire address #2
l19e0   ldy #$16        // remove wood (i.e. draw empty base below player)
        lda #$00
	sta ($00),y
	lda #$1e        // fire char behind player (to be drawn when player moves)
	sta v_plr_bg_char
	lda #$07        // color yellow behind player
	sta v_plr_bg_col
	lda #$20        // start fire immunity counter
	sta v_plr_immun
	lda #$00        // clear carry status
	sta v_plr_carry
	sta v_fire_state       // fire status: burning
        lda $00
	sta v_fire_adr,x     // store address of digit under fire
	sta $10         // copy to ZP for writing through pointer
	lda $01
	sta v_fire_adr+1,x
	sta $11
	ldy #$2c
	lda #$b9        // print digit '9' below base below fire (timer display)
	sta ($10),y
        lda $11         // calc color address: +$9400 -$1000
        clc
        adc #$94-$10
        sta $11
        lda #$07
	sta ($10),y
        // index X invalid below
        jsr prt_egg_status  // update display for carry status
        lda #<l12e3     // print "FIRE IS BURNING"
        sta $10
        lda #>l12e3
        sta $11
        jsr prt_message
l1a20	jmp player_status_check


// ----------------------------------------------------------------------------
// User-defined characters
// - 32 user-defined characters, 8x8 bit each
// - must start at $1c00, where the data is read by VIA HW (register $9005)
// - note address is selected so that char codes $80-$ff are mapped to
//   reverse character definitions in ROM (i.e. address cannot be changed!)

// fill up possible gap before fixed start address of this section
// ATTENTION: assembler "xa" will not generate error if the gap has negative size
.dsb $1c00 - *, 0
* = $1c00

l1c00	.byt $ff,$88,$55,$22,$00,$00,$00,$00    // #$00: Base
	.byt $ff,$88,$55,$22,$3e,$7f,$7f,$3e    // #$01: Base with egg
	.byt $ff,$88,$55,$22,$1c,$2a,$51,$43    // #$02: Base with stone
	.byt $ff,$88,$55,$22,$7f,$7f,$27,$60    // #$03: Base with wood
	.byt $ff,$88,$55,$22,$41,$22,$14,$5d    // #$04: Base with power gain
	.byt $ff,$88,$55,$22,$41,$7f,$41,$41    // #$05: Base with ladder
	.byt $ff,$88,$55,$22,$3c,$6a,$56,$3c    // #$06: Base with snake egg
	.byt $3e,$7f,$7f,$3e,$00,$00,$00,$00    // #$07: one egg
	.byt $3e,$7f,$7f,$3e,$3a,$7f,$7f,$3e    // #$08: two eggs
	.byt $65,$51,$43,$49,$61,$55,$26,$1c    // #$09: stone lower half (under base)
	.byt $41,$7f,$41,$41,$41,$7f,$41,$41    // #$0a: ladder
	.byt $3e,$36,$36,$3e,$5d,$14,$22,$41    // #$0b: power gain below
	.byt $1c,$1c,$08,$7f,$49,$dd,$14,$36    // #$0c: player normal
	.byt $dc,$5c,$49,$7f,$08,$3c,$64,$06    // #$0d: player climbing
	.byt $1c,$5c,$48,$7e,$0b,$3d,$22,$66    // #$0e: player walking left
	.byt $38,$3a,$12,$7e,$d0,$bc,$44,$66    // #$0f: player walking right
	.byt $5d,$5d,$49,$7f,$08,$1c,$14,$14    // #$10: player falling
	.byt $07,$07,$04,$78,$80,$7e,$01,$fe    // #$11: snake coiled up
        .byt $00,$00,$00,$00,$00,$30,$49,$86    // #$12: snake v1 tail (left)
        .byt $00,$00,$00,$70,$70,$80,$00,$00    // #$13: snake v1 head (right)
        .byt $00,$00,$00,$00,$02,$05,$08,$08    // #$14: snake v2 tail (left)
        .byt $00,$00,$00,$07,$07,$08,$90,$60    // #$15: snake v2 head (right)
	.byt $00,$00,$00,$00,$1c,$2a,$51,$43    // #$16: stone upper half (w/o base)
	.byt $21,$24,$29,$24,$20,$2a,$24,$21    // #$17: dino foot mid/left
	.byt $20,$8a,$40,$09,$a0,$15,$40,$15    // #$18: dino foot mid/mid
	.byt $84,$24,$44,$14,$44,$04,$a4,$04    // #$19: dino foot mid/right
	.byt $20,$60,$d0,$d0,$c8,$67,$70,$00    // #$1a: dino foot low/left
	.byt $40,$8a,$40,$00,$00,$c7,$7c,$00    // #$1b: dino foot low/mid
	.byt $44,$14,$44,$14,$06,$8e,$fe,$00    // #$1c: dino foot low/right
l1ce8	.byt $aa,$00,$55,$00,$aa,$00,$55,$00    // #$1d: home - ROR'ed at run-time
l1cf0	.byt $00,$00,$00,$00,$00,$00,$00,$00    // #$1e: fire - written/toggled at run-time
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // #$1f: UNUSED
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // #$20: blank

// player figure:
// -climbing-   -falling-
// xx.xxx..     .x.xxx.x
// .x.xxx..     .x.xxx.x
// .x..x..x     .x..x..x
// .xxxxxxx     .xxxxxxx
// ....x...     ....x...
// ..xxxx..     ...xxx..
// .xx..x..     ...x.x..
// .....xx.     ...x.x..

// fire v1         v2
// ....*...        ........
// ..*.*...        ........
// *.*.*..*        ...*.*..
// *.***..*        .*.**..*
// .******.        ..***.*.
// ..****..        ..****..
// ...**...        ...**...
// .******.        .******.
l1ca8_0 .byt $08,$28,$69,$b9,$7f,$3c,$18,$7e    // #$1e: fire v1
l1ca8_1 .byt $00,$00,$14,$59,$3a,$3c,$18,$7e    // #$1e: fire v2

// snake: tail+head (v1) (v2)                   coiled          base+snake egg
// ........|........    ........|........       .....xxx        xxxxxxxx
// ........|........    ........|........       .....xxx        x...x...
// ........|........    ........|........       .....x..        .x.x.x.x
// ........|.xxx....    ........|.....xxx       .xxxx...        ..x...x.
// ........|.xxx....    ......x.|.....xxx       x.......        ..xxxx..
// ..xx....|x.......    .....x.x|....x...       .xxxxxx.        .xx.x.x.
// .x..x..x|........    ....x...|x..x....       .......x        .x.x.xx.
// x....xx.|........    ....x...|.xx.....       xxxxxxx.        ..xxxx..

// Dino foot (claw)
// ..x....x|..x.....|x....x..
// ..x..x..|x...x.x.|..x..x..
// ..x.x..x|.x......|.x...x..
// ..x..x..|....x..x|...x.x..
// ..x.....|x.x.....|.x...x..
// ..x.x.x.|...x.x.x|.....x..
// ..x..x..|.x......|x.x..x..
// ..x....x|...x.x.x|.....x..

// ..x....x|xx......|.x...x..
// .xx...x.|x...x.x.|...x.x..
// xx.x...x|.x......|.x...x..
// xx.x....|........|...x.x..
// xx..x...|........|.....xx.
// .xx..xxx|xx...xxx|x...xxx.
// .xxx....|.xxxxx..|xxxxxxx.
// ........|........|........

// perl -pe 'tr /\.x\|/01 /d;s/([01]{8})/sprintf("\$%02x,", oct("0b$1"));/ge;'

// ----------------------------------------------------------------------------
//                      // --- player status handling ---
// Note this section has two alternate entry points

player_no_action        // no player action (i.e. no key/joystick input)
        lda #$00
	sta v_plr_jumps       // -> clear direction to "not moving"
        ldy #$00
	lda ($00),y
        cmp #$10
        bne player_status_check
        lda #$0c        // change player figure from falling to normal
        sta ($00),y

player_status_check     // jumped to after player actions (e.g. key input)
	lda v_plr_ladder       // player on ladder?
	beq l1e2f
	lda v_plr_bg_char       // check char behind player
	cmp #$05
        beq l1e2f
	cmp #$0a
	beq l1e2f
	ldy #$00
	sty v_plr_ladder       // blank -> clear ladder status
	lda #$0c        // redraw player figure as "normal"
	sta ($00),y
        jsr activate_snake_player

l1e2f   lda v_plr_immun       // immunity counter running?
	beq l1e30
	dec v_plr_immun       // decrement immunity counter

l1e30   lda v_plr_bg_char
	cmp #$1e        // player standing in fire?
	bne l1e44
	lda v_plr_immun       // fire immunity timer still running?
	bne l1e50
	ldy #$2c        // immunity timeout
	lda ($00),y
	cmp #$b2        // '2'
	bcc l1e50
        lda #$01
	jmp post_game   // burnt to death
l1e44   cmp #$11        // player moved into any part of a snake?
        bcc l1e50
        cmp #$15+1
        bcs l1e50
        lda #$04
	jmp post_game   // death by snake bite

l1e50                   // --- end player status // next: timer actions ---
        lda v_key_cur
        sta v_key_prev       // remember last processed key for filtering

	lda #$ff        // configure $9120 for input (i.e. allow querying if joystick right)
	sta $9122

        sec             // --- time delay ---
        lda $a2         // initially calc delta of full 24 bit counter
        sbc v_timestamp+2       // discarding result of MSB delta
        lda $a1
        sbc v_timestamp+1
        bne l1e10       // delta more than 256 -> skip delay loop
        lda $a0
        sbc v_timestamp
        bne l1e10
l1e0f   lda $a2         // delay loop: poll clock counter
        sec
        sbc v_timestamp+2
        cmp #$05        // ignore underflow - LSB delta valid anyway
        bcc l1e0f
l1e10   sei             // disable interrupts to get consistent values
        lda $a0         // take new copy of clock counters
        sta v_timestamp
        lda $a1
        sta v_timestamp+1
        lda $a2
        sta v_timestamp+2
        cli

        lda v_msg_timer       // message timer running?
        beq l1e59
        dec v_msg_timer       // decrement timer
        cmp #$01
        bne l1e59
        jsr clr_message

l1e59	ldx #$08        // rotate home char definition by one bit right: shimmering effect
l1e5b	lda l1ce8-1,x
	lsr
	bcc l1e64
	ora #$80
l1e64	sta l1ce8-1,x
	dex
	bne l1e5b

	lda v_main_timer       // fire char definition: toggling for flickering effect
        and #$01
        bne l1e66
        ldx #$08        // copy char variant #1
l1e65   lda l1ca8_0-1,x
        sta l1cf0-1,x
	dex
	bne l1e65
	beq l1e67
l1e66   ldx #$08        // copy char variant #2
l1e68   lda l1ca8_1-1,x
        sta l1cf0-1,x
	dex
	bne l1e68

l1e67   inc v_main_timer       // increment game loop counter

        lda v_fire_state       // fire burning?
	bne l1ef1
        lda v_main_timer
        and #$7f
        bne l1ef1
        ldx #$00        // --- maintain digits under fire ---
        stx $fb
l1e70   lda v_fire_adr,x     // copy address of fire char to ZP
        sta $10
        lda v_fire_adr+1,x   // this fire active?
        beq l1e71       // no -> skip to next
        sta $11
	ldy #$2c
	lda ($10),y     // update fire status display: -1
	sec
	sbc #$01
	sta ($10),y
        cmp $fb         // determine max digit value across both fires
        bcc l1e72
        sta $fb
l1e72   cmp #$b0        // digit now '0'? AKA is fire out?
        bne l1e71
        //lda v_plr_bg_char       // fire char behind player?  FIXME compare addresses
	//cmp #$1e
	//bne l1ec6
	//lda #$20        // replace player background with blank (i.e. clear fire char)
	//sta v_plr_bg_char
	//bne l1ecc
l1ec6	ldy #$00        // remove fire char
	lda #$20
	sta ($10),y
l1ecc	ldy #$2c        // clear digit below fire
	sta ($10),y
        lda #$00
        sta v_fire_adr+1,x   // invalidate address to mark fire as inactive
l1e71   inx             // loop across 2 fires
        inx
        cpx #$04
        bcc l1e70

        lda $fb         // check combined fire status
        cmp #$b1        // '1'?
	beq l1eb0
        cmp #$b0        // '0'?
	beq l1eb4
	jmp tick_stone_fall

l1eb0	lda #<l130d     // print "FIRE IS GOING OUT"
        sta $10
	lda #>l130d
        sta $11
        jsr prt_message
        lda #$20
	sta v_plr_immun
	jmp tick_stone_fall

l1eb4	lda #$01        // new fire status: "make a fire"
	sta v_fire_state
	lda #$fe        // timer for issuing next warning message
	sta v_fire_timer
	ldx #$0b-2
        lda #<l12e4     // print "FIRE IS OUT"
        sta $10
        lda #>l12e4
        sta $11
        jsr prt_message
        lda #$20
	sta v_plr_immun
	jmp tick_stone_fall

l1ef1	lda v_fire_state
	and #$f8
	beq l1efb
	jmp l1f9c       // to "dino mum actions"
l1efb	lda v_fire_timer       // timer running?
	bne l1f03
l1f00	jmp tick_stone_fall
l1f03	dec v_fire_timer       // counter up to status message
	bne l1f00
l1f08	lda v_fire_state
	beq l1f00       // fire burning -> nothing to do
l1f0d	cmp #$01        // fire status 1? (fire freshly out)
	bne l1f2e
	lda #<l12ed     // print "MAKE A FIRE"
        sta $10
	lda #>l12ed
        sta $11
        jsr prt_message
	lda #$02        // new fire status
	sta v_fire_state
	lda #$f0        // counter up to next fire warning
	sta v_fire_timer
l1f26	lda #$20
	sta v_plr_immun
	jmp tick_stone_fall

l1f2e	cmp #$02        // fire status 2?
	bne l1f49
	lda #<l12f8     // print "DINO MUM COMING"
        sta $10
	lda #>l12f8
        sta $11
        jsr prt_message
	lda #$d0
	sta v_fire_timer
	lda #$04
	sta v_fire_state
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
	lda $00         // get LSB of player address
l1f70	sec             // calc Yoff/22 via iteration
l1f71	sbc #$16
	bcs l1f71
	dec $0f
	bpl l1f70
	clc
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
	sta v_fire_state
        // fall-through

// ----------------------------------------------------------------------------
//                      // --- dino mum actions ---
//                      // This is a "busy loop" animating a huge foot stomping
//                      // down on the player figure (i.e. nothing else can move
//                      // concurrently, esp. player cannot flee).

l1f9c	lda v_fire_state       // attack ongoing?
	cmp #$10
	bcc l1fa0
	jmp l2030       // -> raise foot

l1fa0	lda #18         // start iteration for foot lowering: MAX to row of lowest base
	sta $fa
        lda $0e         // backup Xoff of foot (left side)
        sta $fb
l1faa	ldy #$09
l1fb0	lda l133c,y     // foot pattern (higher row, i.e. middle part)
	sta ($0e),y     // foot +1 row
	dey
	bpl l1fb0
	lda $0e         // advance pointer by one row
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
        lda $0e         // calc color address: +$9400 -$1000
        sta $10
        lda $0f
        clc
        adc #$94-$10
        sta $11
	ldy #$09
l1fce	lda ($0e),y
	sta ($22),y     // backup chars behind by foot to $0800-...
	cmp #$0c        // stomping onto player figure? (in any shape, i.e. #$0c...#$0f)
	bcc l1fde
	cmp #$11
	bcs l1fde
	lda #$00        // yes -> player dead
	sta $01
l1fde	lda l1346,y     // foot pattern (lower row, i.e. sole of foot)
	sta ($0e),y
        lda #$01        // color: white
	sta ($10),y
	dey
	bpl l1fce

	ldy #$16+09     // loop to check for base char in row below foot
l1fe0	lda ($0e),y
	cmp #$07        // base char (range #$00-$06)?
	bcc l2001       // found base char
        dey
        cpy #$09
        bcs l1fe0
        bcc l201a       // not found -> continue stomping into next row
l2001
        lda $0f         // calc address of start of screen row containing foot sole (i.e. address of Xoff:0)
        sta $11
        lda $0e
        sec
        sbc $fb
	bcs l2002
	dec $11
l2002	sta $10
        lda $01         // compare foot row address with player address
        cmp $11
        bcc l2024       // MSB player < foot -> end iteration
        bne l201a       // MSB ">" -> continue
        lda $00
        cmp $10
        bcc l2024       // LSB player < foot -> end iteration

l201a	ldy #$20        // time delay
l2011	ldx #$ff
l2012	dex
	bne l2012
l2013	dey
	bne l2011
        dec $fa         // next iteration foot lowering
        beq l2024
	jmp l1faa

l2024   lda #$10        // fire status $10
	sta v_fire_state
	lda $01         // player dead?
	bne l2030       // no -> raise foot
        lda #$02
	jmp post_game   // stomped to death

//                      // --- foot raising ---
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
	dec $0f
l204d	sta $0e
	lda $0f         // foot back in first row?
	cmp #$10
	bne l2030
	lda $0e
	cmp #$16
	bcs l2030
	ldx #$16        // clear first row
	lda #$20
l206e	sta $1000,x
	dex
	bpl l206e

	jsr get_rand    // get RAND number
	ora #$1f        // OR lower bits to ensure minimum time delay 31
	sta v_fire_timer       // time until next attack
	lda #$04        // fire status back to 4
	sta v_fire_state
	lda #$01
	sta v_plr_immun
	jsr clr_message
	jmp tick_stone_fall

// ----------------------------------------------------------------------------
//                      // Stone fall tick function

tick_stone_fall
        ldx #$00        // loop across all instances of falling stones
l1d09   lda l03e0,x
        bne l1d01
        jmp l1dee       // inactive -> skip this instance

l1d01   stx $fa         // backup X = loop index
        lda l03e4,x     // copy screen address to pointer in ZP
	sta $0a
        lda l03e4+1,x
	sta $0b

        lda l03e0,x     // get instance state
        cmp #$01
        bne l1d02
        lda $0a         // --- start loop for falling stone ---
	sta $10         // temp copy of address for sub-function
        lda $0b
	sta $11
        jsr get_base_idx_and_xoff
        bcs l1d11
        ldx $fa
        lda #$00
        sta l03e0,x
        jmp l1dee       // abort if player is not directly above a base (should never happen)
l1d11   tay
	lda l1250,x
	sta $10
	lda l1250+1,x
	sta $11
	lda ($10),y     // query egg directory for content previously hidden by stone
        ldx $fa
        sta l03e1,x     // store result
        cmp #$40
        bcc l1d40
	lda #$04        // char for base with power-gain
	bne l1d4d
l1d40	and #$2f
	cmp #$10
	bcc l1d46
	lda #$03        // char for base with wood
	bne l1d4d
l1d46	cmp #$08
	bcc l1d47
	lda #$06        // char for base with snake egg
	bne l1d4d
l1d47	cmp #$01
	bcc l1d4d
	lda #$01        // char for base with egg
l1d4d	ldy #$16
	sta ($0a),y     // draw new base char
        lda $0a         // calc color address: ($00) + $9400 -$1000
        sta $10
        lda $0b
        clc
        adc #$94-$10
        sta $11
	ldy #$2c        // offset to row below base
	lda #$16        // char for upper half of stone without base
	sta ($0a),y
        lda #$01        // color: white
	sta ($10),y
	ldy #$42        // offset two rows below base
	lda ($0a),y
	cmp #$20        // room for lower half of stone?
	bne l1d63
	lda #$09        // draw lower half of stone
	sta ($0a),y
        lda #$01        // color: white
	sta ($10),y

l1d63   lda #$02        // continue stone-fall in next iteration
        sta l03e0,x
        jmp l1dec

l1d02   cmp #$02        // --- second stage: stone two rows below base ---
        bne l1dd0

	lda l03e1,x     // query egg directory again for drawing row below base
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

	lda $0a         // address of upper-half of stone
	clc
	adc #$42
	bcc l1d8a
	inc $0b
l1d8a	sta $0a
        lda #$03        // fall-through to third stage
        sta l03e0,x
        bne l1d8c

l1dd0	ldy #$00        // --- third stage: stone 3 or more rows below ---
        lda #$20
	sta ($0a),y     // remove upper half of stone
	lda $0a         // move stone pointer one row down
	clc
	adc #$16
	bcc l1dd3
	inc $0b
l1dd3	sta $0a

l1d8c	ldy #$00
	lda ($0a),y     // read char below new base
	cmp #$09        // is lower half of stone? (written by previous iteration)
	beq l1dac       // yes -> continue stone-fall
	cmp #$20        // blank? -> continue
	beq l1dac
        cmp #$11        // is any part of a snake?
        bcc l1d90
        cmp #$15+1
        bcs l1d90
        lda $0a         // yes -> kill snake
        sta $10
        lda $0b
        sta $11
        jsr stomp_snake_addr
        ldx $fa
        bcs l1d8c       // snake found -> check char below stone again
        bcc l1de0       // no snake matched (should never be reached)

l1d90   cmp #$1e        // is fire hit by stone?
	bne l1dd8       // no (and not blank) -> stop stone fall
	ldy #$2c        // yes -> nearly extinguish fire
	lda #$b2        // set fire counter to '2'
	sta ($0a),y
	lda #$ff        // manipulate timer to make fire counter decrement immediately
	sta v_main_timer
	bne l1de0       // end stone fall

l1dac	lda #$16        // draw upper half of stone
	sta ($0a),y
	ldy #$16
	lda ($0a),y
	cmp #$20        // still blank one row below?
	bne l1dbc
	lda #$09        // yes -> draw lower half of stone
	sta ($0a),y
        lda $0a         // calc color address: ($00) + $9400 -$1000
        sta $10
        lda $0b
        clc
        adc #$94-$10
        sta $11
        lda #$01        // color: white
	sta ($10),y
l1dbc	jmp l1dec       // continue stone fall in next iteration

l1dd8   lda $0a         // undo last subtraction: pointer into row above base
	sec
	sbc #$16
	bcs l1dd9
	dec $0b
l1dd9	sta $0a

        lda l03e1,x     // check egg directory of base/level above
        and #$ff-$10    // anything below stone?
        bne l1de0
	jsr get_rand    // get RAND number: randomly spawn snake on this level
        cmp #$66        // probability ~40%
        bcs l1de0
        lda $0a
        sta $10
        lda $0b
        sta $11
        jsr get_base_idx_and_xoff
        bcc l1de0
        jsr spawn_snake

l1de0   ldx $fa
        ldy #$16
        lda ($0a),y
	cmp #$02        // stone hit base with stone?
	bne l1de1
        lda #$01        // yes -> new stone fall at current position
        bne l1de2
l1de1   lda #$00        // no -> end stone fall
l1de2   sta l03e0,x

l1dec	lda $0a
        sta l03e4,x
        lda $0b
        sta l03e4+1,x
l1dee	inx
        inx
        cpx #$02+1      // next falling stone
        bcs l1def
        jmp l1d09

l1def   jmp tick_snakes

// ----------------------------------------------------------------------------
// Sub-function for starting a stone-fall, usually triggered by user.
// The function silently ignores if the max. number of falling stones is
// already reached (i.e. the stone will remain unchanged in that case).
//
// Parameters: global $00-$01: player position (read-only)
// Side-effects: invalidates X

start_stone_fall
        ldx #$00
l1df0   lda l03e0,x     // stone instance already active?
        bne l1df1       // yes -> try next
        lda $00         // store screen start address, equal player address
	sta l03e4,x
	lda $01
	sta l03e4+1,x
        lda #$01        // set initial state
        sta l03e0,x
        rts
l1df1   inx
        inx
        cpx #$02+1      // max. no of instances reached?
        bcc l1df0
        rts

// ----------------------------------------------------------------------------
//                      // Snake main tick, animating all snake instances


tick_snakes
	ldx #$04        // iterate across snake instances: X:=4->2->0
        stx $fa         // backup iteration index
l2101   lda l0358,x     // copy snake (base) address to $02-$03
        sta $02
        sta $10
        lda l0358+1,x
        sta $03
        clc             // calc color (base) address $10-$11
        adc #$84
        sta $11
        lda l0352,x     // get snake status
        bne l2107
l2108   jmp l2102       // inactive state -> skip this snake instance

l2107   cmp #$01        // in coiled up state?
        bne l2105
//                      // ---- coiled-up state ----
        dec l035e+1,x     // decrement timer
        bne l2108       // not zero -> no further action
        ldy l0353,x
        cpy #$16-1      // at right-most border?
        bcc l2104
        ldy #$00        // yes -> check if fire is right of border
        lda ($02),y
        cmp #$1e
        beq l2108       // yes -> keep waiting
        ldy l0353,x
        lda l035e,x     // restore char under snake
        sta ($02),y
        lda l0364,x
        sta ($10),y
        lda #$00        // move to Xoff := 0
        tay
        sta l0353,x     // store new Xoff
        lda ($02),y     // backup char under new Xoff
	cmp #$0c        // player figure next to coiled snake? (in any shape, i.e. #$0c...#$0f)
	bcc l210a
	cmp #$11
	bcc l2112
l210a   sta l035e,x     // (NOTE l035e+1 initialized below)
        lda ($10),y
        sta l0364,x
        clc
        bcc l2104

l2105   cmp #$02        // ---- moving v1: by one col ----
        bne l2106
        ldy l0353,x
        lda l035e,x     // delete snake tail from old position
        sta ($02),y
        lda l0364,x     // restore background color
        sta ($10),y
        iny
        lda l035e+1,x     // move head background to tail background
        sta l035e,x
        lda l0364+1,x
        sta l0364,x
        cpy #$16-1      // snake tail reached right-most column?
        bcs l2110       // -> coil up
        tya
        sta l0353,x     // store new Xoff
l2104
        lda #$12        // char for snake tail (v1)
        sta ($02),y     // draw snake tail at new pos (former head pos)
        lda #$04        // update color too (needed only in case of uncoiling)
        sta ($10),y
        iny
        lda ($02),y     // read background char at snake head
	cmp #$0c        // reaching player figure? (in any shape, i.e. #$0c...#$0f)
	bcc l2109
	cmp #$11
	bcc l2112
l2109   cmp #$1e        // reached burning fire?
        beq l2111       // yes -> coil up to left of fire
        cmp #$09        // hit falling stone? (lower half)
        beq l2111
        cmp #$16        // hit falling stone? (upper half)
        beq l2111       // yes -> wait here until stone has passed (simplification; moving objects shall never cross paths)
        sta l035e+1,x     // no -> new pos OK, store bg char
        lda ($10),y
        sta l0364+1,x
        lda #$13        // char for snake head (v1)
        sta ($02),y
        lda #$04
        sta ($10),y
        lda #$03        // toggle to moving state v2
        sta l0352,x
        bne l2102

l2112   lda #$04        // player bitten by snake
        // FIXME draw snake next to player (to make cause visible)
        jmp post_game

l2111   dey
l2110                   // ---- coiling up again ----
        lda #$11        // char for coiled up snake
        sta ($02),y
        lda #$01        // set state to coiled-up
        sta l0352,x
        tya
        sta l0353,x     // store Xoff
        jsr is_player_same_level  // player currently on same base?
        bcc l2161
        lda #$04        // yes -> minimal time until uncoiling
        bne l2162
l2161   lda #$40        // no -> longer time
l2162   sta l035e+1,x
        clc
        bcc l2102

l2106   cmp #$03
        bne l2102
        ldy l0353,x     // ---- moving v2: by half col ----
        lda #$02
        sta l0352,x     // toggle back to moving state v1
        lda #$14        // char for snake tail v2
        sta ($02),y
        iny
        lda #$15        // char for snake head v2
        sta ($02),y
        // fall-through

l2102   dex
        dex
        bmi l2103
        jmp l2101

l2103	jmp tick_player // jump back to first of main "tick" loop

// ----------------------------------------------------------------------------
// Sub-function for activating a snake in a given level at a given X-offset
// Note only a single snake per level is supported & only in 3 lower levels.
// The call is ignored silently if a snake already is active on this level.
// Snakes are created in coiled-up state and uncoil after a random delay.
//
// NOTE: The caller has to check the given start position does not overlap
// any other moving object, esp. the player.
//
// - Parameter: A:=Xoff (col index in row above base)
//              X:=level index * 2
// - Results: none

spawn_snake
        cpx #$2*2+1     // check range of X
        bcs l2621
        cmp #$16        // check range of Xoff
        bcs l2621
        tay
        lda l0352,x     // check status of snake: must be inactive
        bne l2621
        tya
        sta l0353,x
        lda #$01        // set snake state to coiled-up
        sta l0352,x
        lda l0358,x
        sta $02
        lda l0358+1,x
        sta $03
        lda ($02),y     // backup char under snake
        sta l035e,x
        lda #$11        // char for coiled-up snake
        sta ($02),y
        lda $03         // calc color address
        clc
        adc #$84
        sta $03
        lda ($02),y     // backup color under snake
        sta l0364,x
        lda #$04
        sta ($02),y
        txa
        pha
        jsr get_rand    // get RAND number
        and #$3f
        adc #$10
        tay
        pla
        tax
	tya             // set timer until uncoiling
        sta l035e+1,x
l2621   rts

// ----------------------------------------------------------------------------
// Sub-function for killing the snake on the same level as the player
//
// Parameters: global $00-$01: player address (read-only)
// Side-effects: overwrites temporary $10-$11
//               invalidates X,Y
// Results: status.C: 1 when snake killed; else 0

stomp_snake_player
        clc
        adc $00         // Parameter: Accu contains X-offset
        sta $10
        lda $01
        adc #$00
        sta $11
        jsr get_base_idx_and_xoff
        bcs stomp_snake_x
        rts

// ----------------------------------------------------------------------------
// Sub-function for killing the snake on the given level
//
// Parameters: $10-$11: screen address (in row above a level)
// Side-effects: invalidates X,Y
// Results: status.C: 1 when snake killed; else 0

stomp_snake_addr
        jsr get_base_idx_and_xoff
        bcs stomp_snake_x
        rts

stomp_snake_x
        lda l0352,x
        beq l2601

        lda l0358,x     // copy snake (base) address to $02-$03
        sta $02
        sta $10
        lda l0358+1,x
        sta $03
        clc             // calc color (base) address $10-$11
        adc #$84
        sta $11

        ldy l0353,x
        lda l035e,x     // undraw snake
        sta ($02),y
        lda l0364,x
        sta ($10),y
        lda l0352,x
        cmp #$01        // in coiled-up state?
        beq l2602       // yes -> undraw single char only
        iny             // next col (note snake never crosses screen border)
        lda l035e+1,x
        sta ($02),y
        lda l0364+1,x
        sta ($10),y
l2602   lda #$00        // set state to inactive
        sta l0352,x

	lda #<l1318     // print "STOMPED A SNAKE"
        sta $10
	lda #>l1318
        sta $11
        jmp prt_message
        sec
        rts
l2601   clc
        rts

// ----------------------------------------------------------------------------
// Sub-function for uncoiling a snake on the same level as the player.
// This function is called whenever a player changes levels (e.g. via ladder)
// The function does nothing if no snake is active on this level or if the
// snake is not currently coiled-up.
//
// Parameters: global $00-$01: player address (read-only)
// Side-effects: overwrites temporary $10-$11
//               invalidates X,Y
// Results: none

activate_snake_player
        lda $00
        sta $10
        lda $01
        sta $11
        jsr get_base_idx_and_xoff
        bcc l2630
        lda l0352,x
        cmp #$01        // snake on this level in coiled state?
        bne l2601
        sta l035e+1,x     // make timer expire in next tick
l2630   rts

// ----------------------------------------------------------------------------
// Sub-function to querying if player is on the given level
//
// Parameters: X := level to compare *2 (not invalidated by function)
//             $00-$01: player address
// Side-effects: invalidates Y
// Results: status.C := 1=OK, 0=nOK

is_player_same_level
        cpx #$2*2+1     // check range of X
        bcs l2640
        lda l1240+2,x   // subtract player address from base address
        sec
	sbc $00
        tay
	lda l1240+3,x
	sbc $01
	bne l2640       // MSB delta (incl. carry) not zero -> player not on this base
	cpy #$16+1      // LSB delta: player within row above the base?
	bcs l2640
        sec             // result: yes
        rts
l2640   clc             // result: no
        rts

// ----------------------------------------------------------------------------
// Sub-function for updating "carrying" status;
// to be called after picking up or dropping any item
//
// - Parameter: global v_plr_carry (read-only)

prt_egg_status
	lda v_plr_carry
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
	lda v_plr_carry
        cmp #1          // multiple eggs?
        bne l2204
	ldx #$04        // no -> use singular
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
// Sub-function: draw/delete player figure
//
// - Parameter: A = new player char code
// - globals: $00-$01: current player address (read-only)
// - side-effects: stores char/color under player v_plr_bg_char/v_plr_bg_col
//                 overwrites temp pointer $10-$11

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
	sta v_plr_bg_char
	lda ($10),y
	sta v_plr_bg_col
        txa
	sta ($00),y     // write player figure
        lda #$05        // color green
	sta ($10),y
        rts

undraw_player
	ldy #$00
        lda v_plr_bg_char
	sta ($00),y
        lda $00         // calc color address: ($00) + $9400 -$1000
        sta $10
        lda $01
        clc
        adc #$94-$10
        sta $11
        lda v_plr_bg_col
	sta ($10),y
        rts

// ----------------------------------------------------------------------------
// Sub-function: calc base level idx (*2) and X-offset
// - Parameter: $10-$11: address - must be in row ABOVE a base
// - Results: A := X-offset
//            X := base index * 2
//            status.C := 1=OK, 0=nOK (addr out of range)
//
// Note: the bottom-most level has index 0, above 2 etc.

get_base_idx_and_xoff
        ldx #$06        // iterate across all bases
l2312	lda l1240+2,x   // subtract player address from base address
        sec
	sbc $10
        tay
	lda l1240+3,x
	sbc $11
	bne l2323       // MSB delta (incl. carry) not zero -> player not on this base
	cpy #$16+1      // LSB delta: player within row above the base?
	bcc l2327       // yes -> done
l2323	dex
	dex
	bpl l2312
        clc             // no match
        rts
l2327	tya
        eor #$ff
        sec
        adc #$16        // calc 16-A via 2-complement(A) + 16
        rts

// ----------------------------------------------------------------------------
// Sub-function to calculate column index of the player figure
// - Parameter: global $00-$01 (read-only)
// - Side-effects: invalidates Y; X not used
// - Results: A := player address % 22

get_player_xoff
        lda $01         // player address MSB
        sec
        sbc #$10        // minus MSB of screen base address
        tay
        lda $00
l2332	sec             // loop: subtract 22 until MSB negative
l2331	sbc #$16
	bcs l2331
	dey
	bpl l2332
	//clc
	adc #$16        // undo last subtraction
        rts

// ----------------------------------------------------------------------------
// Sub-function for adding points to score counter and updating display
// - Parameter: A = in BCD: number of points to be added
// - Side-effects: invalidates X; Y not used
//                 overwrites temporary v_tmp_score
// - Results: none

add_score
        ldx #$00        // convert parameter to BCD
l2302   cmp #$0a        // calc X:=val/10
        bcc l2301
        sec
        sbc #$0a
        inx
        bne l2302
l2301   sta v_tmp_score       // BAK:=val%10
        txa
        asl
        asl
        asl
        asl
        clc
        adc v_tmp_score

        sed             // enable BCD mode for arithmetics
        clc
        adc v_plr_score       // add to lower nibbles
        sta v_plr_score
        lda #$00
        adc v_plr_score+1       // add C-bit to higher nibble
        sta v_plr_score+1
        cld

        lda v_plr_score
        and #$0f
        clc
        adc #$b0
        sta $11a2+4*$16+$12+2
        lda v_plr_score
        lsr
        lsr
        lsr
        lsr
        clc
        adc #$b0
        sta $11a2+4*$16+$12+1
        lda v_plr_score+1
        and #$0f
        clc
        adc #$b0
        sta $11a2+4*$16+$12+0
        rts

// ----------------------------------------------------------------------------
//      Zero-terminated message strings (max 20 chars fit in message box)
//      Note 1: Characters are screen codes, not ASCII
//      Note 2: Text has to use reverse char set (i.e. 0x80-0xff),
//              as others are replaced by user-defined characters at $1c00

l12e3   .byt $86,$89,$92,$85,$20        // "FIRE IS BURNING"
        .byt $89,$93,$20
        .byt $82,$95,$92,$8e,$89,$8e,$87,$00
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
l1317   .byt $85,$87,$87,$93,$20        // "EGGS TOO HEAVY"
        .byt $94,$8f,$8f,$20
        .byt $88,$85,$81,$96,$99,$00
l1318   .byt $93,$94,$8f,$8d,$90,$85,$84,$20        // "STOMPED A SNAKE"
        .byt $81,$20,$93,$8e,$81,$8b,$85,$00


l1320   .byt $83,$8f,$8e,$87,$92,$81,$94,$95    // "CONGRATULATIONS"
        .byt $8c,$81,$94,$89,$8f,$8e,$93,$00
l1321   .byt $82,$95,$92,$8e,$94,$20    // "BURNT TO DEATH"
        .byt $94,$8f,$20
        .byt $84,$85,$81,$94,$88,$00
l1322   .byt $93,$94,$8f,$8d,$90,$85,$84,$20    // "STOMPED BY DINO"
        .byt $82,$99,$20
        .byt $84,$89,$8e,$8f,$00
l1323   .byt $86,$81,$8c,$8c,$85,$8e,$20    // "FALLEN TO DEATH"
        .byt $94,$8f,$20
        .byt $84,$85,$81,$94,$88,$00
l1324   .byt $84,$89,$85,$84,$20            // "DIED FROM SNAKE BITE"
        .byt $86,$92,$8f,$8d,$20
        .byt $93,$8e,$81,$8b,$85,$20
        .byt $82,$89,$94,$85,$00
l1330   .byt $94,$92,$99,$20            // "TRY AGAIN? (Y/N)"
        .byt $81,$87,$81,$89,$8e,$bf,$20
        .byt $a8,$99,$af,$8e,$a9,$00

//      Table of strings indexed by "post-game" function parameter
l132x   .word l1320
        .word l1321
        .word l1322
        .word l1323
        .word l1324

// ----------------------------------------------------------------------------
// Sub-function for printing a status text to the message box. The text has
// to be zero-terminated; the text is displayed centered within the box.
//
// - Parameters: $10-$11: message text address
// - Side-effects: invalidates registers A, X, Y
// - Results: none

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
l2503   tya
        eor #$ff        // calculate 20-len/2: start offset for centering
        sec             // calculate "-len" by taking 2-complement (~A+1)
        adc #20
        lsr
        tax
        ldy #$00        // copy message until zero-byte
l2504   lda ($10),y
        beq l2505
        sta $11a2+22+1,x
        iny
        inx
        bne l2504
l2505   lda #$50        // set timer for automatically clearing message
        sta v_msg_timer
        rts

// ----------------------------------------------------------------------------
// Sub-function for clearing the text in the message box
//
// - Parameters: none
// - Side-effects: invalidates registers A, X
// - Results: none

clr_message
        ldx #22
l2510   lda l126e-1,x
        sta $11a2+22-1,x
	dex
	bne l2510
        rts


// ----------------------------------------------------------------------------
// Sub-function for initializing color for the complete screen to a fixed value

#if 0 /* currently unused */
set_screen_color
        lda #<$9400+19*22-1
        sta $00
        lda #>$9400+19*22-1
        sta $01
        ldy #$00
l2520   lda #$01        // color: white
l2521   sta ($00),y
        dec $00
        bne l2521
        sta ($00),y
        dec $00
        dec $01
        lda $01
        cmp #$94
        bcs l2520
#endif

// ----------------------------------------------------------------------------
// Sub-function to get random number in range 0..255
// Parameters: none
// Side-effects: external sub-function may be called
//               at least X,Y and $8c-$8f modified
// Results: A = random value $00..$ff

get_rand
        ldy v_rand_idx
        cpy #$04
        bcc l2531
        jsr $e094       // get 4 new RAND numbers
        ldy #$00
l2531   lda v_rand_accu
        eor $8c,y
        sta v_rand_accu
        iny
        sty v_rand_idx
        rts

// This sub-function has to be called once during start-up to initialize
// the pseudo-random number generator management.

init_rand_gen
	jsr $e09b       // seed pseudo-random number generator (with VIA timer)
        jsr $e094       // get initial set of RAND numbers
        lda $8c         // XOR to improve starting quality
        eor $8d
        eor $8e
        eor $8f
        sta v_rand_accu
        ldy #$04        // initialize rand buffer to empty
        sty v_rand_idx
        rts

// ----------------------------------------------------------------------------
// Sub-function to get random number in range 0 to value passed in A
//
// Note: Numbers will not be evenly distributed, as those in range 0..256%A
//       occur one more than others as result of iteration below. As most
//       limits are <<256 this is deemed acceptable.
//
//       Alternatively, we could calculate (RAND16 * A) >> 16, but this would
//       require firstly a 16-bit rand value (with 8 distribution is still
//       uneven) and performing 8*16 bit multiplication, or 24-bit addition
//       for A times. (The idea behind the formula is using 16-bit fix-point
//       arithmetic. Then RAND16 is a value in range [0..1[ which we scale
//       to [0..A[ via multiplication.)
//
//       Another alternative could be calculating RAND16 / ((1<<16) / A),
//       where the constant would be calculated at compile-time and division
//       implemented via iteration. However imprecision of the pre-calculated
//       constant still leads to slightly uneven distribution. To improve,
//       one could use instead (RAND16<<8) / ((1<<24) / A)
//
get_rand_lim
        sta v_rand_tmp       // backup limit value
        jsr get_rand    // get random number in A
        sec
l2532   sbc v_rand_tmp       // iterate to calculate N modulo A
        bcs l2532
        adc v_rand_tmp
        rts

// ----------------------------------------------------------------------------
// This sub-function is called when the player dies, or the goal is reached.
// The function prints a message indicating the cause and asks if the game
// should be restarted. If the user answers no, the game exits back to BASIC.
//
// Parameter: A = cause

post_game
        asl
        tax
        lda l132x,x
        sta $10
        lda l132x+1,x
        sta $11
        jsr prt_message

        ldx #3*22       // overwrite status boxes with another message box
l2404	lda l1258-1,x
	sta $11a2+3*22-1,x
	dex
	bne l2404

        ldx #$10
l2408	lda l1330-1,x   // print "TRY AGAIN?"
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
l2411   lda #$00
        sta $c6
        jmp l1400       // restart from scratch


// ----------------------------------------------------------------------------
// This sub-function is installed as hook for keyboard presses, which is called
// from within the timer interrupt handler. The intention is to record the
// keypress in a local variable, so that the keypress is not missed if the
// key is released again before the part of the main loop which polls $cb
// is reached.

key_int
        lda $cb         // code of last key read during interrupt
        cmp #$40        // any key pressed?
        beq l2520
        cmp v_key_prev       // filter last processed key (i.e. key still pressed) to avoid introducing bouncing/echo
        beq l2520
        sta v_key_next
l2520   rts

// ----------------------------------------------------------------------------
// Variables
_var_sect_start = *             // start/end labels are used for zero-initialization

v_plr_bg_col    .byt 0          // saved color below player (companion to v_plr_bg_char)
v_plr_bg_char   .byt 0          // saved char below player (e.g. ladder)
v_plr_carry     .byt 0          // number of carried eggs; >$7f:wood
v_plr_fall_h    .byt 0          // counter of fallen height
v_plr_score     .byt 0,0        // score BCD (3 nibbles, LSB in first byte)
v_plr_jumps     .byt 0          // player direction & jump state
                                //   $01: right (straight); $02: jump right phase 1; $04: jump right phase 2
                                //   $10: left (straight); $20: jump right phase 1; $40: jump right phase 2
                                //   $80: jump upwards
v_plr_ladder    .byt 0          // on ladder? (0:no, else:yes)
v_plr_immun     .byt 0          // counter fire immunity
v_plr_power     .byt 0          // power gain? 0:no else:yes

v_fire_timer    .byt 0          // counter until fire warning
v_fire_state    .byt 0          // fire state: 0:burning 1:make 2:coming 3:attack 8:stamping
v_fire_adr      .dsb 2*2,0      // array of [2]: address digit char under fire; MSB zero if not burning

v_snakes        .dsb 8*3,0      // state if snakes; ATTN: each word is array[3] separately (not whole struct)
                                // +0: snake state: 0=inactive; 1=coiled up; 2,3=moving v1,v2
                                // +1: snake X-offset
                                // +6-7: snake address address of col #0 in row (i.e. always add l0353)
                                // +12-13: snake char under tail,head / timer until uncoiling LSB/MSB
                                // +18-19: snake color under tail,head

v_egg_dir       .dsb 4*$16,0    // egg directory (for 4 bases, len=$16 each (see l1250)) bitmask:
                                // - mask $03: egg count (1..3)
                                // - mask $08: snake egg
                                // - mask $10: stone (may be combined with any other but $80)
                                // - mask $20: wood
                                // - mask $40: power gain
                                // - mask $80: ladder <-> blocked for content
v_stonefall     .dsb 4*2,0      // containing state of up to two falling stones; ATTN: each word is array[2] separately
                                // +0: state: 0=none, 1=start, 2=fall
                                // +1: content below stone (copied from egg directory)
                                // +4: address of stone on screen (meaning varies with state)
v_msg_timer     .byt 0          // message clearing counter
v_main_timer    .byt 0          // main loop counter
v_timestamp     .byt 0,0,0      // copy of system clock in $a0-$a2 (MSB first!) for calculating time delay
v_key_prev      .byt 0          // previous keypress (copied from $cb) used to suppress auto-repeat on F7
v_key_next      .byt 0          // next keypress: $ff=invalid until peek($cb) != $40
v_key_cur       .byt 0          // current keypress (used during player actions)
                                // Internal state of random number management:
v_rand_accu     .byt 0          // - current random number
v_rand_idx      .byt 0          // - random number index
v_rand_tmp      .byt 0          // - temporary buffer used by get_rand_lim function
v_tmp_score     .byt 0          // temporary used during score calculation

l0352   = v_snakes
l0353   = v_snakes + 1
l0358   = v_snakes + 6
l035e   = v_snakes + 12
l0364   = v_snakes + 18

l03e0   = v_stonefall + 0       // state of first falling stone; second is at *+2
l03e1   = v_stonefall + 1       // content below first falling stone; second is at *+2
l03e4   = v_stonefall + 4       // address of first falling stone; second is at *+2

_var_sect_end = *               // DO NOT ADD BELOW
// ----------------------------------------------------------------------------
