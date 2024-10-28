input_loop
    JSR Poll
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

Poll

CheckLeftArrow

CheckUpArrow

CheckRightArrow

CheckDownArrow

DoneCheckInput
    RTS

.endn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
