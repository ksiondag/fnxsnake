CheckCollision
    ; Check for bounce off the bottom
    LDA sprite_y
    CMP #$00FE
    BMI DoneBottomCheck
    BRA Reset
DoneBottomCheck

    ; Check for bounce off the right
    LDA sprite_x
    CMP #$014F
    BMI DoneRightCheck
    BRA Reset
DoneRightCheck

    ; Check for bounce off the top
    LDA sprite_y
    CMP #$0020
    BPL DoneTopCheck
    BRA Reset
DoneTopCheck

    ; Check for bounce off the left
    LDA sprite_x
    CMP #$0020
    BPL DoneLeftCheck
    BRA Reset
DoneLeftCheck


    ; Commit sprite positions
    LDA sprite_x
    STA SP0_X_L 
    LDA sprite_x+1
    STA SP0_X_H ;
    LDA sprite_y
    STA SP0_Y_L
    LDA sprite_y+1
    STA SP0_Y_H

    ; Reset frame counter
    setaxs
    LDA #3
    STA frame_counter

    .as
    .xs
    REP #$20
    SEC
    XCE

DoneUpdate
    RTS
