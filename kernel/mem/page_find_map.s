;page_find_map                                                  => rax = address of page
;-------------------------------------------------------------------------------------------
[bits 64]

page_find_map:
    push rdx                ;save reg       
    push rdi
    mov rdi, page_pages     ;get pointer to pageindex
    xor rdx, rdx            ;set counter to 0
    .l1: 
        mov rax, rdi
        add rax, rdx        ;get pointer + offset
        mov al, [rax]       ;get byte from pointer 
        cmp al, 0x00        ;is byte 0 ?
        je .return          ;yes then return
        inc dx              ;inc counter
        cmp dx, page_numpages   ;check if done
        jle .l1             ;if not done keep going
    mov rdi, page_E_space   ;set pointer to error string
    call screen_print_string;print string
    jmp $                   ;hang on error
    .return:                ;return
    add rdi, rdx            ;get pointer no page index
    mov byte [rdi], 0x01    ;make as used
    mov rax, 0x1000         ;factors of mul 1 = 0x1000 / 2 = rdx index of page / res = rax
    mul rdx
    mov rdi, page_start     ;get start addr
    add rax, [rdi]          ;get starting locations of pages
    pop rdi 
    pop rdx
    ret