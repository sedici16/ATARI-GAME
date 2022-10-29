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
P0Xpos .byte ; player x position 
P0ypos .byte ; player x position 
BomberXpos .byte ;enemy x pos
Bomberypos .byte ;enemy x pos
jetspriteptr word ;pointer to jet sprite a word can hold 2 bytes or 16 bits which is a memory address
jetcolourptr word
bomberspriteptr word
bombercolourptr word
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DEFINE CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JET_HEIGHT = 9 ;player zero height
BOMBER_HEIGHT = 9 ;Bomber zero height


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code segment starting at $F000.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START    ; macro to clean memory and TIA

    ldx #$85    ; blue background color
    stx COLUBK
    ldx #$c2
    stx COLUPF
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; initialise ram variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	lda #79
        sta P0Xpos
        lda #10
        sta P0ypos
        lda #40
        sta BomberXpos
        lda #83
        sta Bomberypos
        
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
    
    lda WSYNC
    lda HMOVE
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
;set the playfield

    	LDX #%0000001 ;this set the platfield to reflect the pattern
    	STX CTRLPF
	
        lda #%1111000; solid line for the playfield zero
        sta PF0
        
        lda #0 ;no line
        sta PF1
        lda #0
        sta PF2
        
;loop for the visible scan lines

	ldx #91;  I have 2 wsync in the sprite rendering so half of the lines
        
.visiblelines:

	txa ;tranfer x to a
        sec; set the carry for subtraction 
        sbc P0ypos ; subtract player position from scan lines.
        cmp JET_HEIGHT; are we inside the sprite height 
        bcc .drawsprite0
        lda #0; else load zero
        
.drawsprite0:
	tay; transfer a to y, a has the differrence 9,8,7,6 and so on
	lda (jetspriteptr),y; load playyer bitmap slice 
        
       
	sta GRP0; store the graphic in player GRP0
	;load the colour code for the player
	;store the colour in COLUP0
        
         sta WSYNC; wait for the scanline
	
        lda jetcolourptr,y       ; player 0 color light red
    	sta COLUP0; store the colours in player 1

;	sta WSYNC ;wait for scan line
;        dex; decrement scan line
;        bne visiblelines; repeat for next scan line until finished
        
        
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
	
        lda bombercolourptr,y       ; player 0 color light red
    	sta COLUP1; store the colours in player 1

        
        dex; decrement scan line
        bne .visiblelines; repeat for next scan line until finished



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

CheckP0down:

        lda #%00100000 ;joystick down
        bit SWCHA
        bne CheckP0left
        dec P0ypos

CheckP0left:
	lda #%01000000 ;joystick left
        bit SWCHA
        bne CheckP0right
        dec P0Xpos

CheckP0right:
	lda #%10000000 ;joystick down
        bit SWCHA
        bne noaction
        inc P0Xpos
        
noaction:
    
    jmp StartFrame
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;x pos subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetObjectSubRoutine subroutine
	sta WSYNC
        sec
DivideLoop:
	sbc #15 ;subtract 15 from accumulator 
        bcs DivideLoop; loop while carry flag is still set
        ;the accumulator will contain the remainder of the division
        
        eor #%00000111 ; this is 7; xor the result to obtain a value between -8 and 7
        
        asl
        asl 
        asl 
        asl ;bit shift as HMP0 use only four bits
        
        sta HMP0,y ; set fine positioning Y is the object type 0 player, 1 Bomber
        sta RESP0,y; reset 15 brute posinition Y is the object type 0 player, 1 Bomber
        rts

        





    
;---Graphics Data for the jet sprite ---


        
jet_Frame0
	.byte #%00000000;
	.byte #%00010000;$40
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
        .byte #%00111000;$1A
        .byte #%00010000;$40
        .byte #%00010000;$40
        .byte #%00010000;$1E
        
        
;---End Graphics Data--


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
        .byte #$1b;
        .byte #$40;
        .byte #$40;
        .byte #$1A;
        .byte #$3C;
        .byte #$D0;
        .byte #$70;
        .byte #$40;
jet_ColorFrame1
	.byte #$00
        .byte #$1E;
        .byte #$40;
        .byte #$40;
        .byte #$1A;
        .byte #$3C;
        .byte #$D0;
        .byte #$70;
        .byte #$40;
;---End Color Data---


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
         