;mem_v_to_p               rdi = V-Addr                                      => rdi = paddr  /  cf = 1->error | 0->ok
;---other-tools
;mem_init                 rdi = pointer to memory system tables start addr 
;mem_palloc               rax = size (in pages)                             => rdi = paddr(start)
;mem_pfree                rdi = paddr ptr / rax = number of pages
;mem_alloc                rdi = size (in bytes)                             => rdi = addr(start) in kernelspace 
;mem_free                 rdi = start                                       => cf -> 1=error | 0=ok
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
    ;VMA setup with kernelspace
    mov QWORD [rdi + mem_s_alloc_list_next], 0
    mov QWORD [rdi + mem_s_alloc_list_start], kernelstart
    mov rsi, mem_v_alloc
    mov [rsi], rdi
    ;setup pageig filter
    mov rsi, V_P_ADDR_BITS
    mov cl, [rsi]
    dec cl
    mov bl, 12
    call math_fill
    mov rsi, mem_pageing_filter
    mov [rsi], rax
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


mem_alloc:
    ;check input
    test rdi, rdi
    jz .error_invalidinput
    ;save regs
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    ;---find v-space for alloc---
    ;check if there is a list; if not then error out
    test rsi, rsi
    jz .error_noinit
    xor rax, rax
    mov rsi, mem_v_alloc
    mov rsi, [rsi]
    ;pre calc inp size + tail size
    mov rcx, rdi
    add rcx, mem_s_alloc_list_tail
    ;loop through list and find spot in list
    .searchloop1:
        ;check if the current entry is a valid entry
        test rsi, rsi
        jz .list_append
        ;check if there is a last entry
        test rax, rax
        jz .next
        ;calc space between entries
        mov rbx, [rsi + mem_s_alloc_list_start]
        sub rbx, rax
        sub rbx, mem_s_alloc_list_tail
        ;check if the space is enough to fit needed mem + tail -> if not then skipp
        cmp rbx, rcx
        jl .next
        ;exit loop and setup in that space
        jmp .list_found
        .next:
        ;set pointer for next entry
        mov rax, rsi
        mov rsi, [rsi + mem_s_alloc_list_next]
        ;loop to top
        jmp .searchloop1
    ;if there is no space found is list append to list
    .list_append:
        ;get pointer to start of entry
        mov rcx, rax
        add rax, mem_s_alloc_list_tail
        ;get pointer to tail
        mov rbx, rax
        add rbx, rdi
        ;add entry to list
        mov [rcx + mem_s_alloc_list_next], rbx
        ;setup tail
        mov QWORD [rbx + mem_s_alloc_list_next], 0
        mov QWORD [rbx + mem_s_alloc_list_prev], rcx
        mov QWORD [rbx + mem_s_alloc_list_start], rax
        ;alloc pages
        mov rdx, rax
        jmp .palloc
    .list_found:
        ;get pointer to tail of new entry
        mov rbx, rax
        add rbx, mem_s_alloc_list_tail
        mov rdx, rbx
        add rbx, rdi
        ;setup entry
        mov [rbx + mem_s_alloc_list_prev], rax
        mov rcx, [rax + mem_s_alloc_list_next]
        mov [rbx + mem_s_alloc_list_next], rcx
        mov [rbx + mem_s_alloc_list_start], rdx
        ;insert entry into list
        mov [rax + mem_s_alloc_list_next], rbx
        mov [rcx + mem_s_alloc_list_prev], rbx
    ;--alloc pages--
    ;--input: rdx:start rbx:tail rcx
    .palloc:
        ;setup pointers etc
        mov rdi, rdx
        add rbx, mem_s_alloc_list_tail
        dec rbx
        and rbx, 0xFFFFFFFFFFFFF000
        mov rax, 1 
        ;check if the start is on a new page
        test rdx, 0x0FFF
        and rdx, 0xFFFFFFFFFFFFF000
        jz .list_append_skipp1
            ;check if the end is on a new page -> if not then exit
            cmp rdx, rbx
            je .exit
            call screen_debug_hex
            jmp $
        .list_append_iter1:
            
            ;alloc page
            .list_append_skipp1:
            call mem_palloc
            call screen_debug_hex
            call screen_nl
            call screen_print_yes
            jmp $


            jmp .list_append_iter1

        ;exit
    .exit:
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret
    .error_invalidinput:
        mov rdi, mem_error_alloc_input
        call screen_print_string
        xor rdi, rdi
        ret
    .error_noinit:
        mov rdi, mem_error_alloc_notinit
        call screen_print_string
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        jmp $        

mem_free:
    ;save regs
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    ;get pointer to first
    mov rax, mem_v_alloc
    mov rax, [rax]
    ;search list
    .l1:
        ;check if there is an entry
        test rax, rax
        jz .error_notfound
        ;check if we found the entry
        cmp rdi, [rax + mem_s_alloc_list_start]
        je .found
        ;load next entry
        mov rax, [rax]
        ;loop to top
        jmp .l1
    .found:
    ;get pointer(1) to prev entry
    mov rdi, [rax + mem_s_alloc_list_prev]
    ;get pointer(2) to next entry
    mov rsi, [rax + mem_s_alloc_list_next]
    ;check if it is the last entry
    test rsi, rsi
    jz .last
    ;set prev of next entry to prev / set next of prev entry to next -> remove entry from list
    mov [rsi + mem_s_alloc_list_prev], rdi
    mov [rdi + mem_s_alloc_list_next], rsi



    
    jmp .exit
    .last:
        mov rsi, rdi
        ;remove entry from list
        mov QWORD [rsi + mem_s_alloc_list_next], 0
        ;setup for loop
        ;get start page of entry
        mov rbx, [rax + mem_s_alloc_list_start]
        and rbx, 0xFFFFFFFFFFFFF000
        ;get end page of entry
        add rax, mem_s_alloc_list_tail
        and rax, 0xFFFFFFFFFFFFF000
        ;get end page of prev entry
        add rsi, mem_s_alloc_list_tail - 1
        and rsi, 0xFFFFFFFFFFFFF000
        ;check if entry is one page long
        cmp rax, rbx
        je .last_onepage
        ;chek if the 1. entey is clearable
        cmp rbx, rsi
        je .last_skipp1
        ;loop though all pages
        .last_l2:
            ;FREE PAGE
            push rax
            mov rdi, rbx
            mov rax, 1
            call mem_v_to_p
            jc .error_unexpected
            call mem_pfree
            pop rax
            ;check if it is done
            cmp rbx, rax
            je .exit
            ;-
            .last_skipp1:
            ;set pointer to next page
            add rbx, 0x1000
            ;loop to top
            jmp .last_l2

        .last_onepage:
        ;call screen_debug_hex
        ;check if the prev ends on the same page the entry starts on
        cmp rsi, rax
        je .exit
        
        ;UNMAP PAGE
        call screen_debug_bin
        jmp $

    .used:
    ;exit
    .exit:
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        clc
        ret
    .error_notfound:
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        stc
        ret
    .error_unexpected:
        mov rdi, mem_error_free_unexpected
        call screen_print_string
        jmp $
    
mem_v_to_p:
    ;save regs
    push rax
    push rbx 
    push rcx
    push rdx
    push rsi
    ;load filter
    mov rsi, mem_pageing_filter
    mov r8, [rsi]
    ;extract offset
    mov rsi, rdi
    and rsi, 0x0FFF
    ;get addr of plm4
    mov rcx, cr3
    ;calc entry addr
    mov rax, 0x0000FF8000000000
    and rax, rdi
    shr rax, 39
    mov rdx, 8
    mul rdx
    add rax, rcx
    ;eval entry
    mov rax, [rax]
    test rax, 1
    jz .error_notfound
    ;get addr of pdpt
    and rax, r8
    mov rcx, rax
    ;calc entry addr
    mov rax, 0x0000007FC0000000
    and rax, rsi
    shr rax, 39
    mov rdx, 8
    mul rdx
    add rax, rcx
    ;eval entry
    mov rax, [rax]
    test rax, 1
    jz .error_notfound
    ;get addr of pd
    and rax, r8
    mov rcx, rax
    ;calc entry addr
    mov rax, 0x000000003FE00000
    and rax, rsi
    shr rax, 39
    mov rdx, 8
    mul rdx
    add rax, rcx
    ;eval entry
    mov rax, [rax]
    test rax, 1
    jz .error_notfound
    ;get addr of pt
    and rax, r8
    mov rcx, rax
    ;calc entry addr
    mov rax, 0x00000000001FF000
    and rax, rsi
    shr rax, 39
    mov rdx, 8
    mul rdx
    add rax, rcx
    ;eval entry
    mov rax, [rax]
    test rax, 1
    jz .error_notfound
    ;get addr of page
    and rax, r8
    mov rcx, rax
    ;add offset
    add rsi, rcx
    .exit:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    clc
    ret
    .error_notfound: 
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    stc
    ret

;-------------------------------------------------------------------------------------------
;MEM MAP BETTER REPRESENTATION 24 bytes
;  0 paddr - start
;  8 number of pages
; 16 start of BIT-MAP
; 24 paddr - end
;VMA Entry TAIL
;  0 next entry(0 if last)
;  8 prev entry
; 16 start vaddr
;-------------------------------------------------------------------------------------------
;vars

mem_p_alloc:               dq 0

mem_v_alloc:               dq 0

mem_buffer:                dq 0

mem_memmap_cnt:            dq 0
mem_memmap_start:          dq 0

mem_pageing_filter:        dq 0

;-------------------------------------------------------------------------------------------
;error msgs
mem_error_init_error0:     db "\nERROR-> IT APPEARS THAT THE MEMORY MAP HAS NO USEABLE ENTRIES TO ALLOCATE!\e"
mem_error_palloc_error0:   db "\nERROR-> CAN NOT ALLOCATE 0 PAGES!\e"
mem_error_palloc_nospace:  db "\nERROR-> OUT OF P-MEMORY!\e"
mem_error_pfree_notfound:  db "\nERROR-> THERE IS NO PAGE WITH ADDR: 0x\rA!\e"
mem_warn_pfree_notvalid:   db "\nWARNING-> \rA IS NOT A VALID PAGE ADDRESS!\e"
mem_error_alloc_input:     db "\nERROR-> CAN NOT ALLOCATE 0 PAGES!\e"
mem_error_alloc_notinit:   db "\nERROR-> MEM ALLOC NOT READY! FATAL ERROR\e"
mem_error_free_unexpected: db "\nERROR-> TRYING TO FREE \rB BUT IT IS ALREADY FREE!\e"
;-------------------------------------------------------------------------------------------
;struct helper
mem_s_alloc_list_next      equ  0
mem_s_alloc_list_prev      equ  8
mem_s_alloc_list_start     equ  16
mem_s_alloc_list_tail      equ  24  ;size of tail