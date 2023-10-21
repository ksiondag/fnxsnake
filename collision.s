Reset
    .as
    .xs
    REP #$20
    SEC
    XCE
	JMP MAIN

CheckCollision
    ; Use 816 mode
    CLC
    XCE
    
    setaxs
    setaxl
CheckBottom
    LDA sprite_y
    CMP #$00FE
    BMI CheckRight
    BRA Reset

CheckRight
    LDA sprite_x
    CMP #$014F
    BMI CheckTop
    BRA Reset

CheckTop
    LDA sprite_y
    CMP #$0020
    BPL CheckLeft
    BRA Reset

CheckLeft
    LDA sprite_x
    CMP #$0020
    BPL CommitPositions
    BRA Reset

CommitPositions
    ; Reset frame counter
    setaxs
    LDA #1
    STA frame_counter

    .as
    .xs
    REP #$20
    SEC
    XCE
