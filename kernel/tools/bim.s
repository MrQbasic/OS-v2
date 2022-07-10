;helper lib for bitmaps
;-------------------------------------------------------------------------------------------
;bim_get    rdi = pointer to bit map / rax = index of bit                                 =>   rdx = val
;bim_set    rdi = pointer to bit map / rax = index of bit / rdx = val
;bim_find_0 rdi = pointer to bit map / rax = number of bits / rbx = max bits              =>   rdi = index / CF = 1:not found 0:found
;bim_find_1 rdi = pointer to bit map / rax = number of bits / rbx = max bits              =>   rdi = index / CF = 1:not found 0:found
;bim_fill_0 rdi = pointer to bit map / rax = start index / rbx = number of bits
;bim_fill_1 rdi = pointer to bit map / rax = start index / rbx = number of bits
;-------------------------------------------------------------------------------------------
[bits 64]

bim_get:
    push rdi
    push rax
    push rbx
    push rcx
    ;positget offset of byte in the map
    xor rdx, rdx
    mov rbx, 8
    div rbx
    ;add offset of byte to base of map
    add rdi, rax
    ;get byte
    xor rax, rax
    mov al, [rdi]
    ;get bit in byte
    mov cl, dl
    shr al, cl
    and al, 0x01
    ;prepare for return
    mov rdx, rax
    pop rcx
    pop rbx
    pop rax
    pop rdi
    ret

bim_set:
    push rdi
    push rax
    push rbx
    push rcx
    push rdx
    ;get offset of byte in the map
    xor rdx, rdx
    mov rbx, 8
    div rbx
    ;add offset of byte to base addr
    add rdi, rax
    ;get byte
    xor rax, rax
    mov al, [rdi]
    ;shift input to target bit
    mov cl, dl
    pop rdx
    push rdx
    shl dl, cl
    ;setup filter
    xor rbx, rbx
    mov rbx, 0x01
    shl bl, cl
    xor bl, 0xFF
    ;set target bit to 0 useing filter
    and al, bl
    ;set target bit to input bit
    or al, dl
    ;write byte to map
    mov[rdi], al
    ;exit
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rdi
    ret

bim_find_0:
    push rax        ;number of bits needed
    push rbx        ;number of bits available
    push rcx        ;bits to do
    push rdx        ;bits for l2 to search
    push rsi        ;input registers
    push rdi        ;starting address
    ;check inputs
    cmp rax, 0
    je error0
    ;setup loop 
    mov rcx, rax    ;backup one input
    .l1:
        ;check if there are still bits available -> if not error out
        cmp rbx, 0
        je error1
        ;check size of not scanned map to find best size of mem load
        cmp rbx, 64
        jge .LOAD_QWORD
        cmp rbx, 32
        jge .LOAD_DWORD
        cmp rbx, 16
        jge .LOAD_WORD
        cmp rbx, 08
        jge .LOAD_BYTE
        ;if there are not enough bit available to fill one unit, load a byte and set function to number of remaining bits
            xor rdx, rdx
            mov dl, [rdi]
            mov rsi, rdx
            mov rdx, rbx
            xor rbx, rbx
            jmp .l2
        ;setup sbr's for bit search loop
        .LOAD_QWORD:
            xor rdx, rdx
            mov rdx, [rdi]
            mov rsi, rdx
            mov rdx, 64
            sub rbx, rdx
            jmp .l2
        .LOAD_DWORD:
            xor rdx, rdx
            mov edx, [rdi]
            mov rsi, rdx
            mov rdx, 32
            sub rbx, rdx
            jmp .l2
        .LOAD_WORD:
            xor rdx, rdx
            mov dx, [rdi]
            mov rsi, rdx
            mov rdx, 16
            sub rbx, rdx
            jmp .l2
        .LOAD_BYTE:
            xor rdx, rdx
            mov dl, [rdi]
            mov rsi, rdx
            mov rdx, 08
            sub rbx, rdx
            jmp .l2
        ;loop to search through all bits in given size
        .l2:
            ;check counter and exit if needed
            test dl, dl
            jz .skipp2
            ;check if first bit is =0 
            test rsi, 1
            je .found
            ;do this if checked bit is not wanted type
            mov rcx, rax
            jmp .skipp3
            .found:
            dec rcx
            jnz .skipp3
            ;do this is all bits where found (calculate index of start bit in sequence)
            ;calc bit index of current byte
            pop rsi
            sub rdi, rsi
            add rdi, rdi
            add rdi, rdi
            add rdi, rdi
            ;add index of current bit in byte
            shr rdx, 8
            add rdi, rdx
            ;sub number of bits to find, to find start bit index
            dec rax
            sub rdi, rax
            ;exit
            mov rdx, rdi
            jmp .exit
            ;loop l2
            .skipp3:
            dec dl
            inc dh
            shr rsi, 1
            jmp .l2
    ;loop l1 
    .skipp2:
    push rax
    push rbx
    push rcx
    shr rdx, 8
    mov rax, rdx
    xor rdx, rdx
    mov rbx, 8
    div rbx
    mov rdx, rax
    pop rcx
    pop rbx
    pop rax
    add rdi, rdx
    jmp .l1
    ;to exit get regs back
    .exit:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    clc
    ret



bim_find_1:
    push rax        ;number of bits needed
    push rbx        ;number of bits available
    push rcx        ;bits to do
    push rdx        ;bits for l2 to search
    push rsi        ;input registers
    push rdi        ;starting address
    ;check inputs
    cmp rax, 0
    je error0
    ;setup loop 
    mov rcx, rax    ;backup one input
    .l1:
        ;check if there are still bits available -> if not error out
        cmp rbx, 0
        je error1
        ;check size of not scanned map to find best size of mem load
        cmp rbx, 64
        jge .LOAD_QWORD
        cmp rbx, 32
        jge .LOAD_DWORD
        cmp rbx, 16
        jge .LOAD_WORD
        cmp rbx, 08
        jge .LOAD_BYTE
        ;if there are not enough bit available to fill one unit, load a byte and set function to number of remaining bits
            xor rdx, rdx
            mov dl, [rdi]
            mov rsi, rdx
            mov rdx, rbx
            xor rbx, rbx
            jmp .l2
        ;setup sbr's for bit search loop
        .LOAD_QWORD:
            xor rdx, rdx
            mov rdx, [rdi]
            mov rsi, rdx
            mov rdx, 64
            sub rbx, rdx
            jmp .l2
        .LOAD_DWORD:
            xor rdx, rdx
            mov edx, [rdi]
            mov rsi, rdx
            mov rdx, 32
            sub rbx, rdx
            jmp .l2
        .LOAD_WORD:
            xor rdx, rdx
            mov dx, [rdi]
            mov rsi, rdx
            mov rdx, 16
            sub rbx, rdx
            jmp .l2
        .LOAD_BYTE:
            xor rdx, rdx
            mov dl, [rdi]
            mov rsi, rdx
            mov rdx, 08
            sub rbx, rdx
            jmp .l2
        ;loop to search through all bits in given size
        .l2:
            ;check counter and exit if needed
            test dl, dl
            jz .skipp2
            ;check if first bit is =1 
            test rsi, 1
            jz .notfound
            jmp .found
            ;do this if checked bit is not wanted type
            .notfound:
            mov rcx, rax
            jmp .skipp3
            .found:
            call screen_space
            call screen_print_yes
            dec rcx
            jnz .skipp3
            ;do this is all bits where found (calculate index of start bit in sequence)
            ;calc bit index of current byte
            pop rsi
            sub rdi, rsi
            add rdi, rdi
            add rdi, rdi
            add rdi, rdi
            ;add index of current bit in byte
            shr rdx, 8
            add rdi, rdx
            ;sub number of bits to find, to find start bit index
            dec rax
            sub rdi, rax
            ;exit
            mov rdx, rdi
            jmp .exit
            ;loop l2
            .skipp3:
            dec dl
            inc dh
            shr rsi, 1
            jmp .l2
    ;loop l1 
    .skipp2:
    push rax
    push rbx
    push rcx
    shr rdx, 8
    mov rax, rdx
    xor rdx, rdx
    mov rbx, 8
    div rbx
    mov rdx, rax
    pop rcx
    pop rbx
    pop rax
    add rdi, rdx
    jmp .l1
    ;to exit get regs back
    .exit:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    clc
    ret

    error0:
        mov rdi, bim_error_search_0
        call screen_print_string
        jmp $
    error1:
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        mov rdi, 0
        stc
        ret

bim_fill_0:
    push rax        ;start index
    push rbx        ;number of bits to fill
    push rcx
    push rdx        ;data to write
    push rsi
    push rdi        ;start of bitmap
    ;check input
    test rbx, rbx
    jz .exit
    ;check if starting index is 0; if yes skipp first byte process
    test rax, rax
    jz .l1
    ;calc starting addr based of first byte based on the starting index
    xor rdx, rdx
    mov rcx, 8
    div rcx
    add rdi, rax
    ;create bitmask and sub number of bit in first byte from target
    mov rcx, 8
    sub cl, dl
    sub rbx, rcx
    mov dl, 0xFF
    shr dl, cl
    ;write byte
    and [rdi], dl
    ;set pointer to next byte
    add rdi, 1
    .l1:
        ;check counter
        cmp rbx, 0
        je .exit
        ;get size to write
        cmp rbx, 64
        jge .LOAD_QWORD
        cmp rbx, 32
        jge .LOAD_DWORD
        cmp rbx, 16
        jge .LOAD_WORD
        cmp rbx, 8
        jge .LOAD_BYTE
        ;generate bitmask for last byte
        mov cl, bl
        mov dl, 0xFF
        shr dl, cl
        ;apply bitmask
        and [rdi], dl
        ;exit
        jmp .exit

        .LOAD_QWORD:
            mov qword [rdi], 0
            add rdi, 8
            jmp .skipp1
        .LOAD_DWORD:
            mov dword [rdi], 0
            add rdi, 4
            jmp .skipp1
        .LOAD_WORD:
            mov word [rdi], 0
            add rdi, 2
            jmp .skipp1
        .LOAD_BYTE:
            mov byte [rdi], 0
            add rdi, 1
            jmp .skipp1
        .skipp1:

        ;loop l1
        dec rbx
        jmp .l1
    .exit:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

bim_fill_1:
    push rax        ;start index
    push rbx        ;number of bits to fill
    push rcx
    push rdx        ;data to write
    push rsi
    push rdi        ;start of bitmap
    ;check input
    test rbx, rbx
    jz .exit
    ;check if starting index is 0; if yes skipp first byte process
    test rax, rax
    jz .l1
    ;calc starting addr based of first byte based on the starting index
    xor rdx, rdx
    mov rcx, 8
    div rcx
    add rdi, rax
    cmp rbx, 8
    jl .skipp2    
    ;create bitmask and sub number of bit in first byte from target
    mov rcx, 8
    sub cl, dl
    sub rbx, rcx
    mov dl, 0xFF
    shl dl, cl
    ;write byte
    or [rdi], dl
    add rdi, 1
    jmp .l1
    ;create bitmask and set target to 0
    .skipp2:
    mov rax, rdx
    mov rcx, 8
    sub cl, bl
    mov dl, 0xFF
    shl dl, cl
    shr dl, cl
    mov cl, al
    shl dl, cl
    ;write byte
    or [rdi], dl
    xor rbx, rbx
    ;set pointer to next byte
    .l1:
        ;check counter
        cmp rbx, 0
        je .exit
        ;get size to write
        cmp rbx, 64
        jge .LOAD_QWORD
        cmp rbx, 32
        jge .LOAD_DWORD
        cmp rbx, 16
        jge .LOAD_WORD
        cmp rbx, 8
        jge .LOAD_BYTE
        ;generate bitmask for last byte
        xor rdx, rdx
        mov cl, bl
        mov dl, 0xFF
        shl dl, cl
        ;apply bitmask
        xor dl, 0xFF
        or [rdi], dl
        ;exit
        jmp .exit

        .LOAD_QWORD:
            mov qword [rdi], 0
            add rdi, 8
            jmp .skipp1
        .LOAD_DWORD:
            mov dword [rdi], 0
            add rdi, 4
            jmp .skipp1
        .LOAD_WORD:
            mov word [rdi], 0
            add rdi, 2
            jmp .skipp1
        .LOAD_BYTE:
            mov byte [rdi], 0
            add rdi, 1
            jmp .skipp1
        .skipp1:

        ;loop l1
        dec rbx
        jmp .l1
    .exit:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

;-------------------------------------------------------------------------------------------
bim_error_search_0:         db "\nERROR-> can not find 0 bits in bitmap! Input other number!\e"
