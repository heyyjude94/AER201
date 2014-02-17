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
		COUNTH ;0x70
		COUNTM ;0x71
		COUNTL ;0x72
		Table_Counter ;0x73
		lcd_tmp ;0x74
        key_temp ;0x75
        test ;0x76
        rtc1 ;0x77
        rtc2
        com
        dat
        lcd_d1
        lcd_d2
        bcd
        count
        show_data
        w_temp
        status_temp
        pass
        flickerfail
        ledfail
        runtime
        timercount
        ones
        tens
        huns
        count_temp
        run_temp

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
         clrf      TRISA          ; All port A is output
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



;MAIN PROGRAM
;***************************************
Main	Display		Welcome_Msg
        call        HalfS
        call        HalfS
        call        HalfS
        Clear_Display

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

RTC2
		addwf	PCL,F
		dt		":", 0

Trial
        addwf   PCL, F
        dt      "P:  FF:  LF: ", 0



;***************************************
; Helper Subrountines
;***************************************
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
    bsf    INTCON, 5
    Clear_Display
    Display Run
    call    HalfS
    Clear_Display
    call    Motor_On
    call    count_down
    Clear_Display
    call    Motor_Off
    bcf    INTCON, 5
    Display Done
    Switch_Lines
    Display Runtime 
    call Convert
    call    wait
    clrf    runtime
    Clear_Display
    return

check_B
    movf key_temp, W
    xorlw D'7'
    btfss STATUS, Z
        goto check_C
    Clear_Display
    Display PMem
    Switch_Lines
    Display PMenu
    call HalfS
    call pmenu_access
    call HalfS
    Clear_Display
    return

check_C
    movf key_temp, W
    xorlw D'11'
    btfss STATUS, Z
        goto Other_wise
    Clear_Display
    call show_RTC
    Clear_Display
    return

Other_wise
    Clear_Display
    return


count_down
        movlw D'9'
        movwf count
        movlw H'00'
        movwf show_data
        clrf pass
        clrf flickerfail
        clrf ledfail

count_loop
        incf show_data
        BCD_DisplayS show_data
        Switch_Lines
        Display Trial
        movlw B'11000010' ;move cursor to Pass
        call WR_INS
        incf pass
        BCD_DisplayS pass
        movlw B'11000111' ;move cursor to 47
        call WR_INS
        BCD_DisplayS flickerfail
        movlw B'11001100' ;move cursor to position H?4C?
        call WR_INS
        BCD_DisplayS ledfail
        call HalfS
        Clear_Display
        decfsz  count, F
        goto count_loop
        return

pmenu_access
         call		HalfS    ;Wait until data is available from the keypad
         btfss		PORTB,1
         goto		pmenu_access

         swapf		PORTB,W     ;Read PortB<7:4> into W<3:0>
         andlw		0x0F
         movwf key_temp
check_1
        xorlw D'0'
        btfss STATUS, Z
            goto check_2
        Clear_Display
        movlw H'01'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        Switch_Lines
        Display Trial
        call wait
        return

check_2
        movf key_temp, W
        xorlw D'1'
        btfss STATUS, Z
            goto check_3
        Clear_Display
        movlw H'02'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        Switch_Lines
        Display Trial
        call wait
        return

check_3
        movf key_temp, W
        xorlw D'2'
        btfss STATUS, Z
            goto check_4
        Clear_Display
        movlw D'3'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        Switch_Lines
        Display Trial
        call wait
        return

check_4
        movf key_temp, W
        xorlw D'4'
        btfss STATUS, Z
            goto check_5
        Clear_Display
        movlw H'04'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        Switch_Lines
        Display Trial
        call wait
        return

check_5
        movf key_temp, W
        xorlw D'5'
        btfss STATUS, Z
            goto check_6
        Clear_Display
        movlw H'05'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        Switch_Lines
        Display Trial
        call wait
        return

check_6
        movf key_temp, W
        xorlw D'6'
        btfss STATUS, Z
            goto check_7
        Clear_Display
        movlw H'06'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        Switch_Lines
        Display Trial
        call wait
        return

check_7
        movf key_temp, W
        xorlw D'8'
        btfss STATUS, Z
            goto check_8
        Clear_Display
        movlw H'07'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        Switch_Lines
        Display Trial
        call wait
        return

check_8
        movf key_temp, W
        xorlw D'9'
        btfss STATUS, Z
            goto check_9
        Clear_Display
        movlw H'08'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        Switch_Lines
        Display Trial
        call wait
        return

check_9
        movf key_temp, W
        xorlw D'10'
        btfss STATUS, Z
            goto continue
        Clear_Display
        movlw H'09'
        movwf lcd_tmp
        BCD_Display lcd_tmp
        Switch_Lines
        Display Trial
        call wait
        return

continue
        Clear_Display
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
    Clear_Display
    return

Motor_Off
    Display SW_OFF
    movlw 0x02 ;turn motor on
    movwf PORTC
    call HalfS
    movlw 0x00 ;turn motor off
    movwf PORTC
    Clear_Display
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
        bcf INTCON, 2
        decfsz  timercount, f
            goto finish
        incf runtime, f
        movlw D'38'
        movwf timercount


finish
        movf status_temp, w
        movwf STATUS
        swapf w_temp, f
        swapf w_temp, w
        retfie

END
