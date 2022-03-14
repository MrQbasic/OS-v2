;page_map             rax = p-addr / rbx = v-addr / cl = flags
;-------------------------------------------------------------------------------------------
[bits 64]

page_map:
    push rdi
    push rax
    push rbx
    push rcx
    push rdx
    ;save the input values
    mov [page_buffer_p_addr], rax
    mov [page_buffer_v_addr], rbx
    mov [page_buffer_flags], cx
    ;setup filter
    mov cl, [V_P_ADDR_BITS]
    mov bl, 12
    call math_fill
    mov [page_filter], rax
    ;get the PML4 addr from cr3
    mov rdx, cr3    
    mov [page_pml4_base], rdx
    .reentry:
    ;get pointer to PML4E
    mov rbx, [page_buffer_v_addr]
    mov rdx, 0xFF8000000000
    and rbx, rdx 
    shr rbx, 39
    mov rax, 8
    mul rbx
    add rax, [page_pml4_base]
    mov rbx, [rax]
    mov [page_pml4e], rbx
    ;get the PDPT_base from PML4E
    test rbx, 1
    jz .no_pml4e
    and rbx, [page_filter]
    mov [page_pdpt_base], rbx
    ;get the PDPTE
    mov rdx, 0x7FC0000000
    mov rbx, [page_buffer_v_addr]
    and rbx, rdx
    shr rbx, 30
    mov rax, 8
    mul rbx
    add rax, [page_pdpt_base]
    mov rbx, [rax]
    mov [page_pdpte], rbx
    ;get the PD_base from PDPTE
    test rbx, 1
    jz .no_pdpt
    and rbx, [page_filter]
    mov [page_pd_base], rbx
    ;get the PDE
    mov rdx, 0x3FE00000
    mov rbx, [page_buffer_v_addr]
    and rbx, rdx
    shr rbx, 21
    mov rax, 8
    mul rbx 
    add rax, [page_pd_base]
    mov rbx, [rax]
    mov [page_pde], rbx
    ;get the PT_base from PDE
    test rbx, 1
    jz .no_pd
    and rbx, [page_filter]
    mov [page_pt_base], rbx
    ;set the PTE
    mov rdx, 0x1FF000
    mov rbx, [page_buffer_v_addr]
    and rbx, rdx
    shr rbx, 12
    mov rax, 8
    mul rbx
    add rax, [page_pt_base]
    mov rbx, [rax]
    test rbx, 1
    jz .no_pt
    mov rbx, [page_buffer_p_addr]
    and rbx, [page_filter]
    or bl, [page_buffer_flags]
    mov [rax], rbx
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rdi
    ret
    .no_pml4e:
        mov rdi, page_E_pml4
        call screen_print_string
        jmp $
    .no_pdpt:
        mov rdi, page_E_pdpt
        call screen_print_string
        jmp $
    .no_pd:
        mov rdi, page_E_pd
        call screen_print_string
        jmp $
    .no_pt:
        mov rdi, page_E_pt
        call screen_print_string
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