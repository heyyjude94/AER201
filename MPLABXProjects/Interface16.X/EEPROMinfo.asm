    ;shift 8 to 9
    banksel DATAL
    movlw   0x2c
    movwf   ADDRL
    call    read_EE
    movlw   0x30
    movwf   ADDRL
    call    write_EES

    movlw   0x2d
    movwf   ADDRL
    call    read_EE
    movlw   0x31
    movwf   ADDRL
    call    write_EES

    movlw   0x2e
    movwf   ADDRL
    call    read_EE
    movlw   0x32
    movwf   ADDRL
    call    write_EES

    movlw   0x2f
    movwf   ADDRL
    call    read_EE
    movlw   0x33
    movwf   ADDRL
    call    write_EES

        ;shift 7 to 8
    banksel DATAL
    movlw   0x28
    movwf   ADDRL
    call    read_EE
    movlw   0x2c
    movwf   ADDRL
    call    write_EES

    movlw   0x29
    movwf   ADDRL
    call    read_EE
    movlw   0x2d
    movwf   ADDRL
    call    write_EES

    movlw   0x2a
    movwf   ADDRL
    call    read_EE
    movlw   0x2e
    movwf   ADDRL
    call    write_EES

    movlw   0x2b
    movwf   ADDRL
    call    read_EE
    movlw   0x2f
    movwf   ADDRL
    call    write_EES

    ;shift 6 to 7
    banksel DATAL
    movlw   0x24
    movwf   ADDRL
    call    read_EE
    movlw   0x28
    movwf   ADDRL
    call    write_EES

    movlw   0x25
    movwf   ADDRL
    call    read_EE
    movlw   0x29
    movwf   ADDRL
    call    write_EES

    movlw   0x26
    movwf   ADDRL
    call    read_EE
    movlw   0x2a
    movwf   ADDRL
    call    write_EES

    movlw   0x27
    movwf   ADDRL
    call    read_EE
    movlw   0x2b
    movwf   ADDRL
    call    write_EES

    ;shift 5 to 6
    banksel DATAL
    movlw   0x20
    movwf   ADDRL
    call    read_EE
    movlw   0x24
    movwf   ADDRL
    call    write_EES

    movlw   0x21
    movwf   ADDRL
    call    read_EE
    movlw   0x25
    movwf   ADDRL
    call    write_EES

    movlw   0x22
    movwf   ADDRL
    call    read_EE
    movlw   0x26
    movwf   ADDRL
    call    write_EES

    movlw   0x23
    movwf   ADDRL
    call    read_EE
    movlw   0x27
    movwf   ADDRL
    call    write_EES

    ;shift 4 to 5
    banksel DATAL
    movlw   0x1c
    movwf   ADDRL
    call    read_EE
    movlw   0x20
    movwf   ADDRL
    call    write_EES

    movlw   0x1d
    movwf   ADDRL
    call    read_EE
    movlw   0x21
    movwf   ADDRL
    call    write_EES

    movlw   0x1e
    movwf   ADDRL
    call    read_EE
    movlw   0x22
    movwf   ADDRL
    call    write_EES

    movlw   0x1f
    movwf   ADDRL
    call    read_EE
    movlw   0x23
    movwf   ADDRL
    call    write_EES

    ;shift 3 to 4
    banksel DATAL
    movlw   0x18
    movwf   ADDRL
    call    read_EE
    movlw   0x1c
    movwf   ADDRL
    call    write_EES

    movlw   0x19
    movwf   ADDRL
    call    read_EE
    movlw   0x1d
    movwf   ADDRL
    call    write_EES

    movlw   0x1a
    movwf   ADDRL
    call    read_EE
    movlw   0x1e
    movwf   ADDRL
    call    write_EES

    movlw   0x1b
    movwf   ADDRL
    call    read_EE
    movlw   0x1f
    movwf   ADDRL
    call    write_EES

    ;shift 2 to 3
    banksel DATAL
    movlw   0x14
    movwf   ADDRL
    call    read_EE
    movlw   0x18
    movwf   ADDRL
    call    write_EES

    movlw   0x15
    movwf   ADDRL
    call    read_EE
    movlw   0x19
    movwf   ADDRL
    call    write_EES

    movlw   0x16
    movwf   ADDRL
    call    read_EE
    movlw   0x1a
    movwf   ADDRL
    call    write_EES

    movlw   0x17
    movwf   ADDRL
    call    read_EE
    movlw   0x1b
    movwf   ADDRL
    call    write_EES

    ;shift 1 to 2
    banksel DATAL
    movlw   0x10
    movwf   ADDRL
    call    read_EE
    movlw   0x14
    movwf   ADDRL
    call    write_EES

    movlw   0x11
    movwf   ADDRL
    call    read_EE
    movlw   0x15
    movwf   ADDRL
    call    write_EES

    movlw   0x12
    movwf   ADDRL
    call    read_EE
    movlw   0x16
    movwf   ADDRL
    call    write_EES

    movlw   0x13
    movwf   ADDRL
    call    read_EE
    movlw   0x17
    movwf   ADDRL
    call    write_EES

    return

pc_init bsf       STATUS,RP0     ; select bank 1
        clrf      TRISD

        ;Setup USART for RS232
        movlw     d'15'          ; BAUD rate 9600, assuming 10MHz oscillator
        movwf     SPBRG
        clrf      TXSTA          ; 8 bits data ,no,1 stop

        bcf       STATUS,RP0     ; select bank 0
        bsf       RCSTA,SPEN     ; Asynchronous serial port enable
        bsf       RCSTA,CREN     ; continuous receive

        bsf       STATUS,RP0     ; select bank 1
        bsf       TXSTA,TXEN     ; Transmit enable
        bcf       STATUS,RP0     ; select bank 0

        return
