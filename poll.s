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
    ; left_press wasn't pressed down, save that info if we last saw it on
    STZ left_press
    JMP CheckUpArrow

CheckLeftPressed
    ; If left_press wasn't zero, then we already marked it down before
    LDA left_press
    CMP #$00
    BNE CheckUpArrow
    
    LDA vel_x
    CMP #$00
    BNE CheckUpArrow
    
    LDA vel_x+1
    CMP #$00
    BNE CheckUpArrow
    
    LDA #$01
    STA left_press

    LDA #$FC
    STA vel_x
    LDA #$FF
    STA vel_x+1
    LDA #$00
    STA vel_y
    STA vel_y+1
    JMP DoneCheckInput

CheckUpArrow
    ; UpArrow is PA0, PB7
    LDA #(1 << 0 ^ $FF)
    STA VIA1_PRA
    LDA VIA1_PRB
    CMP #(1 << 7 ^ $FF)
    BEQ CheckUpPressed
    ; up_press wasn't pressed down, save that info if we last saw it on
    STZ up_press
    JMP CheckRightArrow
CheckUpPressed
    ; If up_press wasn't zero, then we already marked it down before
    LDA up_press
    CMP #$00
    BNE CheckRightArrow
    
    LDA vel_y
    CMP #$00
    BNE CheckRightArrow
    
    LDA vel_y+1
    CMP #$00
    BNE CheckRightArrow
    
    LDA #$01
    STA up_press

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
    ; up_press wasn't pressed down, save that info if we last saw it on
    STZ right_press
    JMP CheckDownArrow

CheckRightPressed
    ; If right_press wasn't zero, then we already marked it down before
    LDA right_press
    CMP #$00
    BNE CheckDownArrow
    
    LDA vel_x
    CMP #$00
    BNE CheckDownArrow
    
    LDA vel_x+1
    CMP #$00
    BNE CheckDownArrow
    
    LDA #$01
    STA right_press

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
    ; down_press wasn't pressed down, save that info if we last saw it on
    STZ down_press
    JMP DoneCheckInput

CheckDownPressed
    ; If down_press wasn't zero, then we already marked it down before
    LDA down_press
    CMP #$00
    BNE DoneCheckInput
    
    LDA vel_y
    CMP #$00
    BNE DoneCheckInput
    
    LDA vel_y+1
    CMP #$00
    BNE DoneCheckInput
    
    LDA #$01
    STA down_press

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
