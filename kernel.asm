org 0x7C00
bits 16

cursor_pos dw 0

_start: ; real mode
    ; clearing system registers
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    
    xor dl, dl
    
    ; clear screen
    mov ax, 0x03
    int 0x10
    
    ; enabling access to memory more then 1MB
    in al, 0x92
    or al, 2
    out 0x92, al
    
    lgdt [gdt_descriptor]
    
    ; enabling protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    jmp 0x08:protected_mode

bits 32
protected_mode:
    ; configuring system registers
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Page Map Level 4 address 
    mov eax, 0x1000
    mov dword [eax], 0x2003 
    
    ; Page Directory Pointer Table address
    mov eax, 0x2000
    mov dword [eax], 0x3003  
    
    ; Page Directory address
    mov eax, 0x3000
    mov dword [eax], 0x0083 
    
    ; Page Map Level 4 address
    mov eax, 0x1000
    mov cr3, eax
    
    ; enabling Physical Address Extension
    mov eax, cr4
    or eax, 0x20
    mov cr4, eax
    
    ; enabling long mode using ESSR MSR
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x0100
    wrmsr
    
    ; enabling paging
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
    
    jmp 0x18:long_mode

bits 64
long_mode:
    ; clearing system registers
    xor al, al
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

main_code:
    
    call wait_key
    test al, al
    jz main_code ; jump if zero
    
    call check_enter

    mov ah, 0x0F
    mov rcx, 0xB8000
    mov dx, WORD [cursor_pos]
    add dx, dx
    add cx, dx
    mov [rcx], al
    
    call move_cursor
    
    mov rbx, 1 ; pseudo second
    call seconds_delay
    
    jmp main_code


seconds_delay:
    jmp .convert
    .convert:
        imul rbx, 735000
    
    .loop:
        in al, 0x60 ; accepting input and then discarding it, so input data doesn't accumulate 

        test rbx, rbx
        jz .end
        dec rbx
        jmp .loop
    
    .end:
        ret

wait_key:
    mov rbx, 1
    call seconds_delay
    
    in al, 0x64
    test al, 2
    jnz wait_key

    in al, 0x60
    test al, 0b10000000
    jnz wait_key

    movzx rax, al
    mov al, [scan_to_ascii + rax]


    ret

move_cursor:
    push rax
    push rdx
    
    inc BYTE [cursor_pos]
    cmp BYTE [cursor_pos], 254
    jae .limit_cursor
    
    .continue_cursor:
        mov dx, 0x3D4
        mov al, 0x0F
        out dx, al
        mov dx, 0x3D5
        mov al, BYTE [cursor_pos] ; position from the left
        out dx, al
        
        pop rdx
        pop rax
        ret

    .limit_cursor:
        dec BYTE [cursor_pos]

        mov dx, 0x3D4
        mov al, 0x0F
        out dx, al
        mov dx, 0x3D5
        mov al, BYTE [cursor_pos] ; position from the left
        out dx, al

        pop rdx
        pop rax
        ret
    

check_enter:
    push rcx
    push rax
    ; minimum 0xB8000
    ; maximum 0xB8EFE
    cmp al, 13

    jne .exit1
    
    mov ch, 0x0F
    mov cl, 0
    mov rax, 0xB8EFE
    mov [rax], cl
    
    .loop:
        cmp rax, 0xB7FFE
        jbe .exit2
        mov [rax], cl
        sub rax, 2
        jmp .loop
    
    .exit1:
        pop rax
        pop rcx
        ret
    
    .exit2:
        
        mov BYTE [cursor_pos], 0 
        mov dx, 0x3D4
        mov al, 0x0F
        out dx, al

        mov dx, 0x3D5
        mov al, 0
        out dx, al
        
        pop rax
        pop rcx
        pop rbp
        jmp main_code

scan_to_ascii:
    db 0, 0 ; Error, Esc 
    db '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '='
    db 0, 0 ; Backspace, Tab 
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']'
    db 13, 0 ; Enter, Left ctrl
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", '`'
    db 0 ; Left shift
    db '\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 
    db 0, 0, 0 ; Right shift, PrintScreen, Left alt
    db ' '
    db 0 ; Capslock

gdt_start:
    ; Explanation for GDT tables, Comming from the end:
    ; 0x00CF9A000000FFFF:
    ;
    ; Limit[15..0] = 0xFFFF - blocks size
    ; Base[15..0] = 0x0000
    ; Base[23..16] = 0x00
    ; Access = 0x9A -> 10011010
    ; P=1 (segment exists and can be used), DPL=00 (ring0), S=1 (not a system descriptor), Type=1010 (1 bit - execute, bit 2 - allows to call from unpriviliged levels, bit 3 - readable, bit 4 - accessed )
    ; Flags + Limit[19..16] = 0xCF -> 11001111
    ; G=1 (limit * 4KB), D/B=1 (32 bit instructions), L=0 (32 bit code), Limit[19..16] = 1111
    ; Base[31..24] = 0x00
    ; 
    ; 0x00209A0000000000:
    ;
    ; Limit[15..0] = 0x0000 (ignored)
    ; Base[15..0] = 0x0000
    ; Base[23..16] = 0x00
    ; Access = 0x9A -> 10011010
    ; P=1 (segment exists and can be used), DPL=00 (ring0), S=1 (not a system descriptor), Type=1010 (1 bit - execute, bit 2 - allows to call from unpriviliged levels, bit 3 - readable, bit 4 - accessed )
    ; Flags + Limit[19..16] = 0x20 -> 00100000
    ; G=0(limit * 0), D/B=0(16 bit instructions, needed for x64 mode), L=1 (64 bit code), Limit[19..16] = 0
    ; 

    dq 0x0000000000000000 ; NULL
    dq 0x00CF9A000000FFFF ; 32-bit code descriptor (exec/read).
    dq 0x00CF92000000FFFF ; 32-bit data descriptor (read/write).
    dq 0x00209A0000000000 ; 64-bit code descriptor (exec/read).
    dq 0x0000920000000000 ; 64-bit data descriptor (read/write).
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

times 510-($-$$) db 0
dw 0xAA55
