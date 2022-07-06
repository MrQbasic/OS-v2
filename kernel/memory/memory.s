;mem_init       rdi = pointer to end of kernel code
;mem_alloc      rax = size                              => rdi = start addr
;mem_free       rdi = vaddr
;mem_palloc                                             => rdi = paddr
;mem_palloc_
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
    ;setup base addrs 
    mov rsi, mem_paddr_map
    mov [rsi], rdi
    ;get size of p-memory
    mov rdi, V_MEM_USEABLE
    mov rax, [rdi]
    ;get number of pages
    mov rcx, 4096           ;size of 1 page
    xor rdx, rdx
    div rcx
    ;get number of bytes
    mov rcx, 8              ;number of bits in a byte
    xor rdx, rdx
    div rcx
    cmp rdx, 0
    je .skipp1
    inc rax
    .skipp1:
    ;clear bytes (set everything to used)
    mov rdi, mem_paddr_map
    mov rdi, [rdi]
    .l1:
        mov byte [rdi], 0xFF
        inc rdi
        dec rax
        jnz .l1
    ;extract pointer to linked list start
    inc rdi
    mov rsi, mem_list_addr
    mov [rsi], rdi
    ;setup map -> set pages in memory map to free
    mov rdi, memorymap
    mov rcx, V_BOOT_MEMMAP_CNT
    mov cx, [rcx]
    ;setup
    xor rsi, rsi
    .l2:
        push rcx
        push rdi
        ;calc number of pages
        mov rax, [rdi + 8]
        xor rdx, rdx
        mov rbx, 0x1000
        div rbx
        mov rbx, rax
        ;check type
        mov dl, [rdi + 16]
        cmp dl, 0x01
        jne .skipp2
        ;loop and setup map
        mov rdi, mem_paddr_map
        mov rdi, [rdi]
        mov rdx, 0x0000
        .l3:
            cmp rbx, 0
            je .skipp2
            mov rax, rsi
            call bim_set 
            inc rsi
            dec rbx
            jmp .l3
        .skipp2:
        pop rdi
        pop rcx
        add rdi, 20
        dec cx
        jnz .l2
    ;print size used for page fram allocator
    mov rdi, mem_paddr_map_cnt
    mov [rdi], rsi
    mov rax, rsi
    xor rdx, rdx
    mov rcx, 8
    div rcx
    mov rsi, rax
    mov rdi, mem_t_palloc
    call screen_print_string
    mov rdx, rsi
    call screen_print_size
    ;calculate start of alloc list
    mov rdi, mem_paddr_map
    mov rdi, [rdi]
    add rdi, rsi
    add rdi, 0x1000
    and rdi, 0xFFFFFFFFFFFFF000

    mov rdx, rdi
    call screen_nl
    call screen_print_hex_q

    ;SETUP V_MEM ALLOC 

    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


mem_palloc:
    push rax
    push rbx
    push rcx
    push rdx
    ;setup for scan
    mov rdi, mem_paddr_map
    mov rdi, [rdi]
    mov rbx, mem_paddr_map_cnt
    mov rbx, [rbx]
    xor rax, rax
    ;loop over bitmap
    .l1:
        call bim_get
        cmp dl, 0
        je .found
        inc rax
        cmp rax, rbx
        je .error
        jmp .l1
    .found:
    ;claim page
    mov rdx, 1
    call bim_set
    ;get addr of page
    mov rcx, rax
    mov rdi, memorymap
    xor rbx, rbx
    .l2:
        ;validate memmap entry
        mov al, [rdi+16]
        cmp al, 0x01
        je .skipp2
        add rdi, 20
        jmp .l2
        .skipp2:
        ;get number of pages
        mov rax, [rdi+8]
        xor rdx, rdx
        mov rbx, 0x1000
        div rbx
        ;check if entry lies in range
        cmp rcx, rax
        jge .skipp1
        ;if yes then get start addr and calc offset
        mov rax, [rdi]
        shl rcx, 12
        add rax, rcx
        mov rdi, rax
        jmp .done
        ;if not then dec page
        .skipp1:
        sub rcx, rax
        add rdi, 20
        jmp .l2
    .done:
    pop rdx
    pop rcx
    pop rbx
    pop rax

    ret
    ;error out if no free page found
    .error:
        mov rdi, mem_error_palloc_nospace
        call screen_print_string
        jmp $


mem_pfree:
    push rdi
    push rax
    push rbx
    push rcx
    push rdx
    ;loop though memory map and find addr
    mov rsi, memorymap
    mov rcx, V_BOOT_MEMMAP_CNT
    mov cx, [rcx]
    xor rbx, rbx
    .l1:
        cmp cx, 0
        je .error
        ;check if entry if valid for loop
        cmp byte [rsi+16], 0x01
        je .skipp1
        add rsi, 20
        dec cx
        jmp .l1
        .skipp1:
        ;get number of pages and turn it into bytes
        push rbx
        mov rax, [rsi+8]
        mov rbx, 0x1000
        xor rdx, rdx
        div rbx
        shl rax, 12
        pop rbx
        ;add starting addr to size
        add rax, [rsi]
        ;check if input is in range
        cmp rdi, rax
        jg .skipp2
        cmp rdi, [rsi]
        jl .skipp2
        jmp .found
        .skipp2:
        ;offset bit index to end addr of this map entry
        push rbx
        mov rax, [rsi+8]
        mov rbx, 0x1000
        xor rdx, rdx
        div rbx
        pop rbx
        add rbx, rax
        ;set pointer to next map entry
        add rsi, 20
        dec cx 
        jmp .l1
    .found:
    sub rdi, [rsi]
    shr rdi, 12
    add rdi, rbx
    ;clear bit in bitmap
    mov rax, rdi
    mov dl, 0
    mov rdi, mem_paddr_map
    mov rdi, [rdi]
    call bim_set
    ;exit
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rdi
    ret
    .error:
        mov rax, rdi
        mov rdi, mem_error_pfree_notfound
        call screen_print_string
        jmp $

;-------------------------------------------------------------------------------------------
;MEM List structure
;  0 pointer ti next entry (0 if last)
;  8 start
; 16 size

mem_paddr_map_cnt:         dq 0

mem_paddr_map:             dq 0
mem_list_addr:             dq 0

mem_error_palloc_nospace:  db "\nERROR-> OUT OF MEMORY!\e"
mem_error_pfree_notfound:  db "\nERROR-> THERE IS NO PAGE WITH ADDR: 0x\rA!\e"

mem_t_palloc:              db "\nSize of page frame allocator: \e"