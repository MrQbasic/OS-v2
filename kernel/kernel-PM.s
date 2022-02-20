[org 0x1000]
[bits 16]
    ;kill cursor
	mov ah, 0x01
	mov cx, 0x2607
	int 0x10
	jmp PM_enter
	jmp $
	db "THIS IS THE KERNEL MADE BY LEON"
%define PM_STACK 0x90000
PM_enter:
	cli
	lgdt[gdtrbuffer]
	mov eax, cr0
	or eax, 0x1
	mov cr0, eax	
	jmp CODE_SEG:PM_enter_2
[bits 32]
PM_enter_2:
	mov ax, DATA_SEG
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ebp, PM_STACK
	mov esp, ebp
	jmp start
;------------------------------------------------------------------------------------------------------------------------------

start:
    ;check if LM is supported
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb reboot
    mov eax, 0x80000001
    cpuid
    test edx, (1 << 29)
    jz reboot
    ;go into LM
    mov ecx, 0xC0000080
    rdmsr
    or eax, (1 << 8)
    wrmsr
    ;setup GDT
    lgdt [GDT64.Pointer] 
	jmp GDT64.Code:LM

reboot:
    lidt[IDTR]
IDTR:
    dw 0
    dd 0

;---GDT-TO-ENTER-PM---
gdt_start:
gdt_null:
	dd 0
	dd 0
gdt_code:
	dw 0xffff
	dw 0x0000
	db 0x00
	db 10011010b
	db 11001111b
	db 0x00
gdt_data:
	dw 0xffff
	dw 0x0000
	db 0x00
	db 10010010b
	db 11001111b
	db 0x00
gdt_end:
gdtrbuffer:
	dw gdt_end - gdt_start - 1
	dd gdt_start
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
;---GDT-TO-ENTER-LM---
PRESENT        equ 1 << 7
NOT_SYS        equ 1 << 4
EXEC           equ 1 << 3
DC             equ 1 << 2
RW             equ 1 << 1
ACCESSED       equ 1 << 0
GRAN_4K        equ 1 << 7
SZ_32          equ 1 << 6
LONG_MODE      equ 1 << 5
GDT64:
    .Null: equ $ - GDT64
        dq 0
    .Code: equ $ - GDT64
        dd 0xFFFF
        db 0
        db PRESENT | NOT_SYS | EXEC | RW
        db GRAN_4K | LONG_MODE | 0xF
        db 0
    .Data: equ $ - GDT64
        dd 0xFFFF
        db 0
        db PRESENT | NOT_SYS | RW
        db GRAN_4K | SZ_32 | 0xF
        db 0
    .TSS: equ $ - GDT64
        dd 0x00000068
        dd 0x00CF8900
    .Pointer:
        dw $ - GDT64 - 1
        dq GDT64
;---------------------------------------------------------

[BITS 64]
LM:
    cli                           ; Clear the interrupt flag.
    mov ax, GDT64.Data            ; Set the A-register to the data descriptor.
    mov ds, ax                    ; Set the data segment to the A-register.
    mov es, ax                    ; Set the extra segment to the A-register.
    mov fs, ax                    ; Set the F-segment to the A-register.
    mov gs, ax                    ; Set the G-segment to the A-register.
    mov ss, ax                    ; Set the stack segment to the A-register.
    mov edi, 0xB8000              ; Set the destination index to 0xB8000.
    mov rax, 0x1F201F201F201F20   ; Set the A-register to 0x1F201F201F201F20.
    mov ecx, 500                  ; Set the C-register to 500.
    rep stosq                     ; Clear the screen.
    jmp $

;https://wiki.osdev.org/Setting_Up_Long_Mode