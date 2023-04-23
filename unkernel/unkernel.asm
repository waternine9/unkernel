[BITS 16]
[ORG 0x7C00]

Boot:
    

    ; NOTE: At boot the boot drive number is stored in DL,
    ;       Preserve it for later 
    mov   [DriveNumber], dl

    ; NOTE: Activate A20
    mov   ax, 0x2403
    int   0x15
    
    ; NOTE: SETUP VBE
    jmp SetupVbe
    %include "unkernel/vesa_vbe_setup.asm"
SetupVbe:
    call VesaVbeSetup

    ; NOTE: Load GDT and activate protected mode
    cli
    lgdt  [GDTDesc]
    mov   eax, cr0
    or    eax, 1
    mov   cr0, eax
    jmp   8:After
    
DriveNumber: db 0
[BITS 32]

After:
    ; NOTE: Setup segments.
    mov   ax, 16
    mov   ds, ax
    mov   es, ax
    mov   fs, ax
    mov   gs, ax
    mov   ss, ax
    
    mov dl, [DriveNumber]
    mov edi, OS_Start
    mov ecx, 4
    call unkernel_read_ata

    ; Use scancode set 1
    mov dx, 0x60
    mov al, 0xF0
    out dx, al    
    mov al, 1
    out dx, al
    

    ; Setup keyboard and mouse
    mov dx, 0x64
    mov al, 0xAD
    out dx, al ; Disable keyboard port

    mov al, 0xA7
    out dx, al ; Disable mouse port

    
    mov al, 0x20
    out dx, al ; Request current configuration byte

    in al, 0x60 ; Read configuration byte

    or al, 0x03 ; Enable IRQ1 and IRQ 12
    and al, 0b11001111 ; Clear bits 4 and 5 to enable translation for the keyboard port

    mov bl, al
    
    mov al, 0x60
    out dx, al ; Request to send new configuration byte

    mov al, bl
    out 0x60, al ; Set new configuration byte
    
    mov al, 0xAE
    out dx, al ; Enable the keyboard port

    mov al, 0xA8
    out dx, al ; Enable the mouse port
    
    mov al, 0xD4
    out dx, al ; Request to send a command to the mouse
    
    mov al, 0xF4
    out 0x60, al ; Enable mouse data reporting

    

    jmp OS_Start

GDTStart:
    dq 0 
GDTCode:
    dw 0xFFFF     ; Limit
    dw 0x0000     ; Base
    db 0x00       ; Base
    db 0b10011010 ; Access
    db 0b11001111 ; Flags + Limit
    db 0x00       ; Base
GDTData:
    dw 0xFFFF     ; Limit
    dw 0x0000     ; Base
    db 0x00       ; Base
    db 0b10010010 ; Access
    db 0b11001111 ; Flags + Limit
    db 0x00       ; Base
GDTEnd:

GDTDesc:
    .GDTSize dw GDTEnd - GDTStart ; GDT size 
    .GDTAddr dd GDTStart          ; GDT address

%include "unkernel/ata/ata.asm"

times 510-($-$$) db 0
dw 0xAA55
  
align 16
%include "unkernel/vesa_vbe_setup_vars.asm"

times 2048-($-$$) db 0

OS_Start: