;idt_setreg            ax = size
;idt_set               rax = offset / bx = SegmenSelector / cx = idte / dx = Flags
;idt_init
;-------------------------------------------------------------------------------------------

idt_init:
    push rax
    push rcx
    mov rax, isr_default            ;setup offset
    mov bx, 0                       ;setup segment selector
    mov dx, 0x8E00                  ;setup flags (64-bit intr kernel gate)
    xor rcx, rcx                    ;zero counter
    .loop1:
        call idt_set
        inc rcx                     ;counter += 1
        cmp rcx, 0xFF
        jle .loop1
    mov ax, 0xFF 
    call idt_setreg
    pop rcx
    pop rax
    ret

idt_set:
    mov [V_AReg], rax
    mov [V_BReg], rbx
    mov [V_CReg], rcx
    mov [V_DReg], rdx
    push rdi
    ;setup pointer
    mov rdi, [V_IDT_BASE]           ;get a pointer to the base addr of the idt
    mov ax, 16                      ;1 IDTE = 16 bytes
    mul cx                          ;16 times the IDTE_NUM
    and rax, 0xFFFF                 ;get the lowes word of rax
    add rdi, rax                    ;add as an offset to pointer
    mov rdx, rdi
    call screen_print_hex_q
    call screen_nl
    mov rax, [V_AReg]
    mov rdx, [V_DReg]
    ;dword 0
    mov rbx, [V_BReg]
    mov rax, [V_AReg]
    shl ebx, 16                     ;set segsel to upper 16 bits
    and eax, 0xFFFF                 ;get bits 0-15 from offset
    or ebx, eax                     ;or both together
    mov [rdi], ebx                  ;write it
    ;dword 1
    mov rax, [V_AReg]               ;ger Offset back
    and rax, 0xFFFF0000             ;get scond lowest word of the offset
    mov rbx, [V_DReg]               ;get flags back
    and edx, 0xFFFF                 ;filter flags
    or eax, ebx                     ;or both together
    mov [rdi+4], eax                ;write it
    ;dword 2
    mov rax, [V_AReg]               ;get Offset back
    and rax, 0xFFFFFFFF00000000     ;get higher dword
    mov [rdi+8], rax                ;write it
    ;dword 3
    xor ebx, ebx                    ;zero ebx
    mov [rdi+12], ebx               ;write it
    ;exit
    pop rdi
    mov rax, [V_AReg]
    mov rbx, [V_BReg]
    mov rcx, [V_CReg]
    mov rdx, [V_DReg]
    ret

idt_setreg:
    push rcx
    cmp ax, 0                       ;is size = 0
    je .error                       ;if yes then error out
    mov rdi, [V_IDT_BASE]           ;get the IDT_BASE_ADDR
    mov [IDTR.offset], rdi          ;set the offset
    mov cx, 16                      ;setup 16 for mul
    mul cx                          ;size = size * 16
    add ax, 16                      ;set size += 16
    mov [IDTR.size], ax             ;set the size
    cli
    lidt[IDTR]                      ;load IDTR
    ;sti
    pop rcx
    ret
    .error:
        mov rdi, T_E_IDTR           ;set pointer to error string
        call screen_print_string    ;print error string
        jmp $                       ;hang

;-------------------------------------------------------------------------------------------
;Struc
IDTR:
    .size:      dw 0
    .offset:    dq 0
;Text
T_E_IDTR:       dd "\nERROR-> IDTR can not have a size of 0!\e"
;Vars
V_IDT_BASE:     dq 0x100000
V_AReg:         dq 0
V_BReg:         dq 0
V_CReg:         dq 0
V_DReg:         dq 0
T_INT:          db "\nINT!\e"
;-------------------------------------------------------------------------------------------
isr_default:
    push rax
	mov al, 0x20
    out 0x20, al
    pop rax
    jmp $
	iretq