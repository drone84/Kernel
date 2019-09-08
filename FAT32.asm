.cpu "65816"
.include "FAT32_def.asm"
.include "stdlib.asm"

* = $10000

FAT32_Byte_Per_Sector = $10000 ; 512 for a Floppy disk
FAT32_Sector_Per_Cluster = $10002 ; 1
FAT32_Nb_Of_reserved_Cluster = $10004 ; 1 , this number include the boot sector
FAT32_Nb_Of_FAT = $10006 ; 2
FAT32_Max_Root_Entry = $10008 ; 224  => 14 sector for the root directory and 32Byte foe en entry (14 * 512 / 32)
FAT32_Total_Sector_Count = $1000A ; 2880 => 80 track of 18 sector on each 2 dide (80*18*2)
FAT32_Sector_per_Fat = $1000C
FAT32_Sector_per_Track = $10010
FAT32_Nb_of_Head = $10012
FAT32_Total_Sector_Count_FAT32 = $10014
FAT32_Boot_Signature = $10018
FAT32_Volume_ID = $1001A
FAT32_Volume_Label =  $1001E
FAT32_File_System_Type =  $10029

FAT32_Sector_loaded_in_ram = $10031 ; updated by any function readding Sector from FDD like : IFAT32_READ_BOOT_SECTOR / IFAT32_GET_ROOT_DIR_POS
FAT32_Root_entry_Sector_index = $10033 ; hold the sector index position of the fists Root directory sectoe
FAT32_Root_entry_value = $10035 ; store the 32 byte of root entry

FAT32_Sector_index = $10055 ; store the sector index of the first fat sector
FAT32_next_entry = $10057  ; store the 12 bit fat entry
FAT32_FAT_Sector_loaded_in_ram = $1005B ; store the actual fat sector loades in ram
;Temp_data_FAT12 = $19059
;19061
MBR_Partition_address = $10064
* = $10068
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
FAT32_test
              JSL IFAT32_READ_MBR
              RTL

;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
IFAT32_READ_MBR
                  setal
                  LDA #`FAT32_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA $0 ; read sector 0 (where the MBR sector is stored)
                  JSL IHDD_READ
                  PLX
                  PLX

                  LDX #MBR_Partition_Entry
READ_MBR_Scan
                  LDA FAT32_ADDRESS_BUFFER_512,X+8
                  CMP #0
                  BEQ READ_MBR_Partition_Entry_LSB_Not_Null
                  LDY #1
READ_MBR_Partition_Entry_LSB_Not_Null
                  STA MBR_Partition_address
                  LDA FAT32_ADDRESS_BUFFER_512,X+8+2
                  CMP #0
                  BEQ READ_MBR_Partition_Entry_MSB_Not_Null
                  LDY #1
READ_MBR_Partition_Entry_MSB_Not_Null
                  STA MBR_Partition_address+2

                  CPY #1
                  BEQ READ_MBR_Partition_valid_address
                  CPX #$1FE
                  BEQ READ_MBR_End_Scan_no_partition
                  TXA
                  ADC #MBR_Partition_Entry_size
                  TAX
                  BRA READ_MBR_Scan

READ_MBR_Partition_valid_address ; the number in MBR_Partition_address is an ofset in cluster of a Partiton
                  LDX #<>Partition_ofset_text
                  LDA #`Partition_ofset_text
                  JSL IPRINT_ABS       ; print the first line
                  LDA #'0'
                  JSL IPUTC
                  LDA #'x'
                  JSL IPUTC
                  LDA MBR_Partition_address +3
                  JSL IPRINT_HEX
                  LDA MBR_Partition_address +2
                  JSL IPRINT_HEX
                  LDA MBR_Partition_address +1
                  JSL IPRINT_HEX
                  LDA MBR_Partition_address
                  JSL IPRINT_HEX
                  LDA $0D
                  JSL IPUTC
                  ;-----------------------------------
                  ;LDA #`FAT32_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  ;PHA
                  ;LDA #<>FAT32_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  ;PHA
                  ;LDA MBR_Partition_address+2 ; dont use X value for now IHDD_READ is a dummy function unlit I ger the real HDD hardware driver
                  ;TAX
                  ;LDA MBR_Partition_address
                  ;JSL IHDD_READ
                  JSL IFAT32_READ_BOOT_SECTOR
                  JSL IFAT32_GET_ROOT_DIR_POS
                  LDA #0
                  JSL IFAT32_GET_ROOT_ENTRY

READ_MBR_End_Scan_no_partition
                  LDA #-1
READ_MBR_End
                  RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
IFAT32_READ_BOOT_SECTOR
                  setaxl
                  LDA #`FAT32_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA MBR_Partition_address+2 ; dont use X value for now IHDD_READ is a dummy function unlit I ger the real HDD hardware driver
                  TAX
                  LDA MBR_Partition_address
                  JSL IHDD_READ
                  PLX
                  PLX;
                  STA FAT32_Sector_loaded_in_ram
                   ; Byte per sector offset ; 2 byte data
                  LDX #$B ;11
                  LDA FAT32_ADDRESS_BUFFER_512,X
                  STA FAT32_Byte_Per_Sector

                  LDX #$0D ;13
                  LDA FAT32_ADDRESS_BUFFER_512,X
                  AND #$FF
                  STA FAT32_Sector_Per_Cluster

                  LDX #$0E ;14
                  LDA FAT32_ADDRESS_BUFFER_512,X
                  STA FAT32_Nb_Of_reserved_Cluster

                  LDX #$10 ;16
                  LDA FAT32_ADDRESS_BUFFER_512,X
                  AND #$FF
                  STA FAT32_Nb_Of_FAT

                  ;LDX #17 ;  not used on FAT 32
                  ;LDA FAT32_ADDRESS_BUFFER_512,X
                  ;STA FAT32_Max_Root_Entry

                  ;LDX #19 ; not used on FAT 32
                  ;LDA FAT32_ADDRESS_BUFFER_512,X
                  ;STA FAT32_Total_Sector_Count

                  ;LDX #22 ;; not used on FAT 32
                  ;LDA FAT32_ADDRESS_BUFFER_512,X
                  ;STA FAT32_Sector_per_Fat

                  LDX #24 ;
                  LDA FAT32_ADDRESS_BUFFER_512,X
                  STA FAT32_Sector_per_Track

                  LDX #26 ;
                  LDA FAT32_ADDRESS_BUFFER_512,X
                  STA FAT32_Nb_of_Head

                  ;LDX #$20; ;32
                  ;LDA FAT32_ADDRESS_BUFFER_512,X
                  ;STA FAT32_Total_Sector_Count_FAT32
                  ;LDX #34 ;
                  ;LDA FAT32_ADDRESS_BUFFER_512,X
                  ;STA FAT32_Total_Sector_Count_FAT32+2

                  LDX #$24 ;36 ;
                  LDA FAT32_ADDRESS_BUFFER_512,X
                  STA FAT32_Sector_per_Fat
                  LDX #$26 ;36 ;
                  LDA FAT32_ADDRESS_BUFFER_512,X
                  STA FAT32_Sector_per_Fat+2


                  ;LDA #<>FAT32_ADDRESS_BUFFER_512
                  ;ADC #43
                  ;TAX
                  ;LDY #<>Volume_Label
                  ;LDA #11-1
                  ;MVN `FAT32_Volume_Label , `FAT32_ADDRESS_BUFFER_512

                  ;LDA #<>FAT32_ADDRESS_BUFFER_512
                  ;ADC #54
                  ;TAX
                  ;LDY #<>File_System_Type
                  ;LDA #8-1
                  ;MVN `FAT32_File_System_Type, `FAT32_ADDRESS_BUFFER_512


                  ; at this point all the important FAT infornation are stored between 19000 and 19030
                  LDA FAT32_Byte_Per_Sector
                  CMP #512
                  BNE FAT32_ERROR_BLOCK_SEIZE

                  LDA FAT32_Sector_Per_Cluster
                  CMP #1
                  BNE FAT32_ERROR_SECTOR_PER_CLUSTER

                  LDA FAT32_Nb_Of_reserved_Cluster
                  CMP #1
                  BCC FAT32_ERROR_RESERVED_SECTOR

                  LDA FAT32_Nb_Of_FAT
                  CMP #1
                  BCC FAT32_ERROR_NB_FAT

                  ;LDA FAT32_Max_Root_Entry
                  ;cMP #224
                  ;BNE FAT32_ERROR_NB_ROOT_ENTRY

                  ;LDA FAT32_Total_Sector_Count
                  ;CMP #2880
                  ;BNE FAT32_ERROR_NB_TOTAL_SECTOR_COUNT

                  LDA FAT32_Sector_per_Fat
                  CMP #0
                  BEQ FAT32_ERROR_SECTOR_PER_FAT


                  ;LDA FAT32_Boot_Signature
                  ;CMP #$29
                  ;BNE FAT32_ERROR_BOOT_SIGNATURE
                  LDA #1
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
FAT32_ERROR_BLOCK_SEIZE LDA #-1
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
FAT32_ERROR_SECTOR_PER_CLUSTER
                  LDA #-2
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
FAT32_ERROR_RESERVED_SECTOR
                  LDA #-3
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
FAT32_ERROR_NB_FAT      LDA #-4
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
FAT32_ERROR_NB_ROOT_ENTRY
                  LDA #-5
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
FAT32_ERROR_NB_TOTAL_SECTOR_COUNT
                  LDA #-6
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
FAT32_ERROR_SECTOR_PER_FAT
                  LDA #-7
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
FAT32_ERROR_SECTOR_PER_TRACK
                  LDA #-8
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
FAT32_ERROR_NB_HEAD_NULL
                  LDA #-9
                  BRA RETURN_IFAT32_READ_BOOT_SECTOR
FAT32_ERROR_BOOT_SIGNATURE
                  LDA #-10
RETURN_IFAT32_READ_BOOT_SECTOR
                  RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
IFAT32_GET_ROOT_DIR_POS
                  setaxl
                  LDA FAT32_Nb_Of_FAT;
                  TAX
                  LDA FAT32_Sector_per_Fat
FAT32_ADD_ONE_FAT       DEC X
                  CPX #0
                  BEQ FAT32_FDD_END_LOOP_FAT_SECTOR_USAGE
                  CLC
                  ADC FAT32_Sector_per_Fat
                  BRA FAT32_ADD_ONE_FAT
FAT32_FDD_END_LOOP_FAT_SECTOR_USAGE
                  CLC
                  ADC FAT32_Nb_Of_reserved_Cluster
                  CLC
                  ADC MBR_Partition_address; at this point we have the sector where the Root directory is starting
                                             ; and because for the floppy disc Cluster = sector we just need to read the sector number
                                             ; stored in A
                  STA FAT32_Root_entry_Sector_index
                  RTL

IFAT32_GET_ROOT_FIRST_ENTRY
                  setaxl
                  RTL

IFAT32_GET_ROOT_NEXT_ENTRY
                  setaxl
                  RTL
;-------------------------------------------------------------------------------
;
; REG A (16 bit) contain the root directory entry to read
;
;-------------------------------------------------------------------------------
IFAT32_GET_ROOT_ENTRY
                  setaxl
                  ;CMP FAT32_Max_Root_Entry
                  ;BPL FAT32_ERROR_NB_ROOT_ENTRY_INDEX
                  PHA ; Save the root entry index we want to read
                  LDX #0 ; compute in witch sector the desired root entry is, 16 entry per sector so we just need to divit the sector size by 16
FAT32_KEEP_SHIFT_ROOT_ENTRY_INDEX
                  LSR
                  INC X
                  CPX #4 ; divide by 16
                  BNE FAT32_KEEP_SHIFT_ROOT_ENTRY_INDEX
                  CLC ; reset the carry flag potencialy set by CPX
                  ADC FAT32_Root_entry_Sector_index ; add the relative sector position of the rrot entry to the start root entry position shoud be 19 (0 based index)
                  ; test if the sector is alreaddy loaddes in RAM
                  CMP FAT32_Sector_loaded_in_ram
                  BEQ FAT32_FDD_SECTOR_ALREADDY_LOADDES_IN_RAM
                  STA FAT32_Sector_loaded_in_ram ; save the new sector loaded
                  LDA #`FAT32_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_Sector_loaded_in_ram ; read the ROOT directory sector saved at the begining of the function
                  JSL IHDD_READ
                  PLX
                  PLX
FAT32_FDD_SECTOR_ALREADDY_LOADDES_IN_RAM
                  ; get the root entry now we have the right sector loaded in RAM
                  PLA ; GET the root entry FDD_INDEX
                  PHA
                  AND #$0F ; get only the 4 first byte to get the 16 value ofset in the root entry sector loades in ram (16 entry per sector)
                  ASL
                  ASL
                  ASL
                  ASL ; now A contain the ofset to read the root entry from
                  CLC
                  ADC #<>FAT32_ADDRESS_BUFFER_512
                  TAX
                  LDA #<>FAT32_Root_entry_value
                  TAY
                  LDA #31
                  MVN `FAT32_Root_entry_value, `FAT32_ADDRESS_BUFFER_512
                  PLA
                  RTL
;-------------------------------------------------------------------------------
;
;
;
;
;-------------------------------------------------------------------------------
IFAT32_GET_FAT_POS
                  LDA FAT32_Nb_Of_reserved_Cluster
                  STA FAT32_Sector_index
                  RTL

;-------------------------------------------------------------------------------
;
; Get  in A the FAT entry where to get the next One
; return the next fat entry to read  in FAT32_next_entry
;
;-------------------------------------------------------------------------------
FAT32_IFAT_GET_FAT_ENTRY
                  PHA
                  ; find in witch sector the fat entry is suposed to be
                  LDX #0
                  CMP #128 ; test if the wanted fat entry is in the first fat cluster (128 entry per FAT)
                  BCC FAT32_ENTRY_SECTOR_LOCATION_FIND
FAT32_FAT_ENTRY_NEXT_SECTOR
                  INC X
                  SBC #128
                  BPL FAT32_FAT_ENTRY_NEXT_SECTOR
FAT32_ENTRY_SECTOR_LOCATION_FIND
                  TXA
                  ADC FAT32_Nb_Of_reserved_Cluster
                  ADC MBR_Partition_Entry           ; add the partiton offset due to the MBR
                  CMP FAT32_Sector_loaded_in_ram
                  BEQ FAT32_COMPUT_OFSET_IN_CLUSTER ; dont need to load the fat sector because it's alreaddy loaded
                  STA FAT32_Sector_loaded_in_ram
                  LDA #`FAT32_FAT_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_FAT_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_Sector_loaded_in_ram ; read the ROOT directory sector saved at the begining of the function
                  JSL IHDD_READ
                  PLX
                  PLX
                  ; from here the right fat sector is loades in ram
FAT32_COMPUT_OFSET_IN_CLUSTER

                  ; PLA ; get the fat entry
                  ; PHA ; save it back again
                  LDA 1,S
                  AND #$7F ; get only the 7 first byte to get the ofset in the curent fat cluster loades
                  ASL
                  ASL ; *4 to point to the FAT entry 32 byte
                  STA FAT32_next_entry

                  LDA #<>FAT32_FAT_ADDRESS_BUFFER_512
                  CLC
                  ADC FAT32_next_entry                ; Add the ofset FAT entry to the data bufer wgere the FAT data is loaded
                  TAX
                  LDA #<>FAT32_next_entry
                  TAY
                  LDA #3 ; read 4 byte
                  MVN `FAT32_next_entry,`FAT32_FAT_ADDRESS_BUFFER_512
                  LDA FAT32_next_entry
                  PHA
                  ; dont need to reload the source address the instrction MVN already incrementer it to the right value
                  LDA #<>FAT32_next_entry
                  TAY
                  LDA #0 ; read one byte only
                  MVN `FAT32_next_entry,`FAT32_FAT_ADDRESS_BUFFER_512
                  LDA FAT32_next_entry
                  PLA ; get the initial fat entry, FAT32_next_entry contain the next fat entry and sector to read
                  RTL

;-------------------------------------------------------------------------------
; Search for the file name in the root directory
; Stack 0-1-3-4 pointer to the file name strings to load
; Stack 5-6-7-8 buffer where to load the file
;-------------------------------------------------------------------------------
FAT32_ILOAD_FILE
                  JSL IFAT32_READ_BOOT_SECTOR
                  CMP #$0001
                  BEQ ILOAD_FILE_FAT_32_BOOT_SECTOR_PARSING_OK
                  LDA #-1
                  BRA FAT32_ILOAD_FILE_RETURN_ERROR_temp
ILOAD_FILE_FAT_32_BOOT_SECTOR_PARSING_OK
                  JSL IFAT32_GET_ROOT_DIR_POS
                  setaxl
                  LDA #$00 ; sellect the first entry
                  PHA
FAT32_ILOAD_FILE_READ_NEXT_ROOT_ENTRY
                  JSL IFAT32_GET_ROOT_ENTRY
                  LDA FAT32_Root_entry_value + 11 ; get the flag Byte to test if it a file or a directory
                  AND #$10
                  CMP #$10
                  BNE FAT32_ILOAD_FILE_ENTRY ; if equal we read a directory so just read the next one
FAT32_ILOAD_FILE_STRING_NOT_MATCHED
                  PLA   ; get the actual root entry
                  CMP FAT32_Max_Root_Entry ; prevent to loop forever so exit
                  BEQ FAT32_ILOAD_FILE_NO_FILE_MATCHED
                  INC A ; sellect the next root entry
                  PHA   ; save the next root entry to read
                  BRA FAT32_ILOAD_FILE_READ_NEXT_ROOT_ENTRY
FAT32_ILOAD_FILE_ENTRY
                  setaxl
                  PLA   ; get the actual root entry
                  CMP Max_Root_Entry ; prevent to loop forever so exit
                  BEQ FAT32_ILOAD_FILE_NO_FILE_MATCHED
                  INC A ; sellect the next root entry
                  PHA   ; save the next root entry to read

                  ; copare the file name we want to load and the root entry file name
                  LDX #-1
                  LDY #-1
FAT32_ILOAD_FILE_CHAR_MATCHING
                  INC X
                  INC Y
                  CPX #11 ; FAT12 file or folder size
                  BEQ FAT32_ILOAD_FILE_STRING_MATCHED
                  LDA (6,S),Y ; load the "y" char file name we want to read
                  CMP FAT32_Root_entry_value,X
                  BEQ FAT32_ILOAD_FILE_CHAR_MATCHING
                  BRA FAT32_ILOAD_FILE_STRING_NOT_MATCHED
FAT32_ILOAD_FILE_NO_FILE_MATCHED
                  PLA
                  LDA #-2
FAT32_ILOAD_FILE_RETURN_ERROR_temp
                  BRA FAT32_ILOAD_FILE_RETURN_ERROR
FAT32_ILOAD_FILE_STRING_MATCHED
                  PLA
                  LDA FAT32_Root_entry_value + 26 ; get the first fat entry for the fil from the root directory entry we matched
                  STA FAT32_next_entry

FAT32_ILOAD_FILE_Read_next_sector; read sector function to call there
                  ;LDA #`FAT32_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  ;PHA
                  ;LDA #<>FAT32_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  ;PHA
                  LDA 10,S ; load the byte nb 3 (bank byte)
                  PHA
                  LDA 12,S ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_next_entry ; sector to read
                  ADC #1+9+9+14 ; skip the reserved sector ,  the 2 fat and the root sector
                  JSL IHDD_READ
                  PLX
                  PLX
                  ; point to the next 512 byte in the buffer
                  LDA 12,S ; load the low world part of the buffer address
                  CLC
                  LDA #0
                  PHA ; save the conter vaue
                  PHA ; save the
FAT32_ILOAD_FILE_Add_More_Sector_Per_Cluster
                  LDA 4,S ; load the Byte per cluster value
                  ADC FAT32_Byte_Per_Sector
                  STA 4,S
                  LDA FAT32_Sector_Per_Cluster
                  CMP 2,S
                  BEQ FAT32_ILOAD_FILE_Read_Next_Data
                  LDA 2,S
                  INC A
                  STA 2,S
                  BRA FAT32_ILOAD_FILE_Add_More_Sector_Per_Cluster
FAT32_ILOAD_FILE_Read_Next_Data
                  PLX ; removing the compter valuer from the stack
                  ;-------------------------------------------------------------
                  ; compute the next buffer address to use to copy file
                  LDA 14,S ; load the low world part of the buffer address
                  CLC
                  ADC 2,S
                  BCC FAT32_ILOAD_FILE_New_Buiffer_Address_computed
                  STA 14,S ; Save the low world part of the buffer address
                  LDA 12,S ; load the byte nb 3 (bank byte)
                  ADC #1
                  STA 12,S ; Save the byte nb 3 (bank byte)
FAT32_ILOAD_FILE_New_Buiffer_Address_computed
                  PLX ; get the Byte per cluster count out of the stack
                  ;-------------------------------------------------------------
                  LDA FAT32_next_entry ; sector to read
                  JSL FAT32_IFAT_GET_FAT_ENTRY
                  LDA FAT32_next_entry
                  CMP #$FFE
                  BCS FAT32_ILOAD_FILE_END_OF_FILE
                  BRA FAT32_ILOAD_FILE_Read_next_sector
FAT32_ILOAD_FILE_END_OF_FILE
FAT32_ILOAD_FILE_RETURN_ERROR
                  RTL

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
IHDD_READ       setaxl
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

                ADC #<>data_hard_drive
                TAX


                setas
                LDA 8,S
                STA HDD_MVN_INSTRUCTION_ADDRESS + 2 ; rewrite the second parameter of the instruction in RAM
                setaxl
                LDA #511
HDD_MVN_INSTRUCTION_ADDRESS  MVN `FAT32_ADDRESS_BUFFER_512,`data_hard_drive
                PLA
                RTL

* = $20425
Partition_ofset_text    .text "Partition ofset (in cluster) : "

* = $12000
.include "HDD_row_TEXT_HEX.asm"
