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
    LDA #3
    STA frame_counter

    .as
    .xs
    REP #$20
    SEC
    XCE

    LDA #$00
    STA dst_pointer
    LDA #$D9
    STA dst_pointer+1

    LDA sprite_x
    PHA
    LDA sprite_x+1
    PHA
    LDA sprite_y
    PHA
    LDA sprite_y+1
    PHA

    LDX #$00

CommitSpriteX
    CPX #$02
    BEQ DoneUpdate
    INX

    ; Commit sprite positions
    LDY #$04
    LDA sprite_x
    STA (dst_pointer),y 

    INY
    LDA sprite_x+1
    STA (dst_pointer),y

    INY
    LDA sprite_y
    STA (dst_pointer),y

    INY
    LDA sprite_y+1
    STA (dst_pointer),y

    CLC
    LDA sprite_y
    ADC #$10
    STA sprite_y

    CLC
    LDA dst_pointer
    ADC #$08
    STA dst_pointer
    LDA dst_pointer+1
    ADC #$00
    STA dst_pointer+1

    BRA CommitSpriteX

DoneUpdate
    PLA
    STA sprite_y+1
    PLA
    STA sprite_y
    PLA
    STA sprite_x+1
    PLA
    STA sprite_x