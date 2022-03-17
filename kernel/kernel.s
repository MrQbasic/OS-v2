[org 0x40000000]
[bits 64]
kernelstart:
    ;clear screen + start msg
    call screen_clear
    mov rdi, T_MSG_KERNEL
    call screen_print_string

    ;print kernel start addr
    mov rax, kernelstart
    mov rdi, T_MSG_SADDR
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
    mov [V_P_ADDR_BITS], al
    mov [V_L_ADDR_BITS], ah
    mov edi, T_MSG_PAB
    call screen_print_string
    mov dl, al
    call screen_print_hex_b
    mov edi, T_MSG_LAB
    call screen_print_string
    mov dl, ah
    call screen_print_hex_b

    ;print done string
    mov rdi, T_MSG_END
    call screen_print_string

    mov cl, 0b00000011
    mov rbx, 0x9000
    mov rax, 0x1000
    call page_map

    jmp $


T_MSG_KERNEL:       db "---KERNEL-IN-64BIT-MODE---\e"
T_MSG_SADDR:        db "\nKernel start addr: \rA\e"
T_MSG_PIC:          db "\nRemaped IRQs\e"
T_MSG_IDT:          db "\nEnable IDT\e"
T_MSG_EXC:          db "\nSetup exception handler\e"
T_MSG_PAB:          db "\nPhysical address bits: 0x\e"
T_MSG_LAB:          db "\nLinear address bits:   0x\e"
T_MSG_END:          db "\nDone with boot process \e"

V_P_ADDR_BITS:      db 0
V_L_ADDR_BITS:      db 0

%include "./screen.s"
%include "./idt.s"
%include "./pic.s"
%include "./exception.s"
%include "./pageing.s"
%include "./math.s"