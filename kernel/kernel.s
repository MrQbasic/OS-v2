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
    
    mov edi, T_R
    call screen_print_string
    jmp $

T_TEST: db "\nHELLO WORLD!\e"

T_R:    db "\nA: \rA\nB: \rB\nC: \rC\nD: \rD\e"

%include "./screen.s"