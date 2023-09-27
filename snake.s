.cpu "65816"                        ; Tell 64TASS that we are using a 65816

.include "includes/TinyVicky_Def.asm"
.include "includes/interrupt_def.asm"
.include "includes/f256jr_registers.asm"
.include "includes/f256k_registers.asm"
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
    LDA #$24 ;#(Mstr_Ctrl_Text_Mode_En|Mstr_Ctrl_Text_Overlay|Mstr_Ctrl_Graph_Mode_En|Mstr_Ctrl_Bitmap_En|Mstr_Ctrl_Sprite_En)
    STA @w MASTER_CTRL_REG_L 
    LDA #(Mstr_Ctrl_Text_XDouble|Mstr_Ctrl_Text_YDouble)
    STA @w MASTER_CTRL_REG_H

    ; Disable the cursor
    LDA VKY_TXT_CURSOR_CTRL_REG
    AND #$FE
    STA VKY_TXT_CURSOR_CTRL_REG
    
    JSR ClearScreen        
             
    ; Clear to lavender
    LDA #$B6
    STA $D00D ; Background blue channel
    LDA #$7B
    STA $D00E ; Background green channel
    LDA #$96
    STA $D00F ; Background red channel

    ; Turn off the border
    STZ VKY_BRDR_CTRL
    
    STZ TyVKY_BM0_CTRL_REG ; Make sure bitmap 0 is turned off
    STZ TyVKY_BM1_CTRL_REG ; Make sure bitmap 1 is turned off
    STZ TyVKY_BM2_CTRL_REG ; Make sure bitmap 2 is turned off
    
    JSR Init_IRQHandler

    ; Load sprite colors into CLUT
    LDA #$01 ; Switch to I/O Page #1
    sta MMU_IO_CTRL

    lda #<balls_clut_start ; Set the source pointer to the palette
    sta src_pointer
    lda #>balls_clut_start
    sta src_pointer+1

    lda #<VKY_GR_CLUT_0 ; Set the destination to Graphics CLUT
    sta dst_pointer
    lda #>VKY_GR_CLUT_0
    sta dst_pointer+1

    ldx #0 ; X is the number of colors copied

color_loop: 
    ldy #0 ; Y points to the color component

    lda (src_pointer),y ; Read a byte from the code
    sta (dst_pointer),y ; And write it to the CLUT
    iny ; Move to the next byte
    lda (src_pointer),y
    sta (dst_pointer),y 
    iny 
    lda (src_pointer),y
    sta (dst_pointer),y 
    iny 
    iny 

    inx ; Move to the next color
    CPX #16
    beq done_lut ; Until we have copied all 16

    clc ; Move ptr_src to the next source color
    lda src_pointer
    adc #4
    sta src_pointer
    lda src_pointer+1
    adc #0
    sta src_pointer+1

    clc ; Move ptr_dst to the next destination
    lda dst_pointer
    adc #4
    sta dst_pointer
    lda dst_pointer+1
    adc #0
    sta dst_pointer+1
    bra color_loop ; And start copying that new color
done_lut: 
    stz MMU_IO_CTRL ; Go back to I/O Page 0
    
    ; Point sprite 0 to the pixel data, set its location in screen, and enable the sprite
    init_sp0: 
    lda #<balls_img_start ; Address = balls_img_start
    sta SP0_Addy_L
    lda #>balls_img_start
    sta SP0_Addy_M
    stz SP0_Addy_H

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

    lda #$41 ; Size=16x16, Layer=0, LUT=0, Enabled
    sta SP0_Ctrl
    
    JSR Init_IRQHandler
    
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

Lock
    JSR Poll
    LDA frame_counter
    BNE Lock

    ; Use 816 mode
    CLC
    XCE
    
    setaxs

    ; Move sprite to the right
    stz MMU_IO_CTRL ; Go back to I/O Page 0

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
    LDA #$FE
    STA VIA1_PRA
    LDA VIA1_PRB
    CMP #$FB
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
    LDA #$FE
    STA VIA1_PRA
    LDA VIA1_PRB
    CMP #$7F
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