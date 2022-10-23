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
    push r8   ; page filter buffer
    push r9   ; buffer for v-addr
    push r10  ; buffer for p-addr
    push r11  ; buffer for flags
    push r12  ; buffer of base addr of ervery stage
    ;
    ;save the input values
    mov r10, rax
    mov r9,  rbx
    and rcx, 0x0000_0000_0000_00FF
    mov r11, rcx
    ;setup filter
    mov rsi, V_P_ADDR_BITS
    mov cl, [rsi]
    dec cl
    mov bl, 12
    call math_fill
    mov r8, rax
    ;get the PML4 addr from cr3
    mov rdx, cr3
    mov r12, rdx
    ;get pointer to PML4E
    mov rbx, r9
    mov rdx, 0xFF8000000000
    and rbx, rdx
    shr rbx, 39
    mov rax, 8
    mul rbx
    add rax, r12
    mov rbx, [rax]
    ;get the PDPT_base from PML4E
    test rbx, 1
    jz .no_pml4e
    and rbx, r8
    mov r12, rbx
    ;get the PDPTE
    mov rdx, 0x7FC0000000
    mov rbx, r9
    and rbx, rdx
    shr rbx, 30
    mov rax, 8
    mul rbx
    add rax, r12
    mov rbx, [rax]
    ;get the PD_base from PDPTE
    test rbx, 1
    jz .no_pdpte
    and rbx, r8
    mov r12, rbx
    ;get the PDE
    mov rdx, 0x3FE00000
    mov rbx, r9
    and rbx, rdx
    shr rbx, 21
    mov rax, 8
    mul rbx 
    add rax, r12
    mov rbx, [rax]
    ;get the PT_base from PDE
    test rbx, 1
    jz .no_pde
    and rbx, r8
    mov r12, rbx
    ;set the PTE
    mov rdx, 0x1FF000
    mov rbx, r9
    and rbx, rdx
    shr rbx, 12
    mov rax, 8
    mul rbx
    add rax, r12
    ;-
    mov rbx, r10
    and rbx, r8
    or rbx, r11
    mov [rax], rbx
    ;exit
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
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
        call screen_print_no
        call screen_print_no
        jmp $
    .no_pdpte:
        call screen_nl
        call screen_print_no
        call screen_print_no
        jmp $
    .no_pde:
        call screen_nl
        call screen_print_no
        jmp $

mem_page_res_plm4e:     dq 0
mem_page_res_pdpte:     dq 0
mem_page_res_pde:       dq 0