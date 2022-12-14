;;;;dasm cart_exercises3.asm -f3 -v0 -ocart_exercises2.bin;; compile with this   
   
    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files with register mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start an uninitialized segment at $80 for var declaration.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80
P0Xpos byte ; player x position 
P0ypos byte ; player x position 
BomberXpos byte ;enemy x pos
Bomberypos byte ;enemy x pos
score byte; 2 digit variable for the score stored as bcd
timer byte ; 2 digit variable for the timer as bcd
temp byte; store temporary values 
unit_score word; needed for the calculation of the units in the score
tens_score word; needed for the calculation of the decimals in the score
jetspriteptr word ;pointer to jet sprite a word can hold 2 bytes or 16 bits which is a memory address
jetcolourptr word
bomberspriteptr word
bombercolourptr word
jetoffsetanimation byte ;player zero to change the sprite animation
Random byte ;the random number
score_sprite byte; store the score sprite
timer_sprite byte; store the timer sprite
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DEFINE CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JET_HEIGHT = 9 ;player zero height
BOMBER_HEIGHT = 9 ;Bomber zero height
DIGIT_HEIGTH = 5; scoreboard height


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code segment starting at $F000.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START    ; macro to clean memory and TIA

 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; initialise ram variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	lda #60
        sta P0Xpos
        lda #10
        sta P0ypos
        lda #40
        sta BomberXpos
        lda #54
        sta Bomberypos
        
        lda #0 ;initialise the score and timer with zero
        sta score
        sta timer
        
        lda #%11010100; initialise the random number
        sta Random
        
        ;initialise sprite pointer in ram low and high byte
       
        lda #<jet_Frame0; sprite low byte
        sta jetspriteptr
        lda #>jet_Frame0; sprite high byte
        sta jetspriteptr+1
        
        ;colour 
        lda #<jet_ColorFrame0; colour low byte
        sta jetcolourptr
        lda #>jet_ColorFrame0; colour high byte
        sta jetcolourptr+1
        
        
        ;bomber
        
        lda #<bomber_Frame0; low byte
        sta bomberspriteptr
        lda #>bomber_Frame0;#>jet_Frame1; high byte
        sta bomberspriteptr+1
        
        ; colour
        
        lda #<bomber_ColorFrame0; colour low byte
        sta bombercolourptr
        lda #>bomber_ColorFrame0; colour high byte
        sta bombercolourptr+1
        
        
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; start main game loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; X position calculation before vblank
;Y is the object type 0 player, 1 Bomber. A is the position
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
    lda P0Xpos ;set player x pos
    ldy #0; load object 1
    jsr SetObjectSubRoutine;call subroutine

    lda BomberXpos
    ldy #1
    jsr SetObjectSubRoutine
    
    jsr calculate_digit_offset
    
    sta WSYNC
    sta HMOVE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;vblank
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #2
    sta VBLANK     ; turn VBLANK on
    sta VSYNC      ; turn VSYNC on

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 3
        sta WSYNC  ; first three VSYNC scanlines
    REPEND

    lda #0
    sta VSYNC      ; turn VSYNC off
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the 35 recommended lines of VBLANK
; now it is 35 scan lines instead of 37 as I have used 2 scan lines above
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 37
        sta WSYNC
    REPEND

    lda #0
    sta VBLANK     ; turn VBLANK off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;render the 192 visible lines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;space for the score board
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
        lda #0 ;set all values to zero to have an empty space
        sta PF0
        sta PF1
        sta PF0
        sta GRP0 ;set value to zero for the player graphics
        sta GRP1
        
        lda #$1c ;load a colour for the score board
        sta COLUPF
        
        lda #%00000000
        sta CTRLPF ; do not refelct the playfield 

; loop for the display 

	ldx DIGIT_HEIGTH
.score_digit_loop:
;;;;;;;;;the tens sprite display
	ldy tens_score
        lda Digits,y
        and #%00001111
        lda score_sprite
;;;;;;;;;the units sprite display
        ldy unit_score
        lda Digits,y
        and #%11110000
        ora score_sprite
        sta score_sprite
        
        sta WSYNC
        sta PF1
        
        
	dex 
        bne .score_digit_loop



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;variables for the playfield and colours
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



   	ldx #$85    ; blue background color
    	stx COLUBK
    	
        ldx #$c2; PLAYFIELD color
    	stx COLUPF

    	LDX #%0000001 ;this set the platfield to reflect the pattern
    	STX CTRLPF
	
        lda #%11111111; solid line for the playfield zero
        sta PF0
        
        lda #%11110000;no line
        sta PF1
        lda #0
        sta PF2
        
        

        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;loop for the visible scan lines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #86;  I have 2 wsync in the sprite rendering so half of the lines
        
.visiblelines:

	txa ;tranfer x to a
        sec; set the carry for subtraction 
        sbc P0ypos ; subtract player position from scan lines.
        cmp JET_HEIGHT; are we inside the sprite height 
        bcc .drawsprite0
        lda #0; else load zero
        
.drawsprite0:

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;off set animation for going left or right, add the height to the sprite
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	clc ; clear carry for addition
        adc jetoffsetanimation; jump to the correct frame in memory
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
	tay; transfer a to y, a has the differrence 9,8,7,6 and so on
	lda (jetspriteptr),y; load playyer bitmap slice 
        
       
	sta GRP0; store the graphic in player GRP0
	;load the colour code for the player
	;store the colour in COLUP0
        
        sta WSYNC; wait for the scanline
	
        lda (jetcolourptr),Y       ; player 0 color light red
    	sta COLUP0; store the colours in player 1
        
        
;;;draw the bomber sprite

	txa ;tranfer x to a
        sec; set the carry for subtraction 
        sbc Bomberypos ; subtract player position from scan lines.
        cmp BOMBER_HEIGHT; are we inside the sprite height 
        bcc .drawbomber0
        lda #0; else load zero

.drawbomber0:

	tay; transfer a to y, a has the differrence 9,8,7,6 and so on
	
        lda #%000000101;double the width of the sprite
        sta NUSIZ1
        
        lda (bomberspriteptr),y; load playyer bitmap slice 

        
	sta GRP1; store the graphic in player GRP0
	;load the colour code for the player
	;store the colour in COLUP0
        sta WSYNC; wait for the scanline
	
        lda (bombercolourptr),y       ; player 0 color light red
    	sta COLUP1; store the colours in player 1

        
        dex; decrement scan line
        bne .visiblelines; repeat for next scan line until finished
        
        lda #0
        sta jetoffsetanimation



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
; OVERSCAN generates the 30 recommended scan lines for the NTSC TV

    REPEAT 30
        sta WSYNC
    REPEND
    lda #0
    sta VBLANK ;turn off vblank
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joystick controls
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
CheckP0up:

	lda #%00010000 ;joystick up
        bit SWCHA
        bne CheckP0down; if the pattern does not match bypass
        inc P0ypos
        lda #0 ; no frame change for going up or down
        sta jetoffsetanimation

CheckP0down:

        lda #%00100000 ;joystick down
        bit SWCHA
        bne CheckP0left
        dec P0ypos
        lda #0 ; no frame change for going up or down
        sta jetoffsetanimation

CheckP0left:
	lda #%01000000 ;joystick left
        bit SWCHA
        bne CheckP0right
        dec P0Xpos
        lda JET_HEIGHT  ; it is 9
        sta jetoffsetanimation
        

CheckP0right:
	lda #%10000000 ;joystick down
        bit SWCHA
        bne noaction
        inc P0Xpos
        lda JET_HEIGHT  ; it is 9
        sta jetoffsetanimation
        
        
noaction:

; move the sprite

Updatebomber_pos:

	lda Bomberypos
	clc
        cmp #5
        bmi .startfromtop;branch if minus 
        dec Bomberypos
        jmp .end_position_update
        
.startfromtop:
;	lda #96
;        sta Bomberypos
	jsr bomber_random_num; jump to random number generator

.end_position_update


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;check for collision
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.collision_bomber_player0:
	lda #%10000000 ;CXPPMM detects the collision between player0 and player1
        bit CXPPMM; test the bit player0 and player1
        bne collision_detected ;if collision happens jump to collision dectected, if it is not zero repeat
        jmp .check_collision_PF_P0; if there is no collision
        
.check_collision_PF_P0:
	lda #%10000000 
        bit CXP0FB; test the bit for player and playfield
        bne collision_PF_P0
        jmp end_collision_check

collision_PF_P0:
	jsr gameover


collision_detected:
	jsr gameover
        
end_collision_check:
	sta CXCLR ;clear the collision flags before thenext frame

    
    jmp StartFrame
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;x pos subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetObjectSubRoutine subroutine
	sta WSYNC
        sec
.DivideLoop:
	sbc #15 ;subtract 15 from accumulator 
        bcs .DivideLoop; loop while carry flag is still set
        ;the accumulator will contain the remainder of the division
        
        eor #7 ; this is 7; xor the result to obtain a value between -8 and 7
        
        asl
        asl 
        asl 
        asl ;bit shift as HMP0 use only four bits
        
        sta HMP0,Y ; set fine positioning Y is the object type 0 player, 1 Bomber
        sta RESP0,Y; reset 15 brute posinition Y is the object type 0 player, 1 Bomber
        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;generate a linear feedback shift Register random number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bomber_random_num subroutine    

	lda Random ;load random 
        asl ;left bit shift
        eor Random ; xor random 
        asl 
    	eor Random
        asl
        asl
        eor Random
        asl
        rol Random
        
        
        
        lsr ;2 right shift are equal to divide by 4
        lsr
        
        sta BomberXpos
        
        lda #30
        
        adc BomberXpos ; off set for the grass
        
        sta BomberXpos
        
        lda #96
        sta Bomberypos
        
        rts
        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;digit display subroutine. this transform the score or the timer into 
; the diplay digits
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

calculate_digit_offset subroutine
	
        ; these are the units
        
        ldx #1 ; loop counter 
.prepare_score_loop ; this will loop tiwce 1 for the score 2 for the timer.
	
        lda score,x; load the accumulator with TIMER score+1, timer is next in memory after score
        and #%00001111 ; to mask the decimals
        sta temp ; save the variable to a temporary variable
        asl; shift left euqal of multiplication X2
        asl ;multiplication X2
        adc temp ;add the value saved in temp. N*2*2+n
        sta unit_score,x ; save A in the unit score, 1 for SCORE or +1 for timer
        
        ; these are the tens tens_score
        
        lda score,x
        and #%11110000
        lsr ; divide by 2
        lsr ; divide by 2 for a total of 4
        sta temp
        lsr
        lsr ; total divide by 16
        adc temp; Formula is n/16*5 = N/2/2 + N/2/2/2/2
        sta tens_score,x
        
        dex ; decrement x
        
        bpl .prepare_score_loop  ; while x greater or equal than 0 end of loop
        
        
        
        
        
        
        
        rts
        
        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;gameover subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
gameover subroutine
	lda #$30
        sta COLUBK

	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare ROM lookup tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Digits:
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00110011          ;  ##  ##
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %00100010          ;  #   #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01100110          ; ##  ##
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01100110          ; ##  ##
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01100110          ; ##  ##

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01100110          ; ##  ##
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #

        
;---Graphics Data for the jet sprite ---


        
jet_Frame0
	.byte #%00000000;
	.byte #%00101000;$40
        .byte #%11111110;$70
        .byte #%01111100;$D0
        .byte #%00111000;$3C
        .byte #%00111000;$1A
        .byte #%00010000;$40
        .byte #%00010000;$40
        .byte #%00010000;$1E
       
        
jet_Frame1        
	.byte #%00000000;
        .byte #%00010000;$40
        .byte #%01111100;$70
        .byte #%00111000;$D0
        .byte #%00111000;$3C
        .byte #%00010000;$1A
        .byte #%00010000;$40
        .byte #%00010000;$40
        .byte #%00010000;$1E


;---Graphics Data for the bomber--

bomber_Frame0
	.byte #%00000000;
        .byte #%00101000;$1A
        .byte #%00101000;$40
        .byte #%00101000;$40
        .byte #%00101000;$40
        .byte #%01101100;$40
        .byte #%11101110;$40
        .byte #%01101100;$40
        .byte #%00111000;$40
;---End Graphics Data---


;---Color Data from PlayerPal 2600---

jet_ColorFrame0
        .byte #$00
        .byte #$FE
        .byte #$0C
        .byte #$0E
        .byte #$0E
        .byte #$04
        .byte #$BA
        .byte #$0E
        .byte #$08
        
jet_ColorFrame1
        .byte #$00
        .byte #$FE
        .byte #$0C
        .byte #$0E
        .byte #$0E
        .byte #$04
        .byte #$BA
        .byte #$0E
        .byte #$08


bomber_ColorFrame0
	.byte #$00
        .byte #$1A;
        .byte #$15;
        .byte #$15;
        .byte #$15;
        .byte #$15;
        .byte #$15;
        .byte #$10;
        .byte #$10;
;---End Color Data---

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    .word Reset
    .word Reset
         