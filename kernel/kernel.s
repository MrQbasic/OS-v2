[bits 64]
kernelstart:
    call screen_clear
    mov edi, T_TEST
    call screen_print_string
    jmp $

T_TEST: db "\nHELLO WORLD!\e"

%include "./screen.s"