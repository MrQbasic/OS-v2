;syscounter_init
;syscounter_irq
;-------------------------------------------------------------------------------------------
[bits 64]

syscounter_init:
    push rax
    push rbx
    push rcx
    push rdx
    ;set isr
    mov rax, syscounter_irq
    mov bx, 0x08
    mov cx, 0x20
    mov dx, 0x8E00
    call idt_set
    ;exit
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

syscounter_irq:
    push rdi
    ;get pointer and inc it
    mov rdi, syscounter
    inc qword [rdi]
    ;exit
    pop rdi
    call pic_eoi
    iretq 

;-------------------------------------------------------------------------------------------
syscounter:             dq 0