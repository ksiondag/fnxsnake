input_loop
    bit     kernel.args.events.pending

    jsr     kernel.NextEvent
    bcs     input_loop

    lda     event.type
    cmp     #kernel.event.key.PRESSED
    beq     _kbd
    cmp     #kernel.event.JOYSTICK
    beq     joystick
    cmp     #kernel.event.timer.EXPIRED
    beq     _timer
    bra     input_loop
_kbd
    JSR KBD.Poll
    bra input_loop
_timer
    lda event.timer.cookie
    cmp #$EA
    bne input_loop
    rts
joystick
    JSR JOY.Poll
    bra input_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init_EventHandler
    ; Init the event buffer.
    lda     #<event
    sta     kernel.args.events.dest+0
    lda     #>event
    sta     kernel.args.events.dest+1

timer_schedule
    lda     #kernel.args.timer.FRAMES | kernel.args.timer.QUERY
    sta     kernel.args.timer.units
    jsr     kernel.Clock.SetTimer
    adc #0
    
    ; Schedule the timer.
    stz     kernel.args.timer.units
    sta     kernel.args.timer.absolute
    lda #$EA
    sta kernel.args.timer.cookie
    jsr     kernel.Clock.SetTimer
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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
    bra DoneCheckInput

TryMoveDown
    JSR TRY_MOVE.Down
    JMP DoneCheckInput

DoneCheckInput
    RTS

.endn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
