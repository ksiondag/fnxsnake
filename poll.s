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
    
    LDA vel_x
    CMP #$00
    BNE CheckUpArrow
    
    LDA vel_x+1
    CMP #$00
    BNE CheckUpArrow
    
    LDA direction_press
    ORA #$20
    STA direction_press

    LDA #$FC
    STA vel_x
    LDA #$FF
    STA vel_x+1
    STZ vel_y
    STZ vel_y+1
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
    
    LDA vel_y
    CMP #$00
    BNE CheckRightArrow
    
    LDA vel_y+1
    CMP #$00
    BNE CheckRightArrow
    
    LDA direction_press
    ORA #$70
    STA direction_press

    LDA #$FC
    STA vel_y
    LDA #$FF
    STA vel_y+1
    LDA #$00
    STA vel_x
    STA vel_x+1
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
    
    LDA vel_x
    CMP #$00
    BNE CheckDownArrow
    
    LDA vel_x+1
    CMP #$00
    BNE CheckDownArrow
    
    LDA direction_press
    ORA #$10
    STA direction_press

    LDA #$3
    STA vel_x
    LDA #$00
    STA vel_x+1
    LDA #$00
    STA vel_y
    STA vel_y+1
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
    
    LDA vel_y
    CMP #$00
    BNE DoneCheckInput
    
    LDA vel_y+1
    CMP #$00
    BNE DoneCheckInput
    
    LDA direction_press
    ORA #$40
    STA direction_press

    LDA #$3
    STA vel_y
    LDA #$00
    STA vel_y+1
    LDA #$00
    STA vel_x
    STA vel_x+1
    JMP DoneCheckInput

DoneCheckInput
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
