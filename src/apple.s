PlaceApple
    PHX
    PHY
    LDA apple_present
    BNE PlaceAppleDone
PlaceAppleX
    LDX RNDL
PlaceAppleXLoop
    CPX #$14
    BLT PlaceAppleXDone
    SEC
    TXA
    SBC #$14
    TAX
    BRA PlaceAppleXLoop
PlaceAppleXDone
    STX apple_pos_x
PlaceAppleY
    LDY RNDH
PlaceAppleYLoop
    CPY #$0F
    BLT PlaceAppleYDone
    SEC
    TYA
    SBC #$0F
    TAY
    BRA PlaceAppleXLoop
PlaceAppleYDone
    STY apple_pos_y
PlaceAppleDone
    PLY
    PLX
    LDA #$01
    STA apple_present
    RTS

AppleCollisionCheck
    LDA apple_pos_x
    CMP grid_pos_x
    BNE AppleCollisionCheckDone
    LDA apple_pos_y
    CMP grid_pos_y
    BNE AppleCollisionCheckDone

    ; X is currently the part of the snake we're on, 0 is the head
    ; If we collided on the head, then we're eating the apple
    CPX #$00
    BEQ AppleEaten
    ; TODO: If colliding with a non-head part of snake, we've spawned it on that part
    ; Just move the apple to the tail in this case
    BRA AppleCollisionCheckDone
AppleEaten
    LDA snake_length
    CLC
    ADC #$01
    STA snake_length
    STZ apple_present
AppleCollisionCheckDone
    RTS

RenderApple
    PHX
    PHY

    LDA sprite_x
    PHA
    LDA sprite_x+1
    PHA
    LDA sprite_y
    PHA
    LDA sprite_y+1
    PHA

RenderAppleRow
    LDY #$00
    LDA #$20
    STA sprite_y
    STZ sprite_y+1
RenderAppleRowLoop
    CPY apple_pos_y
    BEQ RenderAppleCol

    CLC
    LDA sprite_y
    ADC #$10
    STA sprite_y
    LDA sprite_y+1
    ADC #$00
    STA sprite_y+1

    INY
    BRA RenderAppleRowLoop
RenderAppleCol:
    LDX #$00
    LDA #$20
    STA sprite_x
    STZ sprite_x+1
RenderAppleColLoop:
    CPX apple_pos_x
    BEQ RenderAppleCommit

    CLC
    LDA sprite_x
    ADC #$10
    STA sprite_x
    LDA sprite_x+1
    ADC #$00
    STA sprite_x+1

    INX
    BRA RenderAppleColLoop
RenderAppleCommit
    ; TODO: Right now using animate movement sprite leftover information to render apple
    ; Will want to not depend on that logic when actually using different sprites, though
    ; Commit sprite positions
    LDY #$04
    LDA sprite_x
    STA (dst_pointer),y 

    INY
    LDA sprite_x+1
    STA (dst_pointer),y

    ; In emulator, SPX_Y_H must always be zero, so we're going to be on the very edge of SPX_Y_L to use the last row
    ; Comment this code out when developing directly on hardware
    LDA sprite_y+1
    CMP #$01
    BNE AppleLoadSpriteY

    INY
    LDA #$FF
    STA (dst_pointer),y
    JMP RenderAppleDone

AppleLoadSpriteY:
    INY
    LDA sprite_y
    STA (dst_pointer),y

    INY
    LDA sprite_y+1
    STA (dst_pointer),y

RenderAppleDone
    PLA
    STA sprite_y+1
    PLA
    STA sprite_y
    PLA
    STA sprite_x+1
    PLA
    STA sprite_x

    PLY
    PLX
    RTS