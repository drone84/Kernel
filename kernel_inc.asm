;Kernel_INC.asm
;Kernel ROM jump table

BOOT             = $180000 ; Cold boot routine
RESTORE          = $180004 ; Warm boot routine
BREAK            = $180008 ; End program and return to command prompt
READY            = $18000C ; Print prompt and wait for keyboard input
SCINIT           = $180010 ;
IOINIT           = $180014 ;
PUTC             = $180018 ; Print a character to the currently selected channel
PUTS             = $18001C ; Print a string to the currently selected channel
PUTB             = $180020 ; Output a byte to the currently selected channel
PUTBLOCK         = $180024 ; Ouput a binary block to the currently selected channel
SETLFS           = $180028 ; Obsolete (done in OPEN)
SETNAM           = $18002C ; Obsolete (done in OPEN)
OPEN             = $180030 ; Open a channel for reading and/or writing. Use SETLFS and SETNAM to set the channels and filename first.
CLOSE            = $180034 ; Close a channel
SETIN            = $180038 ; Set the current input channel
SETOUT           = $18003C ; Set the current output channel
GETB             = $180040 ; Get a byte from input channel. Return 0 if no input. Carry is set if no input.
GETBLOCK         = $180044 ; Get a X byes from input channel. If Carry is set, wait. If Carry is clear, do not wait.
GETCH            = $180048 ; Get a character from the input channel. A=0 and Carry=1 if no data is wating
GETCHW           = $18004C ; Get a character from the input channel. Waits until data received. A=0 and Carry=1 if no data is wating
GETCHE           = $180050 ; Get a character from the input channel and echo to the screen. Wait if data is not ready.
GETS             = $180054 ; Get a string from the input channel. NULL terminates
GETLINE          = $180058 ; Get a line of text from input channel. CR or NULL terminates.
GETFIELD         = $18005C ; Get a field from the input channel. Value in A, CR, or NULL terminates
TRIM             = $180060 ; Removes spaces at beginning and end of string.
PRINTC           = $180064 ; Print character to screen. Handles terminal commands
PRINTS           = $180068 ; Print string to screen. Handles terminal commands
PRINTCR          = $18006C ; Print Carriage Return
PRINTF           = $180070 ; Print a float value
PRINTI           = $180074 ; Prints integer value in TEMP
PRINTH           = $180078 ; Print Hex value in DP variable
PRINTAI          = $18007C ; Prints integer value in A
PRINTAH          = $180080 ; Prints hex value in A. Printed value is 2 wide if M flag is 1, 4 wide if M=0
LOCATE           = $180084 ;
PUSHKEY          = $180088 ;
PUSHKEYS         = $18008C ;
CSRRIGHT         = $180090 ;
CSRLEFT          = $180094 ;
CSRUP            = $180098 ;
CSRDOWN          = $18009C ;
CSRHOME          = $1800A0 ;
SCROLLUP         = $1800A4 ; Scroll the screen up one line. Creates an empty line at the bottom.
SCRREADLINE      = $1800A8 ; Loads the MCMDADDR/BCMDADDR variable with the address of the current line on the screen. This is called when the RETURN key is pressed and is the first step in processing an immediate mode command.
SCRGETWORD       = $1800AC ; Read a current word on the screen. A word ends with a space, punctuation (except _), or any control character (value < 32). Loads the address into CMPTEXT_VAL and length into CMPTEXT_LEN variables.
CLRSCREEN        = $1800B0 ; Clear the screen
INITCHLUT        = $1800B4 ; Init character look-up table
INITSUPERIO      = $1800B8 ; Init Super-IO chip
INITKEYBOARD     = $1800BC ; Init keyboard
INITRTC          = $1800C0 ; Init Real-Time Clock
INITCURSOR       = $1800C4 ; Init the Cursors registers
INITFONTSET      = $1800C8 ; Init the Internal FONT Memory
INITGAMMATABLE   = $1800CC ; Init the RGB GAMMA Look Up Table
INITALLLUT       = $1800D0 ; Init the Graphic Engine (Bitmap/Tile/Sprites) LUT
INITVKYTXTMODE   = $1800D4 ; Init the Text Mode @ Reset Time
INITVKYGRPMODE   = $1800D8 ; Init the Basic Registers for the Graphic Mode
