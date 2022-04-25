;mem_cp_v             rax = start addr / rbx = destination addr / rcx = number of bytes
;------------------------------------------------------------------------------
[bits 64]

mem_cp_v:
    push rax
    push rbx
    push rcx
    push rdx
    .l1:
        mov dl, [rax]       ;set from counter 1
        mov [rbx], dl       ;write to counter 2
        inc rax             ;inc counter 1
        inc rbx             ;inc counter 2
        dec rcx             ;dec counter 3
        jnz .l1             ;if not 0 then loop
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret