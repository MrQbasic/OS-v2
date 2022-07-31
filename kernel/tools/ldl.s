;helper lib for linked lists
;-------------------------------------------------------------------------------------------
;ldl_add       rdi = pointer to list  /  rsi = pointer to entry 
;ldl_get       rdi = pointer to list  /  rax = entry index          => rsi = pointer to entry
;ldl_remove    rdi = pointer to list  /  rax = entry index
;ldl_end       rdi = pointer to list                                => rdi = pointer to last entry on list
;-------------------------------------------------------------------------------------------
ldl_add:
    push rdi
    push rax
    .l1:
        mov rax, [rdi]      ;get pointer to next entry
        cmp rax, 0          ;check if pointer is end val
        je .exit            ;if yes then exit
        mov rdi, rax        ;if not set entry pointer to next entry        
        jmp .l1             ;loop
    .exit:
        mov [rdi], rsi      ;set next entry pointer of last entry to pointer of new entry
        pop rax
        pop rdi
        ret

ldl_get:
    push rdi
    push rax
    .l1:
        mov rsi, rdi        ;set pointer of result entry to current entry
        test rax, rax       ;check if counter is 0
        je .exit            ;if yes then exit
        dec rax             ;if not counter -1
        jmp .l1             ;loop
    .exit:
        pop rax
        pop rdi
        ret

ldl_remove:
    push rdi
    push rsi
    push rax
    push rbx
    ;check if input index is 0 -> exit
    test rax, rax
    jz .exit
    ;get privious entry and set pointer to end val
    dec rax
    call ldl_get
    mov qword [rsi], 0
    mov rbx, rsi
    ;go back to input entry and check if it is last -> exit
    inc rax
    call ldl_get            
    cmp qword [rsi], 0
    je .exit
    ;get addr of following entry
    inc rax
    call ldl_get
    ;get pointer of privious entry to addr of following
    mov [rbx], rsi
    .exit:
        pop rbx
        pop rax
        pop rsi
        pop rdi 
        ret

ldl_end:
    cmp QWORD [rdi], 0
    je .exit
    mov rdi, [rdi]
    jmp ldl_end
    .exit:
    ret