.section data
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
buffer_before_map:
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
movement_map:
    .byte $81, $11, $11, $11, $11, $11, $11, $11, $11, $14, $11, $11, $11, $11, $11, $11, $11, $11, $11, $14
    .byte $88, $00, $44, $00, $00, $00, $00, $00, $44, $44, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44
    .byte $88, $00, $41, $11, $14, $00, $00, $00, $44, $44, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44
    .byte $88, $00, $00, $00, $44, $00, $00, $00, $44, $44, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44
    .byte $88, $22, $22, $22, $42, $00, $00, $00, $44, $44, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44
    .byte $88, $00, $00, $00, $00, $00, $00, $00, $44, $44, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44
    .byte $88, $00, $00, $00, $00, $00, $00, $00, $44, $44, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44
    .byte $88, $00, $00, $00, $00, $00, $00, $00, $41, $41, $11, $11, $11, $11, $11, $11, $11, $11, $11, $14
    .byte $28, $22, $22, $22, $22, $22, $22, $22, $82, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $44
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $81, $11, $44
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $88, $00, $44
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $28, $22, $22, $22, $22, $22, $22, $22, $22, $22, $22, $42
buffer_after_map:
    .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
.send

.section dp
negate_pointer .word ?
movement_map_pointer .word ?
.send

sprite_pointer = src_pointer

UpdateMovement:
    ; Though the game is animating the movement to each tile
    ; direction of movement can only update at overlap of tile
    ; This routine controls that logic

    ; Get movement direction from movement map
    ; This loads various information where we need it regardless of branch taken below
    JSR MovementSrcPointer

    ; Check if time to update grid position
    JSR IncrementMovement
    LDA displacement+1
    CMP #$10
    BGE NextGridPosition
    RTS

NextGridPosition
    JSR UpdateGridPosition
    SEC
    LDA displacement+1
    SBC #$10
    STA displacement+1
    RTS

IncrementMovement:
    ; TODO: Displacement is all I need to know
    ; If above #$0F, then we've gone to next grid
    ; This also handles the non-power-of-two problem
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
    LDA movement_map_pointer
    STA direction_moving_pointer
    LDA movement_map_pointer+1
    STA direction_moving_pointer+1
MovementMapRow:
    LDY #$00
    LDA #$20
    STA sprite_y
    STZ sprite_y+1
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
    STZ sprite_x+1
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

    ; Second, point to sprite_x
    LDA #<sprite_x
    STA sprite_pointer
    LDA #>sprite_x
    STA sprite_pointer+1

    LDA #$10
    STA sprite_update_amount
    STZ sprite_update_amount+1

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

    ; Negate grid_pos_update_amount, sprite_update_amount, direction_moving_update_amount    
    LDA #<grid_pos_update_amount
    STA negate_pointer
    LDA #>grid_pos_update_amount
    STA negate_pointer+1
    JSR NegatePointerInStack

    LDA #<sprite_update_amount
    STA negate_pointer
    LDA #>sprite_update_amount
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
    
    CLC
    LDA src_pointer
    ADC #$02
    STA src_pointer
    LDA src_pointer+1
    ADC #$00
    STA src_pointer+1

    LDA #$14
    STA direction_moving_update_amount
    STZ direction_moving_update_amount+1
    BRA UpdateGridPositionLoop

UpdateGridPositionCommit:
    CLC
    LDA (dst_pointer)
    ADC grid_pos_update_amount
    STA (dst_pointer)

    PHY
    LDY #$00
    CLC
    LDA (src_pointer),y
    ADC sprite_update_amount
    STA (src_pointer),y
    INY
    LDA (src_pointer),y
    ADC sprite_update_amount+1
    STA (src_pointer),y
    PLY

    LDA (direction_moving_pointer)
    PHA

    CLC ; Move direction_moving_pointer based on direction_moving_update_amount
    LDA direction_moving_pointer
    ADC direction_moving_update_amount
    STA direction_moving_pointer
    LDA direction_moving_pointer+1
    ADC direction_moving_update_amount+1
    STA direction_moving_pointer+1

    ; This code updates the next coordinate in movement map to keep moving in the current direction
    ; This prevents a previous movement on this space from changing direction without player involvement
    LDA playback_mode
    BNE _maintain_stack
    LDA #$00
    STA (direction_moving_pointer)
    PLA
    AND #$0F
    STA (direction_moving_pointer)
    ASL
    ASL
    ASL
    ASL
    CLC
    ORA (direction_moving_pointer)
    STA (direction_moving_pointer)
    BRA _maintain_grid

_maintain_stack
    PLA

_maintain_grid
    ; X,Y need to maintain grid position
    ; direction_moving_pointer has been properly updated above
    LDX grid_pos_x
    LDY grid_pos_y

    RTS

LoadLastCell
    PHY
    PHX

    LDA dst_pointer
    PHA
    LDA dst_pointer+1
    PHA

    ; Point to grid_pos_x
    LDA #<grid_pos_x
    STA dst_pointer
    LDA #>grid_pos_x
    STA dst_pointer+1

    LDA #$FF
    STA grid_pos_update_amount
    STZ grid_pos_update_amount+1

    ; Point to sprite_x
    LDA #<sprite_x
    STA src_pointer
    LDA #>sprite_x
    STA src_pointer+1

    LDA #$F0
    STA sprite_update_amount
    LDA #$FF
    STA sprite_update_amount+1

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

    ; Negate grid_pos_update_amount  
    LDA #<grid_pos_update_amount
    STA negate_pointer
    LDA #>grid_pos_update_amount
    STA negate_pointer+1
    JSR NegatePointerInStack
  
    ; Negate direction_moving_update_amount  
    LDA #<sprite_update_amount
    STA negate_pointer
    LDA #>sprite_update_amount
    STA negate_pointer+1
    JSR NegatePointerInStack

    ; Negate direction_moving_update_amount        
    LDA #<direction_moving_update_amount
    STA negate_pointer
    LDA #>direction_moving_update_amount
    STA negate_pointer+1
    JSR NegatePointerInStack

    ; Check to switch src_pointer, direction_moving_update_amount to y-axis
    INY
    CPY #$02
    BNE LoadCellLoop

    CLC
    LDA dst_pointer
    ADC #$01
    STA dst_pointer
    LDA dst_pointer+1
    ADC #$00
    STA dst_pointer+1

    CLC
    LDA src_pointer
    ADC #$02
    STA src_pointer
    LDA src_pointer+1
    ADC #$00
    STA src_pointer+1

    LDA #$EC
    STA direction_moving_update_amount
    LDA #$FF
    STA direction_moving_update_amount+1

    BRA LoadCellLoop

LoadCellCommit:
    CLC
    LDA (dst_pointer)
    ADC grid_pos_update_amount
    STA (dst_pointer)

    LDY #$00
    CLC
    LDA (src_pointer),y
    ADC sprite_update_amount
    STA (src_pointer),y
    INY
    LDA (src_pointer),y
    ADC sprite_update_amount+1
    STA (src_pointer),y

    CLC ; Move direction_moving_pointer based on direction_moving_update_amount
    LDA direction_moving_pointer
    ADC direction_moving_update_amount
    STA direction_moving_pointer
    LDA direction_moving_pointer+1
    ADC direction_moving_update_amount+1
    STA direction_moving_pointer+1

    PLA
    STA dst_pointer+1
    PLA
    STA dst_pointer

    PLX
    PLY

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.section data
displacement_clut .byte ?
.send

FirstSrcColor
    LDA #<snake_clut
    STA src_pointer
    LDA #>snake_clut
    STA src_pointer+1
    JSR NextSrcColor
    RTS
FirstDstColor
    LDA #<VKY_GR_CLUT_1 ; Set the destination to Graphics CLUT
    STA dst_pointer
    LDA #>VKY_GR_CLUT_1
    STA dst_pointer+1
    JSR NextDstColor
    RTS

NextSrcColor
	CLC                         ; Advance src_pointer to the next source color entry
	LDA src_pointer
	ADC #4
	STA src_pointer
	LDA src_pointer+1
	ADC #0
	STA src_pointer+1
    RTS

NextDstColor
	CLC                         ; Advance src_pointer to the next source color entry
	LDA dst_pointer
	ADC #4
	STA dst_pointer
	LDA dst_pointer+1
	ADC #0
	STA dst_pointer+1
    RTS

AnimateSnakeTiles:
    ; Load tile map colors into CLUT
    LDA #$01 ; Switch to I/O Page #1
    STA MMU_IO_CTRL
    JSR FirstSrcColor
    JSR FirstDstColor

_displacement_rotate:
    PHX
    LDX #0
_displacement_loop:
    CPX displacement+1
    BEQ _displacement_done
    JSR NextDstColor
    INX
    BRA _displacement_loop
_displacement_done:
    PLX
    
    SEC
    LDA #16
    SBC displacement+1
    STA displacement_clut
    JSR _tile_color_assign

    JSR FirstDstColor
    LDA displacement+1
    STA displacement_clut
_tile_color_assign
    PHX
    PHY
    LDX #0                      ; X is a counter for the number of colors copied
_tile_color_loop: 
	LDY #0                      ; Y is a pointer to the component within a CLUT color
_comp_loop:  
	CPX displacement_clut
	BEQ _tile_done_lut

	LDA (src_pointer),y             ; Read a byte from the code
	STA (dst_pointer),y             ; And write it to the CLUT
	INY                         ; Move to the next byte
	cpy #4
	bne _comp_loop               ; Continue until we have copied 4 bytes

	INX                         ; Move to the next color

    JSR NextSrcColor
    JSR NextDstColor
	BRA _tile_color_loop              ; And start copying that new color

_tile_done_lut:
    PLY
    PLX
	RTS

AnimateMovement:
    JSR AnimateSnakeTiles
    STZ MMU_IO_CTRL ; Go back to I/O Page 0

    ; Start at first sprite
    LDA #$00
    STA dst_pointer
    LDA #$D9
    STA dst_pointer+1

    LDA direction_moving_pointer
    PHA
    LDA direction_moving_pointer+1
    PHA

    LDA sprite_x
    PHA
    LDA sprite_x+1
    PHA
    LDA sprite_y
    PHA
    LDA sprite_y+1
    PHA

    LDA grid_pos_x
    PHA
    LDA grid_pos_y
    PHA

    PHX
    PHY

    LDX #$00

AnimateSpriteX
    CPX snake_length
    BEQ DoneAnimateMovement
    JSR LoadLastCell
    JSR AppleCollisionCheck
    INX

    ; Right here is the best time to see if the head of our snake
    ; is going to collide with the current part of the snake
    ; grid_pos_x and grid_pos_y are the current loop position
    ; The next two items on the stack is the head's Y position, then X position respectively
    ; We currently don't care about the accumulator value or the Y value, so again perfect timing

    ; Put head grid Y position from stack into Y
    PLY

    ; Put head grid X position from stack into accumulator
    PLA

    ; Push current X onto stack
    PHX

    ; Put grid X position of head into X (we need accumulator for comparison checks)
    TAX

    CPX grid_pos_x
    BNE ContinueRenderingSprite

    CPY grid_pos_y
    BNE ContinueRenderingSprite

    ; If we've gotten this far, the head of the snake has the current ball, save information
    LDA #$01
    STA is_dead

ContinueRenderingSprite:
    ; Put grid X position back into accumulator
    TXA

    ; Set X back to current sprite being rendered
    PLX

    ; Put values back onto stack
    PHA
    PHY

    JSR AddDisplacement

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
    BNE LoadSpriteY

    INY
    LDA #$FF
    STA (dst_pointer),y
    JMP NextSprite

LoadSpriteY:
    INY
    LDA sprite_y
    STA (dst_pointer),y

    INY
    LDA sprite_y+1
    STA (dst_pointer),y

NextSprite:
    CLC
    LDA dst_pointer
    ADC #$08
    STA dst_pointer
    LDA dst_pointer+1
    ADC #$00
    STA dst_pointer+1

    JSR SubtractDisplacement

    BRA AnimateSpriteX

DoneAnimateMovement
    PLY
    PLX

    PLA
    STA grid_pos_y
    PLA
    STA grid_pos_x

    PLA
    STA sprite_y+1
    PLA
    STA sprite_y
    PLA
    STA sprite_x+1
    PLA
    STA sprite_x

    PLA
    STA direction_moving_pointer+1
    PLA
    STA direction_moving_pointer

    RTS

LoadDisplacement
    LDA displacement+1
    STA sprite_update_amount
    STZ sprite_update_amount+1
    RTS
AddDisplacement
    JSR LoadDisplacement
    JMP DisplacementStart
SubtractDisplacement
    JSR LoadDisplacement
    LDA #<sprite_update_amount
    STA negate_pointer
    LDA #>sprite_update_amount
    STA negate_pointer+1
    JSR NegatePointerInStack
DisplacementStart:
    ; Right-shift direction_moving until see a one
    ; Every right shift will negate velocity
    ; Two right-shifts will switch dst_pointer from x-axis to y-axis
    PHX
    PHY

    ; First, point to sprite_x
    LDA #<sprite_x
    STA src_pointer
    LDA #>sprite_x
    STA src_pointer+1

    LDY #$00
    LDA (direction_moving_pointer)
    TAX

DisplacementLoop:
    TXA
    AND #$01
    BNE DisplacementCommit

    TXA
    LSR
    TAX

    ; Negate sprite_update_amount    
    LDA #<sprite_update_amount
    STA negate_pointer
    LDA #>sprite_update_amount
    STA negate_pointer+1
    JSR NegatePointerInStack
    
    ; Check to switch dst_pointer, direction_moving_update_amount to y-axis
    INY
    CPY #$02
    BNE DisplacementLoop
    
    CLC
    LDA src_pointer
    ADC #$02
    STA src_pointer
    LDA src_pointer+1
    ADC #$00
    STA src_pointer+1

    BRA DisplacementLoop

DisplacementCommit:
    LDY #$00
    CLC
    LDA (src_pointer),y
    ADC sprite_update_amount
    STA (src_pointer),y
    INY
    LDA (src_pointer),y
    ADC sprite_update_amount+1
    STA (src_pointer),y

    PLY
    PLX

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
