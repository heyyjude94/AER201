;*******************************************************************
; User Interface
; Assembler : mpasm.exe
; Linker    : mplink.exe
; Written By : Judy Shen
;*******************************************************************

      list p=16f877                 ; list directive to define processor
      #include <p16f877.inc>        ; processor specific variable definitions
      #include <LCD.inc>
      #include <rtc_macros.inc>
      __CONFIG _CP_OFF & _WDT_OFF & _BODEN_ON & _PWRTE_ON & _HS_OSC & _WRT_ENABLE_ON & _CPD_OFF & _LVP_OFF

	cblock	0x20
		COUNTH ;0x20
		COUNTM ;0x21
		COUNTL ;0x22
		Table_Counter ;0x23
		lcd_tmp ;0x24
        key_temp ;0x25
        test ;0x26
        rtc1 ;0x27
        rtc2 ;0x28
        com ;0x29
        dat ;0x2a
        lcd_d1 ;0x2b
        lcd_d2 ;0x2c
        bcd ;0x2d
        count ;0x2e
        show_data ;02f
        w_temp ;0x30
        status_temp ;0x31
        pass ;0x32
        flickerfail ;0x33
        ledfail ;0x34
        runtime ;0x35
        timercount ;0x36
        ones ;0x37
        tens ;0x38
        huns ;0x39
        count_temp ;0x3a
        run_temp ;0x3b
        ADDRL ;0x3c
        DATAL ;0x3d
        VALUEL ;0x3e
        signal ;0x3f
        none ;0x40
        light1 ;0x41
        light2 ;0x42
        light3 ;0x43
        light4 ;0x44
        light5 ;0x45
        light6 ;0x46
        light7 ;0x47
        light8 ;0x48
        light9 ;0x49
        result_temp

	endc

	;Declare constants for pin assignments (LCD on PORTD)

		#define	RS 	PORTD,2
		#define	E 	PORTD,3

        ORG       0x0000     ;RESET vector must always be at 0x00
        clrf PCLATH
        goto      init       ;Just jump to the main code section.

        ORG 0x004
        goto ISR
init
         bsf    INTCON, GIE
         banksel    OPTION_REG
         ;init timer interrupt
         clrf       TMR0
         movlw      B'11000111'
         movwf      OPTION_REG

         bcf        STATUS, RP0

         ;init timer
         movlw      D'38'
         movwf      timercount
         clrf       runtime

         bsf       STATUS,RP0     ; select bank 1
         clrf      TRISA
         movlw     b'11110011'    ; Set required keypad inputs
         movwf     TRISB
         clrf      TRISC          ; All port C is output
         clrf      TRISD          ; All port D is output

         ;Set SDA and SCL to high-Z first as required for I2C
		 bsf	   TRISC,4
		 bsf	   TRISC,3

         bcf       STATUS,RP0     ; select bank 0
         clrf      PORTA
         clrf      PORTB
         clrf      PORTC
         clrf      PORTD
		 call 	   i2c_common_setup

         call      InitLCD    ;Initialize the LCD (code in lcd.asm; imported by lcd.inc)

         ; init EEPROM
         movlw    0x0a
         movwf    ADDRL
         clrf     DATAL
         clrf     VALUEL




;MAIN PROGRAM
;***************************************
Main	Display		Welcome_Msg
        call        HalfS
        call        HalfS
        call        HalfS
        call        Clear_Display

Start_Test
   		Display		Menu

Test     movlw		b'00011000'		;Move to the left
         call		WR_INS
         call		HalfS    ;Wait until data is available from the keypad
         btfss		PORTB,1
         goto		Test


         swapf		PORTB,W     ;Read PortB<7:4> into W<3:0>
         andlw		0x0F
         call       check
         goto       Start_Test

; Look up table
;***************************************

Welcome_Msg
		addwf	PCL,F
		dt		"Welcome!", 0

Paused
		addwf	PCL,F
		dt		"Paused", 0

Menu
		addwf	PCL,F
		dt		"A:Start, ", "B:PLog, ", "C:Time",0

Run
		addwf	PCL,F
		dt		"Testing Candles", 0
SW_ON
		addwf	PCL,F
		dt		"Switch On", 0

SW_OFF
        addwf   PCL, F
        dt      "Switch Off", 0

Done
		addwf	PCL,F
		dt		"Finished Testing", 0

Runtime
		addwf	PCL,F
		dt		"Runtime: ", 0

PMem
		addwf	PCL,F
		dt		"Permanent Log", 0
PMenu
        addwf   PCL, F
        dt      "Select Trial", 0

RTC
		addwf	PCL,F
		dt		"Time:", 0

Writing
        addwf   PCL, F
        dt      "Writing EE", 0

Trial
        addwf   PCL, F
        dt      "P: FF: LF: N:", 0


;***************************************
; Helper Subrountines
;***************************************

Switch_Lines
		movlw	B'11000000'
		call	WR_INS
		return

Clear_Display
		movlw	B'00000001'
		call	WR_INS
		return

InitLCD
	bcf STATUS,RP0
	bsf E     ;E default high

	;Wait for LCD POR to finish (~15ms)
	call lcdLongDelay
	call lcdLongDelay
	call lcdLongDelay

	;Ensure 8-bit mode first (no way to immediately guarantee 4-bit mode)
	; -> Send b'0011' 3 times
	movlw	b'00110011'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay
	movlw	b'00110010'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay

	; 4 bits, 2 lines, 5x7 dots
	movlw	b'00101000'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay

	; display on/off
	movlw	b'00001100'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay

	; Entry mode
	movlw	b'00000110'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay

	; Clear ram
	movlw	b'00000001'
	call	WR_INS
	call lcdLongDelay
	call lcdLongDelay
	return

;helper subroutines
;function to check for keyboard input
check
    movwf key_temp

check_A
    xorlw   D'3'
    btfss   STATUS, Z
        goto    check_B

    call Clear_Display
    Display Run
    call    HalfS
    call Clear_Display
    call    Motor_On
    bsf    INTCON, 5
    call    count_down
    bcf    INTCON, 5
    call Clear_Display
    call    Motor_Off

    Display Done
    call Switch_Lines
    Display Runtime 
    call Convert
    clrf    runtime
    ;writing run info into EEPROM
    movf    pass, VALUEL
    movwf   VALUEL
    call    write_EE

    incf    ADDRL
    movf    flickerfail, VALUEL
    movwf   VALUEL
    call    write_EE
    incf    ADDRL

    movf    ledfail, VALUEL
    movwf   VALUEL
    call    write_EE
    incf    ADDRL

    movf    none, VALUEL
    movwf   VALUEL
    call    write_EE
    ;going back to original ADDRL address
    decf    ADDRL
    decf    ADDRL
    decf    ADDRL 
    call    wait
    call Clear_Display
    ;can check previous run trials
    call results_access
    call wait

    call Clear_Display
    return

check_B
    movf key_temp, W
    xorlw D'7'
    btfss STATUS, Z
        goto check_C
    call Clear_Display
    Display PMem
    call Switch_Lines
    Display PMenu
    call pmenu_access
    call Clear_Display
    return

check_C
    movf key_temp, W
    xorlw D'11'
    btfss STATUS, Z
        goto Other_wise
    call Clear_Display
    call show_RTC
    call Clear_Display
    return

Other_wise
    call Clear_Display
    return


count_down
        ;movlw D'9'
        ;movwf count
        clrf show_data
        clrf pass
        clrf flickerfail
        clrf ledfail
        clrf none
        clrf light1
        clrf light2
        clrf light3
        clrf light4
        clrf light5
        clrf light6
        clrf light7
        clrf light8
        clrf light9
        Display Run

count_loop
        movlw b'00000000'
        movwf PORTA
        call Check_Flicker
        movf result_temp, w
        movwf light1

        movlw b'00000001'
        movwf PORTA
        call Check_Flicker
        movf result_temp, w
        movwf light2

        movlw b'00000010'
        movwf PORTA
        call Check_Flicker
        movf result_temp, w
        movwf light3

        movlw b'00000011'
        movwf PORTA
        call Check_Flicker
        movf result_temp, w
        movwf light4

        movlw b'00000100'
        movwf PORTA
        call Check_Flicker
        movf result_temp, w
        movwf light5

        movlw b'00000101'
        movwf PORTA
        call Check_Flicker
        movf result_temp, w
        movwf light6

        movlw b'00000110'
        movwf PORTA
        call Check_Flicker
        movf result_temp, w
        movwf light7

        movlw b'00000111'
        movwf PORTA
        call Check_Flicker
        movf result_temp, w
        movwf light8

        movlw b'00001000'
        movwf PORTA
        call Check_Flicker
        movf result_temp, w
        movwf light9
        return

Check_Flicker
        call    HalfS 
        clrf    signal
        movf    PORTB, w
        andlw   b'00000001'
        btfss   STATUS, Z
                goto flickertime
        incf    none
        incf    show_data
        movlw   b'00000001'
        movwf   result_temp
        goto    Display_results

flickertime
        bsf     PORTA, 4
        clrf    signal
        call    HalfS
        call    HalfS
        call    HalfS
        call    HalfS
        call    HalfS
        call    HalfS
        call    HalfS
        clrf    result_temp
        incf    show_data
        movlw   B'10000000' ;move cursor to position H?4B?
        call    WR_INS
        btfss   signal, 7
            goto    notflickerfail
        incf    flickerfail
        movlw   b'00000100'
        movwf   result_temp
        goto    Display_results

notflickerfail 
        movf    signal, w
        andlw   b'11111000'
        btfss   STATUS, Z
            goto    goodcandle
        incf    ledfail
        movlw   b'00000010'
        movwf   result_temp
        goto    Display_results

goodcandle    
        incf    pass
        movlw   b'00001000'
        movwf   result_temp

Display_results
        call Clear_Display
        BCD_DisplayS show_data
        call    Convert1
        call Switch_Lines
        Display     Trial
        movlw   B'11000010' ;move cursor to Pass
        call    WR_INS
        BCD_DisplayS pass
        movlw   B'11000110' ;move cursor to 46
        call    WR_INS
        BCD_DisplayS flickerfail
        movlw   B'11001010' ;move cursor to position 4A
        call    WR_INS
        BCD_DisplayS ledfail
        movlw   B'11001101' ;move crusor to 4E
        call    WR_INS
        BCD_DisplayS none
        return

results_access
         movlw   B'10000000' ;move cursor to Pass
         call    WR_INS
         Display PMenu
         call		HalfS    ;Wait until data is available from the keypad
         btfss		PORTB,1
         goto		results_access

         swapf		PORTB,W     ;Read PortB<7:4> into W<3:0>
         andlw		0x0F
         movwf      key_temp

lightone
         xorlw      D'0'
         btfss      STATUS, Z
            goto    lighttwo
         movf       light1, w
         movwf      result_temp
         call       Switch_Lines
         movlw      "1"
         call       WR_DATA
         movlw      ":"
         call       WR_DATA
         call       display
         call       HalfS
         call       Clear_Display
         goto       results_access

lighttwo
        movf key_temp, W
        xorlw       D'1'
        btfss       STATUS, Z
            goto    lightthree
        movf        light2, w
        movwf       result_temp
        call        Switch_Lines
        movlw       "2"
        call        WR_DATA
        movlw       ":"
        call        WR_DATA
        call        display
        call        HalfS
        call        Clear_Display
        goto        results_access

lightthree 
        movf key_temp, W
        xorlw       D'2'
        btfss       STATUS, Z
            goto    lightfour
        movf        light3, w
        movwf       result_temp
        call        Switch_Lines
        movlw       "3"
        call        WR_DATA
        movlw       ":"
        call        WR_DATA
        call        display
        call        HalfS
        call        Clear_Display
        goto        results_access

lightfour
        movf key_temp, W
        xorlw       D'4'
        btfss       STATUS, Z
            goto    lightfive
        movf        light4, w
        movwf       result_temp
        call        Switch_Lines
        movlw       "4"
        call        WR_DATA
        movlw       ":"
        call        WR_DATA
        call        display
        call        HalfS
        call        Clear_Display
        goto        results_access

lightfive
        movf key_temp, W
        xorlw       D'5'
        btfss       STATUS, Z
            goto    lightsix
        movf       light5, w
        movwf      result_temp
        call        Switch_Lines
        movlw      "5"
        call       WR_DATA
        movlw      ":"
        call       WR_DATA
        call       display
        call       HalfS
        call       Clear_Display
        goto       results_access

lightsix
        movf key_temp, W
        xorlw       D'6'
        btfss       STATUS, Z
            goto    lightseven
         movf       light6, w
         movwf      result_temp
         call Switch_Lines
         movlw      "6"
         call       WR_DATA
         movlw      ":"
         call       WR_DATA
         call       display
         call       HalfS
         call Clear_Display
         goto       results_access

lightseven
        movf key_temp, W
        xorlw       D'8'
        btfss       STATUS, Z
            goto    lighteight
         movf       light7, w
         movwf      result_temp
         call Switch_Lines
         movlw      "7"
         call       WR_DATA
         movlw      ":"
         call       WR_DATA
         call       display
         call       HalfS
         call Clear_Display
         goto       results_access

lighteight
        movf key_temp, W
        xorlw       D'9'
        btfss       STATUS, Z
            goto    lightnine
         movf       light8, w
         movwf      result_temp
         call Switch_Lines
         movlw      "8"
         call       WR_DATA
         movlw      ":"
         call       WR_DATA
         call       display
         call       HalfS
         call Clear_Display
         goto       results_access

lightnine
        movf key_temp, W
        xorlw       D'10'
        btfss       STATUS, Z
            goto    next
         movf       light9, w
         movwf      result_temp
         call Switch_Lines
         movlw      "9"
         call       WR_DATA
         movlw      ":"
         call       WR_DATA
         call       display
         call       HalfS
         call Clear_Display
         goto       results_access

next
         return


display
        btfss   result_temp, 0
            goto notnone
        movlw "N"
        call WR_DATA
        goto end_display

notnone
        btfss   result_temp, 1
            goto notlf
        movlw "L"
        call WR_DATA
        movlw "F"
        call WR_DATA
        goto end_display

notlf
        btfss   result_temp, 2
            goto notff
        movlw "F"
        call WR_DATA
        movlw "F"
        call WR_DATA
        goto end_display
notff
        movlw "P"
        call WR_DATA

end_display
        call HalfS
        return

pmenu_access
         call		HalfS    ;Wait until data is available from the keypad
         btfss		PORTB,1
         goto		pmenu_access

         swapf		PORTB,W     ;Read PortB<7:4> into W<3:0>
         andlw		0x0F
         movwf      key_temp
check_1
        xorlw D'0'
        btfss STATUS, Z
            goto check_2
        call Clear_Display
        movlw H'01'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        call Switch_Lines
        Display Trial
        movlw   B'11000010' ;move cursor to Pass
        call WR_INS
        call read_EE
        BCD_DisplayS DATAL
        movlw   B'11000110' ;move cursor to 46
        call WR_INS
        incf ADDRL
        call read_EE
        BCD_DisplayS DATAL
        movlw   B'11001010' ;move cursor to position 4A
        call WR_INS
        incf ADDRL
        call read_EE
        BCD_DisplayS DATAL
        movlw   B'11001101' ;move cursor to position 4A
        call WR_INS
        incf ADDRL
        call read_EE
        BCD_DisplayS DATAL
        ;letting ADDRL go back
        decf ADDRL
        decf ADDRL
        decf ADDRL
        call HalfS
        goto pmenu_access

check_2
        movf key_temp, W
        xorlw D'1'
        btfss STATUS, Z
            goto check_3
        call Clear_Display
        movlw H'02'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        call Switch_Lines
        Display Trial
        call HalfS
        goto pmenu_access

check_3
        movf key_temp, W
        xorlw D'2'
        btfss STATUS, Z
            goto check_4
        call Clear_Display
        movlw D'3'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        call Switch_Lines
        Display Trial
        call HalfS
        goto pmenu_access

check_4
        movf key_temp, W
        xorlw D'4'
        btfss STATUS, Z
            goto check_5
        call Clear_Display
        movlw H'04'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        call Switch_Lines
        Display Trial
        call HalfS
        goto pmenu_access

check_5
        movf key_temp, W
        xorlw D'5'
        btfss STATUS, Z
            goto check_6
        call Clear_Display
        movlw H'05'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        call Switch_Lines
        Display Trial
        call HalfS
        goto pmenu_access

check_6
        movf key_temp, W
        xorlw D'6'
        btfss STATUS, Z
            goto check_7
        call Clear_Display
        movlw H'06'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        call Switch_Lines
        Display Trial
        call HalfS
        goto pmenu_access

check_7
        movf key_temp, W
        xorlw D'8'
        btfss STATUS, Z
            goto check_8
        call Clear_Display
        movlw H'07'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        call Switch_Lines
        Display Trial
        call HalfS
        goto pmenu_access

check_8
        movf key_temp, W
        xorlw D'9'
        btfss STATUS, Z
            goto check_9
        call Clear_Display
        movlw H'08'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        call Switch_Lines
        Display Trial
        call HalfS
        goto pmenu_access

check_9
        movf key_temp, W
        xorlw D'10'
        btfss STATUS, Z
            goto continue
        call Clear_Display
        movlw H'09'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        call Switch_Lines
        Display Trial
        call HalfS
        goto pmenu_access

continue
        call Clear_Display
        return

wait
         call		HalfS    ;Wait until data is available from the keypad
         btfss		PORTB,1
         goto		wait
         return

show_RTC
		;clear LCD screen
		movlw	b'00000001'
		call	WR_INS

		;Get year
		movlw	"2"				;First line shows 20**/**/**
		call	WR_DATA
		movlw	"0"
		call	WR_DATA

		rtc_read	0x06		;Read Address 0x06 from DS1307---year
		movfw	0x77
		call	WR_DATA
		movfw	0x78
		call	WR_DATA

		movlw	"/"
		call	WR_DATA

		;Get month
		rtc_read	0x05		;Read Address 0x05 from DS1307---month
		movfw	0x77
		call	WR_DATA
		movfw	0x78
		call	WR_DATA

		movlw	"/"
		call	WR_DATA

		;Get day
		rtc_read	0x04		;Read Address 0x04 from DS1307---day
		movfw	0x77
		call	WR_DATA
		movfw	0x78
		call	WR_DATA

		movlw	B'11000000'		;Next line displays (hour):(min):(sec) **:**:**
		call	WR_INS

Refresh
        movlw B'11000000' ;move cursor to position H?4B?
        call WR_INS

		;Get hour
		rtc_read	0x02		;Read Address 0x02 from DS1307---hour
		movfw	0x77
		call	WR_DATA
		movfw	0x78
		call	WR_DATA
		movlw	":"
		call	WR_DATA
		;Get minute
		rtc_read	0x01		;Read Address 0x01 from DS1307---min
		movfw	0x77
		call	WR_DATA
		movfw	0x78
		call	WR_DATA
		movlw			":"
		call	WR_DATA

		;Get seconds
		rtc_read	0x00		;Read Address 0x00 from DS1307---seconds
		movfw	0x77
		call	WR_DATA
		movfw	0x78
		call	WR_DATA

		call	HalfS			;Delay for exactly one seconds and read DS1307 again
        call	HalfS    ;Wait until data is available from the keypad
        btfss	PORTB,1
            goto	Refresh
        return

Motor_On
    Display SW_ON
    movlw 0x01 ;turn motor on
    movwf PORTC
    call HalfS
    movlw 0x00 ;turn motor off
    movwf PORTC
    call Clear_Display
    return

Motor_Off
    Display SW_OFF
    movlw 0x02 ;turn motor on
    movwf PORTC
    call HalfS
    movlw 0x00 ;turn motor off
    movwf PORTC
    call Clear_Display
    return

HalfS
	local	HalfS_0
      movlw 0x88
      movwf COUNTH
      movlw 0xBD
      movwf COUNTM
      movlw 0x03
      movwf COUNTL

HalfS_0
      decfsz COUNTH, f
      goto   $+2
      decfsz COUNTM, f
      goto   $+2
      decfsz COUNTL, f
      goto   HalfS_0

      goto $+1
      nop
      nop
		return

WR_INS
	bcf		RS				;clear RS
	movwf	com				;W --> com
	andlw	0xF0			;mask 4 bits MSB w = X0
	movwf	PORTD			;Send 4 bits MSB
	bsf		E				;
	call	lcdLongDelay	;__    __
	bcf		E				;  |__|
	swapf	com,w
	andlw	0xF0			;1111 0010
	movwf	PORTD			;send 4 bits LSB
	bsf		E				;
	call	lcdLongDelay	;__    __
	bcf		E				;  |__|
	call	lcdLongDelay
	return

WR_DATA
	bsf		RS
	movwf	dat
	movf	dat,w
	andlw	0xF0
	addlw	4
	movwf	PORTD
	bsf		E				;
	call	lcdLongDelay	;__    __
	bcf		E				;  |__|
	swapf	dat,w
	andlw	0xF0
	addlw	4
	movwf	PORTD
	bsf		E				;
	call	lcdLongDelay	;__    __
	bcf		E				;  |__|
	return

Convert
    clrf run_temp
;save and restore
    movf runtime, w
    movwf run_temp
    movlw 8
    movwf count_temp
    clrf huns
    clrf tens
    clrf ones

BCDADD3

    movlw 5
    subwf huns, 0
    btfsc STATUS, C
    CALL ADD3HUNS

    movlw 5
    subwf tens, 0
    btfsc STATUS, C
    CALL ADD3TENS

    movlw 5
    subwf ones, 0
    btfsc STATUS, C
    CALL ADD3ONES

    decf count_temp, 1
    bcf STATUS, C
    rlf runtime, 1
    rlf ones, 1
    btfsc ones,4 ;
    CALL CARRYONES
    rlf tens, 1

    btfsc tens,4 ;
    CALL CARRYTENS
    rlf huns,1
    bcf STATUS, C

    movf count_temp, 0
    btfss STATUS, Z
    GOTO BCDADD3


    movf huns, 0 ; add ASCII Offset
    addlw h'30'
    call WR_DATA

    movf tens, 0 ; add ASCII Offset
    addlw h'30'
    call WR_DATA

    movf ones, 0 ; add ASCII Offset
    addlw h'30'
    call WR_DATA

    movf run_temp, w
    movwf runtime
    RETURN

ADD3HUNS
    movlw 3
    addwf huns,1
    RETURN

ADD3TENS
    movlw 3
    addwf tens,1
    RETURN

ADD3ONES
    movlw 3
    addwf ones,1
    RETURN

CARRYONES
    bcf ones, 4
    bsf STATUS, C
    RETURN

CARRYTENS
    bcf tens, 4
    bsf STATUS, C
    RETURN

Convert1
    clrf run_temp
;save and restore
    movf signal, w
    movwf run_temp
    movlw 8
    movwf count_temp
    clrf huns
    clrf tens
    clrf ones

BCDADD31

    movlw 5
    subwf huns, 0
    btfsc STATUS, C
    CALL ADD3HUNS1

    movlw 5
    subwf tens, 0
    btfsc STATUS, C
    CALL ADD3TENS1

    movlw 5
    subwf ones, 0
    btfsc STATUS, C
    CALL ADD3ONES1

    decf count_temp, 1
    bcf STATUS, C
    rlf signal, 1
    rlf ones, 1
    btfsc ones,4 ;
    CALL CARRYONES1
    rlf tens, 1

    btfsc tens,4 ;
    CALL CARRYTENS1
    rlf huns,1
    bcf STATUS, C

    movf count_temp, 0
    btfss STATUS, Z
    GOTO BCDADD31


    movf huns, 0 ; add ASCII Offset
    addlw h'30'
    call WR_DATA

    movf tens, 0 ; add ASCII Offset
    addlw h'30'
    call WR_DATA

    movf ones, 0 ; add ASCII Offset
    addlw h'30'
    call WR_DATA

    movf run_temp, w
    movwf signal
    RETURN

ADD3HUNS1
    movlw 3
    addwf huns,1
    RETURN

ADD3TENS1
    movlw 3
    addwf tens,1
    RETURN

ADD3ONES1
    movlw 3
    addwf ones,1
    RETURN

CARRYONES1
    bcf ones, 4
    bsf STATUS, C
    RETURN

CARRYTENS1
    bcf tens, 4
    bsf STATUS, C
    RETURN

lcdLongDelay
    movlw d'20'
    movwf lcd_d2
LLD_LOOP
    LCD_DELAY
    decfsz lcd_d2,f
    goto LLD_LOOP
    return


ISR
        ;saving registers
        movwf w_temp
        movf STATUS, w
        movwf status_temp

Timer
        bcf     INTCON, 2
        decfsz  timercount, f
            goto    addsignal
        incf    runtime, f
        movlw   D'38'
        movwf   timercount
        goto    finish

addsignal
        banksel PORTB
        btfss   PORTB, 0
            goto    finish
        incf    signal

finish
        movf status_temp, w
        movwf STATUS
        swapf w_temp, f
        swapf w_temp, w
        retfie

write_EE
;write to EEPROM
    banksel ADDRL
    movf    ADDRL, W ; write address of desired program memory location
    banksel EEADR
    movwf   EEADR
;    movf    ADDRH, W
;    movwf   EEADRH
    banksel VALUEL
    movf    VALUEL, W ; write value to program at desired memory locqation
    banksel EEDATA
    movwf   EEDATA
;    movf    VALUEH, W
;    movwf   EEDATH

    bsf     STATUS, RP0
    bsf     EECON1, EEPGD
    bsf     EECON1, WREN
    bcf     INTCON, GIE

    movlw   0x55
    movwf   EECON2
    movlw   0xaa
    movwf   EECON2 ;
    bsf     EECON1, WR ; start write operation
    nop ;wait for micro
    nop

    bsf    INTCON, GIE ;re-enable interrupts
    bcf    EECON1, WREN ;disables writes
    bcf    STATUS, RP0
    bcf    STATUS, RP1 
    return

read_EE
    banksel ADDRL
    movf   ADDRL, W
    banksel EEADR
    movwf   EEADR
 ;   banksel ADDRH
 ;   movf    ADDRH, W
 ;   banksel EEADRH
 ;   movwf   EEADRH
    banksel EECON1
    bsf     EECON1, EEPGD
    bsf     EECON1, RD
    nop
    nop
    bcf     STATUS, RP0
    movf    EEDATA, W
    banksel DATAL
    movwf   DATAL
  ;  banksel EEDATH
   ; movf    EEDATH, W
   ; banksel DATAH
   ; movwf   DATAH
    bcf     STATUS, RP0
    bcf     STATUS, RP1
    return
END
