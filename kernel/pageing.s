
;page_map             rax = p-addr / rbx = v-addr / cl = flags
;page_unmap           rax = v-addr
;page_find_map                                                  => rax = address of page
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
        or rax, page_plm4_default_flags
        mov [rsi], rax
        mov rbx, rsi
        mov rdi, page_T_plm4
        call screen_print_string
        jmp .reentry
    .no_pdpt:
        mov rsi, rax
        call page_find_map
        or rax, page_pdpt_default_flags
        mov [rsi], rax
        mov rbx, rsi
        mov rdi, page_T_pdpt
        call screen_print_string
        jmp .reentry
    .no_pd:
        mov rsi, rax
        call page_find_map
        or rax, page_pd_default_flags
        mov [rsi], rax
        mov rbx, rsi
        mov rdi, page_T_pd
        call screen_print_string
        jmp .reentry


page_unmap:
    ret

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

page_start:         dq 0    ; start addr of pages

;text
page_E_space:       db "\nERROR->no space left for mem-map pages! \e"
page_T_plm4:        db "\nGet sapce for plm4e  ENTRY:\rA  ADDR:\rB\e"
page_T_pdpt:        db "\nGet sapce for pdpte  ENTRY:\rA  ADDR:\rB\e"
page_T_pd:          db "\nGet sapce for pde    ENTRY:\rA  ADDR:\rB\e"

page_T_ree:         db "\nreentry\e"

;consts
page_plm4_default_flags     equ 0b00000011
page_pdpt_default_flags     equ 0b00000011
page_pd_default_flags       equ 0b00000011  
page_numpages       equ 1023

;page index
page_pages:
times 1024          db 0x00