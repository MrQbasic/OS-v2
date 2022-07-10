;mem_init       rdi = pointer to memory system tables start
;mem_alloc      rarx = size                              => rdi = start addr
;mem_free       rdi = vaddr
;mem_palloc     rax = number of pages                    => rdi = paddr
;mem_pfree      rdi = paddr
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
        ;check if size is bigger then 1 page
        xor rdx, rdx
        mov rax, [rsi + 8]
        mov rbx, 4096
        div rbx
        ;save number of pages
        mov [rdi + 8], rax
        ;get and save start addr
        mov rax, [rsi]
        mov [rdi], rax
        ;set pointer to next entry of memmap
        add rdi, 8*3
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
        add rsi, 8*3
        ;loop l2
        jmp .l2
    .skipp3:
    inc rdi

    ;SETUP V_MEM ALLOC with rdi as start addr

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

;-------------------------------------------------------------------------------------------
;MEM MAP BETTER REPRESENTATION
;  0 paddr
;  8 number of pages
; 16 start of BIT-MAP
;--
;MEM List structure
;  0 pointer ti next entry (0 if last)
;  8 start
; 16 size

mem_buffer:                dq 0

mem_memmap_cnt:            dq 0
mem_memmap_start:          dq 0

mem_error_init_error0:     db "\nERROR-> IT APPEARS THAT THE MEMORY MAP HAS NO USEABLE ENTRIES TO ALLOCATE!\e"
mem_error_palloc_error0:   db "\nERROR-> CAN NOT ALLOCATE 0 PAGES!\e"
mem_error_palloc_nospace:  db "\nERROR-> OUT OF MEMORY!\e"
mem_error_pfree_notfound:  db "\nERROR-> THERE IS NO PAGE WITH ADDR: 0x\rA!\e"

mem_t_palloc:              db "\nSize of page frame allocator: \e"