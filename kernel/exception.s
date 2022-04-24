;exc_init
;-------------------------------------------------------------------------------------------
[bits 64]

exc_init:
    cli
    push rax
    push rbx
    push rcx
    push rdx
    ;setup acb and flags
    mov bx, 0x8
    mov dx, 0x8E00
    ;setup ervery isr
    mov cx, 0
    mov rax, exc_isr_0
    call idt_set
    mov cx, 1
    mov rax, exc_isr_1
    call idt_set
    mov cx, 3
    mov rax, exc_isr_3
    call idt_set
    mov cx, 4
    mov rax, exc_isr_4
    call idt_set
    mov cx, 5
    mov rax, exc_isr_5
    call idt_set
    mov cx, 6
    mov rax, exc_isr_6
    call idt_set
    mov cx, 7
    mov rax, exc_isr_7
    call idt_set
    mov cx, 8
    mov rax, exc_isr_8
    call idt_set
    mov cx, 10
    mov rax, exc_isr_10
    call idt_set
    mov cx, 11
    mov rax, exc_isr_11
    call idt_set
    mov cx, 12
    mov rax, exc_isr_12
    call idt_set
    mov cx, 13
    mov rax, exc_isr_13
    call idt_set
    mov cx, 14
    mov rax, exc_isr_14
    call idt_set
    mov cx, 16
    mov rax, exc_isr_16
    call idt_set
    mov cx, 17
    mov rax, exc_isr_17
    call idt_set
    mov cx, 18
    mov rax, exc_isr_18
    call idt_set
    mov cx, 19
    mov rax, exc_isr_19
    call idt_set
    mov cx, 20
    mov rax, exc_isr_20
    call idt_set
    mov cx, 21
    mov rax, exc_isr_21
    call idt_set
    mov cx, 28
    mov rax, exc_isr_28
    call idt_set
    mov cx, 29
    mov rax, exc_isr_29
    call idt_set
    mov cx, 30
    mov rax, exc_isr_30

    ;return
    pop rdx
    pop rcx
    pop rbx
    pop rax
    sti 
    ret

;-------------------------------------------------------------------------------------------

exc_isr_0:
    mov rdi, T_EXC_0
    call screen_print_string
    jmp $

exc_isr_1:
    mov rdi, T_EXC_1
    call screen_print_string
    jmp $

exc_isr_3:
    mov rdi, T_EXC_3
    call screen_print_string
    jmp $

exc_isr_4:
    mov rdi, T_EXC_4
    call screen_print_string
    jmp $

exc_isr_5:
    mov rdi, T_EXC_5
    call screen_print_string
    jmp $

exc_isr_6:
    mov rdi, T_EXC_6
    call screen_print_string
    jmp $

exc_isr_7:
    mov rdi, T_EXC_7
    call screen_print_string
    jmp $

exc_isr_8:
    mov rdi, T_EXC_8
    call screen_print_string
    jmp $

exc_isr_10:
    mov rdi, T_EXC_10
    call screen_print_string
    jmp $

exc_isr_11:
    mov rdi, T_EXC_11
    call screen_print_string
    jmp $

exc_isr_12:
    mov rdi, T_EXC_12
    call screen_print_string
    jmp $

exc_isr_13:
    mov rdi, T_EXC_13
    call screen_print_string
    jmp $

exc_isr_14:
    mov rdi, T_EXC_14
    call screen_print_string
    mov rax , cr2
    mov rdi, T_CR2
    call screen_print_string
    call screen_space
    pop rdx
    push rdx
    call screen_print_hex_q
    add esp, 4
    iretq

exc_isr_16:
    mov rdi, T_EXC_16
    call screen_print_string
    jmp $

exc_isr_17:
    mov rdi, T_EXC_17
    call screen_print_string
    jmp $

exc_isr_18:
    mov rdi, T_EXC_18
    call screen_print_string
    jmp $

exc_isr_19:
    mov rdi, T_EXC_19
    call screen_print_string
    jmp $
    
exc_isr_20:
    mov rdi, T_EXC_20
    call screen_print_string
    jmp $

exc_isr_21:
    mov rdi, T_EXC_21
    call screen_print_string
    jmp $

exc_isr_28:
    mov rdi, T_EXC_28
    call screen_print_string
    jmp $

exc_isr_29:
    mov rdi, T_EXC_29
    call screen_print_string
    jmp $

exc_isr_30:
    mov rdi, T_EXC_30
    call screen_print_string
    jmp $

;-------------------------------------------------------------------------------------------
T_EXC_0:          db "\nERROR-> Divide by zero\e"
T_EXC_1:          db "\nERROR-> Debug\e"
T_EXC_3:          db "\nERROR-> Breakpoint\e"
T_EXC_4:          db "\nERROR-> Overflow\e"
T_EXC_5:          db "\nERROR-> Bound Range Exceeded\e"
T_EXC_6:          db "\nERROR-> Invalid Opcode\e"
T_EXC_7:          db "\nERROR-> Device Not Available"
T_EXC_8:          db "\nERROR-> Double Fault\e"
T_EXC_10:         db "\nERROR-> Invalid TSS\e"
T_EXC_11:         db "\nERROR-> Segment Not Present\e"
T_EXC_12:         db "\nERROR-> Stack-Segment Fault\e"
T_EXC_13:         db "\nERROR-> General Protection Fault\e"
T_EXC_14:         db "\nERROR-> Page Fault\e"
T_EXC_16:         db "\nERROR-> x87 Floating-Point Exception\e"
T_EXC_17:         db "\nERROR-> Alignment Check\e"
T_EXC_18:         db "\nERROR-> Machine Check\e"
T_EXC_19:         db "\nERROR-> SIMD Floating-Point Exception\e"
T_EXC_20:         db "\nERROR-> Virtualization Exception\e"
T_EXC_21:         db "\nERROR-> Control Protection Exception\e"
T_EXC_28:         db "\nERROR-> Hypervisor Injection Exception\e"
T_EXC_29:         db "\nERROR-> VMM Communication Exception\e"
T_EXC_30:         db "\nERROR-> Security Exception\e"

T_CR2:            db "\n  cr2: \rA\e"