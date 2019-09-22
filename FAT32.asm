.cpu "65816"
.include "FAT32_def.asm"
.include "stdlib.asm"

* = $10000
FAT32_Byte_Per_Sector           .word 0; 512 for a Floppy disk
FAT32_Sector_Per_Cluster        .word 0; 1
FAT32_Nb_Of_reserved_Cluster    .word 0; 1 , this number include the boot sector
FAT32_Nb_Of_FAT                 .word 0; 2
FAT32_Max_Root_Entry            .word 0; not used in FAT32
FAT32_Total_Sector_Count        .word 0; 2880 => 80 track of 18 sector on each 2 dide (80*18*2)
FAT32_Sector_per_Fat            .dword 0
FAT32_Sector_per_Track          .word 0
FAT32_Nb_of_Head                .word 0
FAT32_Total_Sector_Count_FAT32  .dword 0
FAT32_Boot_Signature            .word 0
FAT32_Volume_ID                 .dword 0
FAT32_Volume_Label              .fill 11,0 ;0xB
FAT32_File_System_Type          .word 0
FAT32_Sector_loaded_in_ram      .dword 0; updated by any function readding Sector from FDD like : IFAT32_READ_BOOT_SECTOR / IFAT32_COMPUT_ROOT_DIR_POS

FAT32_Root_Base_Sector          .dword 0; hold the first sector containing the Root directory data
FAT32_Root_Sector_loaded_in_ram .dword 0  ; store the actual Folder sector loades in ram
FAT32_Root_entry_value          .fill 32,0 ; store the 32 byte of root entry

FAT32_FAT_Base_Sector           .dword 0
FAT32_FAT_Sector_loaded_in_ram  .dword 0  ; store the actual FAT sector loades in ram
FAT32_FAT_Entry                 .dword 0
FAT32_FAT_Next_Entry            .dword 0  ; store the next 32 bit FAT entry associated to the FAT entry in 'FAT32_FAT_Entry'
FAT32_FAT_Linked_Entry           .dword 0

MBR_Partition_address           .dword 0

;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
FAT32_init  ; init
              JSL IFAT32_READ_MBR           ; Init only
              JSL IFAT32_READ_BOOT_SECTOR   ; Init only
              JSL IFAT32_COMPUT_FAT_POS   ; Init only
              JSL IFAT32_COMPUT_ROOT_DIR_POS   ; Init only
              ; make sure the FAT sector stored in ram (missing befor init) is differant than the one we are requesting (at least the first tine the code is called)
              LDA #0
              STA FAT32_Sector_loaded_in_ram
              STA FAT32_Root_Sector_loaded_in_ram
              STA FAT32_FAT_Sector_loaded_in_ram
              LDA #0
              STA FAT32_Sector_loaded_in_ram+2
              STA FAT32_Root_Sector_loaded_in_ram+2
              STA FAT32_FAT_Sector_loaded_in_ram+2

              JSL IFAT32_GET_ROOT_ENTRY
              LDA #5
              STA FAT32_FAT_Entry
              LDA #0
              STA FAT32_FAT_Entry+2
              JSL FAT32_IFAT_GET_FAT_ENTRY
              RTL
FAT32_test
              JSL IFAT32_GET_ROOT_ENTRY
              LDA #5
              STA FAT32_FAT_Entry
              LDA #0
              STA FAT32_FAT_Entry+2
              JSL FAT32_IFAT_GET_FAT_ENTRY
              LDA #$0D
              JSL IPUTC
              JSL FAT32_Open_File
              RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
FAT32_Open_File   LDX #0 ; start by readding the first folder entry
FAT32_Open_File_Read_Next_Folder_Entry
                  TXA
                  JSL IFAT32_GET_ROOT_ENTRY
                  INC X
                  LDA FAT32_Root_entry_value
                  AND #$00FF
                  CMP #$E5 ; test if the entry is deleted
                  BEQ FAT32_Open_File_Read_Next_Folder_Entry
                  LDA FAT32_Root_entry_value +11
                  AND #$00FF
                  CMP #$0F ; test if its a long name entry
                  BEQ FAT32_Open_File_Read_Next_Folder_Entry
                  CMP #$20 ; if different from 0x20 its nor a file name entry (need to confirm that)
                  BNE FAT32_Open_File_Read_Next_Folder_Entry
                  ;-------
                  ;debug
                  JSL FAT32_Print_File_Name
                  LDA #$0D
                  JSL IPUTC
                  ;-------
                  ;BRA FAT32_Open_File_J1
;FAT32_Open_File_Read_Next_Folder_Entry_temp
                  ;BRA FAT32_Open_File_Read_Next_Folder_Entry
;FAT32_Open_File_J1

                  TXA
                  CMP #32
                  BNE FAT32_Open_File_Read_Next_Folder_Entry;_temp
                  RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
FAT32_Print_File_Name
                LDA FAT32_Root_entry_value
                JSL IPUTC
                LDA FAT32_Root_entry_value +1
                JSL IPUTC
                LDA FAT32_Root_entry_value +2
                JSL IPUTC
                LDA FAT32_Root_entry_value +3
                JSL IPUTC
                LDA FAT32_Root_entry_value +4
                JSL IPUTC
                LDA FAT32_Root_entry_value +5
                JSL IPUTC
                LDA FAT32_Root_entry_value +6
                JSL IPUTC
                LDA FAT32_Root_entry_value +7
                JSL IPUTC
                LDA #'.'
                JSL IPUTC
                LDA FAT32_Root_entry_value +8
                JSL IPUTC
                LDA FAT32_Root_entry_value +9
                JSL IPUTC
                LDA FAT32_Root_entry_value +10
                JSL IPUTC
                RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
IFAT32_READ_MBR
                  setal
                  LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA #0 ; read sector 0 (where the MBR sector is stored)
                  JSL IHDD_READ
                  PLX
                  PLX

                  LDX #MBR_Partition_Entry
READ_MBR_Scan
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X+8
                  CMP #0
                  BEQ READ_MBR_Partition_Entry_LSB_Not_Null
                  LDY #1
READ_MBR_Partition_Entry_LSB_Not_Null
                  STA MBR_Partition_address
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X+8+2
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
                  LDA #$0D
                  JSL IPUTC
                  ;-----------------------------------
                  ;LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  ;PHA
                  ;LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  ;PHA
                  ;LDA MBR_Partition_address+2 ; dont use X value for now IHDD_READ is a dummy function unlit I ger the real HDD hardware driver
                  ;TAX
                  ;LDA MBR_Partition_address
                  ;JSL IHDD_READ

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
                  LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
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
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Byte_Per_Sector

                  LDX #$0D ;13
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  AND #$FF
                  STA FAT32_Sector_Per_Cluster

                  LDX #$0E ;14
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Nb_Of_reserved_Cluster

                  LDX #$10 ;16
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  AND #$FF
                  STA FAT32_Nb_Of_FAT

                  ;LDX #17 ;  not used on FAT 32
                  ;LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  ;STA FAT32_Max_Root_Entry

                  ;LDX #19 ; not used on FAT 32
                  ;LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  ;STA FAT32_Total_Sector_Count

                  ;LDX #22 ;; not used on FAT 32
                  ;LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  ;STA FAT32_Sector_per_Fat

                  LDX #24 ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Sector_per_Track

                  LDX #26 ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Nb_of_Head

                  ;LDX #$20; ;32
                  ;LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  ;STA FAT32_Total_Sector_Count_FAT32
                  ;LDX #34 ;
                  ;LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  ;STA FAT32_Total_Sector_Count_FAT32+2

                  LDX #$24 ;36 ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Sector_per_Fat
                  LDX #$26 ;36 ;
                  LDA FAT32_DATA_ADDRESS_BUFFER_512,X
                  STA FAT32_Sector_per_Fat+2


                  ;LDA #<>FAT32_DATA_ADDRESS_BUFFER_512
                  ;ADC #43
                  ;TAX
                  ;LDY #<>Volume_Label
                  ;LDA #11-1
                  ;MVN `FAT32_Volume_Label , `FAT32_DATA_ADDRESS_BUFFER_512

                  ;LDA #<>FAT32_DATA_ADDRESS_BUFFER_512
                  ;ADC #54
                  ;TAX
                  ;LDY #<>File_System_Type
                  ;LDA #8-1
                  ;MVN `FAT32_File_System_Type, `FAT32_DATA_ADDRESS_BUFFER_512


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
IFAT32_COMPUT_ROOT_DIR_POS
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
                  STA FAT32_Root_Base_Sector
                  RTL
;-------------------------------------------------------------------------------
IFAT32_GET_ROOT_FIRST_ENTRY
                  setaxl
                  RTL
;-------------------------------------------------------------------------------
IFAT32_GET_ROOT_NEXT_ENTRY
                  setaxl
                  RTL
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
IFAT32_COMPUT_FAT_POS
                  setaxl
                  LDA FAT32_Nb_Of_reserved_Cluster
                  CLC
                  ADC MBR_Partition_address;
                  STA FAT32_FAT_Base_Sector
                  RTL
;
;-------------------------------------------------------------------------------
;
; REG A (16 bit) contain the root directory entry to read
;
;-------------------------------------------------------------------------------

IFAT32_READ_LIKED_FAT_ENTRY
                  PHX
  IFAT32_READ_LIKED_FAT_ENTRY___READ_NEXT_FAT
                  JSL FAT32_IFAT_GET_FAT_ENTRY
                  LDA FAT32_FAT_Next_Entry +2 ; test for EOC (End Of Cluster)
                  AND #$0FFF
                  CMP #$0FFF
                  BEQ IFAT32_READ_LIKED_FAT_ENTRY___NEXT_CLUSTER_VALID
                  LDA FAT32_FAT_Next_Entry +2 ; test for EOC (End Of Cluster)
                  AND #$FFF0
                  CMP #$FFF0
                  BEQ IFAT32_READ_LIKED_FAT_ENTRY___NEXT_CLUSTER_VALID
                  LDA FAT32_FAT_Next_Entry +2 ; test for EOC (End Of Cluster)
                  AND #$000F
                  CMP #8
                  BMI IFAT32_READ_LIKED_FAT_ENTRY___NEXT_CLUSTER_VALID
                  LDA #-1 ; end of the file
                  BRA IFAT32_READ_LIKED_FAT_ENTRY___EOC
IFAT32_READ_LIKED_FAT_ENTRY___NEXT_CLUSTER_VALID
                  LDA FAT32_FAT_Linked_Entry
                  DEC A
                  BMI IFAT32_READ_LIKED_FAT_ENTRY___UNDERFLOW
                  STA FAT32_FAT_Entry ; update the low part the the fat entry we want to read
                  BRA IFAT32_READ_LIKED_FAT_ENTRY___READ_NEXT_FAT
IFAT32_READ_LIKED_FAT_ENTRY___UNDERFLOW
                  LDA FAT32_FAT_Linked_Entry+2
                  DEC A
                  BMI IFAT32_READ_LIKED_FAT_ENTRY___WENT_THRW_ALL_FAT_LINKED
                  STA FAT32_FAT_Entry+2
                  BRA IFAT32_READ_LIKED_FAT_ENTRY___READ_NEXT_FAT
IFAT32_READ_LIKED_FAT_ENTRY___WENT_THRW_ALL_FAT_LINKED
                  LDA #1
IFAT32_READ_LIKED_FAT_ENTRY___EOC
                  PLX
;-------------------------------------------------------------------------------
;
; REG A (16 bit) contain the root directory entry to read
;
;-------------------------------------------------------------------------------
IFAT32_GET_ROOT_ENTRY
                  setaxl
                  PHX
                  PHA ; Save the root entry index we want to read
                  LDX #0 ; compute in witch sector the desired root entry is, 16 entry per sector so we just need to divid the sector size by 16
FAT32_KEEP_SHIFT_ROOT_ENTRY_INDEX
                  LSR
                  INC X
                  CPX #4 ; divide by 16
                  BNE FAT32_KEEP_SHIFT_ROOT_ENTRY_INDEX
                  CMP #0
                  BEQ IFAT32_GET_ROOT_ENTRY__Load_first_sector
                  ; the entry is bigger than 16, so we need to search for the entry cluster liked to the folder
                  LDA FAT32_Root_Base_Sector
                  STA FAT32_FAT_Entry
                  LDA FAT32_Root_Base_Sector +2
                  STA FAT32_FAT_Entry + 2
                  TXA
                  STA FAT32_FAT_Linked_Entry
                  LDA #0
                  STA FAT32_FAT_Linked_Entry+2
                  JSL IFAT32_READ_LIKED_FAT_ENTRY
                  CMP #-1
                  BEQ IFAT32_GET_ROOT_ENTRY__ERROR_NO_MORE_FAT_ENTRY

IFAT32_GET_ROOT_ENTRY__Load_first_sector
                  CLC ; reset the carry flag potencialy set by CPX
                  ADC FAT32_Root_Base_Sector ; add the relative sector position of the rrot entry to the start root entry position shoud be 19 (0 based index)
                  ; test if the sector is alreaddy loaddes in RAM
                  CMP FAT32_Root_Sector_loaded_in_ram
                  BEQ FAT32_FDD_SECTOR_ALREADDY_LOADDED_IN_RAM
                  STA FAT32_Root_Sector_loaded_in_ram ; save the new sector loaded
                  LDA #`FAT32_FOLDER_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_FOLDER_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_Root_Sector_loaded_in_ram ; Get the ROOT directory sector saved rearlyer
                  JSL IHDD_READ
                  PLX
                  PLX
FAT32_FDD_SECTOR_ALREADDY_LOADDED_IN_RAM
                  ; get the root entry now we have the right sector loaded in RAM
                  PLA ; GET the root entry FDD_INDEX
                  ;PHA
                  AND #$0F ; get only the 4 first byte to get the 16 value ofset in the root entry sector loades in ram (16 entry per sector)
                  ASL
                  ASL
                  ASL
                  ASL
                  ASL ; now A contain the ofset to read the root entry from
                  CLC
                  ADC #<>FAT32_FOLDER_ADDRESS_BUFFER_512
                  TAX
                  LDA #<>FAT32_Root_entry_value
                  TAY
                  LDA #31
                  MVN `FAT32_Root_entry_value, `FAT32_FOLDER_ADDRESS_BUFFER_512
                  BRA IFAT32_GET_ROOT_ENTRY___EXIT_OK
IFAT32_GET_ROOT_ENTRY__ERROR_NO_MORE_FAT_ENTRY
                  PLX
IFAT32_GET_ROOT_ENTRY___EXIT_OK
                  PLX
                  RTL
;-------------------------------------------------------------------------------
;
; Get in FAT32_FAT_Entry the FAT entry where to get the next One
; return the next fat entry to read  in FAT32_FAT_Next_Entry
;
; JSL IFAT32_GET_ROOT_ENTRY
; LDA #5
; STA FAT32_FAT_Entry
; LDA #0
; STA FAT32_FAT_Entry+2
;
;-------------------------------------------------------------------------------
FAT32_IFAT_GET_FAT_ENTRY
                  PHA
                  PHX
                  PHY
                  ; find in witch sector the fat entry is suposed to be
                  ;------- Test id the FAT entry is in the first cluster -------
                  LDA FAT32_FAT_Entry+2
                  CMP #0
                  BNE FAT32_FAT_ENTRY_FIND_THE_CLUSTER ; the FAT entry is definitly not in the first FAT cluster
                  LDA FAT32_FAT_Entry
                  LSR A
                  LSR A
                  LSR A
                  LSR A
                  STA FAT32_FAT_Next_Entry
                  CMP #0
                  BNE FAT32_FAT_ENTRY_FIND_THE_CLUSTER
                  BRA FAT32_ENTRY_SECTOR_LOCATION_FIND ; if this part of the code i riched, its mean that the FAT entry requested is with in the first FAT clustrer (entry smaller than 16)
FAT32_FAT_ENTRY_FIND_THE_CLUSTER
                  ; ----- shift the 32 Byte FAT entry by 4 (divide by 16) ------
                  ;-------- to comput the FAT cluster to load in memory --------
                  LDA FAT32_FAT_Entry+2
                  LSR A
                  LSR A
                  LSR A
                  LSR A ; comput the high part divided by 16
                  STA FAT32_FAT_Next_Entry+2 ; use FAT32_FAT_Next_Entry as a temporary variable
                  LDA FAT32_FAT_Entry+2 ;extract the 4 bits of the HIGHT part of FAT32_FAT_Entry to casrry them in the LOW part
                  AND #$F
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A
                  ASL A ; get the 4 bit in the right position to be added to the LOW part
                  STA FAT32_FAT_Next_Entry
                  LDA FAT32_FAT_Entry
                  LSR A
                  LSR A
                  LSR A
                  LSR A ; divide the high part of the FAT entry requested by 16  because there is 16 FAt entry per sector
                  AND #$0FFF
                  ORA FAT32_FAT_Next_Entry
                  STA FAT32_FAT_Next_Entry ; Now contain the 32 bit FAT Cluster to load
FAT32_ENTRY_SECTOR_LOCATION_FIND
                  ; need to modify thre code to use 32 byte number
                  LDA FAT32_FAT_Next_Entry
                  CLC
                  ADC FAT32_FAT_Base_Sector
                  CMP FAT32_FAT_Sector_loaded_in_ram
                  BEQ FAT32_COMPUTED_OFSET_IN_CLUSTER ; dont need to load the fat sector because it's alreaddy loaded
                  STA FAT32_FAT_Sector_loaded_in_ram  ; update the cluster value
                  ; comput the address where to read the data from
                  LDA #`FAT32_FAT_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  PHA
                  LDA #<>FAT32_FAT_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_FAT_Sector_loaded_in_ram ; read the ROOT directory sector saved at the begining of the function
                  JSL IHDD_READ
                  PLX
                  PLX
                  ; from here the right FAT sector is loades in ram
FAT32_COMPUTED_OFSET_IN_CLUSTER
                  LDA FAT32_FAT_Entry
                  AND #$0F ; get only the 7 first byte to get the ofset in the curent FAT cluster loades
                  ASL
                  ASL ; *4 to point to the FAT entry 32 byte
                  ;STA FAT32_FAT_Next_Entry+2
                  ;LDA #<>FAT32_FAT_ADDRESS_BUFFER_512
                  CLC
                  ;ADC FAT32_FAT_Next_Entry+2                ; Add the ofset FAT entry to the data bufer wgere the FAT data is loaded
                  ADC #<>FAT32_FAT_ADDRESS_BUFFER_512
                  TAX
                  LDA #<>FAT32_FAT_Next_Entry
                  TAY
                  LDA #3 ; read 4 byte
                  MVN `FAT32_FAT_Next_Entry,`FAT32_FAT_ADDRESS_BUFFER_512
                  LDA FAT32_FAT_Next_Entry    ; FOR DEBUG
                  LDA FAT32_FAT_Next_Entry+2  ; FOR DEBUG
                  LDA FAT32_FAT_Next_Entry    ; FOR DEBUG
                  LDA FAT32_FAT_Next_Entry+2  ; FOR DEBUG
                  PLY
                  PLX
                  PLA
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
                  JSL IFAT32_COMPUT_ROOT_DIR_POS
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
                  STA FAT32_FAT_Next_Entry

FAT32_ILOAD_FILE_Read_next_sector; read sector function to call there
                  ;LDA #`FAT32_DATA_ADDRESS_BUFFER_512 ; load the byte nb 3 (bank byte)
                  ;PHA
                  ;LDA #<>FAT32_DATA_ADDRESS_BUFFER_512 ; load the low world part of the buffer address
                  ;PHA
                  LDA 10,S ; load the byte nb 3 (bank byte)
                  PHA
                  LDA 12,S ; load the low world part of the buffer address
                  PHA
                  LDA FAT32_FAT_Next_Entry ; sector to read
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
                  LDA FAT32_FAT_Next_Entry ; sector to read
                  JSL FAT32_IFAT_GET_FAT_ENTRY
                  LDA FAT32_FAT_Next_Entry
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
HDD_MVN_INSTRUCTION_ADDRESS  MVN `FAT32_DATA_ADDRESS_BUFFER_512,`data_hard_drive
                PLA
                RTL

* = $20425
Partition_ofset_text    .text "Partition ofset (in cluster) : "

* = $12000
.include "HDD_row_TEXT_HEX.asm"
