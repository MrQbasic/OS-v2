[bits 64]
kernelstart:
    ;clear screen
    call screen_clear
    mov rdi, T_MSG_KERNEL
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

    ;print done string
    mov rdi, T_MSG_END
    call screen_print_string

    jmp $


T_MSG_KERNEL:       db "---KERNEL-IN-64BIT-MODE---\e"
T_MSG_PIC:          db "\nRemaped IRQs\e"
T_MSG_IDT:          db "\nEnable IDT\e"
T_MSG_EXC:          db "\nSetup exception handler\e"
T_MSG_END:          db "\nDone with boot process \e"

%include "./screen.s"
%include "./idt.s"
%include "./pic.s"
%include "./exception.s"