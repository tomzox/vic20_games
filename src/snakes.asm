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

// P00 header
_start_data = $123d
.word _start_data

.text
* = _start_data

// ----------------------------------------------------------------------------
// Description of memory layout:
//
// >>>>> Prerequisite: 8 kB memory extension at $2000 <<<<<
//
// $0000-$00ff: pointer variables; see description below
// $0100-$01ff: stack (only used for JSR/RTS here)
//
// $1000-$11fa: screen buffer (23 rows * 22 columns)
// $1240-$13ff: read-only data section
// $1400-$1bff: code section, part 1
// $1c00-$1dff: user-defined characters (position restricted by HW/ROM)
// $1e00-$2fff: code section, part 2
//              followed by variable definitions

// ----------------------------------------------------------------------------
// Main control flow:
//
// - $1400: game entry point from BASIC (SYS 5120)
// - main loop: chain of "jmp" from player handler, to snake handler loop,
//   and back to player
// - game is ended via "rts"

// ----------------------------------------------------------------------------
// Variables in ZP: (other variables are defined at the end of this file)
//
// $00:        -unused-
// $01-$02:    -unused-
// $03-$04:    player address
// $05:        -unused-
// $06:        -unused-
// $07:        -unused-
// $08-$09:    snake head address (temporary copy of l0384)
// $0a:        snake direction (temporary copy of l03a6)

// $22-$25     temporary during sub-functions
// $4b-$4c     -unused-
// $d7:        temporary during snake handler
// $fb:        warm boot flag (temporary during restart)
// $fc-$fe     -unused-

// FIXME sound:
// - small noise when crossing excrement
// - tone when rejecting movement due to zero skill
// - longer tone going doen after death; opposite upon rebirth

// ----------------------------------------------------------------------------
// Initialized data

        // Highscore value in BCD, little endian: 126722
        // overwritten here if exceeded by player's score at game end
l123d   .byt $22,$67,$12

        // Display text including color codes
        // (upper-case charset PLUS $80 for use in user-defined graphics mode)
l1241	.byt $93,$00    // "SKILL:" (black)
	.byt $8b,$00
	.byt $89,$00
	.byt $8c,$00
	.byt $8c,$00
	.byt $ba,$00
	.byt $20,$01    // blank, to be replaced by 2 digits (white)
	.byt $20,$01
	.byt $20,$01
l1252	.byt $93,$00    // "SCORE:" (black)
	.byt $83,$00
	.byt $8f,$00
	.byt $92,$00
	.byt $85,$00
	.byt $ba,$00
	.byt $b0,$01    // white
	.byt $b0,$01
	.byt $b0,$01
	.byt $b0,$01
	.byt $b0,$01
	.byt $b0,$01
	.byt $20,$01
#if 0
        .byt $88,$02    // "HIGHSCORE:" (red)
	.byt $89,$02
	.byt $87,$02
	.byt $88,$02
	.byt $93,$02
	.byt $83,$02
	.byt $8f,$02
	.byt $92,$02
        .byt $85,$02
        .byt $ba,$02
#else
        .byt $20,$02    // -unused-
	.byt $20,$02
	.byt $20,$02
	.byt $20,$02
	.byt $20,$02
	.byt $20,$02
	.byt $20,$02
	.byt $20,$02
        .byt $20,$02
        .byt $20,$02
#endif
        .byt $20,$02    // blank, to be replaced by 6 digits
        .byt $20,$02
        .byt $20,$02
        .byt $20,$02
        .byt $20,$02
        .byt $20,$02
        .byt $20,$02
        .byt $20,$06   // space, to be replaced by "EAT" (blue)
        .byt $20,$06
        .byt $20,$06
l12cc   .byt $87,$95,$94,$20,$87,$8c,$95,$85,$83,$8b,$2a   // "GUT GLUECK!"

        // "GUTGLUECK" as user-defined characters, each letter circled:
        // table of bonus characters, need to be picked-up by player in this order
l12d7   .byt $39,$3a,$3b,$39,$3c,$3a,$3d,$3e,$3f
l12c2	.byt $39,$3a,$3b,$00,$39,$3c,$3a,$3d,$3e,$3f   // same with space between words

l126c	.byt $88,$89,$87,$88,$93,$83,$8f,$92,$85,$ba  // "HIGHSCORE:"
l1295   .byt $87,$92,$85,$81,$94   // "GREAT"
l129a   .byt $93,$8d,$81,$8c,$8c,$20,$82,$8f,$8e,$95,$93    // "SMALL BONUS"
        .byt $ba,$20,$b2,$b0,$b0,$b0,$20,$90,$94,$93        // ": 2000 PTS" (number will be replaced on screen)

        // Text used on game-end screen (lower-case ROM charset)
l126d	.byt $48,$09,$07,$08,$13,$03,$0f,$12,$05,$3a        // "Highscore:"
l1f8f	.byt $4c,$01,$13,$14,$20,$53,$03,$0f,$12,$05,$3a    // "Last Score:"
l1330   .byt $54,$12,$19,$20            // "TRY AGAIN? (Y/N)"
        .byt $01,$07,$01,$09,$0e,$3f,$20
        .byt $28,$59,$2f,$4e,$29

        // Text used on welcome screen (lower-case ROM charset)
l12b9   .byt $53,$03,$08,$0c,$01,$0e,$07,$05,$0e   // "Schlangen"
l12ba   .byt $50,$12,$05,$13,$13,$20,   // "Press any key"
        .byt $01,$0e,$19,$20
        .byt $0b,$05,$19

// ----------------------------------------------------------------------------
//                      // Game entry point

.dsb $1400 - *, 0
* = $1400

init_game
	lda #$00
	sta $900e
	lda #$19        // set screen color: screen:white border:white
	sta $900f
	lda #$c2        // reset screen & character map addresses
	sta $9005
	jsr $e55f       // clear screen
	jsr $e09b       // seed pseudo-random number generator (with VIA timer)
	lda #$ff        // disable SHIFT/Commodore case switching
	sta $0291
        lda #<key_int   // set dummy keyboard interrupt hook
        sta $028f
        lda #>key_int
        sta $0290

                        // ---- print game title on screen & wait for keypress ----
	ldx #$09
l1614	lda l12b9-1,x   // print game title
	sta $1000+10*22+6-1,x
	lda #$02        // color: red
	sta $9400+10*22+6-1,x
	dex
	bne l1614

l1622	lda $cb         // wait for no key pressed
	cmp #$40
	bne l1622

        lda #$00
        sta $22
        sta $23
        sta $24
l162d	lda $cb         // wait for keypress or joystick
	cmp #$40
	bne l1666
#if 0
// FIXME does not work in VICE
	lda $911f       // check joystick
	cmp #$7e
	beq l1666
#endif
        inc $22         // count waiting time
        lda $22
        bne l162d
        inc $23
        lda $23
        bne l162d
        inc $24
        lda $24
        cmp #$04        // apx. 4-5 seconds?
        bcc l162d

	ldx #$0d
l1615	lda l12ba-1,x   // print "Press any key"
	sta $1000+21*22+4-1,x
	lda #$06        // color: blue
	sta $9400+21*22+4-1,x
	dex
	bne l1615
        beq l162d

l1666	lda #$02
	sta v_plr_lives // init number of lives := 2
	lda #$00
	sta $fb         // clear warm boot flag
        // fall-through

l166f	                // ---- warm-boot / restart of game ----
	jsr $e55f       // clear screen
	lda #$ac        // set screen color: screen:pink border:purple
	sta $900f
	lda #$cf        // screen:$1000, color:$9400, user-def:$1C00
	sta $9005       // screen:$1000, color:$9400, charmap:$1400

	lda #$42        // loop to draw "food" on screen $1000...
	sta $00
	sta $22
	lda #$10
	sta $01
	lda #$94-$10
	sta $23
	ldx #$02
l168e	ldy #$c5
l1690	lda #$19        // "food" char code
	sta ($00),y
	lda #$07        // color: yellow
	sta ($22),y
	dey
	bne l1690
	lda #$07
	sta $00
	sta $22
	inc $01
	inc $23
	dex
	bne l168e

	ldx #$16        // draw horizontal borders at top & bottom
l16b1	lda #$1c
	sta $1000+2*22-1,x
	lda #$1d
	sta $1000+21*22-1,x
	lda #$00
	sta $9400+2*22-1,x
	sta $9400+21*22-1,x
	dex
	bne l16b1

	lda #$42        // draw vertical border at left and right side
	sta $00
	sta $02
	lda #$10
	sta $01
	lda #$94
	sta $03
	lda #$12        // counter for outer loop = border height
	sta $08
l16e2	ldy #$00        // offset left border
	lda #$1d        // char code for vertical borders
	sta ($00),y
	lda #$00        // color: black
	sta ($02),y
        ldy #$16-1      // offset to right border
	lda #$1d        // char code for vertical borders
	sta ($00),y
	lda #$00        // color: black
	sta ($02),y
        lda $00         // advance pointers to next row +22
        clc
        adc #$16
        bcc l16f0
        inc $01
        inc $03
l16f0   sta $00         // both pointers have same LSB
        sta $02
	dec $08
	bne l16e2

	ldx #42-1       // print status display at top of screen
	ldy #42*2-1
l1711	lda l1241,y
	sta $9400,x
	dey
	lda l1241,y
	sta $1000,x
	dey
	dex
	bpl l1711

#if 0
	lda #<$1020     // print highscore value in second row of screen
        sta $08
	lda #>$1020
        sta $09
        lda l123d+0
        sta $22
        lda l123d+1
        sta $23
        lda l123d+2
        sta $24
	jsr print_highscore
#endif

	lda #$16        // display "target" char in middle of screen: X/Y=10/12
	sta $1112
        lda #$00        // color green
	sta $9512

	ldy #$00        // initialize player status: not ready, alive
	sty v_plr_ready
	sty v_plr_dead

	lda #$cc        // calc initial player address
	sta $03
	lda #$11
	sta $04
	lda #$17        // display player char
	sta ($03),y

	lda #$03        // initialize skill = 3
	sta v_plr_skill

	ldx #$00        // clear all snakes: invalid direction value
l1761	lda #$00
	sta l03a6,x
	txa
	clc
	adc #$25
	tax
	cmp #$25*5      // repeat loop for all snakes
	bcc l1761

	sty v_snk_cnt   // initialize snake counter = 0
	sty v_snk_last  // init snake end instance index to 0
	lda #<$10b5     // spawn first snake: X/Y=5/8
	sta $08
	lda #>$10b5
	sta $09
	jsr spawn_snake
	lda #<$116f     // spawn second snake: X/Y=16/15
	sta $08
	lda #>$116f
	sta $09
	jsr spawn_snake

	lda v_plr_lives // display number of lives in bottom-left corner
	beq l1793
	tax
	lda #$17        // char for player, drawn once for each life
l178d	sta $11e3,x
	dex
	bne l178d
l1793	lda $fb         // warm boot -> init or restore score respectively
	bne l17a4
	lda #$26        // init delay factor
	sta v_game_speed
	sty v_plr_score   // init score to 0
	sty v_plr_score+1
	sty v_plr_score+2
	clc
	bcc l17b0
l17a4	jsr print_score // keep old score for "warm boot"

                        // FIXME user may get "boxed" into corner by letters
l17b0	lda #$09        // ---- place bonus letters at random positions in playing field ----
	sta $d7
        sty $22         // LSB of pointer: always 0, use Y instead
l17b4	jsr $e094       // start loop: get RAND numbers
        ldy $8c         // calc address for letter: random offset 0..22*23-1
        lda $8d
        and #$01
        beq l17b5
        cpy #<22*23     // check range of LSB if MSB is equal maximum
        bcs l17b4
l17b5   clc
        adc #$10
        sta $23
        lda ($22),y     // read this screen position
	cmp #$19        // food char? (i.e. not other letter, or outside playing field)
	bne l17b4       // no -> try another random position
	ldx $d7
	lda l12d7-1,x   // get next bonus letter from sequence
	sta ($22),y     // draw letter char
	lda $23         // calc color address
	clc
	adc #$84
	sta $23
	lda #$02        // color: red
	sta ($22),y
	dec $d7         // next character in iteration
	bne l17b4
        ldy #$00

	ldx #$0b
l17de	lda l12cc-1,x   // print "good luck" message
	sta $11e9,x
	dex
	bne l17de

	sty v_plr_bonus_cnt // initialize count of picked-up letters

        lda #$40        // initialize keypress buffers
        sta v_key_prev
        sta v_key_next

        // end game init -> enter main loop
        jmp l17ea

//-----------------------------------------------------------------
//                      // Player control

l17ea   sei
        lda v_key_next  // any key-press detected since action handler?
        cmp #$40
        bne l17eb       // yes -> use that buffered key-press
        lda $cb         // no -> poll currently pressed key
l17eb   sta v_key_cur   // buffer for following processing
        lda #$40
        sta v_key_next
        cli

	lda v_plr_dead  // player still alive?
	beq l17f1
	cmp #$60
	beq l17f0
	jmp l1af2       // player dead -> to defeat handler
l17f0   jmp l1e67       // player eating snake
        //jmp l1ac1     // -> place player
        //jmp l1aed     // -> skip placing player

l17f1	lda #$ff
	sta $9122
	lda v_key_cur   // poll for keypress
	cmp #$09        // key 'w'?
	beq l17fc
	lda $911f       // poll joystick
	and #$04
	bne l181c

l17fc	sty $25         // handle key 'w': up
	jsr undraw_player
l1801	lda $03
	sec
        sbc #$16
	bcs l180d
	dec $04
l180d	sta $03
	lda $25
	bne l1819
	jsr check_player_pos
	bcc l182e
l1819	jmp l1893

l181c	lda v_key_cur
	cmp #$21        // key 'z'?
	beq l1829
	cmp #$0b        // key 'y': equiv. 'Z' for German keyboard
	beq l1829
l1822	lda $911f
	and #$08
	bne l1845

l1829	sty $25         // handle 'z': down
	jsr undraw_player
l182e	lda $03
        clc
        adc #$16
	bcc l1836
	inc $04
l1836	sta $03
	lda $25
	bne l1842
	jsr check_player_pos
	bcc l1801
l1842	jmp l1893

l1845	lda v_key_cur
	cmp #$11        // key 'a'?
	beq l1852
	lda $911f
	and #$10
	bne l186d

l1852	sty $25         // handle 'a': left
	jsr undraw_player
l1857	dec $03
	lda $03
	cmp #$ff
	bne l1861
	dec $04
l1861	lda $25
	bne l186a
	jsr check_player_pos
	bcc l1884
l186a	jmp l1893

l186d	lda v_key_cur
	cmp #$29        // key 's'?
	beq l187f
	lda #$7f
	sta $9122
	lda $9120
	and #$80
	bne l1893

l187f	sty $25         // handle 's': right
	jsr undraw_player
l1884	inc $03
	bne l188a
	inc $04
l188a	lda $25
	bne l1893
	jsr check_player_pos
	bcc l1857

//-----------------------------------------------------------------
//                      // Player status updates

                        // ---- print skill ----
l1893	lda v_plr_skill // calculate skill%10 and skill/10
	jsr div10
        clc
	adc #$30+$80    // add ROM char '0' to skill%10 digit
	sta $1007       // print skill&10 digit
	txa
	adc #$30+$80    // add ROM char '0' to skill/10 digit
	sta $1006       // print skill/10 digit

	lda v_plr_ready // player ready?
	beq l18c9       // no -> do not score for eating food
l18be	lda ($03),y     // read char under player figure
	cmp #$19        // "food" char?
	bne l18c9
	lda #$10        // score +10
	ldx #$00
	jsr add_score

l18c9	lda v_plr_ready // player "ready"?
	bne l1904       // yes -> skip obsolete check for home position
	lda ($03),y     // read char under player figure
	cmp #$16        // home char?
	bne l1904
	lda #$01        // yes -> mark player as ready
	sta v_plr_ready
	lda #$05+$80    // print "EAT" in upper right corner (using ROM chars)
	sta $1027
	lda #$01+$80
	sta $1027+1
	lda #$14+$80
	sta $1027+2
	lda v_plr_skill // any skill left?
	beq l1900
	tax             // add skill * 100 points to score
        tya
	jsr add_score
l1900	lda #$04        // initialize skill to 4 ("level II")
	sta v_plr_skill

l1904	sty v_plr_face  // reset player face: closed/not eating

	lda ($03),y     // read char under player
	cmp #$08        // snake head?
	bcs l1915
l190c	lda #$f0        // kill player
	sta v_plr_dead
	lda #$d8        // sound effect
	sta $900c
        // FIXME improve visibility & sound upon player being eaten

l1915	cmp #$12        // hit snake tail? (#$12-#$15)
	bcc l1965
	cmp #$16
	bcs l1965
	lda v_plr_ready // yes; player ready?
	beq l195d
	lda $028d       // yes; SHIFT key or joystick FIRE pressed?
	bne l192d
	lda $911f
	and #$20
	bne l195d       // neither -> skip
l192d   jsr start_eating_snake
        bcc l196b
	lda #$60        // change player status to "eating snake"
	sta v_plr_dead
	bne l196b
l195d	lda #$07        // score +7
	ldx #$00
	jsr add_score
	clc
	bcc l196b       // always true

l1965	cmp #$19        // found food?
	bne l196b
	sta v_plr_face  // yes -> player face: open/eating

l196b	lda v_game_time // time score
	asl
	asl
	asl
	asl
	bne l197e       // only once per 16 iterations
	lda v_snk_cnt   // any snakes alive?
	beq l197e
	asl             // yes -> score +2 for each living snake
        ldx #$00
	jsr add_score

l197e	lda v_plr_ready // player ready?
	beq l19a1       // no -> ignore eating apple or snake symbols
	lda ($03),y
	cmp #$36        // found apple?
	bne l1990
        ldx #$02        // yes: grant 250 points
	lda #$50
	jsr add_score
	clc
	bcc l199d       // increase skill +2

l1990	cmp #$35        // found snake grant symbol?
	bne l19a1
	lda #<$1112     // address for head of new snake: center of screen
        sta $08
	lda #>$1112
        sta $09
	jsr spawn_snake // spawn new snake
l199d	inc v_plr_skill // increase skill +2
	inc v_plr_skill

                        // ---- skill request handling ----
l19a1	lda v_key_cur   // poll keyboard
	cmp #$07        // key INSERT? (added for emulator)
        beq l19a2
	cmp #$06        // pound key? (skill demand)
	bne l19d0
l19a2	lda v_plr_skill
	cmp #$02        // skill >= 2?
	bcs l19d0       // yes -> disallow
	lda v_plr_score+2  // check "MSB" of score digits
	bne l19c2       // not 0, hence score >9999 -> OK
	lda v_plr_score+1 // middle digit pair of score
	cmp #$10        // >=10 (BCD)?
	bcc l19d0       // no -> disallow
l19c2   sed             // enable BCD arithmetics for adc/sbc
	sec
	lda v_plr_score+1 // subtract 1000 from score
        sbc #$10
        sta v_plr_score+1
	lda v_plr_score+2
        sbc #$00          // update highest pair in case of underflow (01.0x.xx -> 00.9x.xx)
	sta v_plr_score+2
	cld
	jsr print_score
	inc v_plr_skill // increase skill +2
	inc v_plr_skill
        jmp l1aa3
                        // ---- game end request handling ----
l19d0	lda v_key_cur   // poll keyboard
	cmp #$08        // left arrow key?
	beq l19d9
	cmp #$27        // key F1? (added for emulator)
	bne l1aa3
l19d9	lda v_plr_bonus_cnt  // all 10 bonus chars picked-up?
	cmp #$0a
	bcc l1a81       // no -> disallow
        jmp game_won
l1a81	lda v_plr_skill // skill zero?
	bne l1aa3       // no -> disallow
	lda v_plr_lives // any lifes left?
	bne l1a9d
	jmp game_end    // no -> update highscore & enter post-game
l1a9d	dec v_plr_lives // yes; remove one life
	jmp restart_game  // restart game, however keeping score

//-----------------------------------------------------------------
//                      // Place player: Sound

l1aa3	lda ($03),y     // check char at player position
	cmp #$35        // grant symbol found?
	bcc l1aae
	lda #$be        // generate note 266Hz
	sta $900c
l1aae	cmp #$17
	bcs l1ac1
	cmp #$08
	bcc l1af2       // player dead
	lda #$8c        // generate note 123Hz
	sta $900c

l1ac1	lda $03         // calc color address of player
	sta $22
	lda $04
	clc
	adc #$84
	sta $23
	lda #$01        // color: white
	sta ($22),y
	lda v_plr_face  // player eating?
	beq l1add
	lda #$80        // generate noise
	sta $900d
	lda #$18        // char for player eating
	bne l1adf
l1add	lda #$17        // char for player not eating
l1adf	sta ($03),y     // write player character
	lda $900c
	bne l1aed
	lda $900d       // sound being emitted?
	cmp #$f8
	beq l1af2
l1aed	lda #$0f        // yes -> set volume to max
	sta $900e

l1af2	lda v_key_cur   // player defeating?
	cmp #$27        // key F1? (added for emulator)
        beq l1af3
	cmp #$08        // left arrow key?
	bne l1b42
l1af3	lda v_plr_dead  // player dead?
	cmp #$f0
	bne l1b42       // no -> skip
	ldx v_plr_lives // any lives left?
	bne l1af8
	jmp game_end    // no -> end the game
l1af8	lda ($03),y     // read char at player pos: snake still on top?
	cmp #$16
	bcc l1b42       // yes -> skip (cannot revive at this position currently)
	dec v_plr_lives // remove one life
	sty v_plr_dead  // revive player
	lda #$20        // remove one life from display (i.e. player symbol in bottom-left corner)
	sta $11e3,x

l1b42   lda v_key_cur   // remember last processed key for filtering
        sta v_key_prev

        ldy v_game_speed // ---- time delay (I) ----
l1b44	ldx #$ff
l1b46	dex
	bne l1b46
l1b49	dey
	bne l1b44
	ldy #$00

	sty $900c       // stop all sound
	sty $900d
	lda v_snk_cnt
	beq l1b5e
	lda #$f8        // noise for snakes
	sta $900d

l1b5e	jmp l1c44       // to snake handler


// ----------------------------------------------------------------------------
// Sub-function: Calculate A%10 and A/10
// - Parameters: A = value to be divided
// - Results: A = Value % 10
//            X = Value / 10

div10   ldx #$ff
        sec
l1310   inx
        sbc #10
        bcs l1310
        adc #10
        rts

// ----------------------------------------------------------------------------
// Sub-function: Increase v_plr_score by given value and print to display
// - Parameter: A = lower two digits to be added (BCD)
//              X = higher two digits to be added (BCD)

add_score
        sed             // enable BCD arithmetics for adc/sbc
        clc
        adc v_plr_score
        sta v_plr_score
        txa
        adc v_plr_score+1
        sta v_plr_score+1
        tya
        adc v_plr_score+2
        sta v_plr_score+2
        cld
        // fall-through

print_score
        ldx #$00
        ldy #$05
l1306   lda v_plr_score,x
        and #$0f
        clc
        adc #$30+$80    // ROM char '0'
        sta $100f,y
        dey
        lda v_plr_score,x
        lsr
        lsr
        lsr
        lsr
        clc
        adc #$30+$80    // ROM char '0'
        sta $100f,y
        inx
        dey
        bpl l1306
	ldy #$00
	rts

// ----------------------------------------------------------------------------
// Sub-function: Print given score value to given screen address
// - Parameters: $08-$09: screen address where to print to
//               $22-$24: values to print (lowest BCD first)

print_highscore
        ldx #$00
        ldy #$05
l1336   lda $22,x
        and #$0f
        clc
        adc #$30        // ROM char '0'
        sta ($08),y
        dey
        lda $22,x
        lsr
        lsr
        lsr
        lsr
        clc
        adc #$30        // ROM char '0'
        sta ($08),y
        inx
        dey
        bpl l1336
#if 0
        ldy #$00        // remove leading zeros
l1337   lda ($08),y
        cmp #$30        // char for '0'?
        bne l1338
        lda #$20        // replace with blank char
        sta ($08),y
        iny
        cpy #$06-1      // leave last zero
        bcc l1337
#endif
l1338	ldy #$00
	rts

// ----------------------------------------------------------------------------
// Sub-function: Check new player position for movement
// After moving the player figure upon user input, the function checks if the
// move to the given address is allowed. If not, the caller has to undo the change.
//
// - Parameters: global $03-$04: new player address
// - Result: status.C 0:nOK, 1:OK
//
check_player_pos
	lda ($03),y     // read char at player address on screen
	cmp #$1a        // hit "excrement"?
	bne l1356
	lda v_plr_skill // any "skill" left?
	beq l1363       // no -> disallow
	lda $028d       // read prev. status of SHIFT key
	bne l1352
	lda $911f
        and #20
        bne l1363       // no SHIFT or joystick-fire -> disallow
l1352	dec v_plr_skill // reduce "skill" -1
	sec             // allow movement
	rts
l1356	cmp #$08        // hit snake head?
	bcc l13fa       // -> allow (will result in player death later-on)
	cmp #$12        // hit snake mid-section?
	bcc l1363       // -> do not allow
l135e	cmp #$1c        // is horizontal or vertical border?
	beq l1363
	cmp #$1d
	beq l1363       // yes to either -> do not allow
	cmp #$39        // letter characters?
	bcc l13fa       // no, i.e. anything else -> allow

        ldx v_plr_bonus_cnt // get number of eaten bonus chars as index
        cpx #$0a        // all letters done already?
        bcs l1363
        cmp l12c2,x     // is next expected letter in sequence?
        bne l1363
        lda v_plr_ready // player ready?
	beq l1363       // not ready -> do not allow eating letters
        lda l12c2,x
	sta $11ea,x     // mark letter as done in status bar
	inc v_plr_bonus_cnt // increase number of consumed letters
	cpx #$02        // skip blank in bonus letter sequence (i.e. after "GUT")
	bne l13f7
	inc v_plr_bonus_cnt
l13f7	inc v_plr_skill // increase skill +1
	ldx #$02
	lda #$50
	jsr add_score   // increase score by 250
l13fa	sec             // return: allow
	rts
l1363	lda #$aa        // result = do not allow
	sta $25
	clc
	rts

// ----------------------------------------------------------------------------
// Sub-function: Clear player figure

undraw_player
	lda $03         // calc color address of player
	sta $22
	lda $04
	clc
	adc #$84
	sta $23
	lda #$07        // color
	sta ($22),y
	lda #$1a        // place excrement
	sta ($03),y
	rts

// ----------------------------------------------------------------------------
// Sequence after successfully completing a level
// - jumped to when player ends the game after picking up all bonus letters
// - displays message indicating bonus points
// - then jumps back into the game (continuing at same score + bonus)

game_won
	lda v_snk_cnt   // any snakes left alive?
	bne l19e9
	ldx #$30        // no -> great bonus: 3000
	bne l19eb
l19e9	ldx #$20        // yes -> small bonus: 2000
l19eb	lda #$00
	jsr add_score

	lda v_plr_skill
        asl             // add 200 points per remaining skill to score
        adc #$02        // plus 250 points
        tax
        lda #$50
	jsr add_score

	lda v_plr_lives
	cmp #$03        // all three lives left?
	bcs l1a64
	inc v_plr_lives // no -> grant one live
	bne l19f0
l1a64	ldx #$10        // yes -> grant 1000 points
        lda #$00
	jsr add_score

l19f0	ldx #$15        // print "SMALL BONUS: 2000 PTS" (ATTN: value hard-coded)
l19f8	lda l129a-1,x
	sta $11e3,x
	lda #$02        // color: red
	sta $95e3,x
	dex
	bne l19f8
	lda v_snk_cnt   // snakes still alive? (ATTN: must match condition above!)
	bne l1a28
	ldx #$05        // yes -> print "GREAT", replacing "SMALL"
l1a1f	lda l1295-1,x
	sta $11e3,x
	dex
	bne l1a1f
	lda #$33+$80    // patch "BONUS" message: replace digit '2' with '3'
	sta $11e3+14

l1a28   lda $a2         // time delay: 10 seconds
        sta $22
        sty $23
        sty $24
l1a2e   lda $a2         // delay loop: read clock counter
        cmp $22
        beq l1a2e
        sta $22         // clock changed
        inc $23         // increment 2-byte counter
        bne l1a2e
        inc $24
        lda $24
        cmp #1          // 3*256 clock ticks ~= 12.8 seconds
        bcc l1a2e

        dec v_game_speed   // reduce time delay factor ==> increase game speed
	dec v_game_speed
        // fall-through

// Side-entry point: Restart game with current score value
//                   Used after defeat with zero remaining skill (player deadlock)
//                   when player still has lives left (else game ends)
restart_game
        lda #$80        // set flag to indicate warm boot
	sta $fb
	jmp l166f       // to start of game

//-----------------------------------------------------------------
// End game due to player death or skill defeat
// - jumped to when player defeats after losing all lifes or skill
// - print summary of score and highscore
// - offer choise to restart game (at welcome screen) or exit

game_end
                        // ---- Update highscore ----
        lda v_plr_score+2
	cmp l123d+2     // score > highscore? (note binary-cmp also works for BCD)
	bcc l1b3f       // compare with highest-value digit pair
	bne l1b30
	lda v_plr_score+1
	cmp l123d+1     // mid-value digit pair
	bcc l1b3f
	bne l1b30
	lda l123d       // lowest-value digit pair
	cmp v_plr_score
	bcs l1b3f
l1b30	lda v_plr_score // set score as new highscore
	sta l123d
	lda v_plr_score+1
	sta l123d+1
	lda v_plr_score+2
	sta l123d+2

//                      // ---- Clear screen & print score table  ----
l1b3f	jsr $e5c3       // init VIC chip
	jsr $e55f       // clear screen
	lda #$19        // set screen bg colors: screen:white border:white
	sta $900f
	lda #$c2        // switch to lower-case ROM charset
	sta $9005

	ldx #$0b        // print "Last Score:"
l1f34	lda l1f8f-1,x
	sta $1000+5*22+5-1,x
	lda #$02        // color: red
	sta $9400+5*22+5-1,x
	lda #$06        // color: blue: for score values printed in next row
	sta $9400+8*22+7-1,x
	dex
	bne l1f34

	lda #<$1000+8*22+7  // print last player score value
	sta $08
	lda #>$1000+8*22+7
	sta $09
        lda v_plr_score+0
        sta $22
        lda v_plr_score+1
        sta $23
        lda v_plr_score+2
        sta $24
	jsr print_highscore

	ldx #$0a        // print "Highscore:"
l1f14	lda l126d-1,x
	sta $1000+11*22+5-1,x
	lda #$02        // color: red
	sta $9400+11*22+5-1,x
	lda #$06        // color: blue: for score values printed in next row
	sta $9400+14*22+7-1,x
	dex
	bne l1f14

	lda #<$1000+14*22+7     // print highscore value
        sta $08
	lda #>$1000+14*22+7
        sta $09
        lda l123d+0
        sta $22
        lda l123d+1
        sta $23
        lda l123d+2
        sta $24
	jsr print_highscore

        ldx #$10
l1f40	lda l1330-1,x   // print "Try again?"
	sta $1000+20*22+3-1,x
        lda #$02
        sta $9400+20*22+3-1,x
	dex
	bne l1f40

l1f44   lda $cb         // wait for key 'Y', 'Z' or 'N'
        tax
        cmp #$0b        // key 'Y'
        beq l1f79
        cmp #$21        // key 'Z'
        beq l1f79
        cmp #$1c        // key 'N'
        bne l1f44
l1f79	lda $cb         // wait for all keys released
	cmp #$40
	bne l1f79

        cpx #$1c        // exit?
        beq l1f7a
	jmp init_game   // no -> back to start of game (welcome screen)
l1f7a   jmp $e518       // yes -> reset, back to BASIC
        rts

// ----------------------------------------------------------------------------
// This sub-function is installed as hook for keyboard presses, which is called
// from within the timer interrupt handler. The intention is to record the
// keypress in a local variable, so that the keypress is not missed if the
// key is released again before the part of the main loop which polls $cb
// is reached.

key_int
        lda $cb         // code of last key read during interrupt
        cmp #$40        // any key pressed?
        beq l13f0
        cmp v_key_prev  // filter last processed key (i.e. key still pressed) to avoid introducing bouncing/echo
        beq l13f0
        sta v_key_next
l13f0   rts

// ----------------------------------------------------------------------------
// Sub-function for splitting screen for a fixed time
// Can be used to switch between character sets between screen rows

#if 0 /* currently unused */
split_screen
	sty $22         // 3-byte counter to determine time delay
	sty $23
	sty $24
lspl1	lda $9004       // query video line being scanned for TV-out (<<1 as lowest bit is in $9003)
	cmp #$7e        // start of last row? (found experimentally; note this value includes screen border so it's not just #rows *8)
	bcc lspl2
	lda #$c2        // yes -> reset to ROM character set
	bne lspl3
lspl2	lda #$cf        // no -> user-defined characters at $1C00
lspl3	sta $9005
	inc $22
	bne lspl1
	inc $23
	bne lspl1
	inc $24
	cmp #$10
	bcc lspl1
        rts
#endif

// ----------------------------------------------------------------------------
// User-defined characters
// - 64 user-defined characters, 8x8 bit each
// - must start at $1c00, where the data is read by VIA HW (register $9005)
// - note address is selected so that char codes $80-$ff are mapped to
//   reverse character definitions in ROM (i.e. address cannot be changed!)

// fill up possible gap before fixed start address of this section
// ATTENTION: assembler "xa" will not generate error if the gap has negative size
.dsb $1c00 - *, 0
* = $1c00

l1c00	.byt $00,$58,$58,$5c,$5e,$4a,$7a,$7e    // #$00: snake head: upwards & closed
	.byt $00,$46,$46,$4e,$4e,$5a,$5a,$7e    //                   upwards & open
	.byt $00,$0f,$19,$7f,$7b,$03,$7f,$00    //                   left & closed
	.byt $00,$7f,$79,$1f,$07,$01,$7f,$00    //                   left & open
	.byt $7e,$5e,$52,$7a,$3a,$1a,$1a,$00    //                   down & closed
	.byt $7e,$5a,$5a,$72,$72,$62,$62,$00    //                   down & open
	.byt $00,$f0,$98,$fe,$de,$c0,$fe,$00    //                   right & closed
	.byt $00,$fe,$9e,$f8,$e0,$80,$fe,$00    //                   right & open
	.byt $00,$00,$ff,$ff,$ff,$ff,$00,$00    // #$08: snake middle: horizontal
	.byt $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c    // #$09:               vertical
	.byt $3c,$7c,$f8,$f8,$f0,$f0,$00,$00    // #$0a: snake middle: corners
	.byt $00,$00,$c0,$f0,$f8,$f8,$7c,$3c
	.byt $00,$00,$03,$0f,$1f,$1f,$3e,$3c
	.byt $3c,$3e,$1f,$1f,$0f,$03,$00,$00
	.byt $3c,$5e,$ef,$f7,$e7,$ff,$7e,$3c    // #$0e: snake middle: 180° turn
	.byt $3c,$7e,$ff,$e7,$d7,$bf,$7e,$3c
	.byt $3c,$7e,$ff,$e7,$ef,$f7,$fa,$3c
	.byt $3c,$7e,$fd,$eb,$e7,$ff,$7e,$3c
	.byt $00,$00,$f8,$fe,$fe,$f8,$00,$00    // #$12: snake tail: end at right
	.byt $00,$00,$1f,$7f,$7f,$1f,$00,$00    // #$13:             end at left
	.byt $00,$18,$18,$3c,$3c,$3c,$3c,$3c    // #$14:             end at top
	.byt $3c,$3c,$3c,$3c,$3c,$18,$18,$00    // #$15:             end at bottom
	.byt $00,$3c,$42,$5a,$5a,$42,$3c,$00    // #$16: target
	.byt $7e,$99,$99,$ff,$bd,$c3,$ff,$7e    // #$17: player closed
	.byt $7e,$99,$ff,$c3,$81,$c3,$e7,$7e    // #$18: player open
	.byt $00,$00,$18,$24,$24,$18,$00,$00    // #$19: food (score points)
	.byt $00,$00,$00,$00,$08,$00,$00,$00    // #$1a: excrement
	.byt $00,$7e,$99,$ff,$e7,$db,$7e,$00    // #$1b: player dead
	.byt $00,$00,$00,$ff,$ab,$d5,$ab,$ff    // #$1c: border horizontal
	.byt $ff,$ab,$d5,$ab,$d5,$ab,$d5,$ff    // #$1d: border vertical
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -

	.byt $00,$00,$00,$00,$00,$00,$00,$00    // #$20: blank
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $12,$12,$12,$12,$00,$00,$12,$00    // #$2a: fat exclamation mark '!'
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $70,$a8,$f8,$8e,$7b,$1f,$10,$1f    // #$35: symbol: grant level + snake
	.byt $06,$0e,$08,$3c,$7e,$7e,$7e,$3c    // #$36: apple: score bonus
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $00,$00,$00,$00,$00,$00,$00,$00    // - unused -
	.byt $7e,$81,$bd,$a1,$ad,$a5,$bd,$7e    // #$39: {G}
	.byt $7e,$81,$a5,$a5,$a5,$a5,$bd,$7e    // #$3a: {U}
	.byt $7e,$81,$b9,$91,$91,$91,$91,$7e    // #$3b: {T}
	.byt $7e,$81,$a1,$a1,$a1,$a1,$bd,$7e    // #$3c: {L}
	.byt $7e,$81,$bd,$a1,$b9,$a1,$bd,$7e    // #$3d: {E}
	.byt $7e,$81,$bd,$a1,$a1,$a1,$bd,$7e    // #$3e: {C}
	.byt $7e,$81,$a5,$a9,$b1,$a9,$a5,$7e    // #$3f: {K}

	.byt $7e,$99,$99,$ff,$bd,$c3,$ff,$7e    // #$17: player closed
	.byt $7e,$99,$ff,$c3,$81,$c3,$e7,$7e    // #$18: player open

// player closed   open           dead
// .xxxxxx.        .xxxxxx.       ........
// x..xx..x        x..xx..x       ........
// x..xx..x        xxxxxxxx       .xxxxxx.
// xxxxxxxx        xx....xx       x..xx..x
// x.xxxx.x        x......x       xxxxxxxx
// xx....xx        xx....xx       xxx..xxx
// xxxxxxxx        xxx..xxx       xx.xx.xx
// .xxxxxx.        .xxxxxx.       .xxxxxx.

//-----------------------------------------------------------------
// Sub-function: Snake direction handler
// - Parameter: A = direction: up:$20,left:$60,down:$a0,right:$e0
// - Result: status.C 0:nOK, 1:OK

move_and_check_snake_pos
	cmp #$40
	bcs l1bf6
	lda #$ff        // ---- up ----
	sta $25
l1b65	lda $08
        sec
        sbc #$16
	bcs l1b71
	dec $09
l1b71	sta $08
	lda $25
	bne l1b7a
	clc
	rts
l1b7a	jsr check_snake_pos       // check if ok to go there
	bcc l1b85       // not ok
	lda #$20        // store new direction
	sta $0a
	sec
	rts
l1b85	sty $25         // abort movement
	bcc l1b8d

l1bf6	cmp #$80
	bcs l1bfd
	lda #$ff        // ---- left ----
	sta $25
l1bb1	dec $08
	lda $08
	cmp #$ff
	bne l1bbb
	dec $09
l1bbb	lda $25
	bne l1bc1
	clc
	rts
l1bc1	jsr check_snake_pos
	bcc l1bcc
	lda #$60
	sta $0a
	sec
	rts
l1bcc	sty $25
	bcc l1bd4

l1bfd	cmp #$c0
	bcs l1bd0
	lda #$ff        // ---- down ----
	sta $25
l1b8d	lda $08
	clc
        adc #$16
        bcc l1b95
	inc $09
l1b95	sta $08
	lda $25
	bne l1b9e
	clc
	rts
l1b9e	jsr check_snake_pos
	bcc l1ba9
	lda #$a0
	sta $0a
	sec
	rts
l1ba9	sty $25
	bcc l1b65

l1bd0	lda #$ff        // ---- right ----
	sta $25
l1bd4	inc $08
	bne l1bda
	inc $09
l1bda	lda $25
	bne l1be0
	clc
	rts
l1be0	jsr check_snake_pos
	bcc l1beb
	lda #$e0
	sta $0a
	sec
	rts
l1beb	sty $25
	bcc l1bb1       // always branch (CC asserted)

//-----------------------------------------------------------------
// Sub-sub-function: Check if new snake position is allowed
// - Result: status.C: 0:nOk, 1:OK
//
check_snake_pos
	lda ($08),y     // read char at new pos of snake head
	cmp #$39        // is a bonus letter?
	bcs l1c42       // yes -> do not go there
	cmp #$1d        // vertical or horizontal borders?
	beq l1c42
	cmp #$1c
	beq l1c42       // yes (either one) -> do not go there
        cmp #$17        // player char?
        beq l1c10
        cmp #$18
        bne l1c20
l1c10   lda v_plr_dead  // yes; player currently eating a snake?
        beq l1c40
        bne l1c42       // yes -> do not allow (equiv. collision with other snake)

l1c20	cmp #$16        // any part of a snake?
	bcs l1c40       // no -> OK

                        // ---- check for collision with other snake ---
	lda $08         // calc color address from snake address
	sta $22
	lda $09
	clc
	adc #$84
	sta $23
	lda ($22),y     // read color code of snake we're hitting
	and #$07
	sta $22         // backup color code
	sty $23
	lda $d7         // get loop variable of current snake (i.e. index * 25)
	beq l1c37
l1c30	inc $23         // calc index/25
	sec
	sbc #$25
	bne l1c30
l1c37	lda $23
	clc
	adc #$02
	cmp $22         // is color == index/25 + 2?
	bne l1c42       // no, i.e. not the same snake -> do not allow
l1c40	sec             // result: OK
	rts
l1c42	clc             // result: not OK
	rts

//-----------------------------------------------------------------
//                      // Snake main tick function

l1c44	ldx #$00        // start of loop across snakes
l1c46	stx $d7         // backup loop control variable; ATTN: X is 25*iteration index
	lda l03a6,x     // snake instance inactive?
	bne l1c50
	jmp l1e15       // yes -> skip this instance

l1c50	sta $0a         // temp copy of current direction
	sta $24         // backup direction (for comparison after direction change)
	lda l0384,x     // temp copy of snake head address
	sta $08
	lda l0384+1,x
	sta $09

	jsr $e094       // get RAND number
	lda $8d
	and #$e0
	cmp #$e0        // with P=75% do not change direction
	beq l1c70
	lda $0a
	jsr move_and_check_snake_pos
	bcs l1cbc       // OK to keep moving in same direction
l1c70	jsr $e094       // get RAND number
	lda $8d
	cmp #$80        // with P=50% try turning right first, else left first
	bcc l1c9c
	clc
	lda $0a         // try to turn 90° left
	adc #$40
	jsr move_and_check_snake_pos
	bcs l1cbc
	lda $0a         // try to turn 90° right
	sbc #$40
	jsr move_and_check_snake_pos
	bcs l1cbc
	lda $0a         // try keeping direction
	jsr move_and_check_snake_pos
	bcs l1cbc
	lda $0a         // try reversing direction
	sbc #$80
	jsr move_and_check_snake_pos
	bcs l1cbc
l1c9c	lda $0a         // try to turn 90° right
	sbc #$40
	jsr move_and_check_snake_pos
	bcs l1cbc
	lda $0a         // try to turn 90° left
	adc #$40
	jsr move_and_check_snake_pos
	bcs l1cbc
	lda $0a         // try keeping direction
	jsr move_and_check_snake_pos
	bcs l1cbc
	lda $0a         // try reversing direction
	adc #$80
	jsr move_and_check_snake_pos

l1cbc	ldx $d7         // update snake status in array with temporaries
	lda $0a
	sta l03a6,x     // write new direction
	lda $08         // store new head address in temporary BEFORE the address array
	sta l0382,x     // (will be moved into array after removing snake tail)
	lda $09
	sta l0382+1,x
	lda l03a4,x     // --- can tail be removed? ---
	sta $22
	lda l03a4+1,x
	sta $23
	txa
	clc
	adc #$20
	tax
l1cdd	lda l0382,x     // start loop: compare tail address with all snake char addresses
	cmp $22
	bne l1ceb
l1ce4	lda l0382+1,x
	cmp $23
	beq l1d21       // same address -> do not write tail
l1ceb	dex
	dex
	cpx $d7         // end loop: compare next char address
	bne l1cdd
                        // --- remove snake tail ---
        lda v_plr_ready // player ready?
        bne l1cf0
	lda $22         // tail address equal home address?
	cmp #<$1112
	bne l1cf0
	lda $23
	cmp #>$1112
	bne l1cf0
	lda #$16        // char for player "target"
	bne l1d04
l1cf0   lda $22
        cmp $03
        bne l1cf1
        lda $23
        cmp $04
        bne l1cf1
        lda #$1b        // char for dead player
	bne l1d04
l1cf1   lda $8f         // get RAND number: decide char to leave behind tail
	and #$bf
	cmp #$35        // char for grant of new snake (P=8%)
	beq l1d04
	cmp #$36        // char for score (i.e. apple; P=8%)
	beq l1d04
	lda #$1a        // else: char for excrement
l1d04	sta ($22),y     // write char behind snake tail
	sta $8f
	clc
	lda $23         // calc color address
	adc #$84
	sta $23
	lda $8f         // check written char code again
	cmp #$35
	beq l1d19
	cmp #$36
	bne l1d1a
l1d19	lda #$04        // color purple, if special char
	bne l1d1f
l1d1a	cmp #$16
        bne l1d1d
        lda #$00        // color black for home char
	beq l1d1f
l1d1d	lda #$07        // else: yellow for excrement or dead player
l1d1f	sta ($22),y     // write color code for char behind tail

l1d21	lda $d7         // --- shift all addresses in snake array ---
	clc             // (note this copies newly calc'ed addr into pos. of snake head)
	adc #$22
	tax
l1d28	lda l0382-2,x   // starting at tail: copy address of preceding segment
	sta l0382,x     // (unrolled loop for performance)
	lda l0382+1-2,x
	sta l0382+1,x
	dex
	dex
	cpx $d7
	bne l1d28

l1d41	lda $0a         //  --- write char for snake head ---
	lsr             // map direction $20,$60,$a0,$e0 -> 1,3,5,7: char for snake head, open
	lsr
	lsr
	lsr
	lsr
        tax
	lda ($08),y     // read char at new position of snake head
	cmp #$16        // any char of a snake? (can only be self)
        bcc l1d57       // yes -> closed mouth
	cmp #$1a        // char for excrement?
	bne l1d58
l1d57   dex             // yes -> map to char for snake head closed: 0,2,4,6
l1d58	txa
        sta ($08),y

	lda $08         // calc color address of snake head
	sta $22
	lda $09
	clc
	adc #$84
	sta $23
	sty $25
	ldx $d7         // restore X
	txa
	beq l1d6f
l1d68	inc $25         // loop to calculate X/25 (i.e. snake index 0,1,...)
	sec
	sbc #$25
	bne l1d68
l1d6f	lda $25
	clc
	adc #$02        // snake head color code: red ... yellow
	sta ($22),y

	lda l0386,x     // --- write middle char to former pos of snake head ---
	sta $22
	lda l0386+1,x
	sta $23
	lda $0a         // determine direction change
	sec
	sbc $24
	cmp #$80
	bne l1d9b
	lda $0a         // 180° turn
	lsr             // map direction $20,$60,$a0,$e0 -> 0,1,2,3
	lsr
	lsr
	lsr
	lsr
	lsr
	clc
	adc #$0e        // + base char for 180° turn
	bne l1dca
l1d9b	cmp #$00        // same direction?
	bne l1db1
	lda $0a
	cmp #$20
	beq l1da9
	cmp #$a0
	bne l1dad
l1da9	lda #$09
	bne l1dca
l1dad	lda #$08
	bne l1dca
l1db1	cmp #$40        // corner
	beq l1dbc
	lda $0a
	sec
	sbc #$40
	bne l1dbe
l1dbc	lda $0a
l1dbe	lsr
	lsr
	lsr
	lsr
	lsr
	lsr
	clc
	adc #$0a
l1dca	sta ($22),y     // write char for mid-section

	lda l03a4,x     // --- write snake tail char to new last-most address ---
	sta $22
	lda l03a4+1,x   // get address of snake tail
	sta $23
	txa
	clc
	adc #$1e+2      // +2 here compensated by -2 below: needed to compare head addr too (despite "bne" loop end cond)
	tax
l1ddd	lda l0384-2,x   // compare tail address with all preceding snake segments
	cmp $22
	bne l1deb
	lda l0384-2+1,x
	cmp $23
	beq l1e15       // equal address found -> skip writing tail
l1deb	dex
	dex
	cpx $d7
	bne l1ddd
	lda $22         // not found -> determine char for snake tail
        sec
	sbc l03a4-2,x   // calc address delta: snake tail minus preceding segment
        bmi l1e01
	cmp #$01
	bne l1e07
	lda #$12        // char for tail end at right
        bne l1e13
l1e07	//cmp #$16
	//bne l1e0d
	lda #$15        // char for tail end at bottom
        bne l1e13
l1e01	cmp #$ff
	bne l1e0d
	lda #$13        // char for tail end at left
        bne l1e13
l1e0d	//cmp #$ea
	//bne l1e14
	lda #$14        // char for tail end at top
l1e13	sta ($22),y     // write snake tail char

l1e15	ldy #$00        // ---- end loop: handling of one snake instance ---
	lda $d7
	clc
	adc #$25        // increment snake instance pointer for iteration
	tax
	cpx v_snk_last  // last active snake done?
	bcs l1e25
	jmp l1c46       // next snake

l1e25	lda v_plr_dead
	bne l1e35
	lda ($03),y     // read char at player position
	cmp #$08        // replaced by snake head?
	bcs l1e35
	jmp l190c       // yes -> kill player

l1e35	lda v_snk_cnt   // all snakes dead?
	beq l1e4d
	lda v_game_time
	and #$04
	beq l1e45
	lda #$0f        // max volume
	bne l1e47
l1e45	lda #$08        // medium volume
l1e47	sta $900e       // set volume
	inc v_game_time // increment game time counter

l1e4d	ldy v_game_speed // time delay (II)
l1e4f	ldx #$ff
l1e51	dex
	bne l1e51
	dey
	bne l1e4f

	jmp l17ea       // loop back to player actions

//-----------------------------------------------------------------
//                      // Tick function while player eating snake

l1e67	ldx v_snk_eat_seg
l1e6a	tya             // start loop: search if player address equal any other snake segment
l1e6b	sta l0384,x
	cpx v_snk_eat_inst
	beq l1e85
	dex
	dex
	lda l0384,x
	cmp $03
	bne l1e6b
	lda l0384+1,x
	cmp $04
	bne l1e6a
	beq l1e98       // equal address found -> skip writing player char here

l1e85	lda #$19        // write char for food: clearing player char
	sta ($03),y
	lda $03         // calc address of color code
	sta $22
	lda $04
	clc
	adc #$84
	sta $23
	lda #$01        // color: white
	sta ($22),y

l1e98	ldx v_snk_eat_seg  // reached snake head?
	cpx v_snk_eat_inst
	beq l1ea7       // yes -> done
        dex             // no -> proceed eating next segment (towards head)
	dex
	stx v_snk_eat_seg
	lda l0384,x     // set player address to that of next snake segment
	sta $03
	lda l0384+1,x
	sta $04

	lda v_game_speed  // ---- time delay ----
	sbc #$18
	tay
	beq l1ec1
	cmp #$30
	bcc l1ec3
l1ec1	ldy #$01
l1ec3	ldx #$ff
l1ec5	dex
	bne l1ec5
	dey
	bne l1ec3

	lda #$81        // increase score by 81 per snake segment (1782 total)
        ldx #$00
	jsr add_score

	ldx v_snk_eat_seg  // start loop to search new player address in remaining snake segments
l1ed3	cpx v_snk_eat_inst
	beq l1eea
	dex
        dex
        lda l0384,x
        cmp $03
        bne l1ed3
        lda l0384+1,x
        cmp $04
        bne l1ed3

        lda #$80        // found -> skip placing player char
        sta $900d       // generate noise
        jmp l1aed       // skip placing player

l1eea   lda #$19        // not found -> set player face to open/eating
        sta v_plr_face
        jmp l1ac1       // place player

l1ea7	sty v_plr_face  // done; switch player face to closed/not eating
	sty v_plr_dead  // reset "eating" status to normal "alive" status
	jmp l1ac1       // eating done ==> back to regular player status update

//-----------------------------------------------------------------
// Sub-function: Identify & eat snake whose tail was bitten by player
// - Parameters: global $03-$04: player address
// - Side-effects: Invalidates X
// - Results: status.C: 0:nOk (i.e. snake not found), 1:OK

start_eating_snake
        ldx #$00        // search snake array for one with tail at player address
l1934	lda l03a6,x     // snake instance inactive?
	beq l1942
	lda l03a4,x
	cmp $03
	bne l1942
	lda l03a4+1,x
	cmp $04
	beq l1944
l1942	txa
	clc
	adc #$25
	tax
	cpx v_snk_last  // last snake done?
	bcc l1934
        clc             // not found (should never happen)
        rts

l1944	stx v_snk_eat_inst  // found snake: save index
	txa
	clc
	adc #l03a4-l0384
	sta v_snk_eat_seg       // address of currently eaten snake segment
        tya
        sta l03a6,x     // mark snake inactive
	dec v_snk_cnt   // reduce number of active snakes
        txa
	clc
	adc #$25
        cmp v_snk_last
        bcc l1940
	stx v_snk_last  // FIXME (harmless) check preceding if also inactive
l1940   sec             // return success indicator
        rts

// ----------------------------------------------------------------------------
// Sub-function: Activate a new snake
// The call is ignored if the maximum number of snake is already active.
// - Parameters: $08-$09: snake address on screen
// - Side-effects: overwrites temporary $d7
//                 invalidates X
//                 invokes RAND function (invalidates $22-$23)
// - Results: none

spawn_snake
	lda v_snk_cnt
	cmp #$06
	bcs l13b4       // abort if max. number of snakes already reached
	inc v_snk_cnt   // increment number of snakes

	ldx #$00        // search for unused snake instance
        sty $24
l137c	lda l03a6,x     // instance inactive?
	beq l1389       // yes -> stop search; use this one
        inc $24
	txa
	clc
	adc #$25        // advance address to next struct
	tax
	clc
	bcc l137c

l1389	stx $d7         // backup struct start offset
	txa
	clc
	adc #$22        // add offset to snake's tail address
	tax
l1391	lda $08         // start loop: init all snake segment addresses to start address
	sta l0382,x
	lda $09
	sta l0382+1,x
	dex             // advance offset to next snake element in struct
	dex
	cpx $d7         // end loop across all snake elements, up to struct start
	bne l1391

	jsr $e094       // get RAND number
	lda $8d
	and #$c0        // derive direction $20,$60,$a0,$e0
        eor #$20
        ldx $d7
	sta l03a6,x
        ldy #$00

        // FIXME check if pos is blank: if yes stall tick until pos free
	//lda ($08),y     // read char at new position of snake head
	//cmp #$16        // any char of a snake? (can only be self)
        //bcc l1d57       // yes -> closed mouth

	eor #$20        //  --- write char for snake head ---
	lsr             // map direction -> 0,2,4,6: char for snake head, open
	lsr
	lsr
	lsr
	lsr
        sta ($08),y
llx
	lda $09         // calc color address
	clc
	adc #$84
	sta $09
        lda $24
	adc #$02        // snake head color code: red ... yellow
	sta ($08),y

	txa             // new max snake index?
	clc
	adc #$0b
	cmp v_snk_last
	bcc l13b4
	sta v_snk_last
l13b4	rts

//-----------------------------------------------------------------
// Variables

v_plr_skill     .byt 0      // player skill/level
v_plr_ready     .byt 0      // 0:player not ready
v_plr_dead      .byt 0      // $00:player alive; $60:eating snake; $f0:dead
v_plr_face      .byt 0      // controls char used for player: open/closed mouth
v_plr_score     .byt 0,0,0  // score in BCD (little endian)
v_plr_lives	.byt 0      // counter of remaining player lives
v_plr_bonus_cnt	.byt 0      // counter bonus letters picked-up by user

v_game_time     .byt 0      // main loop counter (for timer purposes)
v_game_speed    .byt $26    // factor for time delay in main loop
v_key_prev      .byt $40    // previously processed key
v_key_next      .byt $40    // next key, or $40 if none
v_key_cur       .byt $40    // current key (temporary use during player actions)

v_snk_eat_inst	.byt 0      // while eating snake: index*$25 of snake instance
v_snk_eat_seg   .byt 0      // while eating snake: index eaten snake segment (v_snk_eat_inst+{0..$22})

v_snk_cnt       .byt 0      // counter active snakes
v_snk_last      .byt 0      // offset behind last valid instance in snake array (e.g. 0 if cnt=0)
v_snakes        .dsb 6*$25, 0  // array of struct size $25 (size must be <=$ff)

// The following are always used with X offsets, where X contains a multiple of
// the struct size $25. Sometimes X contains additional offsets to iterate
// across the array of addresses contained within the struct.
l0382 = v_snakes        // new head addr (during movement)
l0384 = v_snakes + 2    // head addr
l0386 = v_snakes + 4    // first middle segments addr
l03a4 = v_snakes + $22  // tail addr
l03a6 = v_snakes + $24  // direction $20,$60,$a0,$e0; $00:inactive
