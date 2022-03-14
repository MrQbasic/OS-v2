;math_fill         rax = out / cl number of bits / bl = offset
;-------------------------------------------------------------------------------------------
[bits 64]

math_fill:
    push rcx
    mov rax, 1
    shl rax, cl
    sub rax, 1
    mov cl, bl
    shl rax, cl
    pop rcx
    ret

