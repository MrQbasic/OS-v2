[bits 64]
kernelstart:
    call screen_clear
    mov edi, T_TEST
    call screen_print_string

    call screen_nl
    mov rdx, 0x0123456789ABCDEF
    call screen_print_hex_q

    call screen_nl
    call screen_print_bin_q
    jmp $

T_TEST: db "\nHELLO WORLD!\e"

%include "./screen.s"