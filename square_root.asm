	processor 6502
        
        
        ;;;some variables
        
	include "vcs.h"
    	include "macro.h"
        
	seg.u Variables
	org $80

xplusy byte ; myresult
ODDnum byte ; myresult
counter byte

	processor 6502
        
        
        ;;;some variables
        
	include "vcs.h"
    	include "macro.h"
        
	seg.u Variables
	org $80

xplusy byte ; myresult
ODDnum byte ; myresult
counter byte
	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code segment starting at $F000.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START    ; macro to clean memory and TIA
    lda #21
    sta xplusy
        
    lda #1
    sta ODDnum
        
    lda #0
    sta counter 


    lda xplusy
;    lda #9
    sec
  
root:
    
    sbc ODDnum ; subtract the odd number
;    sta xplusy
    
    inc ODDnum ; add 2 to the odd nuber
    inc ODDnum; 
    
    ldx ODDnum ;load the odd number to the x accumulator
   
   stx ODDnum ; store back the result
   
   inc counter; increment the counter
   
    cmp #0 ; compare the accumulator with zero
    bne root ; branch if not equal
    
    ldx counter ;load the blue colour for the background
    stx COLUBK ;load the blue in memory 
       

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    .word Reset
    .word Reset
        
	

        
        
        