;idt_setreg            ax = number of entries
;idt_set               rax = offset / bx = SegmenSelector / cx = idte / dx = Flags
;idt_init
;-------------------------------------------------------------------------------------------

idt_init:
    push rax
    push rcx
    mov rax, isr_default            ;setup offset
    mov bx, 0x8                     ;setup segment selector
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
    push rsi
    mov rsi, V_AReg
    mov [rsi], rax
    mov rsi, V_BReg
    mov [rsi], rbx
    mov rsi, V_CReg
    mov [rsi], rcx
    mov rsi, V_DReg
    mov [rsi], rdx
    push rdi
    ;setup pointer
    mov rsi, V_IDT_BASE
    mov rdi, [rsi]                  ;get a pointer to the base addr of the idt
    mov ax, 16                      ;1 IDTE = 16 bytes
    mul cx                          ;16 times the IDTE_NUM
    and rax, 0xFFFF                 ;get the lowes word of rax
    add rdi, rax                    ;add as an offset to pointer
    mov rsi, V_AReg
    mov rax, [rsi]
    ;dword 0
    mov rsi, V_BReg
    mov rbx, [rsi]
    mov rsi, V_AReg
    mov rax, [rsi]
    shl ebx, 16                     ;set segsel to upper 16 bits
    and eax, 0xFFFF                 ;get bits 0-15 from offset
    or ebx, eax                     ;or both together
    mov [rdi], ebx                  ;write it
    ;dword 1
    mov rsi, V_AReg
    mov rax, [rsi]                  ;ger Offset back
    and eax, 0xFFFF0000             ;get scond lowest word of the offset
    mov rsi, V_DReg
    mov rbx, [rsi]                  ;get flags back
    and edx, 0xFFFF                 ;filter flags
    or eax, ebx                     ;or both together
    mov [rdi+4], eax                ;write it
    ;dword 2
    mov rsi, V_AReg
    mov rax, [rsi]                  ;get Offset back
    shr rax, 32                     ;get higher dword
    mov [rdi+8], eax                ;write it
    ;dword 3
    xor ebx, ebx                    ;zero ebx
    mov [rdi+12], ebx               ;write it
    ;exit
    pop rdi
    mov rsi, V_AReg
    mov rax, [rsi]
    mov rsi, V_BReg
    mov rbx, [rsi]
    mov rsi, V_CReg
    mov rcx, [rsi]
    mov rsi, V_DReg
    mov rdx, [rsi]
    pop rsi
    ret

idt_setreg:
    push rcx
    push rdi
    push rsi
    cmp ax, 0                       ;is ax = 0
    je .error                       ;if yes then error out
    mov cx, 16                      ;pepare for mul
    mul cx                          ;mul number of entries * size of one (16)
    add ax, 16                      ;add 1 entrys size - 1
    mov rsi, IDTR.size
    mov [rsi], ax                   ;set IDTR size
    mov rsi, V_IDT_BASE
    mov rdi, [rsi]                  ;get the idt offset
    mov rsi, IDTR.offset
    mov [rsi], rdi                  ;set IDTR offset
    cli                             ;dissable irqs
    mov rsi, IDTR
    lidt [rsi]                      ;load IDTR
    pop rsi
    pop rdi 
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
    push rdi
    mov rdi, T_INT
    ;call screen_print_string

    pop rdi
    call pic_eoi
    iretq 
