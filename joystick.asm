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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code segment starting at $F000.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START    ; macro to clean memory and TIA

    ldx #$80     ; blue background color
    stx COLUBK
    ldx #$D0
    stx COLUPF
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; initialise x position variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_pos:	
	lda #10
	sta P0Xpos


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by configuring VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:


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
;set the player in horizonatal postion
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda P0Xpos
        and #$7F ;this and p0Xpos with binary 01111111 to make sure it is a positive number
	sta WSYNC
        sta HMCLR
        
        SEC ;set the carry for division

DivideLoop:
	sbc #15 ;subtract 15 from accumulator 
        bcs DivideLoop; loop while carry flag is still set
        ;the accumulator will contain the remainder of the division
        
        eor #%00000111 ; this is 7; xor the result to obtain a value between -8 and 7
        
        asl
        asl 
        asl 
        asl ;bit shift as HMP0 use only four bits
        
        sta HMP0 ; set fine positioning 
        sta RESP0; reset 15 brute posinition
        sta WSYNC; wait for fine tune
        sta HMOVE;apply the fine positioning 
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the 35 recommended lines of VBLANK
; now it is 35 scan lines instead of 37 as I have used 2 scan lines above
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 35
        sta WSYNC
    REPEND

    lda #0
    sta VBLANK     ; turn VBLANK off
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the 192 visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;PLAYFIELD;;;;;;;;;;;;
    ;set the the playfield to be reflected CTRLPF.
    LDX #%0000001 ;this set the platfield to reflect the pattern
    STX CTRLPF
         
;empty playfield
    
    REPEAT 160
        sta WSYNC ;wait for the scan line
    REPEND
        
        ldy 11

Loadbitmap:
        
	lda PlayerBitmap,y; load playyer bitmap slice 
	sta GRP0; store the graphic in player GRP0
	
        lda Player0Colour,y       ; player 0 color light red
    	sta COLUP0; store the colours in player 1
        
        sta WSYNC
        
        dey ;decrement y 
        bne Loadbitmap; continue unti zero.
        

         
                 ;set PF0 PF1 PF2 to solid line ldx #%11111111
    	ldx #%11111111
   	stx PF0
   	stx PF1
   	stx PF2
    	
        REPEAT 40
    		STA WSYNC
    	REPEND
        
        ldx #0
   	stx PF0
   	stx PF1
   	stx PF2
        
        
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;overcan 30 lines

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
; OVERSCAN generates the 30 recommended scan lines for the NTSC TV

    REPEAT 30
        sta WSYNC
    REPEND
    lda #0
    sta VBLANK ;turn off vblank
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;joystick logic

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   

CheckP0up:
	lda #%00010000
        bit SWCHA
        bne CheckP0down
        inc P0Xpos

CheckP0down:
	lda #%00100000
        bit SWCHA
        bne CheckP0left
        dec P0Xpos

CheckP0left:
	lda #%01000000
        bit SWCHA
        bne CheckP0right
        dec P0Xpos

CheckP0right:
	lda #%10000000
        bit SWCHA
        bne noinput
        inc P0Xpos


noinput:
        

        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        jmp StartFrame
        

        


PlayerBitmap:
	.byte $00 ; |        |
	.byte $00 ; |  X  X  |
	.byte $28 ; |  X X   |
	.byte $10 ; |   X    |
	.byte $10 ; |   X    |
	.byte $10 ; |   X    |
	.byte $7C ; | XXXXX  |
	.byte $10 ; |   X    |
	.byte $10 ; |   X    |
	.byte $18 ; |   XX   |
	.byte $00 ; |   XX   |


Player0Colour:
	byte $00
        byte $40
        byte $40
        byte $40
        byte $42
        byte $42
        byte $42
        byte $D2
        byte $D2
        byte $D2
        byte $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    .word Reset
    .word Reset