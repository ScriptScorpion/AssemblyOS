; boot.asm
org 0x7C00
bits 16

cursor_pos db 2
boot_drive db 0
null db 0

_start:
    jmp real_mode
real_mode:
    ; clearing system registers
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    
    mov [boot_drive], dl
    
    ; clear screen
    mov ax, 0x0003
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
    cli
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Page Map Level 4 address 
    mov edi, 0x1000
    mov dword [edi], 0x2003 
    
    ; Page Directory Pointer Table address
    mov edi, 0x2000
    mov dword [edi], 0x3003  
    
    ; Page Directory address
    mov edi, 0x3000
    mov dword [edi], 0x0083 
    
    ; Page Map Level 4 address
    mov eax, 0x1000
    mov cr3, eax
    
    ; enabling Physical Address Extension
    mov eax, cr4
    or eax, 0x00000020
    mov cr4, eax
    
    ; enabling long mode using ESSR MSR
    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x00000100
    wrmsr
    
    ; enabling paging
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
    
    jmp 0x18:long_mode

bits 64
long_mode:
    ; clearing system registers
    cli
    xor al, al
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp main_code

main_code:
    call wait_key
    test al, al
    je main_code ; jump if equal to 0
    
    ; minimum 0xB8000
    ; maximum 0xB8EFE
    
    mov ah, 0x0F
    mov rcx, 0xB8000
    add cl, BYTE [cursor_pos-2] ; TODO -> fix that it doesnt follow cursor
    mov [rcx], al
    
    call move_cursor
    
    mov rax, 1 ; pseudo second
    jmp seconds_delay


seconds_delay:
    .convert:
        imul rax, 20000000
    .loop:
        test rax, rax
        jbe main_code
        dec rax
        jmp .loop

wait_key:
    in al, 0x64
    test al, 2
    jnz wait_key

    in al, 0x60
    movzx rax, al
    mov al, [scan_to_ascii + rax]
    ret

move_cursor:

    cmp BYTE [cursor_pos], 254
    jae .stop_cursor
    jmp .continue_cursor
        
    .stop_cursor:
        ret
    .continue_cursor:
        push rax
        push rdx

        mov dx, 0x3D4
        mov al, 0x0F
        out dx, al
        mov dx, 0x3D5
        mov al, BYTE [cursor_pos] ; position from the left
        sub al, 1
        out dx, al
        
        add BYTE [cursor_pos], 2

        pop rdx
        pop rax
        ret

scan_to_ascii:
    db 0, 0 ; Error, Esc 
    db '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '='
    db 0, 0 ; Backspace, Tab 
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']'
    db 0, 0 ; Enter, Left ctrl
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
