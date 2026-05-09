
; 3236 bytes of binary data for the code available (Unless you expand size in kernel and bootloader code)

YOUR_COMMAND_NAME: db "func", 0; string to type to execute your command
main_function: ; DONT CHANGE THIS NAME
    push rbp
    mov rbp, rsp
    
    mov WORD [rsp-4], 0x0F59 ; 0x0F - white text with white background, 0x59 - 'Y'. More info about colors - https://en.wikipedia.org/wiki/BIOS_color_attributes
    
    mov r10w, WORD [rsp-4]
    
    ; minimum address: 0x0B8000
    ; maximum address: 0x0B8EFE
    ; each character is combination of 2 characters: 1. Style specification 2. Character itself
    mov r9, 0x0B8000
    
    mov [r9], r10w
    
    
    leave
    ret ; DONT REMOVE THIS
