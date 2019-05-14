.cpu "65816"
.include "Floppy_def.asm"

FLOPPY_CMD_BUFFER = $1A000 ; 10 Byte buffer for the command to be send to the FDC and the the data recieved as e result of the command
* = $1A00A
ILOOP           NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                RTL

ILOOP_1         JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                JSL ILOOP
                RTL

ILOOP_1MS       JSL ILOOP_1
                RTL

ILOOP_MS        CPX #0
                BEQ LOOP_MS_END
                JSL ILOOP_1MS
                DEX
                BRA ILOOP_MS
LOOP_MS_END     RTL
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
IFDD_MOTOR_0_ON   setas
                setdbr `FDD_DIGITAL_OUTPUT  ; Set Data Bank Register
                LDA #FDD_ENABLE_MOTOR_0
                TSB FDD_DIGITAL_OUTPUT
                RTL

IFDD_MOTOR_0_OFF  setas
                setdbr `FDD_DIGITAL_OUTPUT  ; Set Data Bank Register
                LDA #FDD_ENABLE_MOTOR_0
                TRB FDD_DIGITAL_OUTPUT
                RTL
; Motor 1 wont work for now
;IFDD_MOTOR_1_ON   setas
;                setdbr `FDD_DIGITAL_OUTPUT  ; Set Data Bank Register
;                LDA #FDD_ENABLE_MOTOR_1
;                TSB FDD_DIGITAL_OUTPUT
;                RTL
;
;IFDD_MOTOR_1_OFF  setas
;                setdbr `FDD_DIGITAL_OUTPUT  ; Set Data Bank Register
;                LDA #FDD_ENABLE_MOTOR_1
;                TRB FDD_DIGITAL_OUTPUT
;                RTL

IFDD_MOTOR_ALL_OFF  setas
                setdbr `FDD_DIGITAL_OUTPUT  ; Set Data Bank Register
                LDA #FDD_ENABLE_MOTOR_0
                TRB FDD_DIGITAL_OUTPUT
                LDA #FDD_ENABLE_MOTOR_1
                TRB FDD_DIGITAL_OUTPUT
                RTL
;-------------------------------------------------------------------------------

IFDD_READ_FDD
                setas
                STA FLOPPY_CMD_BUFFER     ; command code 0 : MT MFM SK  0 0 1   1   0
                LDA X                     ; command code 1 : 0  0   0   0 0 HDS DS1 DS2
                AND #7
                STA FLOPPY_CMD_BUFFER+1
                LDA 0                     ; C : Cylinder Address
                STA FLOPPY_CMD_BUFFER+2
                LDA 0                     ; H : Head Address
                STA FLOPPY_CMD_BUFFER+3
                LDA 0                     ; R : Sector Address
                STA FLOPPY_CMD_BUFFER+4
                LDA 2                     ; N : Sector Size Code 0=>128 / 1=>256 / 2=>512
                STA FLOPPY_CMD_BUFFER+5
                LDA 1                     ; EOT : End of Track
                STA FLOPPY_CMD_BUFFER+6
                LDA 0                     ; GPL : Gap Length
                STA FLOPPY_CMD_BUFFER+7
                LDA 2                     ; DTL : Special Sector Size Determin the number of byte to read / 2=>512 ???
                STA FLOPPY_CMD_BUFFER+8
                LDA #9                    ; number of command Bytes
                JSL IFDD_SEND_CMD
                RTL

;-------------------------------------------------------------------------------
;
; setaxl
; LDA #`DESTINATION_BUFFER ; load the byte nb 3 (bank byte)
; PHA
; LDA #<>DESTINATION_BUFFER ; load the low world part of the buffer address
; PHA
; LDA $0 ; read sector 0
; JSL IFDD_READ ;
;
;
;-------------------------------------------------------------------------------

IFDD_INIT_AT    setaxl
                JSL IFDD_RESET_FULL         ; Reset FDD : No DMA, Drive 0 selected, no motor activated
                setdbr `FDD_CONFIG_CTRL  ; Set Data Bank Register
                LDA #$02
                TSB FDD_CONFIG_CTRL
                setdbr `FDD_DATA_RATE_SELECT  ; Set Data Bank Register
                LDA #$00
                TSB FDD_DATA_RATE_SELECT
                setdbr `FDD_DIGITAL_OUTPUT  ; Set Data Bank Register
                LDA #$F0                    ; active all motor output and sellect drive 0 (bit 0-1)
                TSB FDD_DIGITAL_OUTPUT      ; Set the reset bit to exit the reset mode  "Test and Reset Memory Bits Against Accumulator"
                RTL
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
IFDD_RESET      setdbr `FDD_DIGITAL_OUTPUT  ; Set Data Bank Register
                LDA #FDD_nRESET             ; reset the floppy disc controler, deactive all the motors and the DMA
                TRB FDD_DIGITAL_OUTPUT      ; Clear the reset bit to go in reset mode "Test and Reset Memory Bits Against Accumulator"
                JSL ILOOP_1
                ; reset the DATA_RATE_SELECT register : automatic low Power, Pres Comp => Default See tab 10 in FDC doc, Data Rate to 250 Kbps
                setdbr `FDD_DATA_RATE_SELECT
                LDA #2
                STA FDD_DATA_RATE_SELECT    ; if in mode PC/AT or PS/2 the datarate is set in Config Control Register
                JSL ILOOP_1MS
                setdbr `FDD_CONFIG_CTRL
                LDA #2
                STA FDD_CONFIG_CTRL
                ; exit the reset mode
                setdbr `FDD_DIGITAL_OUTPUT
                LDA #FDD_nRESET             ; Load the reset bit to be set
                TSB FDD_DIGITAL_OUTPUT      ; Set the reset bit to exit the reset mode  "Test and Reset Memory Bits Against Accumulator"
                RTL
;-------------------------------------------------------------------------------
IFDD_RESET_FULL setas
                LDA #0                      ; Will set all the bit at 0 to reset everyting
                setdbr `FDD_DIGITAL_OUTPUT
                STA  FDD_DIGITAL_OUTPUT
                NOP                         ; wait, the doc say 100ns min
                NOP
                JSL ILOOP_1
                NOP
                setas
                LDA #FDD_nRESET
                setdbr `FDD_DIGITAL_OUTPUT
                STA FDD_DIGITAL_OUTPUT      ; Set the reset bit to exit the reset mode
                RTL
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
IFDD_READ       setaxl
                PHA ; save the sector to read
                LDA 8,S
                TAY
                LDA 6,S
                TAY
                PLA
                PHA ; save the sector read for the return value
                ASL A ; convert the sector number into byte count
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A

                ADC #<>data_floppy
                TAX

                ;LDX #<>data_floppy
                ; LDY #<>FAT12_ADDRESS_BUFFER_512
                setas
                LDA 8,S
                STA FFD_MVN_INSTRUCTION_ADDRESS + 2 ; rewrite the second parameter of the instruction in RAM
                setaxl
                LDA #511
FFD_MVN_INSTRUCTION_ADDRESS  MVN `FAT12_ADDRESS_BUFFER_512,`data_floppy
                PLA
                RTL

IFDD_READ_ORI   setaxl
                PHA
                LDA 8,S
                TAX
                LDA 6,S
                TAY
                PLA
                PHA ; save the sector read for the return value
                ASL A ; convert the sector number into byte count
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A
                ASL A

                ADC #<>data_floppy
                TAX
                LDA #511
                ;LDX #<>data_floppy
                LDY #<>FAT12_ADDRESS_BUFFER_512
                MVN `FAT12_ADDRESS_BUFFER_512,`data_floppy
                PLA
                RTL
IFDD_WRITE      BRK
IFDD_SETSECTOR  BRK
IFDD_SETTRACK  BRK
IFDD_SETSIDE    BRK
;-------------------------------------------------------------------------------
; Reg A contain the Floppy driver to recalibrate, bring the hrad to the track 0
; by sensing the track0 pin of the FDD
;-------------------------------------------------------------------------------
IFDD_RECALIBRATE
                setas
                AND #3                    ; just get the 2 first bit
                STA FLOPPY_CMD_BUFFER+1
                LDA #7
                STA FLOPPY_CMD_BUFFER
                LDA #2                    ; number of command Bytes
                JSL IFDD_SEND_CMD
                CMP #0
                BMI IFDD_RECALIBRATE_ERROR_SEND_CMD
                LDA #1
                BRA IFDD_RECALIBRATE_DONE
IFDD_RECALIBRATE_ERROR_SEND_CMD
                LDA #-1
                BRA IFDD_RECALIBRATE_ERROR
IFDD_RECALIBRATE_ERROR
IFDD_RECALIBRATE_DONE
                RTL

;-------------------------------------------------------------------------------
; Bring the head at the cylinder selected by X
; Reg X contain cylinder to reach
; Reg A contain the Floppy driver to work with
;-------------------------------------------------------------------------------
IFDD_SEEK       setas
                AND #7                    ; Get the 3 first bit side (2) and driver (1-0)
                STA FLOPPY_CMD_BUFFER+1
                LDA #$F
                STA FLOPPY_CMD_BUFFER
                LDA X                     ; Get the cylinder index
                STA FLOPPY_CMD_BUFFER+2
                LDA #3                    ; number of command Bytes
                JSL IFDD_SEND_CMD
                CMP #0
                BMI IFDD_SEEK_ERROR_SEND_CMD
                LDA #1
                BRA IFDD_SEEK_DONE
IFDD_SEEK_ERROR_SEND_CMD
                LDA #-1
IFDD_SEEK_DONE
                RTL
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
IFDD_SEEKRELATIF BRK

;-------------------------------------------------------------------------------
; Bring the head at the cylinder selected by X
; Reg X contain cylinder to reach
; Reg A contain the Floppy driver to work with
;-------------------------------------------------------------------------------
IFDD_GET_DRIVE_STATUS
                setas
                AND #7                    ; Get the 3 first bit HDS (2) and driver (1-0)
                STA FLOPPY_CMD_BUFFER+1
                LDA #$4
                STA FLOPPY_CMD_BUFFER
                LDA X                     ; Get the cylinder index
                STA FLOPPY_CMD_BUFFER+2
                LDA #2                    ; number of command Bytes
                JSL IFDD_SEND_CMD
                CMP #0
                BMI IFDD_DRIVE_STATUS_ERROR_READ_CMD
                setas
                LDA #1                    ; number of Bytes to read
                JSL IFDD_READ_CMD_RESULT
                CMP #0
                BMI IFDD_DRIVE_STATUS_ERROR_READ_CMD
                LDA #1
                BRA IFDD_DRIVE_STATUS_DONE
IFDD_DRIVE_STATUS_ERROR_READ_CMD
                LDA #-1
IFDD_DRIVE_STATUS_DONE
                RTL
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
; Reg A contain the number of data to send to the Floppy Disc Controler
; The data are in FLOPPY_CMD_BUFFER at address $1A000
; The result is also places in FLOPPY_CMD_BUFFER, the command is over writen
;-------------------------------------------------------------------------------
IFDD_SEND_CMD   PHA                       ; save the number of byt to be sent to the FDC
                PHA                       ; alocate space on the stack to save the main statur value
                setdbr `FDD_MAIN_STATUE
IFDD_SEND_CMD_READ_MAIN_STATUS_REG
                LDA FDD_MAIN_STATUE       ; read bit 6 and 7 to see if we cal sent data to the FDD_CMD_BUSSY
                STA #1, S                 ; Save the Maine Status value
                AND #FDD_RQM                  ; get RQM bit
                CMP #$80                  ; if == 1 we can read or write data from the FIFO,depending on the DIO bit value
                BEQ IFDD_SEND_CMD_TRANSFERT_CAN_BE_DONE ;
                NOP
                NOP
                NOP
                BRA IFDD_SEND_CMD_READ_MAIN_STATUS_REG  ; Try to read the Main register again until it get the right value (will need e timout at some point)
                ;------------ the FDC is now avaliable for transfert -----------
IFDD_SEND_CMD_TRANSFERT_CAN_BE_DONE
                LDA #1, S                 ; get the Main Status avlue
                AND #FDD_DIO                  ; get DIO bit
                CMP #$40                  ; if == 0 we can write data into the FIFO, if == 1 we need to read data
                BNE IFDD_SEND_CMD_READDY_TO_SEND_DATA;
                LDA FDD_FIFO                      ; remove the Main Status value saved
                BRA IFDD_SEND_CMD_READ_MAIN_STATUS_REG  ; retest if we can send data now#
                ;--------------- the FDC can now recuive command ---------------
IFDD_SEND_CMD_READDY_TO_SEND_DATA
                PLA                       ; remove the Main Status value saved
                ;------------------------------
                setdbr `Text_Start_Tx_CMD
                LDX #<>Text_Start_Tx_CMD
                JSL UART_PUTS
                setdbr `FDD_MAIN_STATUE
                LDA #1, S
                JSL UART_PUTHEX
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                ;------------------------------
                LDX #0
SEND_NEXT_DATA  LDA X
                CMP #1, S                 ; Test if we sent all the data ot not
                BEQ ALL_DATA_SENT
                LDA FLOPPY_CMD_BUFFER,X
                STA FDD_FIFO              ; Write the data in the FDC's FIFO
                INX
                PHX
                JSL ILOOP_1MS
                JSL IFDD_PRINT_FDD_MS_REG
                PLX
                setas
                setdbr `FDD_MAIN_STATUE   ; assume the FDC will never ask to read data while we are sendin the command
READ_MAIN_STATUS_REG_FOR_TRANSFERT
                LDA FDD_MAIN_STATUE       ; read bit 6 and 7 to see if we cal sent data to the FDD_CMD_BUSSY
                AND #FDD_RQM                  ; get RQM bit
                CMP #$80                  ; if == 1 we can read or write data from the FIFO,depending on the DIO bit value
                BEQ SEND_NEXT_DATA
                NOP
                NOP
                NOP
                BRA READ_MAIN_STATUS_REG_FOR_TRANSFERT  ; Try to read the Main register again until it get the right value (will need e timout at some point)
                ;------ The command is sent now we need to read the result -----
                ;------ so west the dqta avaliable bit                     -----
ALL_DATA_SENT
                PLA                       ; removing the number of commands byte to send
                setdbr `Text_Stop_Tx_CMD
                LDX #<>Text_Stop_Tx_CMD
                JSL UART_PUTS
IFDD_SEND_CMD_RETURN_ERROR
                LDA #0
                RTL
;-------------------------------------------------------------------------------
; Reg A contain the number of data to read from the Floppy Disc Controler
; The data will be stored in FLOPPY_CMD_BUFFER at address $1A000
;-------------------------------------------------------------------------------
IFDD_READ_CMD_RESULT
                setdbr `FDD_MAIN_STATUE
                PHA                       ; save the number of byt to be sent to the FDC
                PHA                       ; alocate space on the stack to save the main statur value
IFDD_READ_CMD_RESULT_READ_MAIN_STATUS_REG
                LDA FDD_MAIN_STATUE       ; read bit 6 and 7 to see if we cal sent data to the FDD_CMD_BUSSY
                STA #1, S                 ; Save the Maine Status value
                AND #FDD_RQM                  ; get RQM bit
                CMP #$80                  ; if == 1 we can read or write data from the FIFO,depending on the DIO bit value
                BEQ IFDD_READ_CMD_TRANSFERT_CAN_BE_DONE ;
                NOP
                NOP
                NOP
                BRA IFDD_READ_CMD_RESULT_READ_MAIN_STATUS_REG  ; Try to read the Main register again until it get the right value (will need e timout at some point)
                ;------------ the FDC is now avaliable for transfert -----------
IFDD_READ_CMD_TRANSFERT_CAN_BE_DONE
                LDA FDD_MAIN_STATUE
                AND #FDD_DIO              ; get DIO bit
                CMP #$40                  ; if == 0 we can write data into the FIFO, if == 1 we need to read data
                BEQ READDY_TO_READ_DATA   ; We want to read the result of the command
                PLA
                LDA #-1                    ; error, the FDC after reciving the commans is suppos to sent you data
                BRA IFDD_READ_CMD_RESULT_RETURN_ERROR
READDY_TO_READ_DATA
                PLA
                ;------------------------------
                setdbr `Text_Start_Rx_CMD
                LDX #<>Text_Start_Rx_CMD
                JSL UART_PUTS
                setdbr `FDD_MAIN_STATUE
                LDA #1, S
                JSL UART_PUTHEX
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                ;------------------------------
                LDX #0
READ_NEXT_DATA  LDA X
                CMP #1, S                 ; Test if we read all the data ot not
                BPL ALL_DATA_READ
                LDA FDD_FIFO              ; Read the data from the FDC's FIFO
                STA FLOPPY_CMD_BUFFER,X   ; Save it in the Buffer
                INX
                PHX
                JSL ILOOP_1MS
                JSL IFDD_PRINT_FDD_MS_REG
                PLX
                setdbr `FDD_MAIN_STATUE   ; assume the FDC will never ask to read data while we are sendin the command
READ_MAIN_STATUS_REG_FOR_TRANSFERT_2
                LDA FDD_MAIN_STATUE       ; read bit 6 and 7 to see if we cal sent data to the FDD_CMD_BUSSY
                AND #FDD_RQM                  ; get RQM bit
                CMP #$80                  ; if == 1 we can read or write data from the FIFO,depending on the DIO bit value
                BEQ READ_NEXT_DATA
                NOP
                NOP
                NOP
                BRA READ_MAIN_STATUS_REG_FOR_TRANSFERT_2  ; Try to read the Main register again until it get the right value (will need e timout at some point)
ALL_DATA_READ
                LDA #0
IFDD_READ_CMD_RESULT_RETURN_ERROR
                PLA
                setdbr `Text_Stop_Rx_CMD
                LDX #<>Text_Stop_Rx_CMD
                JSL UART_PUTS
                RTL


;-------------------------------------------------------------------------------
; Print on the terminal the value of the Main Status Register from the FDD
;-------------------------------------------------------------------------------
IFDD_PRINT_FDD_MS_REG
                setdbr `Text_FDD_MAIN_STATUE
                LDX #<>Text_FDD_MAIN_STATUE
                JSL UART_PUTS
                setdbr `FDD_MAIN_STATUE
                LDA FDD_MAIN_STATUE
                JSL UART_PUTHEX
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                LDA #$A
                ;---------------
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                RTL
;-------------------------------------------------------------------------------
; Print on the terminal the value of all the readeble register from the FDD
;-------------------------------------------------------------------------------
IFDD_PRINT_REG  setas
                setdbr `Text_FDD_STATUS_A
                LDX #<>Text_FDD_STATUS_A
                JSL UART_PUTS
                setdbr `FDD_STATUS_A
                LDA FDD_STATUS_A
                JSL UART_PUTHEX
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                ;---------------
                setdbr `Text_FDD_STATUS_B
                LDX #<>Text_FDD_STATUS_B
                JSL UART_PUTS
                setdbr `FDD_STATUS_B
                LDA FDD_STATUS_B
                JSL UART_PUTHEX
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                ;---------------
                setdbr `Text_FDD_DIGITAL_OUTPUT
                LDX #<>Text_FDD_DIGITAL_OUTPUT
                JSL UART_PUTS
                setdbr `FDD_DIGITAL_OUTPUT
                LDA FDD_DIGITAL_OUTPUT
                JSL UART_PUTHEX
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                ;---------------
                setdbr `Text_FDD_TAPE_DRIVER
                LDX #<>Text_FDD_TAPE_DRIVER
                JSL UART_PUTS
                setdbr `FDD_TAPE_DRIVER
                LDA FDD_TAPE_DRIVER
                JSL UART_PUTHEX
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                ;---------------
                setdbr `Text_FDD_MAIN_STATUE
                LDX #<>Text_FDD_MAIN_STATUE
                JSL UART_PUTS
                setdbr `FDD_MAIN_STATUE
                LDA FDD_MAIN_STATUE
                JSL UART_PUTHEX
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                ;---------------
                setdbr `Text_FDD_DIGITAL_INPUT
                LDX #<>Text_FDD_DIGITAL_INPUT
                JSL UART_PUTS
                setdbr `FDD_DIGITAL_INPUT
                LDA FDD_DIGITAL_INPUT
                JSL UART_PUTHEX
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                ;---------------
                LDA #$A
                JSL UART_PUTC
                LDA #$D
                JSL UART_PUTC
                RTL
Text_Start_Tx_CMD         .text "- TX CMD Start -",$A,$D,0
Text_Stop_Tx_CMD         .text "- TX CMD Stop -",$A,$D,0
Text_Start_Rx_CMD         .text "- RX CMD Start -",$A,$D,0
Text_Stop_Rx_CMD         .text "- RX CMD Stop -",$A,$D,0

Text_FDD_STATUS_A         .text "FDD_STATUS_A       0x",0
Text_FDD_STATUS_B         .text "FDD_STATUS_B       0x",0
Text_FDD_DIGITAL_OUTPUT   .text "FDD_DIGITAL_OUTPUT 0x",0
Text_FDD_TAPE_DRIVER      .text "FDD_TAPE_DRIVER    0x",0
Text_FDD_MAIN_STATUE      .text "FDD_MAIN_STATUE    0x",0
Text_FDD_DIGITAL_INPUT    .text "FDD_DIGITAL_INPUT  0x",0

.include "FDD_row_TEXT_HEX.asm"
