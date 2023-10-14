; Keep track of each direction of movement, and where came from
; 0 means movement hasn't happened on that tile yet
; Left byte is direction facing on entering
; Right byte is direction facing on exit
; (8) 1000 means up
; (4) 0100 means down
; (2) 0010 means left
; (1) 0001 means right
; 44 means came facing down (from above); leaving facing down
; 82 means came facing up (from below); leaving facing left
movement_map:
    .byte $81, $11, $14, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $88, $00, $44, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $88, $00, $41, $11, $14, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $88, $00, $00, $00, $44, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $28, $22, $22, $22, $42, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

UpdateMovement:
    ; Though the game is animating the movement to each tile
    ; direction of movement can only update at overlap of tile
    ; This routine controls that logic

    ; Check if time to update movement
    LDA next_update_movement
    CMP #$07
    BNE IncrementMovement

    ; Get movement direction from movement map
    LDA #<movement_map
    STA src_pointer
    LDA #>movement_map
    STA src_pointer+1
    JMP MovementMapRow

IncrementMovement:
    LDA next_update_movement
    CLC
    ADC #$01
    STA next_update_movement
    RTS

MovementMapRow:
    LDY #$00
MovementMapRowLoop:
    CPY grid_pos_y
    BEQ MovementMapCol

    CLC ; Move src_pointer to the next row of movement_map
    LDA src_pointer
    ADC #$14 ; A row is 20 (#$14) columns long
    STA src_pointer
    LDA src_pointer+1
    ADC #0
    STA src_pointer+1
    INY
    BRA MovementMapRowLoop

MovementMapCol:
    LDY grid_pos_x
LoadDirectionMoving:
    LDA (src_pointer),y
    STA direction_moving

    LDA direction_moving
    AND #$0F
    CMP #$02
    BEQ GridPosXDecrement

    LDA direction_moving
    AND #$0F
    CMP #$01
    BEQ GridPosXIncrement

    LDA direction_moving
    AND #$0F
    CMP #$08
    BEQ GridPosYDecrement

    LDA direction_moving
    AND #$0F
    CMP #$04
    BEQ GridPosYIncrement

GridPosXDecrement:
    CLC
    LDA grid_pos_x
    ADC #$FF
    STA grid_pos_x
    BRA CheckLeftMovement

GridPosXIncrement:
    CLC
    LDA grid_pos_x
    ADC #$01
    STA grid_pos_x
    BRA CheckLeftMovement

GridPosYDecrement:
    CLC
    LDA grid_pos_y
    ADC #$FF
    STA grid_pos_y
    BRA CheckLeftMovement

GridPosYIncrement:
    CLC
    LDA grid_pos_y
    ADC #$01
    STA grid_pos_y
    BRA CheckLeftMovement

CheckLeftMovement:
    LDA direction_moving
    AND #$0F
    CMP #$02
    BNE CheckUpMovement

    LDA #$20
    STA direction_moving

    LDA #$FE
    STA vel_x
    LDA #$FF
    STA vel_x+1
    STZ vel_y
    STZ vel_y+1
    JMP DoneCheckMovement

CheckUpMovement:
    LDA direction_moving
    AND #$0F
    CMP #$08
    BNE CheckRightMovement

    LDA #$80
    STA direction_moving

    LDA #$FE
    STA vel_y
    LDA #$FF
    STA vel_y+1
    LDA #$00
    STA vel_x
    STA vel_x+1
    JMP DoneCheckMovement

CheckRightMovement:
    LDA direction_moving
    AND #$0F
    CMP #$01
    BNE CheckDownMovement

    LDA #$10
    STA direction_moving

    LDA #$2
    STA vel_x
    LDA #$00
    STA vel_x+1
    LDA #$00
    STA vel_y
    STA vel_y+1
    JMP DoneCheckMovement

CheckDownMovement:
    LDA direction_moving
    AND #$0F
    CMP #$04
    BNE DoneCheckMovement

    LDA #$40
    STA direction_moving

    LDA #$2
    STA vel_y
    LDA #$00
    STA vel_y+1
    LDA #$00
    STA vel_x
    STA vel_x+1
    JMP DoneCheckMovement

DoneCheckMovement:
    STZ next_update_movement
    RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AnimateMovement:
    ; Use 816 mode
    CLC
    XCE
    
    setaxs

    ; Move sprite to the right
    STZ MMU_IO_CTRL ; Go back to I/O Page 0

    ; Nudge sprite to the right
    setaxl
    CLC
    LDA @w sprite_x
    ADC @w vel_x
    STA @w sprite_x
    
    ; Nudge sprite down
    CLC
    LDA @w sprite_y
    ADC @w vel_y
    STA @w sprite_y

    RTS