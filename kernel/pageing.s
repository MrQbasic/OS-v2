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
    .reentry:
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
    mov rbx, [rax]
    test rbx, 1
    jz .no_pt
    mov rsi, page_buffer_p_addr
    mov rbx, [rsi]
    mov rsi, page_filter
    and rbx, [rsi]
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
        mov rdi, page_E_pml4
        call screen_print_string
        mov rdx, [page_buffer_v_addr]
        mov rbx, 0xFF8000000000
        and rdx, rbx
        shr rdx, 27
        call screen_print_hex_q
        jmp $
    .no_pdpt:
        mov rdi, page_E_pdpt
        call screen_print_string
        mov rdx, [page_buffer_v_addr]
        mov rbx, 0x7FC0000000
        and rdx, rbx
        shr rdx, 18
        call screen_print_hex_q
        jmp $
    .no_pd:
        mov rdi, page_E_pd
        call screen_print_string
        mov rdx, [page_buffer_v_addr]
        mov rbx, 0x3FE00000
        and rdx, rbx
        shr rdx, 9
        call screen_print_hex_q
        jmp $
    .no_pt:
        mov rdi, page_E_pt
        call screen_print_string
        mov rdx, [page_buffer_v_addr]
        mov rbx, 0x1FF000
        and rdx, rbx
        call screen_print_hex_q
        jmp $

;-------------------------------------------------------------------------------------------
;vars
page_pml4e:         dq 0
page_pdpte:         dq 0
page_pde:           dq 0

page_pml4_base:     dq 0
page_pdpt_base:     dq 0
page_pd_base:       dq 0
page_pt_base:       dq 0

page_buffer_p_addr: dq 0
page_buffer_v_addr: dq 0
page_buffer_flags:  db 0

page_filter:        dq 0

page_E_pml4:        db "\nERROR->no PML4 entry!\e"
page_E_pdpt:        db "\nERROR->no PDPT entry!\e"
page_E_pd:          db "\nERROR->no PD entry!\e"
page_E_pt:          db "\nERROR->no PT entry!\e"