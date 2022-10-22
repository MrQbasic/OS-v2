;mem_page_map             rax = p-addr / rbx = v-addr / cl = flags
;-------------------------------------------------------------------------------------------
[bits 64]

mem_page_map:
    push rdi
    push rsi
    push rax
    push rbx
    push rcx
    push rdx
    ;save the input values
    mov rsi, mem_page_buffer_p_addr
    mov [rsi], rax
    mov rsi, mem_page_buffer_v_addr
    mov [rsi], rbx
    mov rsi, mem_page_buffer_flags
    mov [rsi], cx
    ;restore if reentry
    .reentry:
    ;setup filter
    mov rsi, V_P_ADDR_BITS
    mov cl, [rsi]
    dec cl
    mov bl, 12
    call math_fill
    mov rsi, mem_page_filter
    mov [rsi], rax
    ;get the PML4 addr from cr3
    mov rdx, cr3
    mov rsi, mem_page_pml4_base
    mov [rsi], rdx
    ;get pointer to PML4E
    mov rsi, mem_page_buffer_v_addr
    mov rbx, [rsi]
    mov rdx, 0xFF8000000000
    and rbx, rdx
    shr rbx, 39
    mov rax, 8
    mul rbx
    mov rsi, mem_page_pml4_base
    add rax, [rsi]
    mov rbx, [rax]
    ;get the PDPT_base from PML4E
    test rbx, 1
    jz .no_pml4e
    mov rsi, mem_page_filter
    and rbx, [rsi]
    mov rsi, mem_page_pdpt_base
    mov [rsi], rbx
    ;get the PDPTE
    mov rdx, 0x7FC0000000
    mov rsi, mem_page_buffer_v_addr
    mov rbx, [rsi]
    and rbx, rdx
    shr rbx, 30
    mov rax, 8
    mul rbx
    mov rsi, mem_page_pdpt_base
    add rax, [rsi]
    mov rbx, [rax]
    ;get the PD_base from PDPTE
    test rbx, 1
    jz .no_pdpt
    mov rsi, mem_page_filter
    and rbx, [rsi]
    mov rsi, mem_page_pd_base
    mov [rsi], rbx
    ;get the PDE
    mov rdx, 0x3FE00000
    mov rsi, mem_page_buffer_v_addr
    mov rbx, [rsi]
    and rbx, rdx
    shr rbx, 21
    mov rax, 8
    mul rbx 
    mov rsi, mem_page_pd_base
    add rax, [rsi]
    mov rbx, [rax]
    ;get the PT_base from PDE
    test rbx, 1
    jz .no_pd
    mov rsi, mem_page_filter
    and rbx, [rsi]
    mov rsi, mem_page_pt_base
    mov [rsi], rbx
    ;set the PTE
    mov rdx, 0x1FF000
    mov rsi, mem_page_buffer_v_addr
    mov rbx, [rsi]
    and rbx, rdx
    shr rbx, 12
    mov rax, 8
    mul rbx
    mov rsi, mem_page_pt_base
    add rax, [rsi]
    ;-
    mov rsi, mem_page_buffer_p_addr
    mov rbx, [rsi]
    mov rsi, mem_page_filter
    and rbx, [rsi]
    mov rdx, [rsi]
    mov rsi, mem_page_buffer_flags
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
        call screen_nl
        call screen_print_no
        jmp $
    .no_pdpt:
        call screen_nl
        call screen_print_no
        jmp $
    .no_pd:
        call screen_nl
        call screen_print_no
        jmp $

mem_page_pml4_base:     dq 0
mem_page_pdpt_base:     dq 0
mem_page_pd_base:       dq 0
mem_page_pt_base:       dq 0

mem_page_res_plm4:      dq 0
mem_page_res_pdpt:      dq 0
mem_page_res_pd:        dq 0
mem_page_res_pt:        dq 0

mem_page_buffer_p_addr: dq 0
mem_page_buffer_v_addr: dq 0
mem_page_buffer_flags:  db 0

mem_page_filter:        dq 0