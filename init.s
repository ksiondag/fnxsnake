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
    LDA #$2
    STA vel_x
    STZ vel_x+1

    STZ direction_press
    LDA #$10
    STA direction_moving
    STZ next_update_movement

    LDA #$01
    STA grid_pos_x
    STZ grid_pos_y

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

    LDA #$20
    STA sprite_x
    STZ sprite_x+1
    LDA #$20
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
