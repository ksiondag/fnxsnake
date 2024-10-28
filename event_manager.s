input_loop
    bit     kernel.args.events.pending

    jsr     kernel.NextEvent
    bcs     input_loop

    lda     event.type
    cmp     #kernel.event.key.PRESSED
    beq     _kbd
    cmp     #kernel.event.timer.EXPIRED
    beq     _timer
    bne     input_loop
_kbd
    JSR KBD.Poll
    bra input_loop
_timer
    lda event.timer.cookie
    cmp #$EA
    bne input_loop
    rts

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
    ; Only set next direction to left if current direction is not left or right
    LDA (direction_moving_pointer)
    AND #$30
    CMP #$00
    BNE CheckUpArrow

    LDA (direction_moving_pointer)
    AND #$F0
    ORA #$02
    STA (direction_moving_pointer)
    
    LDA direction_press
    ORA #$20
    STA direction_press

    JMP DoneCheckInput

CheckUpArrow
    cmp #ASCII_UP
    beq TryMoveUp
    cmp #ASCII_W
    beq TryMoveUp
    bra CheckRightArrow

TryMoveUp
    ; Only set next direction to up if current direction is not up or down
    LDA (direction_moving_pointer)
    AND #$C0
    CMP #$00
    BNE CheckRightArrow

    LDA (direction_moving_pointer)
    AND #$F0
    ORA #$08
    STA (direction_moving_pointer)
    
    LDA direction_press
    ORA #$80
    STA direction_press

    JMP DoneCheckInput

CheckRightArrow
    cmp #ASCII_RIGHT
    beq TryMoveRight
    cmp #ASCII_D
    beq TryMoveRight
    bra CheckDownArrow

TryMoveRight
    ; Only set next direction to left if current direction is not left or right
    LDA (direction_moving_pointer)
    AND #$30
    CMP #$00
    BNE CheckDownArrow

    LDA (direction_moving_pointer)
    AND #$F0
    ORA #$01
    STA (direction_moving_pointer)
    
    LDA direction_press
    ORA #$10
    STA direction_press

    JMP DoneCheckInput

CheckDownArrow
    cmp #ASCII_DOWN
    beq TryMoveDown
    cmp #ASCII_S
    beq TryMoveDown
    bra DoneCheckInput

TryMoveDown
    ; Only set next direction to up if current direction is not up or down
    LDA (direction_moving_pointer)
    AND #$C0
    CMP #$00
    BNE DoneCheckInput

    LDA (direction_moving_pointer)
    AND #$F0
    ORA #$04
    STA (direction_moving_pointer)
    
    LDA direction_press
    ORA #$40
    STA direction_press

    JMP DoneCheckInput

DoneCheckInput
    RTS

.endn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
