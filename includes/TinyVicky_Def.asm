;                                                                                       ;TinyVicky_Def.asm

                            MASTER_CTRL_REG_L =         $D000  
                            Mstr_Ctrl_Text_Mode_En =    $01                      ; Enable the Text Mode
                            Mstr_Ctrl_Text_Overlay =    $02                      ; Enable the Overlay of the text mode on top of Graphic Mode (the Background Color is ignored)
                            Mstr_Ctrl_Graph_Mode_En =   $04                      ; Enable the Graphic Mode
                            Mstr_Ctrl_Bitmap_En =       $08                      ; Enable the Bitmap Module In Vicky
                            Mstr_Ctrl_TileMap_En =      $10                     ; Enable the Tile Module in Vicky
                            Mstr_Ctrl_Sprite_En =       $20                 ; Enable the Sprite Module in Vicky
                            Mstr_Ctrl_GAMMA_En =        $40                 ; this Enable the GAMMA correction - The Analog and DVI have different color value, the GAMMA is great to correct the difference
                            Mstr_Ctrl_Disable_Vid =     $80                ; This will disable the Scanning of the Video hence giving 100% bandwith to the CPU
                            MASTER_CTRL_REG_H =         $D001  
                            Mstr_Ctrl_Video_Mode =      $01                      ; 0 - 640x480@60Hz : 1 - 640x400@70hz (text mode) // 0 - 320x240@60hz : 1 - 320x200@70Hz (Graphic Mode & Text mode when Doubling = 1)
                            Mstr_Ctrl_Text_XDouble =    $02                      ; X Pixel Doubling
                            Mstr_Ctrl_Text_YDouble =    $04                      ; Y Pixel Doubling
                            LAYER_CTRL_REG_0 =          $D002  
                            LAYER_CTRL_REG_1 =          $D003  
                            BORDER_CTRL_REG =           $D004            ; Bit[0] - Enable (1 by default)  Bit[4..6]: X Scroll Offset ( Will scroll Left) (Acceptable Value: 0..7)
                            Border_Ctrl_Enable =        $01  
                            BORDER_COLOR_B  =           $D005  
                            BORDER_COLOR_G  =           $D006  
                            BORDER_COLOR_R  =           $D007  
                            BORDER_X_SIZE   =           $D008              ; X-  Values: 0 - 32 (Default: 32)
                            BORDER_Y_SIZE   =           $D009              ; Y- Values 0 -32 (Default: 32)
;                                                                                       ;VKY_RESERVED_02         = $D00A
;                                                                                       ;VKY_RESERVED_03         = $D00B
;                                                                                       ;VKY_RESERVED_04         = $D00C
                            BACKGROUND_COLOR_B =        $D00D              ; When in Graphic Mode, if a pixel is "0" then the Background pixel is chosen
                            BACKGROUND_COLOR_G =        $D00E  
                            BACKGROUND_COLOR_R =        $D00F              ;
                            VKY_TXT_CURSOR_CTRL_REG =   $D010             ;[0]  Enable Text Mode
                            Vky_Cursor_Enable =         $01  
                            Vky_Cursor_Flash_Rate0 =    $02  
                            Vky_Cursor_Flash_Rate1 =    $04  
                            VKY_TXT_START_ADD_PTR =     $D011              ; This is an offset to change the Starting address of the Text Mode Buffer (in x)
                            VKY_TXT_CURSOR_CHAR_REG =   $D012  
                            VKY_TXT_CURSOR_COLR_REG =   $D013  
                            VKY_TXT_CURSOR_X_REG_L =    $D014  
                            VKY_TXT_CURSOR_X_REG_H =    $D015  
                            VKY_TXT_CURSOR_Y_REG_L =    $D016  
                            VKY_TXT_CURSOR_Y_REG_H =    $D017  
                            VKY_LINE_IRQ_CTRL_REG =     $D018              ;[0] - Enable Line 0 - WRITE ONLY
                            VKY_LINE_CMP_VALUE_LO =     $D019              ;Write Only [7:0]
                            VKY_LINE_CMP_VALUE_HI =     $D01A              ;Write Only [3:0]
                            VKY_PIXEL_X_POS_LO =        $D018              ; This is Where on the video line is the Pixel
                            VKY_PIXEL_X_POS_HI =        $D019              ; Or what pixel is being displayed when the register is read
                            VKY_LINE_Y_POS_LO =         $D01A              ; This is the Line Value of the Raster
                            VKY_LINE_Y_POS_HI =         $D01B              ;
                            TyVKY_BM0_CTRL_REG =        $D100  
                            BM0_Ctrl        =           $01                      ; Enable the BM0
                            BM0_LUT0        =           $02                      ; LUT0
                            BM0_LUT1        =           $04                      ; LUT1
                            TyVKY_BM0_START_ADDY_L =    $D101  
                            TyVKY_BM0_START_ADDY_M =    $D102  
                            TyVKY_BM0_START_ADDY_H =    $D103  
                            TyVKY_BM1_CTRL_REG =        $D108  
                            BM1_Ctrl        =           $01                      ; Enable the BM0
                            BM1_LUT0        =           $02                      ; LUT0
                            BM1_LUT1        =           $04                      ; LUT1
                            TyVKY_BM1_START_ADDY_L =    $D109  
                            TyVKY_BM1_START_ADDY_M =    $D10A  
                            TyVKY_BM1_START_ADDY_H =    $D10B  
                            TyVKY_BM2_CTRL_REG =        $D110  
                            BM2_Ctrl        =           $01                      ; Enable the BM0
                            BM2_LUT0        =           $02                      ; LUT0
                            BM2_LUT1        =           $04                      ; LUT1
                            BM2_LUT2        =           $08                      ; LUT2
                            TyVKY_BM2_START_ADDY_L =    $D111  
                            TyVKY_BM2_START_ADDY_M =    $D112  
                            TyVKY_BM2_START_ADDY_H =    $D113  
                            TyVKY_TL_CTRL0  =           $D200  
                            TILE_Enable     =           $01  
                            TILE_LUT0       =           $02  
                            TILE_LUT1       =           $04  
                            TILE_LUT2       =           $08  
                            TILE_SIZE       =           $10                     ; 0 -> 16x16, 0 -> 8x8
                            TL0_CONTROL_REG =           $D200              ; Bit[0] - Enable, Bit[3:1] - LUT Select,
                            TL0_START_ADDY_L =          $D201              ; Not USed right now - Starting Address to where is the MAP
                            TL0_START_ADDY_M =          $D202  
                            TL0_START_ADDY_H =          $D203  
                            TL0_MAP_X_SIZE_L =          $D204              ; The Size X of the Map
                            TL0_MAP_X_SIZE_H =          $D205  
                            TL0_MAP_Y_SIZE_L =          $D206              ; The Size Y of the Map
                            TL0_MAP_Y_SIZE_H =          $D207  
                            TL0_MAP_X_POS_L =           $D208              ; The Position X of the Map
                            TL0_MAP_X_POS_H =           $D209  
                            TL0_MAP_Y_POS_L =           $D20A              ; The Position Y of the Map
                            TL0_MAP_Y_POS_H =           $D20B  
                            TL1_CONTROL_REG =           $D20C              ; Bit[0] - Enable, Bit[3:1] - LUT Select,
                            TL1_START_ADDY_L =          $D20D              ; Not USed right now - Starting Address to where is the MAP
                            TL1_START_ADDY_M =          $D20E  
                            TL1_START_ADDY_H =          $D20F  
                            TL1_MAP_X_SIZE_L =          $D210              ; The Size X of the Map
                            TL1_MAP_X_SIZE_H =          $D211  
                            TL1_MAP_Y_SIZE_L =          $D212              ; The Size Y of the Map
                            TL1_MAP_Y_SIZE_H =          $D213  
                            TL1_MAP_X_POS_L =           $D214              ; The Position X of the Map
                            TL1_MAP_X_POS_H =           $D215  
                            TL1_MAP_Y_POS_L =           $D216              ; The Position Y of the Map
                            TL1_MAP_Y_POS_H =           $D217  
                            TL2_CONTROL_REG =           $D218              ; Bit[0] - Enable, Bit[3:1] - LUT Select,
                            TL2_START_ADDY_L =          $D219              ; Not USed right now - Starting Address to where is the MAP
                            TL2_START_ADDY_M =          $D21A  
                            TL2_START_ADDY_H =          $D21B  
                            TL2_MAP_X_SIZE_L =          $D21C              ; The Size X of the Map
                            TL2_MAP_X_SIZE_H =          $D21D  
                            TL2_MAP_Y_SIZE_L =          $D21E              ; The Size Y of the Map
                            TL2_MAP_Y_SIZE_H =          $D21F  
                            TL2_MAP_X_POS_L =           $D220              ; The Position X of the Map
                            TL2_MAP_X_POS_H =           $D221  
                            TL2_MAP_Y_POS_L =           $D222              ; The Position Y of the Map
                            TL2_MAP_Y_POS_H =           $D223  
                            TILE_MAP_ADDY0_L =          $D280  
                            TILE_MAP_ADDY0_M =          $D281  
                            TILE_MAP_ADDY0_H =          $D282  
                            TILE_MAP_ADDY0_CFG =        $D283  
                            TILE_MAP_ADDY1  =           $D284  
                            TILE_MAP_ADDY2  =           $D288  
                            TILE_MAP_ADDY3  =           $D28C  
                            TILE_MAP_ADDY4  =           $D290  
                            TILE_MAP_ADDY5  =           $D294  
                            TILE_MAP_ADDY6  =           $D298  
                            TILE_MAP_ADDY7  =           $D29C  
                            XYMATH_CTRL_REG =           $D300              ; Reserved
                            XYMATH_ADDY_L   =           $D301              ; W
                            XYMATH_ADDY_M   =           $D302              ; W
                            XYMATH_ADDY_H   =           $D303              ; W
                            XYMATH_ADDY_POSX_L =        $D304              ; R/W
                            XYMATH_ADDY_POSX_H =        $D305              ; R/W
                            XYMATH_ADDY_POSY_L =        $D306              ; R/W
                            XYMATH_ADDY_POSY_H =        $D307              ; R/W
                            XYMATH_BLOCK_OFF_L =        $D308              ; R Only - Low Block Offset
                            XYMATH_BLOCK_OFF_H =        $D309              ; R Only - Hi Block Offset
                            XYMATH_MMU_BLOCK =          $D30A              ; R Only - Which MMU Block
                            XYMATH_ABS_ADDY_L =         $D30B              ; Low Absolute Results
                            XYMATH_ABS_ADDY_M =         $D30C              ; Mid Absolute Results
                            XYMATH_ABS_ADDY_H =         $D30D              ; Hi Absolute Results
                            SPRITE_Ctrl_Enable =        $01  
                            SPRITE_LUT0     =           $02  
                            SPRITE_LUT1     =           $04  
                            SPRITE_DEPTH0   =           $08                      ; 00 = Total Front - 01 = In between L0 and L1, 10 = In between L1 and L2, 11 = Total Back
                            SPRITE_DEPTH1   =           $10  
                            SPRITE_SIZE0    =           $20                 ; 00 = 32x32 - 01 = 24x24 - 10 = 16x16 - 11 = 8x8
                            SPRITE_SIZE1    =           $40  
                            SP0_Ctrl        =           $D900  
                            SP0_Addy_L      =           $D901  
                            SP0_Addy_M      =           $D902  
                            SP0_Addy_H      =           $D903  
                            SP0_X_L         =           $D904  
                            SP0_X_H         =           $D905  
                            SP0_Y_L         =           $D906              ; In the Jr, only the L is used (200 & 240)
                            SP0_Y_H         =           $D907              ; Always Keep @ Zero '0' because in Vicky the value is still considered a 16bits value
                            SP1_Ctrl        =           $D908
                            SP1_Addy_L      =           $D909
                            SP1_Addy_M      =           $D90A
                            SP1_Addy_H      =           $D90B
                            SP1_X_L         =           $D90C
                            SP1_X_H         =           $D90D
                            SP1_Y_L         =           $D90E              ; In the Jr, only the L is used (200 & 240)
                            SP1_Y_H         =           $D90F              ; Always Keep @ Zero '0' because in Vicky the value is still considered a 16bits value
;                                                                                       ;SP2_Ctrl           = $D910
;                                                                                       ;SP2_Addy_L         = $D911
;                                                                                       ;SP2_Addy_M         = $D912
;                                                                                       ;SP2_Addy_H         = $D913
;                                                                                       ;SP2_X_L            = $D914
;                                                                                       ;SP2_X_H            = $D915
;                                                                                       ;SP2_Y_L            = $D916  ; In the Jr, only the L is used (200 & 240)
;                                                                                       ;SP2_Y_H            = $D917  ; Always Keep @ Zero '0' because in Vicky the value is still considered a 16bits value
;                                                                                       ;SP3_Ctrl           = $D918
;                                                                                       ;SP3_Addy_L         = $D919
;                                                                                       ;SP3_Addy_M         = $D91A
;                                                                                       ;SP3_Addy_H         = $D91B
;                                                                                       ;SP3_X_L            = $D91C
;                                                                                       ;SP3_X_H            = $D91D
;                                                                                       ;SP3_Y_L            = $D91E  ; In the Jr, only the L is used (200 & 240)
;                                                                                       ;SP3_Y_H            = $D91F  ; Always Keep @ Zero '0' because in Vicky the value is still considered a 16bits value
;                                                                                       ;SP4_Ctrl           = $D920
;                                                                                       ;SP4_Addy_L         = $D921
;                                                                                       ;SP4_Addy_M         = $D922
;                                                                                       ;SP4_Addy_H         = $D923
;                                                                                       ;SP4_X_L            = $D924
;                                                                                       ;SP4_X_H            = $D925
;                                                                                       ;SP4_Y_L            = $D926  ; In the Jr, only the L is used (200 & 240)
;                                                                                       ;SP4_Y_H            = $D927  ; Always Keep @ Zero '0' because in Vicky the value is still considered a 16bits value
                            TyVKY_LUT0      =           $D000              ; IO Page 1 -$D000 - $D3FF
                            TyVKY_LUT1      =           $D400              ; IO Page 1 -$D400 - $D7FF
                            TyVKY_LUT2      =           $D800              ; IO Page 1 -$D800 - $DBFF
                            TyVKY_LUT3      =           $DC00              ; IO Page 1 -$DC00 - $DFFF



                            DMA_CTRL_REG    =           $DF00  
                            DMA_CTRL_Enable =           $01  
                            DMA_CTRL_1D_2D  =           $02  
                            DMA_CTRL_Fill   =           $04  
                            DMA_CTRL_Int_En =           $08  
;                                                                                       ;DMA_CTRL_NotUsed0   = $10
;                                                                                       ;DMA_CTRL_NotUsed1   = $20
;                                                                                       ;DMA_CTRL_NotUsed2   = $40
                            DMA_CTRL_Start_Trf =        $80  
                            DMA_DATA_2_WRITE =          $DF01              ; Write Only
                            DMA_STATUS_REG  =           $DF01              ; Read Only
                            DMA_STATUS_TRF_IP =         $80                ; Transfer in Progress
;                                                                                       ;DMA_RESERVED_0      = $DF02
;                                                                                       ;DMA_RESERVED_1      = $DF03
                            DMA_SOURCE_ADDY_L =         $DF04  
                            DMA_SOURCE_ADDY_M =         $DF05  
                            DMA_SOURCE_ADDY_H =         $DF06  
;                                                                                       ;DMA_RESERVED_2      = $DF07
                            DMA_DEST_ADDY_L =           $DF08  
                            DMA_DEST_ADDY_M =           $DF09  
                            DMA_DEST_ADDY_H =           $DF0A  
;                                                                                       ;DMA_RESERVED_3      = $DF0B
                            DMA_SIZE_1D_L   =           $DF0C  
                            DMA_SIZE_1D_M   =           $DF0D  
                            DMA_SIZE_1D_H   =           $DF0E  
;                                                                                       ;DMA_RESERVED_4      = $DF0F
                            DMA_SIZE_X_L    =           $DF0C  
                            DMA_SIZE_X_H    =           $DF0D  
                            DMA_SIZE_Y_L    =           $DF0E  
                            DMA_SIZE_Y_H    =           $DF0F  
                            DMA_SRC_STRIDE_X_L =        $DF10  
                            DMA_SRC_STRIDE_X_H =        $DF11  
                            DMA_DST_STRIDE_Y_L =        $DF12  
                            DMA_DST_STRIDE_Y_H =        $DF13  
;                                                                                       ;DMA_RESERVED_5      = $DF14
;                                                                                       ;DMA_RESERVED_6      = $DF15
;                                                                                       ;DMA_RESERVED_7      = $DF16
;                                                                                       ;DMA_RESERVED_8      = $DF17