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

    ; Get movement direction from movement map
    ; This loads various information where we need it regardless of branch taken below
    JSR MovementSrcPointer

    ; Check if time to update movement
    LDA next_update_movement
    CMP #$07
    BNE IncrementMovement

    JSR UpdateGridPosition
    JMP CheckLeftMovement

IncrementMovement:
    ; TODO: Displacement is all I need to know
    ; If above #$0F, then we've gone to next grid
    ; This also handles the non-power-of-two problem
    LDA next_update_movement
    CLC
    ADC #$01
    STA next_update_movement
    ;LDA displacement
    ;CLC
    ;ADC vel
    ;STA displacement
    ;LDA displacement+1
    ;ADC vel+1
    ;STA displacement+1
    RTS

MovementSrcPointer:
    ; Sets src_pointer to current x,y direction_moving
    ; Sets X to grid_pos_x
    ; Loads direction_moving with the value stored at that x,y in movement_map 
    LDA #<movement_map
    STA src_pointer
    LDA #>movement_map
    STA src_pointer+1
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
    LDX grid_pos_x
    TXA
    CLC
    ADC src_pointer
    STA src_pointer
    LDA src_pointer+1
    ADC #0
    STA src_pointer+1
LoadDirectionMoving:
    LDA (src_pointer)
    STA direction_moving
    RTS

UpdateGridPosition:
    ; Right-shift direction_moving until see a one
    ; Every right shift will negate velocity
    ; Two right-shifts will switch dst_pointer from x-axis to y-axis

    ; First, point to grid_pos_x
    LDA #<grid_pos_x
    STA dst_pointer
    LDA #>grid_pos_x
    STA dst_pointer+1

    ; Using vel for grid_pos update amount
    LDA #$01
    STA vel
    STZ vel+1

    ; Using displacement for src_pointer update amount
    LDA #$01
    STA displacement
    STZ displacement+1

    LDY #$00
    LDX direction_moving

UpdateGridPositionLoop:
    TXA
    AND #$01
    BNE UpdateGridPositionCommit

    TXA
    LSR
    TAX

    ; Negate vel, displacement    
    LDA #<vel
    STA negate_pointer
    LDA #>vel
    STA negate_pointer+1
    JSR NegatePointerInStack
    
    LDA #<displacement
    STA negate_pointer
    LDA #>displacement
    STA negate_pointer+1
    JSR NegatePointerInStack

    ; Check to switch dst_pointer, displacement to y-axis
    INY
    CPY #$02
    BNE UpdateGridPositionLoop

    CLC
    LDA dst_pointer
    ADC #$01
    STA dst_pointer
    LDA dst_pointer+1
    ADC #$00
    STA dst_pointer+1

    LDA #$14
    STA displacement
    STZ displacement+1
    BRA UpdateGridPositionLoop

UpdateGridPositionCommit:
    ; X,Y need to maintain grid position
    ; src_pointer has been properly updated above
    LDX grid_pos_x
    LDY grid_pos_y

    CLC
    LDA (dst_pointer)
    ADC vel
    STA (dst_pointer)
    LDA (dst_pointer)+1
    ADC vel+1
    STA (dst_pointer)+1

    CLC ; Move src_pointer based on displacement
    LDA src_pointer
    ADC displacement
    STA src_pointer
    LDA src_pointer+1
    ADC displacement+1
    STA src_pointer+1

    RTS

CheckLeftMovement:
    LDA direction_moving
    AND #$0F
    CMP #$02
    BNE CheckUpMovement

    LDA #$20
    STA direction_moving

    LDA #$FE
    STA vel
    LDA #$FF
    STA vel+1
    STZ displacement
    STZ displacement+1
    JMP DoneCheckMovement

CheckUpMovement:
    LDA direction_moving
    AND #$0F
    CMP #$08
    BNE CheckRightMovement

    LDA #$80
    STA direction_moving

    LDA #$FE
    STA displacement
    LDA #$FF
    STA displacement+1
    LDA #$00
    STA vel
    STA vel+1
    JMP DoneCheckMovement

CheckRightMovement:
    LDA direction_moving
    AND #$0F
    CMP #$01
    BNE CheckDownMovement

    LDA #$10
    STA direction_moving

    LDA #$2
    STA vel
    LDA #$00
    STA vel+1
    LDA #$00
    STA displacement
    STA displacement+1
    JMP DoneCheckMovement

CheckDownMovement:
    LDA direction_moving
    AND #$0F
    CMP #$04
    BNE DoneCheckMovement

    LDA #$40
    STA direction_moving

    LDA #$2
    STA displacement
    LDA #$00
    STA displacement+1
    LDA #$00
    STA vel
    STA vel+1
    JMP DoneCheckMovement

DoneCheckMovement:
    STZ next_update_movement
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AnimateMovement:
    STZ MMU_IO_CTRL ; Go back to I/O Page 0

AnimateSpriteX:
    ; Nudge sprite along x-direction
    CLC
    LDA sprite_x
    ADC vel
    STA sprite_x
    LDA sprite_x+1
    ADC vel+1
    STA sprite_x+1
    
    ; Nudge sprite along y-direction
    CLC
    LDA sprite_y
    ADC displacement
    STA sprite_y
    LDA sprite_y+1
    ADC displacement+1
    STA sprite_y+1

    RTS

NegatePointerInStack:
    SEC
    LDA #$00
    SBC (negate_pointer)
    STA (negate_pointer)
    LDA #$00
    SBC (negate_pointer+1)
    STA (negate_pointer+1)
    RTS
