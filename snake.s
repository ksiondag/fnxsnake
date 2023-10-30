.cpu "65816"                        ; Tell 64TASS that we are using a 65816

.include "includes/TinyVicky_Def.asm"
.include "includes/interrupt_def.asm"
.include "includes/f256jr_registers.asm"
.include "includes/f256k_registers.asm"
.include "includes/f256_tiles.asm"
.include "includes/random.asm"
.include "includes/macros.s"

dst_pointer = $30
src_pointer = $32
sprite_x = $34
sprite_y = $36
sprite_update_amount = $38
frame_counter = $3A

displacement = $3C
vel = $3E

; Button up/down tracking
direction_press = $40

; Current direction, next direction tracking
direction_moving = $41

; Track if dead
is_dead = $42

; Position as grid (to save history of movement in 2d array)
grid_pos_x = $44
grid_pos_y = $45
grid_pos_update_amount = $46

snake_length = $48

negate_pointer = $4A

direction_moving_pointer = $4C
direction_moving_update_amount = $4E

; Apple data
apple_present = $50
apple_pos_x = $51
apple_pos_y = $52

; Code
* = $000000 
        .byte 0

* = $4000
.logical $4000

.include "init.s"
.include "poll.s"
.include "movement.s"
.include "apple.s"
.include "collision.s"

Lock
    JSR Poll
    LDA frame_counter
    BNE Lock

    JSR PlaceApple
    JSR UpdateMovement
    JSR AnimateMovement
    JSR RenderApple

    LDA is_dead
    CMP #$01
    BEQ Reset

    ; CheckCollision either ends with reset or falls back into lock from above
    JMP CheckCollision

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