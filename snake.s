.cpu "65816"                        ; Tell 64TASS that we are using a 65816

.include "includes/TinyVicky_Def.asm"
.include "includes/interrupt_def.asm"
.include "includes/f256jr_registers.asm"
.include "includes/f256k_registers.asm"
.include "includes/f256_tiles.asm"
.include "includes/macros.s"

dst_pointer = $30
src_pointer = $32
sprite_x = $34
sprite_y = $36
text_memory_pointer = $38
frame_counter = $3A

vel_y = $3B
vel_x = $3D

; Button up/down tracking
left_press = $3F
right_press = $40
up_press = $41
down_press = $42

; Code
* = $000000 
        .byte 0

* = $4000
.logical $4000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

F256_RESET
    CLC     ; disable interrupts
    SEI
    LDX #$FF
    TXS     ; initialize stack

    ;
    ; Set up TinyVicky to display tiles
    ;
    LDA #$14                    ; Graphics and Tile engines enabled
    STA VKY_MSTR_CTRL_0
    STZ VKY_MSTR_CTRL_1         ; 320x240 @ 60Hz

	LDA #$40                    ; Layer 0 = Bitmap 0, Layer 1 = Tile map 0
    STA VKY_LAYER_CTRL_0
    LDA #$15                    ; Layer 2 = Tile Map 1
    STA VKY_LAYER_CTRL_1


    ; initialize mmu
    STZ MMU_MEM_CTRL
    LDA MMU_MEM_CTRL
    ORA #MMU_EDIT_EN

    ; enable mmu edit, edit mmu lut 0, activate mmu lut 0
    STA MMU_MEM_CTRL
    STZ MMU_IO_CTRL

    LDA #$00
    STA MMU_MEM_BANK_0 ; map $000000 to bank 0
    INA
    STA MMU_MEM_BANK_1 ; map $002000 to bank 1
    INA
    STA MMU_MEM_BANK_2 ; map $004000 to bank 2
    INA
    STA MMU_MEM_BANK_3 ; map $006000 to bank 3
    INA
    STA MMU_MEM_BANK_4 ; map $008000 to bank 4
    INA
    STA MMU_MEM_BANK_5 ; map $00a000 to bank 5
    INA
    STA MMU_MEM_BANK_6 ; map $00c000 to bank 6
    INA
    STA MMU_MEM_BANK_7 ; map $00e000 to bank 7
    LDA MMU_MEM_CTRL
    AND #~(MMU_EDIT_EN)
    STA MMU_MEM_CTRL  ; disable mmu edit, use mmu lut 0

                        ; initialize interrupts
    LDA #$FF            ; mask off all interrupts
    STA INT_EDGE_REG0
    STA INT_EDGE_REG1
    STA INT_MASK_REG0
    STA INT_MASK_REG1

    LDA INT_PENDING_REG0 ; clear all existing interrupts
    STA INT_PENDING_REG0
    LDA INT_PENDING_REG1
    STA INT_PENDING_REG1

    CLI ; Enable interrupts
    JMP MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAIN
    LDA #MMU_EDIT_EN
    STA MMU_MEM_CTRL
    STZ MMU_IO_CTRL 
    STZ MMU_MEM_CTRL    
    LDA #$34 ;(Mstr_Ctrl_Text_Mode_En|Mstr_Ctrl_Text_Overlay|Mstr_Ctrl_Graph_Mode_En|Mstr_Ctrl_Bitmap_En|Mstr_Ctrl_Sprite_En|Mstr_Ctrl_TileMap_En)
    STA @w MASTER_CTRL_REG_L 
    LDA #(Mstr_Ctrl_Text_XDouble|Mstr_Ctrl_Text_YDouble)
    STA @w MASTER_CTRL_REG_H

    ; Initialize matrix keyboard
    LDA #$FF
    STA VIA1_DDRA
    LDA #$00
    STA VIA1_DDRB

    STZ VIA1_PRB
    STZ VIA1_PRA
    
    LDA #$7F
    STA VIA0_DDRA
    STA VIA0_PRA
    STZ VIA0_PRB

    ; Disable the cursor
    LDA VKY_TXT_CURSOR_CTRL_REG
    AND #$FE
    STA VKY_TXT_CURSOR_CTRL_REG
    
    JSR ClearScreen

    ; Background: midnight blue
    LDA #$19
    STA VKY_BKG_COL_R
    LDA #$19
    STA VKY_BKG_COL_G
    LDA #$70
    STA VKY_BKG_COL_B

    ; Turn off the border
    STZ VKY_BRDR_CTRL

    ;STZ TyVKY_BM0_CTRL_REG ; Make sure bitmap 0 is turned off
    ;STZ TyVKY_BM1_CTRL_REG ; Make sure bitmap 1 is turned off
    ;STZ TyVKY_BM2_CTRL_REG ; Make sure bitmap 2 is turned off
    
    JSR Init_IRQHandler

    ; Load sprite colors into CLUT
    LDA #$01 ; Switch to I/O Page #1
    STA MMU_IO_CTRL

    LDA #<balls_clut_start ; Set the source pointer to the palette
    STA src_pointer
    LDA #>balls_clut_start
    STA src_pointer+1

    LDA #<VKY_GR_CLUT_0 ; Set the destination to Graphics CLUT
    STA dst_pointer
    LDA #>VKY_GR_CLUT_0
    STA dst_pointer+1

	JSR color_start
	JSR setup_sprite

    ; Load tile map colors into CLUT
    LDA #$01 ; Switch to I/O Page #1
    STA MMU_IO_CTRL

    LDA #<tiles_clut_start ; Set the source pointer to the palette
    STA src_pointer
    LDA #>tiles_clut_start
    STA src_pointer+1

    LDA #<VKY_GR_CLUT_1 ; Set the destination to Graphics CLUT
    STA dst_pointer
    LDA #>VKY_GR_CLUT_1
    STA dst_pointer+1

	LDX #0                      ; X is a counter for the number of colors copied

	JSR tile_color_loop
	JSR setup_tile_map
    
    ; Switch to I/O page 0
    STZ MMU_IO_CTRL

    STZ frame_counter

    STZ vel_y
    STZ vel_y+1
    LDA #$03
    STA vel_x
    STZ vel_x+1

    STZ up_press
    STZ left_press
    STZ right_press
    STZ down_press
	JMP Lock

color_start:
	LDX #0
color_loop: 
    LDY #0 ; Y points to the color component

    LDA (src_pointer),y ; Read a byte from the code
    STA (dst_pointer),y ; And write it to the CLUT
    INY ; Move to the next byte
    LDA (src_pointer),y
    STA (dst_pointer),y 
    INY 
    LDA (src_pointer),y
    STA (dst_pointer),y 
    INY 
    INY 

    INX ; Move to the next color
    CPX #16
    BEQ done_lut ; Until we have copied all 16

    CLC ; Move src_pointer to the next source color
    LDA src_pointer
    ADC #4
    STA src_pointer
    LDA src_pointer+1
    ADC #0
    STA src_pointer+1

    CLC ; Move dst_pointer to the next destination
    LDA dst_pointer
    ADC #4
    STA dst_pointer
    LDA dst_pointer+1
    ADC #0
    STA dst_pointer+1
    BRA color_loop ; And start copying that new color
done_lut:
	RTS

setup_sprite: 
    STZ MMU_IO_CTRL ; Go back to I/O Page 0
    
    ; Point sprite 0 to the pixel data, set its location in screen, and enable the sprite
    init_sp0: 
    LDA #<balls_img_start ; Address = balls_img_start
    STA SP0_Addy_L
    LDA #>balls_img_start
    STA SP0_Addy_M
    STZ SP0_Addy_H

    LDA #32
    STA sprite_x
    STZ sprite_x+1
    LDA #32
    STA sprite_y
    STZ sprite_y+1

    ; Set sprite positioning
    LDA sprite_x
    STA SP0_X_L 
    LDA sprite_x+1
    STA SP0_X_H ; upper-left corner of the screen
    LDA sprite_y
    STA SP0_Y_L
    LDA sprite_y+1
    STA SP0_Y_H

    LDA #$41 ; Size=16x16, Layer=0, LUT=0, Enabled
    STA SP0_Ctrl
    
    JSR Init_IRQHandler

    LDA #$02 ; Set I/O page to 2
    STA MMU_IO_CTRL
    
    ; Put text at the top left of the screen
    LDA #<VKY_TEXT_MEMORY
    STA text_memory_pointer
    LDA #>VKY_TEXT_MEMORY
    STA text_memory_pointer+1

    LDA #<TX_PROMPT
    STA src_pointer

    LDA #>TX_PROMPT
    STA src_pointer+1
    
    JSR PrintAnsiString
	RTS

tile_color_loop: 
	LDY #0                      ; Y is a pointer to the component within a CLUT color
comp_loop:  
	LDA (src_pointer),y             ; Read a byte from the code
	STA (dst_pointer),y             ; And write it to the CLUT
	INY                         ; Move to the next byte
	cpy #4
	bne comp_loop               ; Continue until we have copied 4 bytes

	INX                         ; Move to the next color
	CMP #20
	BEQ tile_done_lut                ; Until we have copied all 20

	CLC                         ; Advance src_pointer to the next source color entry
	LDA src_pointer
	ADC #4
	STA src_pointer
	LDA src_pointer+1
	ADC #0
	STA src_pointer+1

	CLC                         ; Advance dst_pointer to the next destination color entry
	LDA dst_pointer
	ADC #4
	STA dst_pointer
	LDA dst_pointer+1
	ADC #0
	STA dst_pointer+1

	BRA tile_color_loop              ; And start copying that new color

tile_done_lut:
	RTS

setup_tile_map:
    STZ MMU_IO_CTRL             ; Go back to I/O Page 0

    ;
    ; Set tile set #0 to our image
    ;

    LDA #<tiles_img_start
    STA VKY_TS0_ADDR_L
    LDA #>tiles_img_start
    STA VKY_TS0_ADDR_M
    LDA #`tiles_img_start
    STA VKY_TS0_ADDR_H

    ;
    ; Set tile map #0
    ;

    LDA #$01                    ; 16x16 tiles, enable
    STA VKY_TM0_CTRL

    STZ VKY_TM1_CTRL            ; Make sure the other tile maps are off
    STZ VKY_TM2_CTRL

    LDA #22                     ; Our tile map is 20x15
    STA VKY_TM0_SIZE_X
    LDA #16
    STA VKY_TM0_SIZE_Y

    LDA #<tile_map              ; Point to the tile map
    STA VKY_TM0_ADDR_L
    LDA #>tile_map
    STA VKY_TM0_ADDR_M
    LDA #`tile_map
    STA VKY_TM0_ADDR_H

    LDA #$10                    ; Set scrolling X = 16
    STA VKY_TM0_POS_X_L
    LDA #$00
    STA VKY_TM0_POS_X_H

    STZ VKY_TM0_POS_Y_L         ; Set scrolling Y = 0
    STZ VKY_TM0_POS_Y_H

	RTS

Lock
    JSR Poll
    LDA frame_counter
    BNE Lock

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

    ; Check for bounce off the bottom
    LDA sprite_y
    CMP #$00FE
    BMI DoneBottomCheck
    LDA #$FFFC
    STA vel_y
DoneBottomCheck

    ; Check for bounce off the right
    LDA sprite_x
    CMP #$014F
    BMI DoneRightCheck
    LDA #$FFFC
    STA vel_x
DoneRightCheck

    ; Check for bounce off the top
    LDA sprite_y
    CMP #$0020
    BPL DoneTopCheck
    LDA #$3
    STA vel_y
DoneTopCheck

    ; Check for bounce off the left
    LDA sprite_x
    CMP #$0020
    BPL DoneLeftCheck
    LDA #$3
    STA vel_x
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
    JMP Lock

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Poll
    LDA #$00 ; Need to be on I/O page 0
    STA MMU_IO_CTRL
    ; TODO: Need to only update once per movement cycle

CheckLeftArrow
    ; LeftArrow is PA0, PB2
    LDA #(1 << 0 ^ $FF)
    STA VIA1_PRA
    LDA VIA1_PRB
    CMP #(1 << 2 ^ $FF)
    BEQ CheckLeftPressed
    ; left_press wasn't pressed down, save that info if we last saw it on
    STZ left_press
    JMP CheckUpArrow

CheckLeftPressed
    ; If left_press wasn't zero, then we already marked it down before
    LDA left_press
    CMP #$00
    BNE CheckUpArrow
    
    LDA vel_x
    CMP #$00
    BNE CheckUpArrow
    
    LDA vel_x+1
    CMP #$00
    BNE CheckUpArrow
    
    LDA #$01
    STA left_press

    LDA #$FC
    STA vel_x
    LDA #$FF
    STA vel_x+1
    LDA #$00
    STA vel_y
    STA vel_y+1
    JMP DoneCheckInput

CheckUpArrow
    ; UpArrow is PA0, PB7
    LDA #(1 << 0 ^ $FF)
    STA VIA1_PRA
    LDA VIA1_PRB
    CMP #(1 << 7 ^ $FF)
    BEQ CheckUpPressed
    ; up_press wasn't pressed down, save that info if we last saw it on
    STZ up_press
    JMP CheckRightArrow
CheckUpPressed
    ; If up_press wasn't zero, then we already marked it down before
    LDA up_press
    CMP #$00
    BNE CheckRightArrow
    
    LDA vel_y
    CMP #$00
    BNE CheckRightArrow
    
    LDA vel_y+1
    CMP #$00
    BNE CheckRightArrow
    
    LDA #$01
    STA up_press

    LDA #$FC
    STA vel_y
    LDA #$FF
    STA vel_y+1
    LDA #$00
    STA vel_x
    STA vel_x+1
    JMP DoneCheckInput

CheckRightArrow
    ; RightArrow is on its own setup, as is DownArrow
    LDA #(1 << 6 ^ $FF)
    STA VIA1_PRA
    LDA VIA0_PRB
    CMP #(1 << 7 ^ $FF)
    BEQ CheckRightPressed
    ; up_press wasn't pressed down, save that info if we last saw it on
    STZ right_press
    JMP CheckDownArrow

CheckRightPressed
    ; If right_press wasn't zero, then we already marked it down before
    LDA right_press
    CMP #$00
    BNE CheckDownArrow
    
    LDA vel_x
    CMP #$00
    BNE CheckDownArrow
    
    LDA vel_x+1
    CMP #$00
    BNE CheckDownArrow
    
    LDA #$01
    STA right_press

    LDA #$3
    STA vel_x
    LDA #$00
    STA vel_x+1
    LDA #$00
    STA vel_y
    STA vel_y+1
    JMP DoneCheckInput

CheckDownArrow
    ; DownArrow is on its own setup, as is RightArrow
    LDA #(1 << 0 ^ $FF)
    STA VIA1_PRA
    LDA VIA0_PRB
    CMP #(1 << 7 ^ $FF)
    BEQ CheckDownPressed
    ; down_press wasn't pressed down, save that info if we last saw it on
    STZ down_press
    JMP DoneCheckInput

CheckDownPressed
    ; If down_press wasn't zero, then we already marked it down before
    LDA down_press
    CMP #$00
    BNE DoneCheckInput
    
    LDA vel_y
    CMP #$00
    BNE DoneCheckInput
    
    LDA vel_y+1
    CMP #$00
    BNE DoneCheckInput
    
    LDA #$01
    STA down_press

    LDA #$3
    STA vel_y
    LDA #$00
    STA vel_y+1
    LDA #$00
    STA vel_x
    STA vel_x+1
    JMP DoneCheckInput

DoneCheckInput
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init_IRQHandler
    ; Back up I/O state
    LDA MMU_IO_CTRL
    PHA        

    ; Disable IRQ handling
    SEI

    ; Load our interrupt handler. Should probably back up the old one oh well
    LDA #<IRQ_Handler
    STA $FFFE ; VECTOR_IRQ
    LDA #>IRQ_Handler
    STA $FFFF ; (VECTOR_IRQ)+1

    ; Mask off all but start-of-frame
    LDA #$FF
    STA INT_MASK_REG1
    AND #~(JR0_INT00_SOF)
    STA INT_MASK_REG0

    ; Re-enable interrupt handling    
    CLI
    PLA ; Restore I/O state
    STA MMU_IO_CTRL 
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IRQ_Handler
    PHP
    PHA
    PHX
    PHY
    
    ; Save the I/O page
    LDA MMU_IO_CTRL
    PHA
    
    ; Switch to I/O page 0
    STZ MMU_IO_CTRL

    ; Check for start-of-frame flag
    LDA #JR0_INT00_SOF
    BIT INT_PENDING_REG0
    BEQ IRQ_Handler_Done
    
    ; Clear the flag for start-of-frame
    STA INT_PENDING_REG0    

    LDA frame_counter
    BEQ AfterDecFrameCounter
    DEC frame_counter

AfterDecFrameCounter    

IRQ_Handler_Done
    ; Restore the I/O page
    PLA
    STA MMU_IO_CTRL
    
    PLY
    PLX
    PLA
    PLP
    RTI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearScreen
    LDA MMU_IO_CTRL ; Back up I/O page
    PHA
    
    LDA #$02 ; Set I/O page to 2
    STA MMU_IO_CTRL
    
    STZ dst_pointer
    LDA #$C0
    STA dst_pointer+1

ClearScreen_ForEach
    LDA #32 ; Character 0
    STA (dst_pointer)
        
    CLC
    LDA dst_pointer
    ADC #$01
    STA dst_pointer
    LDA dst_pointer+1
    ADC #$00 ; Add carry
    STA dst_pointer+1

    CMP #$C5
    BNE ClearScreen_ForEach
    
    PLA
    STA MMU_IO_CTRL ; Restore I/O page
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Pre-condition: 
;     text_memory_pointer is set as desired dest address
;     src_pointer is set as source address
PrintAnsiString
    LDX #$00
    LDY #$00
    
    LDA MMU_IO_CTRL ; Back up I/O page
    PHA
    
    LDA #$02 ; Set I/O page to 2
    STA MMU_IO_CTRL

PrintAnsiString_EachCharToTextMemory
    LDA (src_pointer),y                          ; Load the character to print
    BEQ PrintAnsiString_DoneStoringToTextMemory  ; Exit if null term        
    STA (text_memory_pointer),Y                  ; Store character to text memory
    INY
    BRA PrintAnsiString_EachCharToTextMemory

PrintAnsiString_DoneStoringToTextMemory

    LDA #$03 ; Set I/O page to 3
    STA MMU_IO_CTRL

    LDA #$F0 ; Text color

PrintAnsiString_EachCharToColorMemory
    DEY
    STA (text_memory_pointer),Y
    BNE PrintAnsiString_EachCharToColorMemory

    PLA
    STA MMU_IO_CTRL ; Restore I/O page

    RTS    
     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TX_PROMPT
.text "Testing SOF updates"
.byte 0 ; null term

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

balls_clut_start:
.byte $00, $00, $00, $00
.byte $00, $88, $00, $00
.byte $18, $7C, $00, $00
.byte $20, $9C, $1C, $00
.byte $38, $90, $1C, $00
.byte $40, $B0, $38, $00
.byte $54, $A8, $38, $00
.byte $5C, $C0, $50, $00
.byte $70, $BC, $50, $00
.byte $74, $D0, $68, $00
.byte $88, $CC, $68, $00
.byte $8C, $E0, $7C, $00
.byte $9C, $DC, $7C, $00
.byte $A4, $EC, $90, $00
.byte $B4, $EC, $90, $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

balls_img_start:
.byte $0, $0, $0, $0, $0, $0, $3, $2, $2, $1, $0, $0, $0, $0, $0, $0
.byte $0, $0, $0, $0, $5, $5, $4, $3, $3, $3, $3, $2, $0, $0, $0, $0
.byte $0, $0, $0, $7, $7, $7, $6, $5, $4, $4, $3, $3, $1, $0, $0, $0
.byte $0, $0, $7, $9, $A, $B, $A, $8, $6, $5, $4, $3, $2, $1, $0, $0
.byte $0, $5, $7, $A, $D, $E, $D, $A, $7, $5, $5, $4, $3, $1, $1, $0
.byte $0, $5, $7, $B, $E, $E, $E, $C, $7, $5, $5, $4, $3, $1, $1, $0
.byte $3, $4, $6, $A, $D, $E, $D, $A, $7, $5, $5, $4, $3, $2, $1, $1
.byte $2, $3, $5, $8, $A, $C, $A, $8, $6, $5, $5, $4, $3, $2, $1, $1
.byte $2, $3, $4, $6, $7, $7, $7, $6, $5, $5, $5, $4, $3, $1, $1, $1
.byte $1, $3, $4, $5, $5, $5, $5, $5, $5, $5, $5, $3, $3, $1, $1, $1
.byte $0, $3, $3, $4, $5, $5, $5, $5, $5, $5, $4, $3, $2, $1, $1, $0
.byte $0, $2, $3, $3, $4, $4, $4, $4, $4, $3, $3, $2, $1, $1, $1, $0
.byte $0, $0, $1, $2, $3, $3, $3, $3, $3, $3, $2, $1, $1, $1, $0, $0
.byte $0, $0, $0, $1, $1, $1, $2, $2, $1, $1, $1, $1, $1, $0, $0, $0
.byte $0, $0, $0, $0, $1, $1, $1, $1, $1, $1, $1, $1, $0, $0, $0, $0
.byte $0, $0, $0, $0, $0, $0, $1, $1, $1, $1, $0, $0, $0, $0, $0, $0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tiles_clut_start:
	.byte $00, $00, $00, $00
	.byte $00, $44, $44, $00
	.byte $00, $28, $70, $00
	.byte $00, $18, $84, $00
	.byte $00, $00, $88, $00
	.byte $5C, $00, $78, $00
	.byte $78, $00, $48, $00
	.byte $84, $00, $14, $00
	.byte $88, $00, $00, $00
	.byte $7C, $18, $00, $00
	.byte $5C, $2C, $00, $00
	.byte $2C, $40, $00, $00
	.byte $00, $3C, $00, $00
	.byte $00, $38, $14, $00
	.byte $00, $30, $2C, $00
	.byte $00, $28, $44, $00
	.byte $40, $40, $40, $00
	.byte $10, $64, $64, $00
	.byte $14, $44, $84, $00
	.byte $18, $34, $98, $00
	.byte $20, $20, $9C, $00
	.byte $74, $20, $8C, $00
	.byte $90, $20, $60, $00
	.byte $98, $20, $30, $00
	.byte $9C, $20, $1C, $00
	.byte $90, $38, $1C, $00
	.byte $78, $4C, $1C, $00
	.byte $48, $5C, $1C, $00
	.byte $20, $5C, $20, $00
	.byte $1C, $5C, $34, $00
	.byte $1C, $50, $4C, $00
	.byte $18, $48, $64, $00
	.byte $6C, $6C, $6C, $00
	.byte $24, $84, $84, $00
	.byte $28, $5C, $98, $00
	.byte $30, $50, $AC, $00
	.byte $3C, $3C, $B0, $00
	.byte $88, $3C, $A0, $00
	.byte $A4, $3C, $78, $00
	.byte $AC, $3C, $4C, $00
	.byte $B0, $40, $38, $00
	.byte $A8, $54, $38, $00
	.byte $90, $68, $38, $00
	.byte $64, $7C, $38, $00
	.byte $40, $7C, $40, $00
	.byte $38, $7C, $50, $00
	.byte $34, $70, $68, $00
	.byte $30, $68, $84, $00
	.byte $90, $90, $90, $00
	.byte $34, $A0, $A0, $00
	.byte $3C, $78, $AC, $00
	.byte $48, $68, $C0, $00
	.byte $58, $58, $C0, $00
	.byte $9C, $58, $B0, $00
	.byte $B8, $58, $8C, $00
	.byte $C0, $58, $68, $00
	.byte $C0, $5C, $50, $00
	.byte $BC, $70, $50, $00
	.byte $AC, $84, $50, $00
	.byte $80, $9C, $50, $00
	.byte $5C, $9C, $5C, $00
	.byte $50, $98, $6C, $00
	.byte $4C, $8C, $84, $00
	.byte $44, $84, $A0, $00
	.byte $B0, $B0, $B0, $00
	.byte $40, $B8, $B8, $00
	.byte $4C, $8C, $BC, $00
	.byte $5C, $80, $D0, $00
	.byte $70, $70, $D0, $00
	.byte $B0, $70, $C0, $00
	.byte $CC, $70, $A0, $00
	.byte $D0, $70, $7C, $00
	.byte $D0, $74, $68, $00
	.byte $CC, $88, $68, $00
	.byte $C0, $9C, $68, $00
	.byte $94, $B4, $68, $00
	.byte $74, $B4, $74, $00
	.byte $68, $B4, $84, $00
	.byte $64, $A8, $9C, $00
	.byte $58, $9C, $B8, $00
	.byte $C8, $C8, $C8, $00
	.byte $50, $D0, $D0, $00
	.byte $5C, $A0, $CC, $00
	.byte $70, $94, $E0, $00
	.byte $88, $88, $E0, $00
	.byte $C0, $84, $D0, $00
	.byte $DC, $84, $B4, $00
	.byte $E0, $88, $94, $00
	.byte $E0, $8C, $7C, $00
	.byte $DC, $9C, $7C, $00
	.byte $D4, $B4, $7C, $00
	.byte $AC, $D0, $7C, $00
	.byte $8C, $D0, $8C, $00
	.byte $7C, $CC, $9C, $00
	.byte $78, $C0, $B4, $00
	.byte $6C, $B4, $D0, $00
	.byte $DC, $DC, $DC, $00
	.byte $5C, $E8, $E8, $00
	.byte $68, $B4, $DC, $00
	.byte $80, $A8, $EC, $00
	.byte $A0, $A0, $EC, $00
	.byte $D0, $9C, $DC, $00
	.byte $EC, $9C, $C4, $00
	.byte $EC, $A0, $A8, $00
	.byte $EC, $A4, $90, $00
	.byte $EC, $B4, $90, $00
	.byte $E8, $CC, $90, $00
	.byte $C0, $E4, $90, $00
	.byte $A4, $E4, $A4, $00
	.byte $90, $E4, $B4, $00
	.byte $88, $D4, $CC, $00
	.byte $7C, $CC, $E8, $00
	.byte $EC, $EC, $EC, $00
	.byte $68, $FC, $FC, $00
	.byte $78, $C8, $EC, $00
	.byte $94, $BC, $FC, $00
	.byte $B4, $B4, $FC, $00
	.byte $E0, $B0, $EC, $00
	.byte $FC, $B0, $D4, $00
	.byte $FC, $B4, $BC, $00
	.byte $FC, $B8, $A4, $00
	.byte $FC, $C8, $A4, $00
	.byte $FC, $E0, $A4, $00
	.byte $D4, $FC, $A4, $00
	.byte $B8, $FC, $B8, $00
	.byte $A4, $FC, $C8, $00
	.byte $9C, $EC, $E0, $00
	.byte $8C, $E0, $FC, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
	.byte $00, $00, $00, $00
tiles_clut_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tiles_img_start:
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $58, $58, $58, $58, $58, $58, $58, $58
	.byte $58, $58, $58, $58, $58, $58, $58, $08, $58, $58, $58
	.byte $58, $58, $58, $58, $58, $58, $58, $58, $58, $58, $58
	.byte $08, $08, $58, $58, $38, $38, $38, $38, $38, $38, $38
	.byte $38, $38, $38, $38, $38, $08, $08, $58, $58, $38, $38
	.byte $38, $38, $38, $38, $38, $38, $38, $38, $38, $38, $08
	.byte $08, $58, $58, $38, $38, $38, $38, $38, $38, $38, $38
	.byte $38, $38, $38, $38, $08, $08, $58, $58, $38, $38, $38
	.byte $38, $38, $38, $38, $38, $38, $38, $38, $38, $08, $08
	.byte $58, $58, $38, $38, $38, $38, $38, $38, $38, $38, $38
	.byte $38, $38, $38, $08, $08, $58, $58, $38, $38, $38, $38
	.byte $38, $38, $38, $38, $38, $38, $38, $38, $08, $08, $58
	.byte $58, $38, $38, $38, $38, $38, $38, $38, $38, $38, $38
	.byte $38, $38, $08, $08, $58, $58, $38, $38, $38, $38, $38
	.byte $38, $38, $38, $38, $38, $38, $38, $08, $08, $58, $58
	.byte $38, $38, $38, $38, $38, $38, $38, $38, $38, $38, $38
	.byte $38, $08, $08, $58, $58, $38, $38, $38, $38, $38, $38
	.byte $38, $38, $38, $38, $38, $38, $08, $08, $58, $58, $38
	.byte $38, $38, $38, $38, $38, $38, $38, $38, $38, $38, $38
	.byte $08, $08, $58, $58, $38, $38, $38, $38, $38, $38, $38
	.byte $38, $38, $38, $38, $38, $08, $08, $58, $08, $08, $08
	.byte $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08
	.byte $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08
	.byte $08, $08, $08, $08, $08, $08, $5C, $5C, $5C, $5C, $5C
	.byte $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $1C
	.byte $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C, $5C
	.byte $5C, $5C, $5C, $1C, $1C, $5C, $5C, $3C, $3C, $3C, $3C
	.byte $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $1C, $1C, $5C
	.byte $5C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C
	.byte $3C, $3C, $1C, $1C, $5C, $5C, $3C, $3C, $3C, $3C, $3C
	.byte $3C, $3C, $3C, $3C, $3C, $3C, $3C, $1C, $1C, $5C, $5C
	.byte $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C
	.byte $3C, $1C, $1C, $5C, $5C, $3C, $3C, $3C, $3C, $3C, $3C
	.byte $3C, $3C, $3C, $3C, $3C, $3C, $1C, $1C, $5C, $5C, $3C
	.byte $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C
	.byte $1C, $1C, $5C, $5C, $3C, $3C, $3C, $3C, $3C, $3C, $3C
	.byte $3C, $3C, $3C, $3C, $3C, $1C, $1C, $5C, $5C, $3C, $3C
	.byte $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $1C
	.byte $1C, $5C, $5C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C
	.byte $3C, $3C, $3C, $3C, $1C, $1C, $5C, $5C, $3C, $3C, $3C
	.byte $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $1C, $1C
	.byte $5C, $5C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C
	.byte $3C, $3C, $3C, $1C, $1C, $5C, $5C, $3C, $3C, $3C, $3C
	.byte $3C, $3C, $3C, $3C, $3C, $3C, $3C, $3C, $1C, $1C, $5C
	.byte $1C, $1C, $1C, $1C, $1C, $1C, $1C, $1C, $1C, $1C, $1C
	.byte $1C, $1C, $1C, $1C, $1C, $1C, $1C, $1C, $1C, $1C, $1C
	.byte $1C, $1C, $1C, $1C, $1C, $1C, $1C, $1C, $1C, $54, $54
	.byte $54, $54, $54, $54, $54, $54, $54, $54, $54, $54, $54
	.byte $54, $54, $14, $54, $54, $54, $54, $54, $54, $54, $54
	.byte $54, $54, $54, $54, $54, $54, $14, $14, $54, $54, $34
	.byte $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34
	.byte $14, $14, $54, $54, $34, $34, $34, $34, $34, $34, $34
	.byte $34, $34, $34, $34, $34, $14, $14, $54, $54, $34, $34
	.byte $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $14
	.byte $14, $54, $54, $34, $34, $34, $34, $34, $34, $34, $34
	.byte $34, $34, $34, $34, $14, $14, $54, $54, $34, $34, $34
	.byte $34, $34, $34, $34, $34, $34, $34, $34, $34, $14, $14
	.byte $54, $54, $34, $34, $34, $34, $34, $34, $34, $34, $34
	.byte $34, $34, $34, $14, $14, $54, $54, $34, $34, $34, $34
	.byte $34, $34, $34, $34, $34, $34, $34, $34, $14, $14, $54
	.byte $54, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34
	.byte $34, $34, $14, $14, $54, $54, $34, $34, $34, $34, $34
	.byte $34, $34, $34, $34, $34, $34, $34, $14, $14, $54, $54
	.byte $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34
	.byte $34, $14, $14, $54, $54, $34, $34, $34, $34, $34, $34
	.byte $34, $34, $34, $34, $34, $34, $14, $14, $54, $54, $34
	.byte $34, $34, $34, $34, $34, $34, $34, $34, $34, $34, $34
	.byte $14, $14, $54, $14, $14, $14, $14, $14, $14, $14, $14
	.byte $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14
	.byte $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14
	.byte $14, $56, $56, $56, $56, $56, $56, $56, $56, $56, $56
	.byte $56, $56, $56, $56, $56, $16, $56, $56, $56, $56, $56
	.byte $56, $56, $56, $56, $56, $56, $56, $56, $56, $16, $16
	.byte $56, $56, $36, $36, $36, $36, $36, $36, $36, $36, $36
	.byte $36, $36, $36, $16, $16, $56, $56, $36, $36, $36, $36
	.byte $36, $36, $36, $36, $36, $36, $36, $36, $16, $16, $56
	.byte $56, $36, $36, $36, $36, $36, $36, $36, $36, $36, $36
	.byte $36, $36, $16, $16, $56, $56, $36, $36, $36, $36, $36
	.byte $36, $36, $36, $36, $36, $36, $36, $16, $16, $56, $56
	.byte $36, $36, $36, $36, $36, $36, $36, $36, $36, $36, $36
	.byte $36, $16, $16, $56, $56, $36, $36, $36, $36, $36, $36
	.byte $36, $36, $36, $36, $36, $36, $16, $16, $56, $56, $36
	.byte $36, $36, $36, $36, $36, $36, $36, $36, $36, $36, $36
	.byte $16, $16, $56, $56, $36, $36, $36, $36, $36, $36, $36
	.byte $36, $36, $36, $36, $36, $16, $16, $56, $56, $36, $36
	.byte $36, $36, $36, $36, $36, $36, $36, $36, $36, $36, $16
	.byte $16, $56, $56, $36, $36, $36, $36, $36, $36, $36, $36
	.byte $36, $36, $36, $36, $16, $16, $56, $56, $36, $36, $36
	.byte $36, $36, $36, $36, $36, $36, $36, $36, $36, $16, $16
	.byte $56, $56, $36, $36, $36, $36, $36, $36, $36, $36, $36
	.byte $36, $36, $36, $16, $16, $56, $16, $16, $16, $16, $16
	.byte $16, $16, $16, $16, $16, $16, $16, $16, $16, $16, $16
	.byte $16, $16, $16, $16, $16, $16, $16, $16, $16, $16, $16
	.byte $16, $16, $16, $16, $51, $51, $51, $51, $51, $51, $51
	.byte $51, $51, $51, $51, $51, $51, $51, $51, $11, $51, $51
	.byte $51, $51, $51, $51, $51, $51, $51, $51, $51, $51, $51
	.byte $51, $11, $11, $51, $51, $31, $31, $31, $31, $31, $31
	.byte $31, $31, $31, $31, $31, $31, $11, $11, $51, $51, $31
	.byte $31, $31, $31, $31, $31, $31, $31, $31, $31, $31, $31
	.byte $11, $11, $51, $51, $31, $31, $31, $31, $31, $31, $31
	.byte $31, $31, $31, $31, $31, $11, $11, $51, $51, $31, $31
	.byte $31, $31, $31, $31, $31, $31, $31, $31, $31, $31, $11
	.byte $11, $51, $51, $31, $31, $31, $31, $31, $31, $31, $31
	.byte $31, $31, $31, $31, $11, $11, $51, $51, $31, $31, $31
	.byte $31, $31, $31, $31, $31, $31, $31, $31, $31, $11, $11
	.byte $51, $51, $31, $31, $31, $31, $31, $31, $31, $31, $31
	.byte $31, $31, $31, $11, $11, $51, $51, $31, $31, $31, $31
	.byte $31, $31, $31, $31, $31, $31, $31, $31, $11, $11, $51
	.byte $51, $31, $31, $31, $31, $31, $31, $31, $31, $31, $31
	.byte $31, $31, $11, $11, $51, $51, $31, $31, $31, $31, $31
	.byte $31, $31, $31, $31, $31, $31, $31, $11, $11, $51, $51
	.byte $31, $31, $31, $31, $31, $31, $31, $31, $31, $31, $31
	.byte $31, $11, $11, $51, $51, $31, $31, $31, $31, $31, $31
	.byte $31, $31, $31, $31, $31, $31, $11, $11, $51, $11, $11
	.byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11
	.byte $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11
	.byte $11, $11, $11, $11, $11, $11, $11, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $50, $50, $50, $50, $50, $50, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $50, $40, $40, $40, $40
	.byte $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $50, $40, $30, $30, $30, $30, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $50, $40, $30, $30, $30, $30
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $50
	.byte $40, $30, $30, $20, $20, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $50, $40, $30, $30, $20, $10, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $50, $50, $50, $50, $50, $50
	.byte $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $40
	.byte $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40
	.byte $40, $40, $40, $40, $30, $30, $30, $30, $30, $30, $30
	.byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
	.byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
	.byte $30, $30, $30, $20, $20, $20, $20, $20, $20, $20, $20
	.byte $20, $20, $20, $20, $20, $20, $20, $20, $10, $10, $10
	.byte $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
	.byte $10, $10, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $50, $50, $50
	.byte $50, $50, $10, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $40, $40, $40, $40, $20, $10, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $30, $30, $30, $30
	.byte $20, $10, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $30, $30, $30, $30, $20, $10, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $20, $40, $30, $30, $20
	.byte $10, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $50, $40, $30, $30, $20, $10, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $50, $40, $30, $30, $20, $10, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $50, $40
	.byte $30, $30, $20, $10, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $50, $40, $30, $30, $20, $10, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $50, $40, $30
	.byte $30, $20, $10, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $50, $40, $30, $30, $20, $10, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $50, $40, $30, $30
	.byte $20, $10, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $50, $40, $30, $30, $20, $10, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $50, $40, $30, $30, $20
	.byte $10, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $50, $40, $30, $30, $20, $10, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $50, $40, $30, $30, $20, $10
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $50
	.byte $40, $30, $30, $20, $10, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $50, $40, $30, $30, $20, $10, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $50, $40
	.byte $30, $30, $20, $10, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $50, $40, $30, $30, $20, $10, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $50, $40, $30
	.byte $30, $20, $10, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $50, $40, $30, $30, $20, $10, $50, $40, $30
	.byte $30, $20, $10, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $50, $40, $30, $30, $20, $10, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $50, $40, $30, $30
	.byte $20, $10, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $50, $40, $30, $30, $20, $10, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $50, $40, $30, $30, $20
	.byte $10, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $50, $40, $30, $30, $20, $10, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $50, $40, $30, $30, $20, $10
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $50
	.byte $40, $30, $30, $20, $10, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $50, $40, $30, $30, $20, $10, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $50, $40
	.byte $30, $30, $20, $10, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $50, $40, $30, $30, $20, $10, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $50, $40, $30
	.byte $30, $20, $10, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $50, $40, $30, $30, $20, $10, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $50, $40, $30, $30
	.byte $20, $10, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $50, $40, $30, $30, $20, $10, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $50, $40, $30, $30, $20
	.byte $10, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $50
	.byte $40, $30, $30, $20, $50, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $50, $40, $30, $30, $40, $40, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $50, $40
	.byte $30, $30, $30, $30, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $50, $40, $30, $30, $30, $30, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $50, $20, $20
	.byte $20, $20, $20, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $10, $10, $10, $10, $10, $10, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $50, $50, $50, $50, $50, $50, $50, $50
	.byte $50, $50, $50, $50, $50, $50, $50, $50, $40, $40, $40
	.byte $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40
	.byte $40, $40, $30, $30, $30, $30, $30, $30, $30, $30, $30
	.byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
	.byte $30, $30, $30, $30, $30, $30, $30, $30, $30, $30, $30
	.byte $30, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte $20, $20, $20, $20, $20, $20, $10, $10, $10, $10, $10
	.byte $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $50, $40, $30, $30, $20
	.byte $10, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $40, $40, $30, $30, $20, $10, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $30, $30, $30, $30, $20, $10
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $30
	.byte $30, $30, $30, $20, $10, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $20, $20, $20, $20, $20, $10, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $10, $10
	.byte $10, $10, $10, $10, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00
tiles_img_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tile_map:   
	.word $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800
	.word $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803
	.word $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800
	.word $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803
	.word $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800
	.word $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803
	.word $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800
	.word $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803
	.word $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800
	.word $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803
	.word $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800
	.word $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803
	.word $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800
	.word $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803
	.word $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800
	.word $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803, $800, $803

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.endlogical

; Write the system vectors
* = $00FFF8
.logical $FFF8
.byte $00
F256_DUMMYIRQ       ; Abort vector
    RTI

.word F256_DUMMYIRQ ; nmi
.word F256_RESET    ; reset
.word F256_DUMMYIRQ ; irq
.endlogical