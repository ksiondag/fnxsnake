.cpu "65c02"                        ; Tell 64TASS that we are using a 65816

.include "includes/TinyVicky_Def.asm"
.include "includes/interrupt_def.asm"
.include "includes/f256jr_registers.asm"
.include "includes/f256k_registers.asm"
.include "includes/f256_tiles.asm"
.include "includes/random.asm"
.include "includes/macros.s"
.include "includes/api.asm"

; Code
* = $000000 
mmu_ctrl    .byte       ?
io_ctrl     .byte       ?
reserved    .fill       6
mmu         .fill       8
            .dsection   dp
            .cerror * > $00ff, "Out of dp space."

* = $0200
JMP F256_RESET
.dsection data

.section dp
; Something breaks when I try to dynamically allocate these variables
; So directly setting where they are
frame .byte ?

dst_pointer .word ?
src_pointer .word ?
sprite_x .word ?
sprite_y .word ?
sprite_update_amount .word ?

displacement .word ?
vel .word ?

; Button up/down tracking
direction_press .byte ?

; Current direction, next direction tracking
direction_moving .byte ?

; Track if dead
is_dead .word ?

; Position as grid (to save history of movement in 2d array)
grid_pos_x .byte ?
grid_pos_y .byte ?
grid_pos_update_amount .word ?

snake_length .word ?

negate_pointer .word ?

direction_moving_pointer .word ?
direction_moving_update_amount .word ?

; Apple data
apple_present .byte ?
apple_pos_x .byte ?
apple_pos_y .byte ?
.send

.section data
event .dstruct kernel.event.event_t
.send

* = $2000
.include "init.s"
.include "poll.s"
.include "poll_kernel.s"
.include "movement.s"
.include "apple.s"
.include "collision.s"

Lock
    JSR input_loop
    JSR PlaceApple
    JSR UpdateMovement
    JSR AnimateMovement
    JSR RenderApple

    LDA is_dead
    CMP #$01
    BEQ Reset

    ; CheckCollision either ends with reset or falls back into lock from above
    JSR CheckCollision

    LDA is_dead
    CMP #$01
    BEQ Reset

    JSR timer_schedule
    BRA Lock

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "assets/sprites/ball.s"

.include "assets/tiles/clut.s"
.include "assets/tiles/image.s"
.include "assets/tiles/map.s"
