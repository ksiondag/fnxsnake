Reset
    #ngn.load16BitImmediate LoadLevel1, ngn.TIMER_VECTOR
    RTS

SetIsDead
    LDA #$01
    STA is_dead

	JMP CommitPositions

CheckCollision
    CLC

CheckBottom                 ; Check if ran into bottom of screen
    LDA sprite_y            ; If sprite_y < #$0101, we have not
    CMP #$01
    BMI CheckRight

    LDA sprite_y+1
    CMP #$01
    BMI CheckRight
    BRA SetIsDead

CheckRight                  ; Check if ran into right of screen
    LDA sprite_x            ; If sprite_x < #$0151, we have not
    CMP #$51
    BMI CheckTop

    LDA sprite_x+1
    CMP #$01
    BMI CheckTop
    BRA SetIsDead

CheckTop                    ; Check if ran into top of screen
    LDA sprite_y            ; If sprite_y > #$0020, we have not
    CMP #$20
    BCS CheckLeft

    LDA sprite_y+1
    CMP #$00
    BNE CheckLeft
    BRA SetIsDead

CheckLeft
    LDA sprite_x
    CMP #$20
    BCS CommitPositions

    LDA sprite_x+1
    CMP #$00
    BNE CommitPositions

    BRA SetIsDead

CommitPositions
    RTS