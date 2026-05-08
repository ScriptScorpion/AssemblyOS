; preffer using r8-r15 registers and stack only

YOUR_COMMAND_NAME: db "func", 0; string to type to execute your command

main_function: ; DONT CHANGE THIS NAME
    push rbp
    mov rbp, rsp
    
    mov WORD [rsp-4], 0x0F59 ; 0x0E - white text with white background, 0x59 - 'Y'
    
    mov r10w, WORD [rsp-4]
    
    mov r9, 0x0B8000
    
    mov [r9], r10w
    
    
    leave
    ret
