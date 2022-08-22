;mem_init                 rdi = pointer to memory system tables start addr 
;mem_palloc               rax = size (in pages)                    => rdi = paddr - start
;mem_pfree                rdi = paddr ptr / rax = number of pages
;-------------------------------------------------------------------------------------------
[bits 64]

mem_init:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    ;save input
    mov rdx, mem_memmap_start
    mov [rdx], rdi
    ;setup better representation
    mov rcx, V_BOOT_MEMMAP_CNT
    mov cx, [rcx]
    mov rsi, memorymap
    ;set pointer to first entry of memmap
    .l1:
        ;check counters
        cmp cx, 0
        je .skipp1
        ;check type of entry
        mov edx, [rsi + 8 + 8]
        cmp edx, 1
        jne .skipp2
        ;calc number of pages
        xor rdx, rdx
        mov rax, [rsi + 8]
        mov rbx, 4096
        div rbx
        ;save number of pages
        mov [rdi + 8], rax
        ;get and save start addr
        mov rax, [rsi]
        mov [rdi], rax
        ;calc and save end addr
        xor rdx, rdx
        mov rax, [rdi + 8]
        mov rbx, 4096
        mul rbx
        add rax, [rdi]
        mov [rdi + 8 + 8 + 8], rax
        ;set pointer to next entry of memmap
        add rdi, 8*4
        mov rdx, mem_memmap_cnt
        inc qword [rdx]
        .skipp2:
            ;loop l1
            add rsi, 20
            dec cx
            jmp .l1
    .skipp1:
    mov rbx, mem_memmap_cnt
    cmp qword [rbx], 0
    je .error0
    ;setup starting addrs of bitmaps
    inc rdi
    mov rsi, mem_p_alloc
    mov [rsi], rdi
    mov rsi, mem_buffer
    mov rbx, mem_memmap_cnt
    mov rbx, [rbx]
    mov [rsi], rbx
    mov rsi, mem_memmap_start
    mov rsi, [rsi]
    .l2:
        ;check counter
        mov rbx, mem_buffer
        cmp qword [rbx], 0
        je .skipp3
        dec qword [rbx]
        ;save pointer to end
        mov [rsi + 8 + 8], rdi
        ;set pointer to next bim
        xor rdx, rdx
        mov rax, [rsi + 8]
        mov rbx, 8
        div rbx
        inc rax
        add rdi, rax
        ;set pointer to next entry
        add rsi, 8*4
        ;loop l2
        jmp .l2
    .skipp3:
    inc rdi
    
    ;VMA setup

    ;exit
    pop rsi
    pop rdi 
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
    .error0:
        mov rdi, mem_error_init_error0
        call screen_print_string
        jmp $



mem_palloc:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    ;check input
    cmp rax, 0
    je .error1
    ;setup loop
    mov rsi, mem_memmap_start
    mov rsi, [rsi]
    xor rcx, rcx
    .l1:
        ;check counter
        mov rdx, mem_memmap_cnt
        cmp rcx, [rdx]
        je .error1
        ;config for scan and do scan
        mov rdi, [rsi + 8 + 8]
        mov rbx, [rsi + 8]
        call bim_find_0
        jc .skipp1
        ;if memory space if found do this
        ;claim pages
        mov rbx, rax
        mov rax, rdi
        mov rdi, [rsi + 8 + 8]
        call bim_fill_1
        mov rdx, rax
        ;calc start addr
        xor rdx, rdx
        mov rdi, 4096   ;size of one page
        mul rdi
        add rax, [rsi]  ;gerneral start addr of map space
        mov rdi, rax
        jmp .exit
        .skipp1:
        ;loop l1
        add rsi, 8*3
        inc rcx
        jmp .l1
    .exit:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
    .error1:
        mov rdi, mem_error_palloc_nospace
        call screen_print_string
        jmp $
    .error0:
        mov rdi, mem_error_palloc_error0
        call screen_print_string
        jmp $


mem_pfree:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    ;check input address and adjust if needed
    push rax
    mov rax, rdi
    xor rdx, rdx
    mov rbx, 4096
    div rbx
    test rdx, rdx
    jz .skipp1
    call .warn_notvalid
    and rdi, 0xFFFFFFFFFFFFF000
    .skipp1:
    ;get bitmap and starting index of first bit form memmap
    mov rsi, mem_memmap_start
    mov rsi, [rsi]
    mov rcx, mem_memmap_cnt
    mov rcx, [rcx]
    .l1:
        ;check counter
        cmp rcx, 0
        je .error_notfound
        ;check address range of memmap entry
        mov rdx, [rsi + 8*3]
        cmp rdx, rdi
        jl .next
        mov rdx, [rsi + 8*0]
        cmp rdx, rdi
        jg .next
        ;calc index of bit
        sub rdi, [rsi + 8*0]
        mov rax, rdi
        xor rdx, rdx
        mov rbx, 4096
        div rbx
        ;free pages
        pop rbx
        mov rdi, [rsi + 8*2]
        call bim_fill_0
        jmp .exit
        .next:
        ;loop l1
        add rsi, 8*4
        dec rcx
        jmp .l1
    .exit: 
    pop rsi
    pop rdi
    pop rdx
    pop rcx 
    pop rbx
    pop rax
    ret
    .error_notfound:
        pop rax
        mov rax, rdi
        mov rdi, mem_error_pfree_notfound
        call screen_print_string
        jmp $
    .warn_notvalid:
        push rax
        push rdi 
        mov rax, rdi
        mov rdi, mem_warn_pfree_notvalid
        call screen_print_string
        pop rdi
        pop rax
        ret



;-------------------------------------------------------------------------------------------
;MEM MAP BETTER REPRESENTATION 24 bytes
;  0 paddr - start
;  8 number of pages
; 16 start of BIT-MAP
; 24 paddr - end
;-------------------------------------------------------------------------------------------
;vars

mem_p_alloc:               dq 0

mem_buffer:                dq 0

mem_memmap_cnt:            dq 0
mem_memmap_start:          dq 0

;-------------------------------------------------------------------------------------------
;error msgs
mem_error_init_error0:     db "\nERROR-> IT APPEARS THAT THE MEMORY MAP HAS NO USEABLE ENTRIES TO ALLOCATE!\e"
mem_error_palloc_error0:   db "\nERROR-> CAN NOT ALLOCATE 0 PAGES!\e"
mem_error_palloc_nospace:  db "\nERROR-> OUT OF P-MEMORY!\e"
mem_error_pfree_notfound:  db "\nERROR-> THERE IS NO PAGE WITH ADDR: 0x\rA!\e"
mem_warn_pfree_notvalid:   db "\nWARNING-> \rA IS NOT A VALID PAGE ADDRESS!\e"
mem_error_alloc_nospace:   db "\nERROR-> OUT OF MEMORY! MEMORY ALLOCATOR CAN NOT WORK PROPERLY!\e"
mem_error_free_notfound:   db "\nERROR-> THER IS NO ALLOCATED MEMORY AT: 0x\rA!\e"
mem_warn_free_notvalid:    db "\nWARNING-> 0x\rA IS NOT A VALID ADDRESS!\e"
;-------------------------------------------------------------------------------------------
