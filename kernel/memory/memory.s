;mem_init                 rdi = pointer to memory system tables start addr 
;mem_alloc                rax = size (in pages)                    => rdi = start addr
;mem_free                 rdi = vaddr
;mem_palloc               rax = size (in pages)                    => rdi = paddr - start
;mem_palloc_onepage                                                => rdi = paddr - start
;mem_pfree                rdi = paddr ptr / rax = number of pages
;mem_vma_page_alloc       rdi = number of qword in page            => rdi = address of page
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
    ;setup VMA with rdi (make rdi page aligned)
    test rdi, 0b0111
    jz .skipp4
    and rdi, 0xFFFFFFFFFFFFF000
    add rdi, 0x0000000000001000
    .skipp4:
    mov rsi, mem_vma_first_page
    mov [rsi], rdi
    mov rsi, mem_vma_last_page
    mov [rsi], rdi
    ;setup first VMA page
    mov word [rdi + mem_vma_page__free], mem_vma_page__free_d
    ;setup VMA entry pointer
    mov rsi, mem_vma_last_entry
    mov rax, mem_vma_first_entry
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
    ;check input address and ajust if needed
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

mem_palloc_onepage:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    ;setup loop
    mov rsi, mem_memmap_start
    mov rsi, [rsi]
    xor rcx, rcx
    mov rax, 1
    .l1:
        ;check counter
        mov rdx, mem_memmap_cnt
        cmp rcx, [rdx]
        je .error_nospace
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
    .error_nospace:
        mov rdi, mem_error_palloc_nospace
        call screen_print_string
        jmp $

mem_alloc:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    ;find some space for entry head
    mov rdi, mem_vma_entry__size_head
    call mem_vma_page_alloc
    test rdi, rdi
    jz .error
    mov rcx, rdi
    ;calc input size in bytes
    mov rbx, 4096
    mul rbx
    ;---find space in list---
    mov rbx, -1
    mov rsi, mem_vma_first_entry
    mov rdi, [rsi + mem_vma_entry__head_next]
    ;check if there is no first entry
    test rdi, rdi
    jz .first_entry
    ;search loop
    .loop1:
        ;check if this is the last entry
        mov QWORD [rdi + mem_vma_entry__head_next], 0
        je .append_entry
        ;check if there is space between this an the next entry
        
        ;DO THAT

        ;set current entry to next entry
        mov rdi, [rdi + mem_vma_entry__head_next]
        ;loop back
        jmp .loop1

    .first_entry:
        mov rdi, rsi
    .append_entry:
        ;setup pointer to current entry
        mov [rdi + mem_vma_entry__head_next], rcx
        inc rbx
        ;seup current entry
        mov QWORD [rcx + mem_vma_entry__head_next], 0
        mov [rcx + mem_vma_entry__head_start], rbx
        add rax, rbx
        dec rax
        mov [rcx + mem_vma_entry__head_end], rax

        ;SETUP BODY

        ;exit out
        mov rdi, rbx
        jmp .exit
        
    .error:
        mov rdi, mem_error_alloc_nospace
        call screen_print_string
        jmp $
    .exit:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


mem_vma_page_alloc:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    ;chekc input
    cmp rdi, mem_vma_page__free_d
    jg .error
    ;setup search loop
    mov rsi, mem_vma_first_page
    mov rsi, [rsi]
    .seach_loop:
        ;check if there are enough qwords
        cmp [rsi + mem_vma_page__free], rdi
        jg .validate
        ;check if this is the last page    
        cmp QWORD [rsi + mem_vma_page__next], 0
        je .append_entry
        ;set current to next of current
        mov rsi, [rsi + mem_vma_page__next]
        ;loop back
        jmp .seach_loop
    .validate:
        xor rcx, rcx
        ;check if this is the last page -> add size wich it takes to append an entry
        cmp QWORD [rsi + mem_vma_page__next], 0
        jne .validate_skipp1
        mov rcx, mem_vma_page__size_append
        .validate_skipp1:
        ;check if page contains useable(continuous) space
        mov rax, rdi
        add rax, rcx
        mov rdi, rsi
        add rdi, mem_vma_page__bitmap
        mov rbx, mem_vma_page__size_bitmap
        call bim_find_0
        jc .not_valid
        ;allocate space
        mov rbx, rax
        sub [rsi + mem_vma_page__free], rbx
        mov rax, rdi
        mov rdi, rsi
        add rdi, mem_vma_page__bitmap
        call bim_fill_1
        ;calc memory address and exit
        mov rbx, 8
        mul rbx
        add rax, rsi
        add rax, mem_vma_page__alloc
        mov rdi, rax
        jmp .exit
    .not_valid:
        ;check if the current page is the last page (append a page if yes)
        cmp QWORD [rsi + mem_vma_page__next], 0
        je .append_entry
        ;else continue the search
        mov rsi, [rsi + mem_vma_page__next]
        jmp .seach_loop
    .append_entry:
        ;search for space on current(last page)
        mov rdi, rsi
        add rdi, mem_vma_page__bitmap
        mov rax, mem_vma_entry__size_body
        mov rbx, mem_vma_page__size_bitmap
        call bim_find_0

        ;pl add feature
        call screen_debug_hex
        jmp $

    .error:
    xor rdi, rdi    ;return 0 -> error
    .exit:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


;-------------------------------------------------------------------------------------------
;MEM MAP BETTER REPRESENTATION 24 bytes
;  0 paddr - start
;  8 number of pages
; 16 start of BIT-MAP
; 24 paddr - end
;-------------------------------------------------------------------------------------------
;VMA-entry (head = 24 bytes)
;---HEAD---
;  8 pointer to next entry (0 if last)
;  8 start - vADDR
;  8 end   - vADDR
;  8 pointer to start of Page List
;---BODY--- (Page List)
;  8 pointer to next Page List (0 if last)
;  8 number of pages
;  8 paddr
;  8 paddr
;  "   "
;  8 paddr
;-------------------------------------------------------------------------------------------
;VMA-Page structure 4096 bytes (1 page)
;    8 pointer to next entry (0 if last)
;    8 pointer to previous entry (0 if first)
;    8 bytes in alloc space free (1 BIT = 1 QWORD)
;   64 bitmap of alloc space  
; 4008 allocation space
;-------------------------------------------------------------------------------------------
;vars

mem_p_alloc:               dq 0

mem_vma_first_page:        dq 0
mem_vma_first_entry:       dq 0
mem_vma_last_page:         dq 0
mem_vma_last_entry:        dq 0 


mem_buffer:                dq 0

mem_memmap_cnt:            dq 0
mem_memmap_start:          dq 0

;-------------------------------------------------------------------------------------------
;error msgs
mem_error_init_error0:     db "\nERROR-> IT APPEARS THAT THE MEMORY MAP HAS NO USEABLE ENTRIES TO ALLOCATE!\e"
mem_error_palloc_error0:   db "\nERROR-> CAN NOT ALLOCATE 0 PAGES!\e"
mem_error_palloc_nospace:  db "\nERROR-> OUT OF P-MEMORY!\e"
mem_error_pfree_notfound:  db "\nERROR-> THERE IS NO PAGE WITH ADDR: 0x\rA!\e"
mem_warn_pfree_notvalid:   db "\nWARNING-> \rA IS NOT A VALID PAGE ADDRESS! PLEASE CHECK YOUR CODE!\e"
mem_error_alloc_nospace:   db "\nERROR-> OUT OF MEMORY! MEMORY ALLOCATOR CAN NOT WORK PROPERLY!\e"
;-------------------------------------------------------------------------------------------
;struct helper

mem_vma_page__next         equ 0x0000
mem_vma_page__prev         equ 0x0008
mem_vma_page__free         equ 0x0010
mem_vma_page__bitmap       equ 0x0018
mem_vma_page__alloc        equ 0x0058
;-
mem_vma_page__free_d       equ 0x01F5 ;in qwords
mem_vma_page__size_bitmap  equ 0x01F5 ;in bits
mem_vma_page__size_append  equ mem_vma_entry__size_body * 5      ;bit (map entries) -> vma_page + pml4 + pdpt + pd + pt 

mem_vma_entry__head_next   equ 0x0000
mem_vma_entry__head_start  equ 0x0008
mem_vma_entry__head_end    equ 0x0010
mem_vma_entry__head_plist  equ 0x0018
;-
mem_vma_entry__body_next   equ 0x0000
mem_vma_entry__body_size   equ 0x0008
mem_vma_entry__body_paddr  equ 0x0010
;-
mem_vma_entry__size_head   equ 0x0004 ;in qwords
mem_vma_entry__size_body   equ 0x0003 ;in qwords