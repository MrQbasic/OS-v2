[bits 64]
kernelstart:
    call screen_clear
    mov rdi, T_KERNEL_MSG
    call screen_print_string

    call idt_init
    int 0x0
    jmp $


T_KERNEL_MSG:       db "---KERNEL-IN-64BIT-MODE---\e"

%include "./screen.s"
%include "./idt.s"