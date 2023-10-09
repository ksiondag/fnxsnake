;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Poll
    LDA #$00 ; Need to be on I/O page 0
    STA MMU_IO_CTRL
    ; TODO: Need to only update once per movement cycle

CheckLeftArrow
    ; LeftArrow is PA0, PB2
    LDA #(1 << 0 ^ $FF)
    STA VIA1_PRA
    LDA VIA1_PRB
    CMP #(1 << 2 ^ $FF)
    BEQ CheckLeftPressed
    ; left arrow wasn't pressed down, save that info in case we last saw it pressed
    LDA direction_press
    AND #$DF
    STA direction_press
    JMP CheckUpArrow

CheckLeftPressed
    ; Check if left arrow was already pressed down
    LDA direction_press
    AND #$20
    CMP #$00
    BNE CheckUpArrow

    ; Only set next direction to left if current direction is not left or right
    LDA direction_moving
    AND #$30
    CMP #$00
    BNE CheckUpArrow

    LDA direction_moving
    AND #$F0
    ORA #$02
    STA direction_moving
    
    LDA direction_press
    ORA #$20
    STA direction_press

    JMP DoneCheckInput

CheckUpArrow
    ; UpArrow is PA0, PB7
    LDA #(1 << 0 ^ $FF)
    STA VIA1_PRA
    LDA VIA1_PRB
    CMP #(1 << 7 ^ $FF)
    BEQ CheckUpPressed
    ; up arrow wasn't pressed down, save that info in case we last saw it pressed
    LDA direction_press
    AND #$7F
    STA direction_press
    JMP CheckRightArrow
CheckUpPressed
    ; Check if up arrow was already pressed down
    LDA direction_press
    AND #$80
    CMP #$00
    BNE CheckRightArrow

    ; Only set next direction to up if current direction is not up or down
    LDA direction_moving
    AND #$C0
    CMP #$00
    BNE CheckRightArrow

    LDA direction_moving
    AND #$F0
    ORA #$08
    STA direction_moving
    
    LDA direction_press
    ORA #$80
    STA direction_press

    JMP DoneCheckInput

CheckRightArrow
    ; RightArrow is on its own setup, as is DownArrow
    LDA #(1 << 6 ^ $FF)
    STA VIA1_PRA
    LDA VIA0_PRB
    CMP #(1 << 7 ^ $FF)
    BEQ CheckRightPressed
    ; right arrow wasn't pressed down, save that info in case we last saw it pressed
    LDA direction_press
    AND #$EF
    STA direction_press
    JMP CheckDownArrow

CheckRightPressed
    ; Check if right arrow was already pressed down
    LDA direction_press
    AND #$10
    CMP #$00
    BNE CheckDownArrow

    ; Only set next direction to left if current direction is not left or right
    LDA direction_moving
    AND #$30
    CMP #$00
    BNE CheckDownArrow

    LDA direction_moving
    AND #$F0
    ORA #$01
    STA direction_moving
    
    LDA direction_press
    ORA #$10
    STA direction_press

    JMP DoneCheckInput

CheckDownArrow
    ; DownArrow is on its own setup, as is RightArrow
    LDA #(1 << 0 ^ $FF)
    STA VIA1_PRA
    LDA VIA0_PRB
    CMP #(1 << 7 ^ $FF)
    BEQ CheckDownPressed
    ; down arrow wasn't pressed down, save that info in case we last saw it pressed
    LDA direction_press
    AND #$BF
    STA direction_press
    JMP DoneCheckInput

CheckDownPressed
    ; Check if down arrow was already pressed down
    LDA direction_press
    AND #$40
    CMP #$00
    BNE DoneCheckInput

    ; Only set next direction to up if current direction is not up or down
    LDA direction_moving
    AND #$C0
    CMP #$00
    BNE DoneCheckInput

    LDA direction_moving
    AND #$F0
    ORA #$04
    STA direction_moving
    
    LDA direction_press
    ORA #$40
    STA direction_press

    JMP DoneCheckInput

DoneCheckInput
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
