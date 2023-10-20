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
    LDA displacement
    CLC
    ADC vel
    STA displacement
    LDA displacement+1
    ADC vel+1
    STA displacement+1
    RTS

MovementSrcPointer:
    ; Sets direction_moving_pointer to current x,y direction_moving
    ; Sets X to grid_pos_x
    ; Loads direction_moving with the value stored at that x,y in movement_map 
    LDA #<movement_map
    STA direction_moving_pointer
    LDA #>movement_map
    STA direction_moving_pointer+1
MovementMapRow:
    LDY #$00
    LDA #$20
    STA sprite_y
MovementMapRowLoop:
    CPY grid_pos_y
    BEQ MovementMapCol

    CLC ; Move direction_moving_pointer to the next row of movement_map
    LDA direction_moving_pointer
    ADC #$14 ; A row is 20 (#$14) columns long
    STA direction_moving_pointer
    LDA direction_moving_pointer+1
    ADC #0
    STA direction_moving_pointer+1

    CLC
    LDA sprite_y
    ADC #$10
    STA sprite_y
    LDA sprite_y+1
    ADC #$00
    STA sprite_y+1

    INY
    BRA MovementMapRowLoop

MovementMapCol:
    LDX #$00
    LDA #$20
    STA sprite_x
MovementMapColLoop:
    CPX grid_pos_x
    BEQ LoadDirectionMoving

    CLC ; Move direction_moving_pointer to the next row of movement_map
    LDA direction_moving_pointer
    ADC #$01 ; Move to next byte
    STA direction_moving_pointer
    LDA direction_moving_pointer+1
    ADC #0
    STA direction_moving_pointer+1

    CLC
    LDA sprite_x
    ADC #$10
    STA sprite_x
    LDA sprite_x+1
    ADC #$00
    STA sprite_x+1

    INX
    BRA MovementMapColLoop

LoadDirectionMoving:
    LDA (direction_moving_pointer)
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

    LDA #$01
    STA grid_pos_update_amount
    STZ grid_pos_update_amount+1

    LDA #$01
    STA direction_moving_update_amount
    STZ direction_moving_update_amount+1

    LDY #$00
    LDA (direction_moving_pointer)
    TAX

UpdateGridPositionLoop:
    TXA
    AND #$01
    BNE UpdateGridPositionCommit

    TXA
    LSR
    TAX

    ; Negate grid_pos_update_amount, direction_moving_update_amount    
    LDA #<grid_pos_update_amount
    STA negate_pointer
    LDA #>grid_pos_update_amount
    STA negate_pointer+1
    JSR NegatePointerInStack
    
    LDA #<direction_moving_update_amount
    STA negate_pointer
    LDA #>direction_moving_update_amount
    STA negate_pointer+1
    JSR NegatePointerInStack

    ; Check to switch dst_pointer, direction_moving_update_amount to y-axis
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
    STA direction_moving_update_amount
    STZ direction_moving_update_amount+1
    BRA UpdateGridPositionLoop

UpdateGridPositionCommit:
    ; X,Y need to maintain grid position
    ; direction_moving_pointer has been properly updated above
    LDX grid_pos_x
    LDY grid_pos_y

    CLC
    LDA (dst_pointer)
    ADC grid_pos_update_amount
    STA (dst_pointer)
    LDA (dst_pointer)+1
    ADC grid_pos_update_amount+1
    STA (dst_pointer)+1

    CLC ; Move direction_moving_pointer based on direction_moving_update_amount
    LDA direction_moving_pointer
    ADC direction_moving_update_amount
    STA direction_moving_pointer
    LDA direction_moving_pointer+1
    ADC direction_moving_update_amount+1
    STA direction_moving_pointer+1

    RTS

LoadLastCell
    PHY
    PHX
    ; Using direction_moving_update_amount for direction_moving_pointer update amount
    LDA #$FF
    STA direction_moving_update_amount
    LDA #$FF
    STA direction_moving_update_amount+1

    LDY #$00
    LDA (direction_moving_pointer)
    LSR
    LSR
    LSR
    LSR
    TAX

LoadCellLoop:
    TXA
    AND #$01
    BNE LoadCellCommit

    TXA
    LSR
    TAX

    ; Negate direction_moving_update_amount        
    LDA #<direction_moving_update_amount
    STA negate_pointer
    LDA #>direction_moving_update_amount
    STA negate_pointer+1
    JSR NegatePointerInStack

    ; Check to switch dst_pointer, direction_moving_update_amount to y-axis
    INY
    CPY #$02
    BNE LoadCellLoop

    LDA #$EC
    STA direction_moving_update_amount
    LDA #$FF
    STA direction_moving_update_amount+1

    BRA LoadCellLoop

LoadCellCommit:
    ; X,Y need to maintain grid position
    ; direction_moving_pointer has been properly updated above
    CLC ; Move direction_moving_pointer based on direction_moving_update_amount
    LDA direction_moving_pointer
    ADC direction_moving_update_amount
    STA direction_moving_pointer
    LDA direction_moving_pointer+1
    ADC direction_moving_update_amount+1
    STA direction_moving_pointer+1

    PLX
    PLY

    RTS

CheckLeftMovement:
    LDA direction_moving_pointer
    PHA
    LDA direction_moving_pointer+1
    PHA
    JSR LoadLastCell

    LDA (direction_moving_pointer)
    AND #$0F
    CMP #$02
    BNE CheckUpMovement

    ;LDA #$20
    ;STA (direction_moving_pointer)

    LDA #$FE
    STA vel
    LDA #$FF
    STA vel+1
    STZ displacement
    STZ displacement+1
    JMP DoneCheckMovement

CheckUpMovement:
    LDA (direction_moving_pointer)
    AND #$0F
    CMP #$08
    BNE CheckRightMovement

    ;LDA #$80
    ;STA (direction_moving_pointer)

    LDA #$FE
    STA displacement
    LDA #$FF
    STA displacement+1
    LDA #$00
    STA vel
    STA vel+1
    JMP DoneCheckMovement

CheckRightMovement:
    LDA (direction_moving_pointer)
    AND #$0F
    CMP #$01
    BNE CheckDownMovement

    ;LDA #$10
    ;STA (direction_moving_pointer)

    LDA #$2
    STA vel
    LDA #$00
    STA vel+1
    LDA #$00
    STA displacement
    STA displacement+1
    JMP DoneCheckMovement

CheckDownMovement:
    LDA (direction_moving_pointer)
    AND #$0F
    CMP #$04
    BNE DoneCheckMovement

    ;LDA #$40
    ;STA (direction_moving_pointer)

    LDA #$2
    STA displacement
    LDA #$00
    STA displacement+1
    LDA #$00
    STA vel
    STA vel+1
    JMP DoneCheckMovement

DoneCheckMovement:
    PLA
    STA direction_moving_pointer+1
    PLA
    STA direction_moving_pointer

    STZ next_update_movement
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AnimateMovement:
    STZ MMU_IO_CTRL ; Go back to I/O Page 0

    ; Start at first sprite
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

AnimateSpriteX
    CPX #$02
    BEQ DoneAnimateMovement
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
    LDA dst_pointer
    ADC #$08
    STA dst_pointer
    LDA dst_pointer+1
    ADC #$00
    STA dst_pointer+1

    BRA AnimateSpriteX

DoneAnimateMovement
    PLA
    STA sprite_y+1
    PLA
    STA sprite_y
    PLA
    STA sprite_x+1
    PLA
    STA sprite_x

    RTS

NegatePointerInStack:
    PHY
    LDY #$00
    SEC
    LDA #$00
    SBC (negate_pointer),y
    STA (negate_pointer),y
    INY
    LDA #$00
    SBC (negate_pointer),y
    STA (negate_pointer),y
    PLY
    RTS
