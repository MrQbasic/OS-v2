;page_map             rax = p-addr / rbx = v-addr / cl = flags
;-------------------------------------------------------------------------------------------
[bits 64]

page_map:
    push rdi
    push rsi
    push rax
    push rbx
    push rcx
    push rdx
    ;save the input values
    mov rsi, page_buffer_p_addr
    mov [rsi], rax
    mov rsi, page_buffer_v_addr
    mov [rsi], rbx
    mov rsi, page_buffer_flags
    mov [rsi], cx
    ;restore if reentry
    .reentry:
    ;setup filter
    mov rsi, V_P_ADDR_BITS
    mov cl, [rsi]
    mov bl, 12
    call math_fill
    mov rsi, page_filter
    mov [rsi], rax
    ;get the PML4 addr from cr3
    mov rdx, cr3
    mov rsi, page_pml4_base
    mov [rsi], rdx
    ;get pointer to PML4E
    mov rsi, page_buffer_v_addr
    mov rbx, [rsi]
    mov rdx, 0xFF8000000000
    and rbx, rdx
    shr rbx, 39
    mov rax, 8
    mul rbx
    mov rsi, page_pml4_base
    add rax, [rsi]
    mov rbx, [rax]
    mov rsi, page_pml4e
    mov [rsi], rbx
    ;get the PDPT_base from PML4E
    test rbx, 1
    jz .no_pml4e
    mov rsi, page_filter
    and rbx, [rsi]
    mov rsi, page_pdpt_base
    mov [rsi], rbx
    ;get the PDPTE
    mov rdx, 0x7FC0000000
    mov rsi, page_buffer_v_addr
    mov rbx, [rsi]
    and rbx, rdx
    shr rbx, 30
    mov rax, 8
    mul rbx
    mov rsi, page_pdpt_base
    add rax, [rsi]
    mov rbx, [rax]
    mov rsi, page_pdpte
    mov [rsi], rbx
    ;get the PD_base from PDPTE
    test rbx, 1
    jz .no_pdpt
    mov rsi, page_filter
    and rbx, [rsi]
    mov rsi, page_pd_base
    mov [rsi], rbx
    ;get the PDE
    mov rdx, 0x3FE00000
    mov rsi, page_buffer_v_addr
    mov rbx, [rsi]
    and rbx, rdx
    shr rbx, 21
    mov rax, 8
    mul rbx 
    mov rsi, page_pd_base
    add rax, [rsi]
    mov rbx, [rax]
    mov rsi, page_pde
    mov [rsi], rbx
    ;get the PT_base from PDE
    test rbx, 1
    jz .no_pd
    mov rsi, page_filter
    and rbx, [rsi]
    mov rsi, page_pt_base
    mov [rsi], rbx
    ;set the PTE
    mov rdx, 0x1FF000
    mov rsi, page_buffer_v_addr
    mov rbx, [rsi]
    and rbx, rdx
    shr rbx, 12
    mov rax, 8
    mul rbx
    mov rsi, page_pt_base
    add rax, [rsi]
    ;-
    mov rsi, page_buffer_p_addr
    mov rbx, [rsi]
    mov rsi, page_filter
    and rbx, [rsi]
    mov rdx, [rsi]
    mov rsi, page_buffer_flags
    or bl, [rsi]
    mov [rax], rbx
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rsi
    pop rdi
    ret
    .no_pml4e:
        mov rsi, rax
        call page_find_map
        call page_get_paddr
        or rax, page_plm4_default_flags
        mov [rsi], rax
        mov rbx, rsi
        mov rdi, page_T_plm4
        call screen_print_string
        jmp .reentry
    .no_pdpt:
        mov rsi, rax
        call page_find_map
        call page_get_paddr
        or rax, page_pdpt_default_flags
        mov [rsi], rax
        mov rbx, rsi
        mov rdi, page_T_pdpt
        call screen_print_string
        jmp .reentry
    .no_pd:
        mov rsi, rax
        call page_find_map
        call page_get_paddr
        or rax, page_pd_default_flags
        mov [rsi], rax
        mov rbx, rsi
        mov rdi, page_T_pd
        call screen_print_string
        jmp .reentry