
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

TXT_CURSOR .text "*"
TXT_START .text "Game Start"
TXT_EXIT .text "Exit Game"

title_index .byte ?
cursor_x .byte ?
cursor_y .byte ?
.send

HIGHLIGHT_COLOR = $77
STANDARD_COLOR = $11

GameStart
    JMP LoadLevel1
ExitGame
    JSR ngn.txtio.init80x60
    LDA #65
    ; TODO: Is it bad that I'm exiting to a different program with data on the stack?
    STA kernel.args.run.block_id
    JSR kernel.RunBlock
    ; This part shouldn't happen
    ; TODO: If above errors, we'll want to do a 'Software reset' (see chapter 17 of system manual)
    RTS

PrepRow
    CPY title_index
    BEQ _highlight
_standard
    LDA #STANDARD_COLOR
    STA ngn.CURSOR_STATE.col
    BRA _done
_highlight
    LDA #HIGHLIGHT_COLOR
    STA ngn.CURSOR_STATE.col
    JMP PrintCursor
_done
    RTS

PrintCursor
    LDA cursor_x
    PHA

    CLC
    SBC #2
    STA cursor_x

    #ngn.locate cursor_x, cursor_y
    #ngn.printString TXT_CURSOR, len(TXT_CURSOR)

    PLA
    STA cursor_x
    RTS

PrintTitleScreen
    JSR ngn.txtio.clear
    PHY
    LDY #$00

    LDA #16
    STA cursor_x

    LDA #15
    STA cursor_y

    JSR PrepRow
    #ngn.locate cursor_x, cursor_y
    #ngn.printString TXT_START, len(TXT_START)

    LDY #$01
    CLC
    LDA cursor_y
    ADC #2
    STA cursor_y

    JSR PrepRow
    #ngn.locate cursor_x, cursor_y
    #ngn.printString TXT_EXIT, len(TXT_EXIT)

    PLY
    RTS

LoadTitle
	JSR setup_sprites   
    STZ title_index
    JSR PrintTitleScreen

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
    LDA title_index
    CMP #0
    BEQ _game_start
    CMP #1
    BEQ _exit_game
    BRA _exit_game ; Shouldn't happen
_game_start
    JMP GameStart
_exit_game
    JMP ExitGame

Left
_done
    RTS

Up
    LDA title_index
    SEC
    SBC #1 
    STA title_index
    CMP #$FF
    BNE _done
    STZ title_index
_done
    JMP PrintTitleScreen

Right
_done
    RTS

Down
    LDA title_index
    CLC
    ADC #1
    STA title_index
    CMP #2
    BNE _done
    LDA #1
    STA title_index
_done
    JMP PrintTitleScreen
.endn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JOY .namespace

UP    =   %00000001
DOWN  =   %00000010
LEFT  =   %00000100
RIGHT =   %00001000
BUTTON1 = %00010000
BUTTON2 = %00100000
BUTTON3 = %01000000

Poll
    PHX
    LDA event.joystick.joy1
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
    BEQ CheckButton
    JSR TRY_MOVE.Down
    JMP DoneCheckInput
CheckButton
    TXA
    AND #BUTTON1
    BNE _confirm
    TXA
    AND #BUTTON2
    BNE _confirm
    TXA
    AND #BUTTON3
    BNE _confirm
    BRA DoneCheckInput
_confirm
    TXA
    AND #$80
    BNE DoneCheckInput
    JSR TRY_MOVE.Confirm

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
