
.section data
title_movement_map:
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $81, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $14, $00, $00, $00, $00
    .byte $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44, $00, $00, $00, $00
    .byte $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44, $00, $00, $00, $00
    .byte $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44, $00, $00, $00, $00
    .byte $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44, $00, $00, $00, $00
    .byte $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44, $00, $00, $00, $00
    .byte $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44, $00, $00, $00, $44
    .byte $00, $00, $00, $88, $00, $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $44, $00, $00, $00, $00
    .byte $00, $00, $00, $28, $22, $22, $22, $22, $22, $22, $22, $22, $22, $22, $22, $42, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.send

TXT_START      .text "PRESS 0-2 TO PLAY. F3 TO EXIT."

LoadTitle
    ; TODO: Temporarily automatically load level 1
    JMP LoadLevel1
    JSR ngn.txtio.clear
    #ngn.locate 5, 27
    #ngn.printString TXT_START, len(TXT_START)
    #ngn.load16BitImmediate LockTitle, ngn.TIMER_VECTOR
    #ngn.load16BitImmediate title.KBD.Poll, ngn.KBD_VECTOR
    #ngn.load16BitImmediate title.JOY.Poll, ngn.JOYSTICK_VECTOR
    RTS

LockTitle
    JSR UpdateMovement
    JSR AnimateMovement

    RTS

_reset
    JMP Reset

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

title .namespace

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

ASCII_UP = 16
ASCII_W = 119

ASCII_DOWN = 14
ASCII_S = 115

ASCII_LEFT = 2
ASCII_A = 97

ASCII_RIGHT = 6
ASCII_D = 100

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
