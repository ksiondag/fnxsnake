dummyCallBack
    clc
    rts

TIMER_VECTOR .word dummyCallBack
KBD_VECTOR .word dummyCallBack
JOYSTICK_VECTOR .word dummyCallBack

input_loop
    bit     kernel.args.events.pending

    jsr     kernel.NextEvent
    bcs     input_loop

    lda     event.type
    cmp     #kernel.event.key.PRESSED
    beq     _kbd
    cmp     #kernel.event.JOYSTICK
    beq     _joystick
    cmp     #kernel.event.timer.EXPIRED
    beq     _timer
    bra     input_loop
_timer
    lda event.timer.cookie
    cmp #$EA
    bne input_loop
    JSR timer_callback
    JSR timer_schedule
    bra input_loop
_joystick
    JSR joystick_callback
    bra input_loop
_kbd
    JSR kbd_callback
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

timer_callback
    jmp (TIMER_VECTOR)


kbd_callback
    jmp (KBD_VECTOR)

joystick_callback
    jmp (JOYSTICK_VECTOR)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

