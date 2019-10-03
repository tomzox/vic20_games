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

// variables in ZP:
// #$00:        skill/level
// #$01-$02:    score digits: lowest 99, middle 99
// #$03-$04:    player address
// #$05:        score digits > 9999 (i.e. highest 99)
// #$06:        0:player not ready
// #$07:        0:player alive
// #$08-$09:    snake head address
// #$0a:        snake direction (short)
// #$0b:        unused

// #$0348-$034a: unknown

// snake data:
// #$0380:       pos. while being eaten
// #$0381:       unused?
//
// struct size #$25
// #$0382-$0383: pre-head
// #$0384-$0385: head
// #$0386...:    middle part
// #$03a4-$03a5: tail
// #$03a6:       direction (up:$20,left:$60,down:$a0,right:$e0)
//
// #$03a7-$03a8: pre-head
// #$03a9-$03aa: head
// #$03ab...:    middle part
// #$03c9-$03ca: tail
// #$03cb:       direction

// ----------------------------------------------------------------------------
//                      // Display text including color codes

l123d   .byt 22,67,12   // Highscore value (digits%100): 126722
        .byt $00

l1241	.byt $28,$00    // "SKILL:"
	.byt $38,$00
	.byt $24,$00
	.byt $25,$00
	.byt $25,$00
	.byt $1b,$00
	.byt $20,$01    // white
	.byt $20,$01
	.byt $20,$01
l1252	.byt $28,$00    // "SCORE:" (black)
	.byt $1f,$00
	.byt $26,$00
	.byt $27,$00
	.byt $21,$00
	.byt $1b,$00
	.byt $2b,$01    // white
	.byt $2b,$01
	.byt $2b,$01
	.byt $2b,$01
	.byt $2b,$01
	.byt $2b,$01
	.byt $20,$01
l126c	.byt $23,$02    // "HIGHSCORE:" (red)
	.byt $24,$02
	.byt $22,$02
	.byt $23,$02
	.byt $28,$02
	.byt $1f,$02
	.byt $26,$02
	.byt $27,$02
        .byt $21,$02
        .byt $1b,$02
        .byt $20,$02
        .byt $20,$02
        .byt $20,$02
        .byt $20,$02
        .byt $20,$02
        .byt $20,$02
        .byt $20,$02
        .byt $20,$06   // blue
        .byt $20,$06
        .byt $20,$06
l1295   .byt $07,$12,$05,$01,$14   // "Great"
l129a   .byt $13,$0d,$01,$0c,$0c,$20,$02,$0f,$0e,$15,$13,   // "Small Bonus: 2000 PTS"
        .byt $3a,$20,$32,$30,$30,$30,$20,$10,$14,$13
l12af   .byt $02,$19,$20,$5a,$0f,$05,$12,$0e,$05,$12   // "by Zoerner"
l12b9   .byt $53,$03,$08,$0c,$01,$0e,$07,$05,$0e   // "Schlangen"
l12c2	.byt $39,$3a,$3b,$00,$39,$3c,$3a,$3d,$3e,$3f   // {GUT} {GLUECK}
l12cc   .byt $22,$37,$29,$20,$22,$25,$37,$21,$1f,$38,$2a   // "GUT GLUECK!"
l12d7   .byt $39,$3a,$3b,$39,$3c,$3a,$3d,$3e,$3f   // {GUTGLUECK}: bonus letters on playing field

// .text
// * = $12e0

// ----------------------------------------------------------------------------
//                      // Sub-function: Increase & print score
//                      // Parameter: X = points to be added

l12e0	inc $01         // increment first/lowest decimal
	lda $01
	cmp #$64        // first==100?
	bne l12f6
	inc $02         // increment second decimal
	sty $01         // zero first decimal
	lda $02
	cmp #$64        // second==100?
	bne l12f6
	inc $05         // increment third decimal
	sty $02         // zero second decimal
l12f6	dex             // loop for number of points to be added
	bne l12e0

l12f9	lda $01         // !! Alternate sub-function entry point
	sta $24
	lda $02
	sta $23
	lda $05
	sta $22
//                      // fall-through

// ----------------------------------------------------------------------------
//                      // Sub-function: Print highscore
//                      // Parameter: $22-$24: MSB-LSB of score
l1305	ldx #$00
l1307	lda #$0a
	sta $25
	lda #$00        // init counter for multiples of 10
	sta $4b
l130f	lda $22,x       // load next digit
	cmp $25         // >= n*10?
	bcc l1320
	clc
	lda #$0a        // increment n by 10
	adc $25
	sta $25
	inc $4b
	bne l130f
l1320	lda $4b
	adc #$2b        // user-defined char '0'
	sta $4b
l1327 = * + 1           // instruction operand modified by code
l1328 = * + 2
	sta $100f,y     // draw higher digit
	lda $22,x
	adc #$36
	sbc $25
	iny
l1331 = * + 1           // instruction operand modified by code
l1332 = * + 2
	sta $100f,y     // draw lower digit
	inx
	cpx #$03        // loop for next 2 digits, max. 2*3
	iny
	bcc l1307
	ldy #$00
	rts
// ----------------------------------------------------------------------------
//                      // Sub-function: Check player movement
//
l133c	lda ($03),y     // read char at player address on screen
	cmp #$1a        // hit "excrement"?
	bne l1356
	lda $00         // any "skill" left?
	beq l1363       // no -> disallow
	lda $028e       // read prev. status of SHIFT key
	bne l1352
	lda $911f
        and #20
        bne l1363       // no SHIFT or joystick-fire -> disallow
l1352	dec $00         // reduce "skill" -1
	sec             // allow movement
	rts
l1356	cmp #$06        // hit snake head?
	bcc l135e
	cmp #$12        // hit snake tail?
	bcc l1363
l135e	jmp l13cb       // check for other special chars
	sec             // result: allow (never reached!?)
	rts
l1363	lda #$aa        // result = do not allow
	sta $25
	clc
	rts
// ----------------------------------------------------------------------------
//                      // Sub-function: Initialize snake
//                      // Parameters:   A = Direction
//                      //               X = LSB snake address on screen
//                      //               Y = MSB snake address on screen
l1369	sta $0348
	stx $0349
	lda l1efc
	cmp #$05
	bcs l13b4       // abort if max. number of snakes already reached
	nop
	inc l1efc       // increment number of snakes
	ldx #$00        // search for unused snake status struct
l137c	lda $03a6,x
	beq l1389       // stop if struct is free (invalid direction value)
	txa
	clc
	adc #$25        // advance address to next struct
	tax
	clc
	bcc l137c
l1389	stx $034a       // temp. save struct start offset
	txa
	clc
	adc #$22        // add offset to snake's tail address
	tax
l1391	lda $0349       // write given snake address
	sta $0382,x
	tya
	sta $0383,x
	dex             // advance offset to next snake element in struct
	dex
	cpx $034a       // iterate across all snake elements, up to struct start
	bne l1391
	lda $0348       // write given direction
	sta $03a6,x
	txa
	clc
	adc #$0b
	cmp l1efa       // new max?
	bcc l13b4
	sta l1efa
l13b4	ldy #$00
	rts
// ----------------------------------------------------------------------------
//                      // Sub-function: Clear player figure
l13b7	lda $03
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
//                      // Sub-function: eat target (or don't)
//                      // Parameter: A = char at player figure
//                      // Returns status.C: 0:nOK, 1:OK (allow movement)
//
l13cb	cmp #$1c        // is border?
	beq l13d3
	cmp #$1d
	bne l13d6
l13d3	jmp l1363       // return to level control: do not allow movement
l13d6	cmp #$39        // letter characters?
	bcs l13dc
	sec             // return: allow
	rts
l13dc	lda $06         // player ready?
	beq l13d3       // not ready -> do not allow eating letters
	ldx l1efe       // get number of eaten bonus chars as index
	lda l12c2,x
	cmp ($03),y     // is next expected bonus char?
	bne l13d3       // no -> do not allow
	sta $11ea,x     // mark letter as done in status bar
	inc l1efe       // increase number of consumed letters
	cpx #$02        // skip blank in bonus letter sequence (i.e. after "GUT")
	bne l13f7
	inc l1efe
l13f7	inc $00         // increase skill +1
	ldx #$fa
	jsr l12e0       // increase score by 250
	sec             // return: allow
	rts

// ----------------------------------------------------------------------------
// Character generator data
// - 64 user-defined characters, 8x8 bit each
// - mapped to start at $1400 (register $9005)

//                      // Parameter: A = direction: up:$20,left:$60,down:$a0,right:$e0

l1400	.byt $00,$58,$58,$5c,$5e,$4a,$7a,$7e    // #$00: snake head: upwards & closed
	.byt $00,$46,$46,$4e,$4e,$5a,$5a,$7e    //                   upwards & open
	.byt $00,$0f,$19,$7f,$7b,$03,$7f,$00    //                   left & closed
	.byt $00,$7f,$79,$1f,$07,$01,$7f,$00    //                   left & open
	.byt $7e,$5e,$52,$7a,$3a,$1a,$1a,$00    //                   down & closed
	.byt $7e,$5a,$5a,$72,$72,$62,$62,$00    //                   down & open
	.byt $00,$f0,$98,$fe,$de,$c0,$fe,$00    //                   right & closed
	.byt $00,$fe,$9e,$f8,$e0,$80,$fe,$00    //                   right & open
	.byt $00,$00,$ff,$ff,$ff,$ff,$00,$00    // #$08: snake horizontal
	.byt $3c,$3c,$3c,$3c,$3c,$3c,$3c,$3c    // #$09: snake vertical
	.byt $3c,$7c,$f8,$f8,$f0,$f0,$00,$00    // #$0a: snake corners
	.byt $00,$00,$c0,$f0,$f8,$f8,$7c,$3c
	.byt $00,$00,$03,$0f,$1f,$1f,$3e,$3c
	.byt $3c,$3e,$1f,$1f,$0f,$03,$00,$00
	.byt $3c,$5e,$ef,$f7,$e7,$ff,$7e,$3c    // #$0e: snake 180� turn
	.byt $3c,$7e,$ff,$e7,$d7,$bf,$7e,$3c
	.byt $3c,$7e,$ff,$e7,$ef,$f7,$fa,$3c
	.byt $3c,$7e,$fd,$eb,$e7,$ff,$7e,$3c
	.byt $00,$00,$f8,$fe,$fe,$f8,$00,$00    // #$12: snake tail
	.byt $00,$00,$1f,$7f,$7f,$1f,$00,$00
	.byt $00,$18,$18,$3c,$3c,$3c,$3c,$3c
	.byt $3c,$3c,$3c,$3c,$3c,$18,$18,$00    //                   end at bottom
	.byt $00,$3c,$42,$5a,$5a,$42,$3c,$00    // #$16: target
	.byt $7e,$99,$99,$ff,$bd,$c3,$ff,$7e    // #$17: player closed
	.byt $7e,$99,$ff,$c3,$81,$c3,$e7,$7e    // #$18: player open
	.byt $00,$00,$18,$24,$24,$18,$00,$00    // #$19: food (score points)
	.byt $00,$00,$00,$00,$08,$00,$00,$00    // #$1a: excrement
	.byt $00,$00,$08,$00,$00,$08,$00,$00    // #$1b: ':'
	.byt $00,$00,$00,$ff,$ab,$d5,$ab,$ff    // #$1c: border horizontal
	.byt $ff,$ab,$d5,$ab,$d5,$ab,$d5,$ff    // #$1d: border vertical
	.byt $18,$24,$42,$7e,$42,$42,$42,$00    // #$1e: 'A'
	.byt $1c,$22,$40,$40,$40,$22,$1c,$00    // #$1f: 'C'

	.byt $00,$00,$00,$00,$00,$00,$00,$00    // #$20: blank
	.byt $7e,$40,$40,$78,$40,$40,$7e,$00    // #$21: 'E'
	.byt $1c,$22,$40,$4e,$42,$22,$1c,$00    // #$22: 'G'
	.byt $42,$42,$42,$7e,$42,$42,$42,$00    // #$23: 'H'
	.byt $1c,$08,$08,$08,$08,$08,$1c,$00    // #$25: 'I'
	.byt $40,$40,$40,$40,$40,$40,$7e,$00    // #$26: 'L'
	.byt $18,$24,$42,$42,$42,$24,$18,$00    // #$27: 'O'
	.byt $7c,$42,$42,$7c,$48,$44,$42,$00    // #$28: 'R'
	.byt $3c,$42,$40,$3c,$02,$42,$3c,$00    // #$29: 'S'
	.byt $3e,$08,$08,$08,$08,$08,$08,$00    // #$2a: 'T'
	.byt $12,$12,$12,$12,$00,$00,$12,$00    // #$2a: fat exclamation mark '!'
	.byt $3c,$42,$46,$5a,$62,$42,$3c,$00    // #$2b..$34: digits '0'..'9'
	.byt $08,$18,$28,$08,$08,$08,$3e,$00
	.byt $3c,$42,$02,$0c,$30,$40,$7e,$00
	.byt $3c,$42,$02,$1c,$02,$42,$3c,$00
	.byt $04,$0c,$14,$24,$7e,$04,$04,$00
	.byt $7e,$40,$78,$04,$02,$44,$38,$00
	.byt $1c,$20,$40,$7c,$42,$42,$3c,$00
	.byt $7e,$42,$04,$08,$10,$10,$10,$00
	.byt $3c,$42,$42,$3c,$42,$42,$3c,$00
	.byt $3c,$42,$42,$3e,$02,$04,$38,$00
	.byt $70,$a8,$f8,$8e,$7b,$1f,$10,$1f    // #$35: symbol: grant level + snake
	.byt $06,$0e,$08,$3c,$7e,$7e,$7e,$3c    // #$36: apple: score bonus
	.byt $42,$42,$42,$42,$42,$42,$3c,$00    // #$37: 'U'
	.byt $42,$44,$48,$70,$48,$44,$42,$00    // #$38: 'K'
	.byt $7e,$81,$bd,$a1,$ad,$a5,$bd,$7e    // #$39: {G}
	.byt $7e,$81,$a5,$a5,$a5,$a5,$bd,$7e    // #$3a: {U}
	.byt $7e,$81,$b9,$91,$91,$91,$91,$7e    // #$3b: {T}
	.byt $7e,$81,$a1,$a1,$a1,$a1,$bd,$7e    // #$3c: {L}
	.byt $7e,$81,$bd,$a1,$b9,$a1,$bd,$7e    // #$3d: {E}
	.byt $7e,$81,$bd,$a1,$a1,$a1,$bd,$7e    // #$3e: {C}
	.byt $7e,$81,$a5,$a9,$b1,$a9,$a5,$7e    // #$3f: {K}

// ----------------------------------------------------------------------------
//                      // Game entry point:
//                      // start graphics
l1600	lda #$00
	sta $900e
	lda #$19        // set screen color: screen:white border:white
	sta $900f
	lda #$c2        // reset screen & character map addresses
	sta $9005
	jsr $e55f       // clear screen
	ldx #$09        // print game title on screen
l1614	lda l12b9-1,x
	sta $10f7,x
	lda #$02        // color: red
	sta $94f7,x
	dex
	bne l1614
l1622	lda $cb         // wait for no key pressed
	cmp #$40
	bne l1622
	lda #$ff        // disable SHIFT/Commodore case switching
	sta $0291
l162d	lda $cb         // wait for keypress or joystick
	cmp #$40
	bne l163a
	lda $911f
#if 0
// FIXME does not work in VICE
//	cmp #$7e
//	beq l162d
#else
        nop
        clc
	bcc l162d
#endif
l163a	lda $00         // read level to check if this is first run of game
	cmp #$4c        // no -> skip author display
	beq l1643
	jmp l1666

l1643	jsr $e55f       // clear screen again
	ldx #$0a
l1648	lda l12af-1,x   // print author's name on screen
	sta $10f7,x
	lda #$06        // color: blue
	sta $94f7,x
	dex
	bne l1648
	lda #$04        // time delay apx. 2 seconds
l1658	ldy #$fe
l165a	ldx #$ff
l165c	dex
	bne l165c
	dey
	bne l165a
	sbc #$01
	bne l1658

//                      // ---- cold start of game ----
l1666	lda #$02
	sta l1efd       // init number of lives := 2
	lda #$00
	sta $fb         // clear warm boot flag
                        // fall-through
l166f	lda #$1f        // ---- warm-boot / restart of game ----
	sta l1327       // patch screen output address for score display sub-function
	sta l1331
	jsr $e55f       // clear screen
	lda #$ac        // set screen color: screen:pink border:purple
	sta $900f
	lda #$cd        // configure screen & character map addresses
	sta $9005       // screen:$1000, color:$9400, charmap:$1400

	lda #$42        // loop to draw "food" on screen $1000...
	sta $00
	lda #$10
	sta $01
	ldx #$02
l168e	ldy #$c5
l1690	lda #$19        // "food" char code
	sta ($00),y
	lda $00         // calculate color code addr: add $9400-$1000 to address
	sta $22
	lda $01
	clc
	adc #$84
	sta $23
	lda #$07        // color: yellow
	sta ($22),y
	dey
	bne l1690
	lda #$07
	sta $00
	inc $01
	dex
	bne l168e

	ldx #$16        // draw horizontal borders at top & bottom
l16b1	lda #$1c
	sta $102b,x
	lda #$1d
	sta $11cd,x
	lda #$00
	sta $942b,x
	sta $95cd,x
	dex
	bne l16b1

	lda #$42        // draw vertical border at left and right side
	sta $00
	sta $02
	lda #$10
	sta $01
	sta $05
	lda #$57
	sta $04
	sta $06
	lda #$94
	sta $03
	sta $07
	lda #$12        // counter for outer loop = border height
	sta $08
l16e2	ldy #$00
	lda #$1d        // border char code
	sta ($00),y
	sta ($04),y
	lda #$00        // color: black
	sta ($02),y
	sta ($06),y
	ldx #$16        // inner loop: add 22 to all pointers
l16f2	inc $00
	inc $02
	bne l16fc
	inc $01
	inc $03
l16fc	inc $04
	inc $06
	bne l1706
	inc $05
	inc $07
l1706	dex
	bne l16f2
	dec $08
	bne l16e2

	ldx #$2b        // display highscore
	ldy #$57
l1711	lda l123d,y
	sta $93fe,x
	dey
	lda l123d,y
	sta $0ffe,x
	dey
	dex
	bne l1711
	lda l123d
	sta $24
	lda l123d+1
	sta $23
	lda l123d+2
	sta $22
	jsr l1305       // print highscore

	lda #$16        // display "target" char in middle of screen: X/Y=10/12
	sta $1112
	lda #$0f
	sta l1327
	sta l1331
	ldy #$00        // initialize player status: not ready, alive
	sty $06
	sty $07
	lda #$cc        // calc initial player address
	sta $03
	lda #$11
	sta $04
	lda #$17        // display player char
	sta ($03),y
	lda #$03        // initialize skill = 3
	sta $00
	sty l1efc       // initialize snake counter = 0
	lda #$01
	sta $9512

	ldx #$00        // clear all snakes: invalid direction value
l1761	lda #$00
	sta $03a6,x
	txa
	clc
	adc #$25
	tax
	cmp #$d0        // loop for 5 snakes
	bcc l1761

	sty l1efa       // init snake max to 0
	nop
	lda #$a0        // spawn first snake: dir=down, X/Y=5/8
	ldx #$b5
	ldy #$10
	jsr l1369
	lda #$20        // spawn second snake: dir:up, X/Y=16/15
	ldx #$6f
	ldy #$11
	jsr l1369

	lda l1efd       // display number of lives in bottom-left corner
	beq l1793
	tax
	lda #$17        // char for player, drawn once for each life
l178d	sta $11e3,x
	dex
	bne l178d
l1793	lda $fb         // warm boot -> init or restore score respectively
	bne l17a4
	lda #$26        // delay factor
	sta $16
	sty $01         // init score to 0
	sty $02
	sty $05
	clc
	bcc l17b0
l17a4	lda $fc         // restore score
	sta $01
	lda $fd
	sta $02
	lda $fe
	sta $05
l17b0	lda #$09        // copy letters from ROM into RAM for user-defined chars
	sta $fc
l17b4	jsr $e094       // get RAND number
	lda $8d
	and #$01        // calculate addr on screen (LSB random byte; MSB random either $10 or $11)
	clc
	adc #$10
	sta $8d         // FIXME overwrites rand number storage with address
	lda ($8c),y     // read this screen position
	cmp #$19        // food char?
	bne l17b4       // no -> try another random position
	ldx $fc
	lda l12d7-1,x   // get next bonus letter from sequence
	sta ($8c),y     // draw letter char
	lda $8d
	clc
	adc #$84        // calc color address
	sta $8d
	lda #$02        // color: red
	sta ($8c),y
	dec $fc         // next character in iteration
	bne l17b4
	ldx #$0b
l17de	lda l12cc-1,x   // print "good luck" message
	sta $11e9,x
	dex
	bne l17de
	sty l1efe       // initialize count of bonus letters on screen = 0

//-----------------------------------------------------------------
//                      // Player control

l17ea	lda #$ff
	sta $9122
	lda $cb         // poll for keypress
	cmp #$09        // key 'w'?
	beq l17fc
	lda $911f       // poll joystick
	and #$04
	bne l181c

l17fc	sty $25         // handle key 'w': up
	jsr l13b7
l1801	ldx #$16        // calc new player addr: -= 22 (via loop)
l1803	dec $03
	lda $03
	cmp #$ff
	bne l180d
	dec $04
l180d	dex
	bne l1803
	lda $25
	bne l1819
	jsr l133c
	bcc l182e
l1819	jmp l1893

l181c	lda $cb
	cmp #$21        // key 'z'?
	beq l1829
	cmp #$0b        // key 'y': equiv. 'Z' for German keyboard
	beq l1829
l1822	lda $911f
	and #$08
	bne l1845

l1829	sty $25         // handle 'z': down
	jsr l13b7
l182e	ldx #$16
l1830	inc $03
	bne l1836
	inc $04
l1836	dex
	bne l1830
	lda $25
	bne l1842
	jsr l133c
	bcc l1801
l1842	jmp l1893

l1845	lda $cb
	cmp #$11        // key 'a'?
	beq l1852
	lda $911f
	and #$10
	bne l186d

l1852	sty $25         // handle 'a': left
	jsr l13b7
l1857	dec $03
	lda $03
	cmp #$ff
	bne l1861
	dec $04
l1861	lda $25
	bne l186a
	jsr l133c
	bcc l1884
l186a	jmp l1893

l186d	lda $cb
	cmp #$29        // key 's'?
	beq l187f
	lda #$7f
	sta $9122
	lda $9120
	and #$80
	bne l1893

l187f	sty $25         // handle 's': right
	jsr l13b7
l1884	inc $03
	bne l188a
	inc $04
l188a	lda $25
	bne l1893
	jsr l133c
	bcc l1857

//-----------------------------------------------------------------
//                      // Checking / level display

l1893	lda #$0a        // calculate skill/10 and skill%10
	sta $25
	sty $4b
l1899	lda $00
	cmp $25
	bcc l18aa
	clc
	lda $25
	adc #$0a
	sta $25
	inc $4b
	bne l1899
l18aa	lda $4b
	adc #$2b        // add user-defined char '0'
	sta $1006       // print skill/10 digit
	lda $00
	adc #$36
	sbc $25
	sta $1007       // print skill%10 digit

	lda $06         // player ready?
	beq l18c9       // no -> do not score for eating food
l18be	lda ($03),y     // read char under player figure
	cmp #$19        // "food" char?
	bne l18c9
	ldx #$0a        // score +10
	jsr l12e0

l18c9	lda $06         // player "ready"?
	bne l1904       // yes -> skip obsolete check for home position
	lda $03         // player address equal home address?
	cmp #$12
	bne l1904
	lda $04
	cmp #$11
	bne l1904
	lda #$01        // yes -> mark player as ready
	sta $06
	lda #$21        // print "EAT" in upper right corner
	sta $1027
	lda #$1e
	sta $1028
	lda #$29
	sta $1029
	lda $00
	beq l1900       // skill zero? -> to pre-reaction
	tax             // start loop to add score by skill * 100 points
l18f1	inc $02         // increase score by 100 (loop)
	lda $02
	cmp #$64        // digit pair >= 100?
	bcc l18fd
l18f9	sty $02         // increase third digit pair
	inc $05         // zero second digit pair
l18fd	dex
	bne l18f1
l1900	lda #$04        // initialize skill to 4 ("level II")
	sta $00

l1904	sty $4c

	lda ($03),y     // read char under player
	cmp #$08        // snake head?
	bcs l1915
l190c	lda #$f0        // kill player
	sta $07
	lda #$d8        // sound effect
	sta $900c

l1915	cmp #$12        // hit snake tail? ($12-$15)
	bcc l1965
	cmp #$16
	bcs l1965
	lda $06         // yes; player ready?
	beq l195d
	lda $028e       // yes; SHIFT key or joystick FIRE pressed?
	bne l192d
	lda $911f
	and #$20
	bne l195d       // neither -> skip
l192d	lda l1efa       // search snake array for one with tail at player address
	clc
	adc #$17
	tax
l1934	lda $0382,x
	cmp $03
	bne l1942
	lda $0383,x
	cmp $04
	beq l1949
l1942	txa
	clc
	sbc #$24
	tax
	bpl l1934
l1949	stx $0380       // found snake index
	txa
	sec
	sbc #$22
	sta l1ef9
	lda #$60
	sta $07
	dec l1efc
	tya
	beq l196b
l195d	ldx #$07        // score +7
	jsr l12e0
	clc
	bcc l196b       // always true

l1965	cmp #$19        // found food?
	bne l196b
	sta $4c

l196b	lda l1efb       // time score
	asl
	asl
	asl
	asl
	bne l197e       // only once per 16 iterations
	lda l1efc       // any snakes alive?
	asl
	tax
	beq l197e       // no -> no score
	jsr l12e0       // yes -> score +2 for each living snake

l197e	lda $06         // player ready?
	beq l19a1       // no -> ignore eating apple or snake symbols
	lda ($03),y
	cmp #$36        // yes; found apple?
	bne l1990
	ldx #$fa        // yes: grant 250 points
	jsr l12e0
	clc
	bcc l199d       // increase skill +2

l1990	cmp #$35        // found snake grant symbol?
	bne l19a1
	lda #$a0
	ldx #$12
	ldy #$11
	jsr l1369       // spawn new snake
l199d	inc $00         // increase skill +2
	inc $00

l19a1	lda $cb         // poll keyboard        
	cmp #$07        // key INSERT? (added for emulator)
        beq l19a2
	cmp #$06        // pound key? (skill demand)
	bne l19d0
l19a2	lda $00
	cmp #$02        // skill >= 2?
	bcs l19d0       // yes -> disallow
	lda $02         // middle digit pair of score
	cmp #$0a        // >= 10?
	bcs l19c2       // yes (i.e. score < 1000) -> OK
	lda $05         // highest digit pair
	cmp #$01        // >= 1? (i.e. score >= 10000)
	bcc l19d0       // no -> disallow
	dec $05         // yes; decrement and (temporary) add 100 to lower digit pair
	lda $02
	clc
	adc #$64
	sta $02
l19c2	lda $02
	sec             // score -1000 points: subtract 10 from middle digit pair
	sbc #$0a
	sta $02
	inc $00         // increase skill +2
	inc $00
	jsr l12f9       // display score

l19d0	lda $cb         // poll keyboard
	cmp #$08        // left arrow key?
	beq l19d9
	cmp #$27        // key F1? (added for emulator)
	beq l19d9
l19d6	jmp l1a80
l19d9	lda l1efe
	cmp #$0a        // all 10 bonus chars picked-up?
	bne l19d6       // no -> disallow
	lda l1efc       // any snakes left alive?
	bne l19e9
	lda #$0b        // no -> great bonus: 2750
	bne l19eb
l19e9	lda #$07        // yes -> small bonus: 1750
l19eb	sta $fa
l19ed	ldx #$fa        // loop to add N*250 as determined above
	jsr l12e0
	dec $fa
	bne l19ed
	ldx #$15        // print bonus message
l19f8	lda l129a-1,x
	sta $11e3,x
	lda #$02
	sta $95e3,x
	dex
	bne l19f8
	lda $00         // skill zero?
	beq l1a13               
l1a0a	ldx #$fa        // no; loop to score +250 for each skill/level left
	jsr l12e0
	dec $00
	bne l1a0a
l1a13	lda l1efc
	bne l1a28       // snakes still alive
	lda #$33
	sta $11f1
	ldx #$05        // print "great"
l1a1f	lda l1295-1,x
	sta $11e3,x
	dex
	bne l1a1f
l1a28	sty $22         // split screen
	sty $23
	sty $24
l1a2e	lda $9004       // query video line being scanned for TV-out
	cmp #$7e
	bcc l1a3a
	lda #$c0
	clc
	bcc l1a3c

l1a3a	lda #$cd        // re-configure screen & character map addresses
l1a3c	sta $9005
	inc $22
	bne l1a2e
	inc $23
	bne l1a2e
	inc $24
	cmp #$10
	bcc l1a2e
	inc $00
l1a4f	ldx #$fa
	jsr l12e0
	dec $00
	bne l1a4f
	lda l1efd
	cmp #$03
	bcs l1a64
	inc l1efd
	bne l1a69
l1a64	ldx #$ff
	jsr l12e0

l1a69	dec $16
	dec $16
l1a6d	lda #$80        // set flag to indicate warm boot
	sta $fb
	lda $01         // backup score value
	sta $fc
	lda $02
	sta $fd
	lda $05
	sta $fe
	jmp l166f       // to start of game

l1a80	lda $cb         // poll keyboard
	cmp #$08        // left arrow key?
	beq l1a81
	cmp #$27        // key F1? (added for emulator)
	bne l1aa3
l1a81	lda $00         // skill zero?
	beq l1a95       // yes -> allow
	lda $1112       // read screen at pos. of target symbol
	cmp #$16        // target symbol still present? (else: eaten by snake)
	beq l1aa3
	lda $06         // target gone; player still non-ready?
	bne l1aa3       // no -> disallow
l1a95	lda l1efd       // any lifes left?
	bne l1a9d
	jmp l1b17       // no -> update highscore & enter post-game
l1a9d	dec l1efd       // yes; remove one life and continue
	jmp l1a6d

//-----------------------------------------------------------------
//                      // Place player: Sound

l1aa3	lda ($03),y     // check char at player position
	cmp #$35        // grant symbol found?
	bcc l1aae
	lda #$be        // generate note 266Hz
	sta $900c
l1aae	cmp #$17
	bcs l1abb
	cmp #$08
	bcc l1af2       // player dead
	lda #$8c        // generate note 123Hz
	sta $900c
l1abb	nop
	nop
	nop
	nop
	nop
	nop
l1ac1	lda $03
	sta $22
	lda $04         // place face:
	clc
	adc #$84
	sta $23
	lda #$01        // write player color
	sta ($22),y
	lda $4c         // player eating?
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

l1af2	lda $cb         // player defeating?
	cmp #$27        // key F1? (added for emulator)
        beq l1af3
	cmp #$08        // left arrow key?
	bne l1b42
l1af3	lda $07
	cmp #$f0
	bne l1b42       // player not dead
	lda ($03),y
	cmp #$16        // snake on top of player?
	bcc l1b42
	lda l1efd       // any lives left?
	beq l1b17       // no -> dead
	dec l1efd       // yes -> remove one life
	sty $07
	tax
	lda #$20        // remove one life from display (i.e. player symbol in bottom-left corner)
	sta $11e3,x
	jmp l1b42       // continue game (with time delay)
l1b17	lda $05         // update highscore
	cmp l123d+2     // score > highscore?
	bcc l1b3f       // compare with highest-value digit pair
	bne l1b30
	lda $02
	cmp l123d+1     // mid-value digit pair
	bcc l1b3f
	bne l1b30
	lda l123d       // lowest-value digit pair
	cmp $01
	bcs l1b3f
l1b30	lda $01         // set score as new highscore
	sta l123d
	lda $02
	sta l123d+1
	lda $05
	sta l123d+2
l1b3f	jmp l1f00       // to post-game sequence

//                      // time delay (I)
l1b42	ldy $16
l1b44	ldx #$ff
l1b46	dex
	bne l1b46
l1b49	dey
	bne l1b44
	ldy #$00

	sty $900c       // stop all sound
	sty $900d
	lda l1efc
	beq l1b5e
	lda #$f8        // noise for snakes
	sta $900d
l1b5e	jmp l1c44       // to snake handler

//-----------------------------------------------------------------
//                      // Snake direction handlers

l1b61	lda #$ff        // up?
	sta $25
l1b65	ldx #$16
l1b67	dec $08
	lda $08
	cmp #$ff
	bne l1b71
	dec $09
l1b71	dex
	bne l1b67
	lda $25
	bne l1b7a
	clc
	rts
l1b7a	jsr l1c07       // check if ok to go there
	bcc l1b85       // not ok
	lda #$20        // store new direction
	sta $0a
	sec
	rts
l1b85	sty $25         // abort movement
	bcc l1b8d

l1b89	lda #$ff        // down?
	sta $25
l1b8d	ldx #$16
l1b8f	inc $08
	bne l1b95
	inc $09
l1b95	dex
	bne l1b8f
	lda $25
	bne l1b9e
	clc
	rts
l1b9e	jsr l1c07
	bcc l1ba9
	lda #$a0
	sta $0a
	sec
	rts
l1ba9	sty $25
	bcc l1b65

l1bad	lda #$ff        // left?
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
l1bc1	jsr l1c07
	bcc l1bcc
	lda #$60
	sta $0a
	sec
	rts
l1bcc	sty $25
	bcc l1bd4

l1bd0	lda #$ff        // right?
	sta $25
l1bd4	inc $08
	bne l1bda
	inc $09
l1bda	lda $25
	bne l1be0
	clc
	rts
l1be0	jsr l1c07
	bcc l1beb
	lda #$e0
	sta $0a
	sec
	rts
l1beb	sty $25
	bcc l1bb1       // always branch (CC asserted)

//-----------------------------------------------------------------
//                      // Sub-function: branching for snake direction
//                      // Parameter: A = direction: up:$20,left:$60,down:$a0,right:$e0
//                      // Result: status.C 0:nOK, 1:OK
l1bef	cmp #$40
	bcs l1bf6
	jmp l1b61
l1bf6	cmp #$80
	bcs l1bfd
	jmp l1bad
l1bfd	cmp #$c0
	bcs l1c04
	jmp l1b89
l1c04	jmp l1bd0

//-----------------------------------------------------------------
//                      // Sub-sub-function: control
//                      // Result: status.C: 0:nOk, 1:OK
//
l1c07	lda ($08),y     // read char under snake head
	cmp #$39        // is a letter?
	bcs l1c42       // -> do not go there
	cmp #$1d        // border?
	beq l1c42       // -> do not go there
	cmp #$1c
	beq l1c42       // -> do not go there
	cmp #$16        // target?
	bcs l1c40       // -> allow going there
	lda $08         // calc color address from snake address
	sta $22
	lda $09
	clc
	adc #$84
	sta $23
	lda ($22),y     // read color of snake
	and #$07
	sta $22
	sty $23
	lda $d7         // read ASCII code of last key press
	beq l1c37
l1c30	inc $23
	sec
	sbc #$25
	bne l1c30
l1c37	lda $23
	clc
	adc #$02
	cmp $22
	bne l1c42
l1c40	sec             // result: OK
	rts
l1c42	clc             // result: not OK
	rts

//-----------------------------------------------------------------
//                      // Snakes

l1c44	ldx #$00        // start of loop across snakes
l1c46	stx $d7
	lda $03a6,x     // dead?
	bne l1c50
	jmp l1e15       // yes
l1c50	sta $0a
	sta $24
	lda $0385,x
	sta $09
	lda $0384,x
	sta $08
	jsr $e094       // get RAND number
	lda $8d
	and #$e0
	cmp #$e0        // with P=50% do not change direction
	beq l1c70
	lda $0a
	jsr l1bef
	bcs l1cbc       // OK to keep moving in same direction
l1c70	jsr $e094       // get RAND number
	lda $8d
	cmp #$80        // with P=50% try turning right first, else left first
	bcc l1c9c
	clc
	lda $0a         // try to turn 90� left
	adc #$40
	jsr l1bef
	bcs l1cbc
	lda $0a         // try to turn 90� right
	sbc #$40
	jsr l1bef
	bcs l1cbc
	lda $0a         // try keeping direction
	jsr l1bef
	bcs l1cbc
	lda $0a         // try reversing direction
	sbc #$80
	jsr l1bef
	bcs l1cbc
l1c9c	lda $0a         // try to turn 90� right
	sbc #$40
	jsr l1bef
	bcs l1cbc
	lda $0a         // try to turn 90� left
	adc #$40
	jsr l1bef
	bcs l1cbc
	lda $0a         // try keeping direction
	jsr l1bef
	bcs l1cbc
	lda $0a         // try reversing direction
	adc #$80
	jsr l1bef

l1cbc	ldx $d7         // update snake status in array with temporaries
	lda $0a
	sta $03a6,x
	lda $08
	sta $0382,x
	lda $09
	sta $0383,x
	lda $03a4,x
	sta $22
	lda $03a5,x
	sta $23
	txa
	tay
	clc
	adc #$20
	tax
l1cdd	lda $0382,x
	cmp $22         // can tail be removed?
	bne l1ceb
l1ce4	lda $0383,x
	cmp $23
	beq l1d21
l1ceb	dex             // no
	dex
	stx $4c
	tya
	cmp $4c
	bne l1cdd
	lda $8f         // yes
	and #$bf
	sta $8f
	cmp #$35        // grant of new snake
	beq l1d04
	cmp #$36        // grant point
	beq l1d04
	lda #$1a
l1d04	ldy #$00
	sta ($22),y     // clear snake tail: replace with excrement
	clc
	lda $23
	adc #$84
	sta $23
	lda $8f
	cmp #$35
	beq l1d19
	cmp #$36
	bne l1d1d
l1d19	lda #$04        // purple for snake grant char
	bne l1d1f
l1d1d	lda #$07        // yellow for excrement
l1d1f	sta ($22),y     // write color code for char behind tail
l1d21	lda $d7
	tay
	clc
	adc #$22
	tax
l1d28	lda $0381,x     // move snake by 1
	sta $0383,x
	dex
	stx $4c
	cpy $4c
	bne l1d28
	ldy #$00
	sty $4c
	lda ($08),y
	cmp #$19
	bne l1d41
	sta $4c
l1d41	lda $0a         // head
	clc
	sbc #$1f
	lsr
	lsr
	lsr
	lsr
	lsr
	sta ($08),y
	lda $4c
	beq l1d58
	lda ($08),y
	clc
	adc #$01
	sta ($08),y
l1d58	lda $08         // snake color
	sta $22
	lda $09
	clc
	adc #$84
	sta $23
	sty $25
	txa
	beq l1d6f
l1d68	inc $25
	sec
	sbc #$25
	bne l1d68
l1d6f	lda $25
	clc
	adc #$02
	sta ($22),y
	lda $0386,x     // snake mid-section
	sta $22
	lda $0387,x
	sta $23
	lda $0a
	clc
	adc #$01
	sbc $24
	cmp #$80
	bne l1d9b
	lda $0a         // 180� turn
	clc
	sbc #$1f
	lsr
	lsr
	lsr
	lsr
	lsr
	lsr
	clc
	adc #$0e
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
	clc
	sbc #$3f
	bne l1dbe
l1dbc	lda $0a
l1dbe	clc
	sbc #$1f
	lsr
	lsr
	lsr
	lsr
	lsr
	lsr
	clc
	adc #$0a
l1dca	sta ($22),y     // write mid-section
	lda $03a5,x     // snake tail
	sta $23
	lda $03a4,x
	sta $22
	stx $4c
	txa
	clc
	adc #$1e
	tax
l1ddd	lda $0384,x
	cmp $22
	bne l1deb
	lda $0385,x
	cmp $23
	beq l1e15
l1deb	dex
	dex
	cpx $4c
	bne l1ddd
	ldy #$00
	lda $22
	clc
	adc #$01
	sbc $03a2,x
	cmp #$01
	bne l1e01
	lda #$12
l1e01	cmp #$ff
	bne l1e07
	lda #$13
l1e07	cmp #$16
	bne l1e0d
	lda #$15
l1e0d	cmp #$ea
	bne l1e13
	lda #$14
l1e13	sta ($22),y

//                      // Increment snake status pointer for iteration
l1e15	ldy #$00
	lda $d7
	clc
	adc #$25
	tax
	cpx l1efa       // last snake done?
	bcs l1e25
	jmp l1c46       // next snake

l1e25	lda $07
	nop
	nop
	bne l1e35
	lda ($03),y
	cmp #$08
	bcs l1e35
	jmp l190c       // kill player
	nop

l1e35	lda l1efc       // all snakes dead?
	beq l1e4d
	lda l1efb
	and #$04
	beq l1e45
	lda #$0f        // max volume
	bne l1e47
l1e45	lda #$08        // medium volume
l1e47	sta $900e       // set volume
	inc l1efb       // increment game time counter

l1e4d	ldy $16         // time delay (II)
l1e4f	ldx #$ff
l1e51	dex
	bne l1e51
	dey
	bne l1e4f
	ldy #$00

//                      // Branching:
	lda $07
	bne l1e60
	jmp l17ea       // player alive -> handle player
l1e60	cmp #$f0
	bne l1e67
	jmp l1af2       // player dead -> to defeat handler

//-----------------------------------------------------------------
//                      // eating snake
l1e67	ldx $0380
l1e6a	tya
l1e6b	sta $0384,x
	cpx l1ef9
	beq l1e85
	dex
	dex
	lda $0384,x
	cmp $03
	bne l1e6b
	lda $0385,x
	cmp $04
	bne l1e6a
	beq l1e98
l1e85	lda #$19        // clear player char
	sta ($03),y
	lda $03         // calc address of color code
	sta $22
	lda $04
	clc
	adc #$84
	sta $23
	lda #$07        // color: yellow
	sta ($22),y
l1e98	ldx $0380
	cpx l1ef9
	bne l1ea7
	sty $4c
	sty $07
	jmp l1ac1       // snake all eaten -> place player
l1ea7	dex
	dex
	stx $0380
	lda $0384,x
	sta $03
	lda $0385,x
	sta $04
	lda $16         // time delay
	sbc #$18
	tay
	beq l1ec1
	cmp #$30
	bcc l1ec3
l1ec1	ldy #$01
l1ec3	ldx #$ff
l1ec5	dex
	bne l1ec5
l1ec8	dey
	bne l1ec3
	ldx #$51        // increase score by total 1782 points
	jsr l12e0
	ldx $0380
l1ed3	cpx l1ef9
	beq l1eea
	dex
        dex
        lda $0384,x
        cmp $03
        bne l1ed3
        lda $0385,x
        cmp $04
        bne l1ed3
        beq l1ef1
l1eea   lda #$19
        sta $4c
        jmp l1ac1       // place player
l1ef1   lda #$80
        sta $900d       // generate noise for player defeat
        jmp l1aed

//-----------------------------------------------------------------
//                      // Variables

l1ef9	.byt 0          // minimum while eating snake
l1efa	.byt 0          // offset of last valid snake struct
l1efb	.byt 0          // main time/ietration counter (while snakes alive)
l1efc	.byt 0          // counter active snakes
l1efd	.byt 0          // counter player lives
l1efe	.byt 0          // counter bonus chars (i.e. letters)
l1eff	.byt 0          // unused

//-----------------------------------------------------------------
//                      // Post-game sequence

l1f00	jsr $e5c3
	jsr $e55f       // clear screen
	lda #$19        // set screen color: screen:white border:white
	sta $900f
	lda #$cd
	sta $9005
	ldx #$0a
	ldy #$14
l1f14	lda l126c-1,y   // print "Highscore"
	sta $1089,x
	sta $110c,x
	lda #$02        // color: red
	sta $9489,x
	sta $950c,x
	lda #$06        // color: blue
	sta $94ca,x
	sta $954e,x
	dey
	dey
	dex
	bne l1f14
l1f32	ldx #$05        // print "last"
l1f34	lda l1f8f,x
	sta $1088,x
	dex
	bne l1f34
l1f3d	lda #$02
	sta $9489
	lda #$cd        // patch code to determine position of score output
	sta l1327
	sta l1331
	ldy #$00
	jsr l12f9       // print new score
	lda #$51
	sta l1327
	sta l1331
	lda #$11
	sta l1328
	sta l1332
	lda l123d       // lowest-value digit pair
	sta $24
	lda l123d+1     // mid-value digit pair
	sta $23
	lda l123d+2     // high-value digit pair
	sta $22
	jsr l1305       // print highscore
	lda #$10
	sta l1328
	sta l1332
l1f79	lda $cb         // wait for all keys released
	cmp #$40
	bne l1f79
l1f7f	lda $cb         // wait for any keypress or joystick
	cmp #$40
	bne l1f8c
	lda $911f
	cmp #$7e
	beq l1f7f
l1f8c	jmp l1600       // back to start of game

l1f8f	.byt $25,$1e,$28,$29,$20        // "LAST"
