
WRT_LCD macro val
        movlw   val
        call    WR_DATA
        endm

    ;Delay: ~160us
 LCD_DELAY macro
    	movlw   0xFF
    	movwf   lcd_d1
    	decfsz  lcd_d1,f
    	goto    $-1
    	endm

BCD_Display macro val
    	swapf val, w
        andlw   0x0f           ; Mask upper four bits 0000 HHHH
        addlw   0x30           ; convert to ASCII
        call WR_DATA

    	call	lcdLongDelay
        movf    val,w
        andlw   0x0f           ; w  = 0000 LLLL
        addlw   0x30           ; convert to ASCII
        call WR_DATA
    	endm

BCD_DisplayS macro val
        movf    val,w
        andlw   0x0f           ; w  = 0000 LLLL
        addlw   0x30           ; convert to ASCII
        call WR_DATA
    	endm

Display macro	Message
		local	loop_
		local 	end_
		clrf	Table_Counter
		clrw
loop_	movf	Table_Counter,W
		call 	Message
		xorlw	B'00000000' ;check WORK reg to see if 0 is returned
		btfsc	STATUS,Z
			goto	end_
		call	WR_DATA
		incf	Table_Counter,F
		goto	loop_
end_
		endm

Switch_Lines macro
		movlw	B'11000000'
		call	WR_INS
		endm

Clear_Display macro
		movlw	B'00000001'
		call	WR_INS
		endm

