;***************************************************************************
;  PROGRAM:     SIODriver
;  PURPOSE:     Subroutines for a Z80 SIO
;  LICENCE:     The MIT Licence
;  AUTHOR:      Lubomir Rintel <lkundrak@v3.sk>, based on UARTDriver
;  CREATE DATE: 2022-11-27
;***************************************************************************

;***************************************************************************
; Initialize
;***************************************************************************

UART_INIT:
        ; Initialize the CTC timer first
        LD      C, TIMER_BASE + 3
        LD      A, 0B6h
        OUT     (C), A
        DEC     C
        LD      A, TIMER_BASE + 1
        OUT     (C), A
        XOR     A
        OUT     (C), A

        ; Initialize the SIO
        LD      HL, SIO_INIT
        LD      C, UART_BASE + 1
        LD      B, E_SIO_INIT - SIO_INIT
        OTIR
        RET

SIO_INIT:
        ;       WRx     Value
        DEFB    0,      00011000b       ; Command 3: Reset
        DEFB    1,      00011101b       ; Interrupts on all receive
        DEFB    3,      11000000b       ; RX 8 bits
        DEFB    4,      01000100b       ; Clock x16, 8/1/n
        DEFB    5,      11101010b       ; DTR, RTS, TX enable
        DEFB    3,      11000000b       ; RX 8 bits, RX enable
        DEFB    5,      11101010b       ; DTR, RTS, TX enable
        DEFB    1,      00011101b       ; Interrupts on all receive
E_SIO_INIT:

;***************************************************************************
; Transmit
;***************************************************************************

UART_TX_RDY:
        XOR     A
        OUT     (UART_BASE + 1), A      ; WR0
        IN      A, (UART_BASE + 1)
        AND     004h
        JR      Z, UART_TX_RDY
        RET

UART_TX:
        PUSH    AF
        CALL    UART_TX_RDY
        POP     AF
        OUT     (UART_BASE), A
        RET

;***************************************************************************
; Receive
;***************************************************************************

UART_RX_RDY:
        XOR     A
        OUT     (UART_BASE + 1), A      ; WR0
        IN      A, (UART_BASE + 1)
        AND     001h
        JR      Z, UART_RX_RDY
        RET

UART_RX:
        CALL    UART_RX_RDY
        IN      A, (UART_BASE)
        RET

;***************************************************************************
; Copied from elsewhere
;***************************************************************************

XOFF:   EQU     013h

;***************************************************************************
;UART_PRNT_STR:
;Function: Print out string starting at MEM location (HL) to Z80 DART
;***************************************************************************
UART_PRNT_STR:
        PUSH    AF
UARTPRNTSTRLP:
        LD      A,(HL)
        CP      EOS                                     ;Test for end byte
        JP      Z,UART_END_PRNT_STR     ;Jump if end byte is found
        CALL    UART_TX
        INC     HL                                      ;Increment pointer to next char
        JP      UARTPRNTSTRLP       ;Transmit loop
UART_END_PRNT_STR:
        POP     AF
        RET
