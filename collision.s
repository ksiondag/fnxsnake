CheckCollision
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
    LDA #3
    STA frame_counter

    .as
    .xs
    REP #$20
    SEC
    XCE

    LDA #$00
    STA src_pointer
    LDA #$D9
    STA src_pointer+1

    LDX #$00
    LDA sprite_x
    PHA
    LDA sprite_y
    PHA

CommitSpriteX
    CPX #$02
    BEQ DoneUpdate
    INX

    ; Commit sprite positions
    LDY #$04
    LDA sprite_x
    STA (src_pointer),y 

    INY
    LDA sprite_x+1
    STA (src_pointer),y

    INY
    LDA sprite_y
    STA (src_pointer),y

    INY
    LDA sprite_y+1
    STA (src_pointer),y

    CLC
    LDA sprite_y
    ADC #$10
    STA sprite_y

    CLC
    LDA src_pointer
    ADC #$08
    STA src_pointer
    LDA src_pointer+1
    ADC #$00
    STA src_pointer+1

    BRA CommitSpriteX

DoneUpdate
    PLA
    STA sprite_y

    PLA
    STA sprite_x
    RTS
