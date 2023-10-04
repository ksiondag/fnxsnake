.cpu "65816"                        ; Tell 64TASS that we are using a 65816

.include "includes/TinyVicky_Def.asm"
.include "includes/interrupt_def.asm"
.include "includes/f256jr_registers.asm"
.include "includes/f256k_registers.asm"
.include "includes/f256_tiles.asm"
.include "includes/macros.s"

dst_pointer = $30
src_pointer = $32
sprite_x = $34
sprite_y = $36
text_memory_pointer = $38
frame_counter = $3A

vel_y = $3B
vel_x = $3D

; Button up/down tracking
left_press = $3F
right_press = $40
up_press = $41
down_press = $42

; Code
* = $000000 
        .byte 0

* = $4000
.logical $4000

.include "init.s"
.include "poll.s"

Lock
    JSR Poll
    LDA frame_counter
    BNE Lock

    ; Use 816 mode
    CLC
    XCE
    
    setaxs

    ; Move sprite to the right
    STZ MMU_IO_CTRL ; Go back to I/O Page 0

    ; Nudge sprite to the right
    setaxl
    CLC
    LDA @w sprite_x
    ADC @w vel_x
    STA @w sprite_x
    
    ; Nudge sprite down
    CLC
    LDA @w sprite_y
    ADC @w vel_y
    STA @w sprite_y

    ; Check for bounce off the bottom
    LDA sprite_y
    CMP #$00FE
    BMI DoneBottomCheck
    BRA Reset
DoneBottomCheck

    ; Check for bounce off the right
    LDA sprite_x
    CMP #$014F
    BMI DoneRightCheck
    BRA Reset
DoneRightCheck

    ; Check for bounce off the top
    LDA sprite_y
    CMP #$0020
    BPL DoneTopCheck
    BRA Reset
DoneTopCheck

    ; Check for bounce off the left
    LDA sprite_x
    CMP #$0020
    BPL DoneLeftCheck
    BRA Reset
DoneLeftCheck


    ; Commit sprite positions
    LDA sprite_x
    STA SP0_X_L 
    LDA sprite_x+1
    STA SP0_X_H ;
    LDA sprite_y
    STA SP0_Y_L
    LDA sprite_y+1
    STA SP0_Y_H

    ; Reset frame counter
    setaxs
    LDA #3
    STA frame_counter

    .as
    .xs
    REP #$20
    SEC
    XCE

DoneUpdate
    JMP Lock

Reset
    .as
    .xs
    REP #$20
    SEC
    XCE
	JMP MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init_IRQHandler
    ; Back up I/O state
    LDA MMU_IO_CTRL
    PHA        

    ; Disable IRQ handling
    SEI

    ; Load our interrupt handler. Should probably back up the old one oh well
    LDA #<IRQ_Handler
    STA $FFFE ; VECTOR_IRQ
    LDA #>IRQ_Handler
    STA $FFFF ; (VECTOR_IRQ)+1

    ; Mask off all but start-of-frame
    LDA #$FF
    STA INT_MASK_REG1
    AND #~(JR0_INT00_SOF)
    STA INT_MASK_REG0

    ; Re-enable interrupt handling    
    CLI
    PLA ; Restore I/O state
    STA MMU_IO_CTRL 
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IRQ_Handler
    PHP
    PHA
    PHX
    PHY
    
    ; Save the I/O page
    LDA MMU_IO_CTRL
    PHA
    
    ; Switch to I/O page 0
    STZ MMU_IO_CTRL

    ; Check for start-of-frame flag
    LDA #JR0_INT00_SOF
    BIT INT_PENDING_REG0
    BEQ IRQ_Handler_Done
    
    ; Clear the flag for start-of-frame
    STA INT_PENDING_REG0    

    LDA frame_counter
    BEQ AfterDecFrameCounter
    DEC frame_counter

AfterDecFrameCounter    

IRQ_Handler_Done
    ; Restore the I/O page
    PLA
    STA MMU_IO_CTRL
    
    PLY
    PLX
    PLA
    PLP
    RTI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearScreen
    LDA MMU_IO_CTRL ; Back up I/O page
    PHA
    
    LDA #$02 ; Set I/O page to 2
    STA MMU_IO_CTRL
    
    STZ dst_pointer
    LDA #$C0
    STA dst_pointer+1

ClearScreen_ForEach
    LDA #32 ; Character 0
    STA (dst_pointer)
        
    CLC
    LDA dst_pointer
    ADC #$01
    STA dst_pointer
    LDA dst_pointer+1
    ADC #$00 ; Add carry
    STA dst_pointer+1

    CMP #$C5
    BNE ClearScreen_ForEach
    
    PLA
    STA MMU_IO_CTRL ; Restore I/O page
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "assets/sprites/ball.s"

.include "assets/tiles/clut.s"
.include "assets/tiles/image.s"
.include "assets/tiles/map.s"

.endlogical

; Write the system vectors
* = $00FFF8
.logical $FFF8
.byte $00
F256_DUMMYIRQ       ; Abort vector
    RTI

.word F256_DUMMYIRQ ; nmi
.word F256_RESET    ; reset
.word F256_DUMMYIRQ ; irq
.endlogical