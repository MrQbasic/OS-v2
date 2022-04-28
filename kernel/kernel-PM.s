;https://wiki.osdev.org/Setting_Up_Long_Mode
;https://wiki.osdev.org/Detecting_Memory_(x86)#Getting_an_E820_Memory_Map

[org 0x1000]
[bits 16]
    ;kill cursor
    mov ah, 0x01
	mov cx, 0x2607
    int 0x10

memorymap:  
    mov ax, 0
    mov es, ax
    mov di, 0x8004
    xor ebx, ebx
    xor bp, bp
    mov edx, 0x534D4150
    mov eax, 0x0000e820
    mov dword [es:di + 20], 1
    mov ecx, 24
    int 0x15
    jc reboot
    mov edx, 0x534D4150
    cmp eax, edx
    jne reboot
    test ebx, ebx
    je reboot

.l1:
    mov eax, 0xe820
    mov dword [es:di + 20], 1
    mov ecx, 24
    int 0x15
    jc .exit
    mov edx, 0x534D4150
.jumpin:
    jcxz .skipent
    cmp cl, 20
    jbe .notext
    test byte[es:di + 20], 1
    je .skipent
.notext:
    mov ecx, [es:di + 8]
    or ecx, [es:di + 12]
    jz .skipent
    inc bp
    add di, 24
.skipent:
    test ebx, ebx
    jne .l1
.exit:
    mov di, 0x7F00
    mov [es:di], bp

    jmp PM_enter

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
    ;setup PLM4 table
    mov edi, PML4_BASE
    mov cr3, edi
    xor eax, eax
    mov ecx, 4096
    rep stosd
    mov edi, cr3
    mov dword [edi], 0x71003
    add edi, 0x1000
    mov dword [edi], 0x72003
    add edi, 0x1000
    mov dword [edi], 0x73003
    add edi, 0x1000
    mov ebx, 0x00000003
    mov ecx, 512
    loop1:
    mov dword [edi], ebx
    add ebx, 0x1000
    add edi, 8
    loop loop1
    mov eax, cr4
    or eax, (1 << 5)
    mov cr4, eax
    ;enter LM
    mov eax, (CR4_PAE | CR4_PGE) 
    mov cr4, eax
    mov eax, PML4_BASE
    mov cr3, eax
    mov ecx, 0xC0000080
    rdmsr
    or eax, EFER_LME
    wrmsr
    mov ebx, cr0
    or ebx, (CR0_PG)
    mov cr0, ebx
    ;setup GDT
    lgdt [GDT64.Pointer] 
    mov ax, GDT64.Data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp GDT64.Code:kernel64

reboot:
    lidt[rebootidt]
rebootidt:
    dw 0
    dd 0
;-------------------------------------------------------------------------------------------
PML4_BASE equ 0x70000
CR0_PE    equ 1 << 0
CR0_PG    equ 1 << 31
CR4_PAE   equ 1 << 5
CR4_PGE   equ 1 << 7
EFER_LME  equ 1 << 8
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
    .Pointer:
        dw $ - GDT64 - 1
        dq GDT64
;---------------------------------------------------------
kernelstart equ 0x80000000
V_stackstart  equ 0x0000400000000000
P_stackstart  equ 0x0000000040001000
;---------------------------------------------------------
%include "./mem/page_find_map.s"
%include "./mem/page_get_paddr.s"
%include "./mem/page_map.s"
%include "./mem/page_vars.s"
%include "./math.s"
%include "./screen.s"
%include "./cpu/exception.s"
%include "./cpu/idt.s"
%include "./cpu/pic.s"
V_P_ADDR_BITS:      db 0
[bits 64]
kernel64:
    ;remap IRQs
    mov bl, 0x20
    mov bh, 0x28
    call pic_remap
    ;init idt
    call idt_init
    ;setup exception handler
    call exc_init
    ;clear screen
    call screen_clear
    ;get pAddr width
    mov eax, 0x80000008
    cpuid
    mov [V_P_ADDR_BITS], al
    ;creat pml4, pdpt, pd, pt
    ;plm4e
    mov rax, 0x70400
    mov rbx, 0x77003
    mov [rax], rbx        
    ;pdpte
    mov rax, 0x71010
    mov rbx, 0x75003
    mov [rax], rbx
    ;-
    mov rax, 0x77000
    mov rbx, 0x78003
    mov [rax], rbx
    ;pd
    mov rax, 0x75000
    mov rbx, 0x76003
    mov [rax], rbx
    ;-
    mov rax, 0x78000
    mov rbx, 0x79003
    mov [rax], rbx
    ;-

    ;map the kernel
    mov dx, 10
    mov cl, 0b00000011
    mov rax, next_kernel
    mov rbx, kernelstart
    .loop2:
        call page_map
        add rax, 0x1000
        add rbx, 0x1000
        dec dx
        jnz .loop2


    ;map the stack
    mov cl, 0b00000011
    mov rax, P_stackstart
    mov rbx, V_stackstart
    mov dx, 0x10
    .loop3:
        call page_map
        add rax, 0x1000
        add rbx, 0x1000
        dec dx
        jnz .loop3

    mov rdx, V_stackstart
    add rdx, 0xFFFF
    mov rbp, rdx
    mov rsp, rbp

    mov rax, kernelstart
    jmp rax

align 0x1000                               ;align for next kernel part to start at an known address to page map
next_kernel: