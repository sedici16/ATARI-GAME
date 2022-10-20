    processor 6502
    
    include vcs.h
    include macro.h

    ;;;;;initialise memory declaration for variable

    seg.u Variables
    org $80
P0Height    ds 1; define one byte for player 0 height
P1Height    ds 1; define one byte for player 0 height
    
    seg CODE; Define a new segment named "Code"
    org $F000 ; Define the origin of the ROM code at memory address $F000

Reset:

    CLEAN_START ; clean memory
    
    ldy #%00000010 ; CTRLPF D1 set to 1 means (score)
    sty CTRLPF

    ldx #$80 ;load the blue colour for the background
    stx COLUBK ;load the blue in memory 

    lda #%1111 ;load the colour for the playfield white
    sta COLUPF

    ;;;;;height of the players

    lda #10
    sta P0Height ; player height set to 10 e.g. A=10
    sta P1Height
    
    ;;;;colours of the players
    
    lda #$48
    sta COLUP0; colour od the player one
    
    lda #$C6
    sta COLUP1; colour of the player two
    

    
NextFrame:
    lda #2
    sta VBLANK ;poke 2 in video memory
    sta VSYNC ; turn on the vertical synch VERTICAL SYNC

    ; generate the 3 lines of the WSYNC weight sync

    REPEAT 3
        sta WSYNC ; first line of WSYNC weight sync
    REPEND
    lda #0
    sta VSYNC ; turn off VSYNC

    ; generates the 37 recommended scan lines for the NTSC TV
    
        ;;;;;;;;;;;;PLAYFIELD;;;;;;;;;;;;
    ;set the the playfield to be reflected CTRLPF.
    ldx #%00000000 ;this set the platfield to reflect the pattern
    stx CTRLPF
    
        
    ldy #%00000010 ; CTRLPF D1 set to 1 means (score)
    sty CTRLPF; each half of the screen has the player colour

    REPEAT 37
        sta WSYNC
    REPEND
    lda #0
    sta VBLANK ;turn off vblank
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;start of the game
    
VisibleScanlines:;;;10 empty scan lines
    REPEAT 10
    sta WSYNC
    REPEND
    
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;draw 10 lines for the score board
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ldy #0
scoreboardLoop:
    lda NumberBitmap,Y;render the bitmap in loop for 1 to 10
    sta PF1;set in in the playfield 
    sta WSYNC
    iny;increment ++1
    cpy #10 ;compare y with 
    bne scoreboardLoop
    
    lda #0
    sta PF1; disable playfield 
    
    ;;;draw 50 empty scan lines
    
    REPEAT 50
    	sta WSYNC
    REPEND
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;player 0 loop
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ldy #0
Player0Loop:
    lda playerzeroBitmap,y;render the bitmap in loop for 1 to 10
    sta GRP0;set the player zero in field
    sta WSYNC
    iny;increment ++1
    cpy P0Height ;compare y with 10
    bne Player0Loop
    
    lda #0
    sta GRP0; disable player 0 graphics 
    
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;player 1 loop
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ldy #0
    
Player1Loop:
    lda playerzeroBitmap,Y;render the bitmap in loop for 1 to 10
    sta GRP1;set the player zero in field
    sta WSYNC
    iny;increment ++1
    cpy P1Height ;compare y with 10
    bne Player1Loop
    
    lda #0
    sta GRP1; disable player 0 graphics 
    
    ;draw another 102 lines
    
    REPEAT 102
    	sta WSYNC
    REPEND
    



;;;overscan

    REPEAT 30
        sta WSYNC
    REPEND
    lda #0
    sta VBLANK ;turn off vblank



    jmp NextFrame


    ;;;;;;;;;;;;;;;;;;;define the bit maps must be out of the loop NEXTFRAME


    org $FFE8
playerzeroBitmap:
    .byte #%01111110
    .byte #%11111111
    .byte #%10011001
    .byte #%11111111
    .byte #%11111111
    .byte #%11111111
    .byte #%11111111
    .byte #%10111101
    .byte #%11111111
    .byte #%01111110

    org $FFF2

NumberBitmap:
    .byte #%00001110
    .byte #%00001110
    .byte #%00000010
    .byte #%00000010
    .byte #%00001110
    .byte #%00001100
    .byte #%00001100
    .byte #%00001000
    .byte #%00001110
    .byte #%00001110

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;complete the rom
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    org $FFFC ; End the ROM always at position $FFFC
    .word Reset ; Put 2 bytes with reset address at memory position $FFFC
    .word Reset ; Put 2 bytes with break address at memory position $FFFE
