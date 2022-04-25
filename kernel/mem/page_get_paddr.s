;page_get_paddr       rax = v-addr                              => rax = p-addr 
;-------------------------------------------------------------------------------------------
[bits 64]

page_get_paddr:
    push rsi
    push rbx
    push rcx
    push rdx
    ;save the input values
    mov rsi, page_buffer_v_addr
    mov [rsi], rax
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
    ;get the PD_base from PDPTE
    test rbx, 1
    jz .no_pdpte
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
    ;get the PT_base from PDE
    test rbx, 1
    jz .no_pde
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
    mov rbx, [rax]
    ;test PTE
    test rbx, 1
    jz .no_pte
    ;add offset to page addr
    mov rsi, page_filter        ;get pointer to filter
    and rbx, [rsi]              ;filter addr from pte
    mov rsi, page_buffer_v_addr ;get input vaddr
    mov rax, [rsi]
    mov rdx, 0x0000000000000FFF ;setup filter to get offset from addr
    and rax, rdx                ;filter offset from inter
    or rbx, rax                 ;put offset and p-addr together
    mov rax, rbx                ;set as output
    pop rdx
    pop rcx
    pop rbx
    pop rsi
    ret
    .no_pml4e:
        mov rdi, page_E_res_1
        call screen_print_string
        jmp $
    .no_pdpte:
        mov rdi, page_E_res_2
        call screen_print_string
        jmp $
    .no_pde:
        mov rdi, page_E_res_3
        call screen_print_string
        jmp $
    .no_pte:
        mov rdi, page_E_res_4
        call screen_print_string
        jmp $