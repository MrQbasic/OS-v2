[bits 64]
kernelstart:
    call screen_clear
    mov rdi, T_MSG_KERNEL
    call screen_print_string

    ;mov bl, 0x20
    ;mov bh, 0x28
    ;call pic_remap
    ;mov rdi, T_MSG_PIC
    ;call screen_print_string

    call idt_init
    int 0x0
    jmp $


T_MSG_KERNEL:       db "---KERNEL-IN-64BIT-MODE---\e"
T_MSG_PIC:          db "\nRemaped IRQs\e"
T_KERNEL_END:       db "\nDone with boot process "

%include "./screen.s"
%include "./idt.s"
