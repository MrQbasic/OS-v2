;ahci_init
;ahci_pci_list
;-------------------------------------------------------------------------------------------
[bits 64]

ahci_init:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    ;get boot drive pci bus+dev
    call ahci_pci_list
    ;verify
    mov rsi, AHCI_V_DRIVES_FOUND
    cmp byte [rsi], 0x01
    je .skipp1
        jmp $
    .skipp1:
    ;set position of new cfg space
    mov rax, 0x0000000040011000
    mov rsi, AHCI_A_HBA_P
    mov qword [rsi], rax
    ;----
    mov rbx, 0x00000000C0000000
    mov rsi, AHCI_A_HBA_V
    mov qword [rsi], rbx
    ;allocate memory
    mov cl, 0b00000011
    mov dx, 0x500
    .l1:
        add rax, 0x1000
        add rbx, 0x1000
        call page_map
        dec dx
        jnz .l1
    ;get old cfg space address
    mov rsi, AHCI_V_PCI_BUS
    mov al, [rsi]
    mov rsi, AHCI_V_PCI_DEV
    mov bl, [rsi] 
    mov cl, 0x00
    xor rdx, rdx
    mov dl, 0x24
    call pci_read_cfg_d
    ;copy old cfg to cfg
    mov rsi, AHCI_A_HBA_V
    mov rax, rdx
    mov rbx, [rsi]
    mov rcx, 0x1100
    call mem_cp
    ;set cfg space to new cfg
    mov dl, 0x24
    mov rsi, [rsi]
    call pci_write_cfg_d




    ;return
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

ahci_pci_list:
    push rdi
    push rax            ;bus counter  
    push rbx            ;dev counter
    push rcx        
    push rdx
    mov rdi, AHCI_T_LIST_TITLE
    call screen_print_string
    xor rax, rax 
    xor rcx, rcx
    mov dl, 0x08        ;offset to reg 2
    .l1:
        xor rbx, rbx    ;reset bus counter
        .l2:
            push rax
            push rbx
            push rcx
            push rdx
            ;get pci reg 0x02
            mov dl, 0x08
            call pci_read_cfg_d
            ror rax, 24
            ;chek if it is PCI_C_CLASS_STORAGE
            cmp al, 0x01
            jne .skipp1
            mov rdi, rax
            pop rdx
            pop rcx
            pop rbx
            pop rax
            push rax
            push rbx
            push rcx
            push rdx
            mov rcx, rdi
            rol rdi, 8
            mov rdx, rdi
            mov rdi, AHCI_T_LIST_FOUND
            call screen_print_string
            mov rdi, AHCI_V_DRIVES_FOUND
            inc byte [rdi]
            mov rdi, AHCI_V_PCI_BUS
            mov [rdi], al
            mov rdi, AHCI_V_PCI_DEV
            mov [rdi], bl
            .skipp1:
            pop rdx
            pop rcx
            pop rbx
            pop rax
            inc bx
            cmp bx, 0x100
            jne .l2
        inc ax
        cmp ax, 0x100
        jne .l1
    mov rdi, AHCI_V_DRIVES_FOUND
    mov bl, [rdi]
    cmp bl, 0x00
    jne .skipp2
        mov rdi, AHCI_T_LIST_FOUND_NO
        call screen_print_string
    .skipp2:
    mov rdi, AHCI_T_LIST_END
    call screen_print_string
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rdi
    ret

;-------------------------------------------------------------------------------------------
;text
AHCI_T_LIST_TITLE:      db "\n---PCI DRIVES---\e"
AHCI_T_LIST_END:        db "\n----------------\e"
AHCI_T_LIST_FOUND:      db "\nBUS:\ra DEV:\rb\  CLASS:\rc SUBCLASS:\rd\e"
AHCI_T_LIST_FOUND_NO:   db "\nNO DRIVE FOUND\e"
;vars
AHCI_V_DRIVES_FOUND:    db 0x00
AHCI_V_PCI_BUS:         db 0x00
AHCI_V_PCI_DEV:         db 0x00
;addr
AHCI_A_HBA_V:           dq 0x00
AHCI_A_HBA_P:           dq 0x00