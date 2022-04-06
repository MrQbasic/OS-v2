;https://wiki.osdev.org/Setting_Up_Long_Mode
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
;---------------------------------------------------------
%include "./pageing.s"
%include "./math.s"
%include "./screen.s"
%include "./exception.s"
%include "./idt.s"
%include "./pic.s"
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
    ;creat pml4 pdpt and pd and pt
    ;plm4e
    ;;mov rax, 0x70800
    ;;mov rbx, 0x74003
    ;;mov [rax], rbx        
    ;pdpte
    mov rax, 0x71010
    mov rbx, 0x75003
    mov [rax], rbx
    ;pd
    mov rax, 0x75000
    mov rbx, 0x76003
    mov [rax], rbx
    ;fill pt
    mov rdi, 0x76000
    mov rbx, 0x00000003
    mov rcx, 512
    .loop1:
        mov [rdi], rbx
        add rdi, 8
        loop .loop1
    ;map the kernel
    mov dx, 512
    mov cl, 0b00000011
    mov rax, next_kernel
    mov rbx, kernelstart
    .loop2:
        call page_map
        add rax, 0x1000
        add rbx, 0x1000
        dec dx
        jnz .loop2
    mov rax, kernelstart
    jmp rax

align 0x1000                               ;align for next kernel part to start at an known address to page map
next_kernel: