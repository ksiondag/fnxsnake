LoadLevel1
	JSR setup_sprites

    #ngn.load16BitImmediate movement_map, movement_map_pointer
    JSR ngn.txtio.clear
    #ngn.load16BitImmediate LockLevel1, ngn.TIMER_VECTOR
    #ngn.load16BitImmediate level1.KBD.Poll, ngn.KBD_VECTOR
    #ngn.load16BitImmediate level1.JOY.Poll, ngn.JOYSTICK_VECTOR

    LDA #$00
    STA playback_mode

    LDA #$01
    STA snake_length

    STZ displacement
    STZ displacement+1
    LDA #$02
    STA vel+1
    LDA #$80
    STA vel

    STZ direction_press
    LDA #$10
    STA direction_moving

    LDA #$01
    STA grid_pos_x
    TAX
    LDA #$00
    STA grid_pos_y
    TAY

    ; On death, need to make sure movement defaults right
    PHY
    LDY #$01
    LDA #$11
    STA movement_map,y
    PLY

    STZ is_dead
    STZ apple_present

    RTS

LockLevel1
    JSR PlaceApple
    JSR UpdateMovement
    JSR AnimateMovement
    JSR RenderApple

    LDA is_dead
    CMP #$01
    BEQ _reset

    ; CheckCollision either ends with reset or falls back into lock from above
    JSR CheckCollision

    LDA is_dead
    CMP #$01
    BEQ _reset

    RTS

_reset
    JMP Reset

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

level1 .namespace

TRY_MOVE .namespace

Left
    ; Only set next direction to left if current direction is not left or right
    LDA (direction_moving_pointer)
    AND #$30
    CMP #$00
    BNE _done

    LDA (direction_moving_pointer)
    AND #$F0
    ORA #$02
    STA (direction_moving_pointer)
    
    LDA direction_press
    ORA #$20
    STA direction_press
_done
    RTS

Up
    ; Only set next direction to up if current direction is not up or down
    LDA (direction_moving_pointer)
    AND #$C0
    CMP #$00
    BNE _done

    LDA (direction_moving_pointer)
    AND #$F0
    ORA #$08
    STA (direction_moving_pointer)
    
    LDA direction_press
    ORA #$80
    STA direction_press
_done
    RTS

Right
    ; Only set next direction to left if current direction is not left or right
    LDA (direction_moving_pointer)
    AND #$30
    CMP #$00
    BNE _done

    LDA (direction_moving_pointer)
    AND #$F0
    ORA #$01
    STA (direction_moving_pointer)
    
    LDA direction_press
    ORA #$10
    STA direction_press
_done
    RTS

Down
    ; Only set next direction to up if current direction is not up or down
    LDA (direction_moving_pointer)
    AND #$C0
    CMP #$00
    BNE _done

    LDA (direction_moving_pointer)
    AND #$F0
    ORA #$04
    STA (direction_moving_pointer)
    
    LDA direction_press
    ORA #$40
    STA direction_press
_done
    RTS
.endn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JOY .namespace

UP    = 1
DOWN  = 2
LEFT  = 4
RIGHT = 8

Poll
    PHX
    LDA event.joystick.joy0+1
    TAX
CheckLeft
    TXA
    AND #LEFT
    BEQ CheckUp
    JSR TRY_MOVE.Left
    JMP DoneCheckInput
CheckUp
    TXA
    AND #UP
    BEQ CheckRight
    JSR TRY_MOVE.Up
    JMP DoneCheckInput
CheckRight
    TXA
    AND #RIGHT
    BEQ CheckDown
    JSR TRY_MOVE.Right
    JMP DoneCheckInput
CheckDown
    TXA
    AND #DOWN
    BEQ DoneCheckInput
    JSR TRY_MOVE.Down
    JMP DoneCheckInput
DoneCheckInput
    PLX
    RTS

.endn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

KBD .namespace

; TODO: Fix copy-paste code between title and level1
ASCII_UP = 16
ASCII_W = 119

ASCII_DOWN = 14
ASCII_S = 115

ASCII_LEFT = 2
ASCII_A = 97

ASCII_RIGHT = 6
ASCII_D = 100

ASCII_ENTER = $0D

Poll
    lda event.key.ascii
CheckLeftArrow
    cmp #ASCII_LEFT
    beq TryMoveLeft
    cmp #ASCII_A
    beq TryMoveLeft
    bra CheckUpArrow

TryMoveLeft
    JSR TRY_MOVE.Left
    JMP DoneCheckInput

CheckUpArrow
    cmp #ASCII_UP
    beq TryMoveUp
    cmp #ASCII_W
    beq TryMoveUp
    bra CheckRightArrow

TryMoveUp
    JSR TRY_MOVE.Up
    JMP DoneCheckInput

CheckRightArrow
    cmp #ASCII_RIGHT
    beq TryMoveRight
    cmp #ASCII_D
    beq TryMoveRight
    bra CheckDownArrow

TryMoveRight
    JSR TRY_MOVE.Right
    JMP DoneCheckInput

CheckDownArrow
    cmp #ASCII_DOWN
    beq TryMoveDown
    cmp #ASCII_S
    beq TryMoveDown
    bra Default

TryMoveDown
    JSR TRY_MOVE.Down
    JMP DoneCheckInput

Default
DoneCheckInput
    RTS

.endn

.endn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
