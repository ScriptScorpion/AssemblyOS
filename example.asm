; preffer using r8-r15 registers and stack only

YOUR_COMMAND_NAME: db "func", 0; string to type to execute your command

%define YOUR_FUNCTION_NAME function ; you can do 'call YOUR_FUNCTION_NAME' to enter this function

funtion:
    push rbp
    mov rbp, rsp
    
    mov QWORD [rsp-8], 0x0E59 ; 0x0E - white text with white background, 0x59 - 'Y'
    
    mov r10, QWORD [rsp-8]
    
    mov r9, 0x0B8000
    
    mov [r9], r10
    
    
    leave
    ret
