[bits 64]
[org 0x80000000]
kernelstart:
    ;clear screen + start msg
    call screen_clear
    mov rdi, T_MSG_KERNEL
    call screen_print_string

    ;print kernel start addr
    mov rax, kernelstart
    mov rdi, T_MSG_SADDR
    call screen_print_string

    ;print stack start addr
    mov rax, rbp
    mov rdi, T_MSG_STACK
    call screen_print_string

    ;remap IRQs
    mov bl, 0x20
    mov bh, 0x28
    call pic_remap
    mov rdi, T_MSG_PIC
    call screen_print_string

    ;init idt
    call idt_init
    mov rdi, T_MSG_IDT
    call screen_print_string

    ;setup exception handler
    call exc_init
    mov rdi, T_MSG_EXC
    call screen_print_string

    ;get the amount of physical address bits
    mov eax, 0x80000008
    cpuid
    mov rsi, V_P_ADDR_BITS
    mov [rsi], al
    mov rsi, V_L_ADDR_BITS
    mov [rsi], ah
    mov rdi, T_MSG_PAB
    call screen_print_string
    mov dl, al
    call screen_print_hex_b
    mov rdi, T_MSG_LAB
    call screen_print_string
    mov dl, ah
    call screen_print_hex_b


    ;setup mappages start addr
    mov rax, kernelend
    mov rdi, page_start
    mov [rdi], rax
    mov rdi, T_MSG_PAGE
    call screen_print_string





    mov rax, 0x0000500000000000
    mov rbx, 0x0000500000000000
    call page_map
    mov [rbx], rax







    jmp $

    ;Setup AHCI
    mov rdi, T_MSG_AHCI
    call screen_print_string 
    call ahci_init


    ;Print done msg
    mov rdi, T_MSG_END
    call screen_print_string
    jmp $


T_MSG_KERNEL:       db "---KERNEL-IN-64BIT-MODE---\e"
T_MSG_SADDR:        db "\nKernel start addr: \rA\e"
T_MSG_STACK:        db "\nStack  start addr: \rA\e"
T_MSG_PIC:          db "\nRemaped IRQs\e"
T_MSG_IDT:          db "\nEnable IDT\e"
T_MSG_EXC:          db "\nSetup exception handler\e"
T_MSG_PAB:          db "\nPhysical address bits: 0x\e"
T_MSG_LAB:          db "\nLinear address bits:   0x\e"
T_MSG_AHCI:         db "\nSetup AHCI\e"
T_MSG_END:          db "\nDone with boot process \e"
T_MSG_PAGE:         db "\nMAP_PAGES start addr: \rA\e"

V_P_ADDR_BITS:      db 0
V_L_ADDR_BITS:      db 0

;include drivers
%include "./driver/pci/pci.s"
%include "./driver/ata/ahci.s"

%include "./screen.s"
%include "./idt.s"
%include "./pic.s"
%include "./exception.s"
%include "./math.s"
%include "./memory.s"
%include "./pageing.s"

align 0x1000    ;get end of kernel page aligned
kernelend:      db 0x00