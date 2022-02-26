[bits 64]
kernelstart:
    call screen_clear
    mov rdi, T_KERNEL_MSG
    call screen_print_string

    call idt_init
    int 0x70
    jmp $


T_KERNEL_MSG:       db "---KERNEL-IN-64BIT-MODE---\e"
T_KERNEL_END:       db "\n Done with boot process "

%include "./screen.s"
%include "./idt.s"
