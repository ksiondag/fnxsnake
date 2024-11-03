
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

TXT_CURSOR .text "*"
TXT_START .text "Game Start"
TXT_EXIT .text "Exit Game"

LoadTitle
	JSR setup_sprites
    JSR ngn.txtio.clear

    LDA #$77
    STA ngn.CURSOR_STATE.col
    #ngn.locate 14, 15
    #ngn.printString TXT_CURSOR, len(TXT_CURSOR)
    #ngn.locate 16, 15
    #ngn.printString TXT_START, len(TXT_START)

    LDA #$11
    STA ngn.CURSOR_STATE.col
    #ngn.locate 16, 17
    #ngn.printString TXT_EXIT, len(TXT_EXIT)

    #ngn.load16BitImmediate title_movement_map, movement_map_pointer
    #ngn.load16BitImmediate LockTitle, ngn.TIMER_VECTOR
    #ngn.load16BitImmediate title.KBD.Poll, ngn.KBD_VECTOR
    #ngn.load16BitImmediate title.JOY.Poll, ngn.JOYSTICK_VECTOR

    LDA #$01
    STA playback_mode

    LDA #$10
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

    LDA #$04
    STA grid_pos_x
    LDA #$03
    STA grid_pos_y

    STZ is_dead
    STZ apple_present

    RTS

LockTitle
    JSR UpdateMovement
    JSR AnimateMovement

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

title .namespace

TRY_MOVE .namespace

Confirm
    JSR LoadLevel1
_done
    RTS

Left
_done
    RTS

Up
_done
    RTS

Right
_done
    RTS

Down
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
CheckEnter
    cmp #ASCII_ENTER
    beq TryConfirm
    bra CheckLeftArrow
TryConfirm
    JSR TRY_MOVE.Confirm
    JMP DoneCheckInput

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
