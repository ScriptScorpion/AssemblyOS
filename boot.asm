bits 16
org 0x7C00

_start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [boot_drive], dl

    ; clear screen
    mov ax, 0x03
    int 0x10

    
    mov ah, 0x02        ; read sector function
    mov al, 0x04        ; amount of sectors to read  (SIZE / 512)
    
    mov bx, 0x1000      ; Destination Offset
    mov dh, 0x00        ; Head 
    mov dl, [boot_drive]    ; BIOS drive number 
    mov ch, 0x00        ; Cylinder
    mov cl, 0x02        ; start from sector specified (1-63)

    int 0x13
    
    jc fail
    
    mov dl, [boot_drive]
    jmp 0x0000:0x1000 ; jump to segment:offset

    jmp $

fail:
    mov ah, 0x0E
    mov al, 'E'
    int 0x10
    mov ah, 0x0E
    mov al, 'R'
    int 0x10
    mov ah, 0x0E
    mov al, 'R'
    int 0x10
    mov ah, 0x0E
    mov al, 'O'
    int 0x10
    mov ah, 0x0E
    mov al, 'R'
    int 0x10
    hlt
    jmp $


boot_drive db 0

times 510 - ($ - $$) db 0
dw 0xAA55
