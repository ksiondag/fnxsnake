ExitGame
    jsr ngn.txtio.init80x60
    lda #65
    ; TODO: Is it bad that I'm exiting to a different program with data on the stack?
    sta kernel.args.run.block_id
    jsr kernel.RunBlock
    ; This part shouldn't happen
    ; TODO: If above errors, we'll want to do a 'Software reset' (see chapter 17 of system manual)
    rts