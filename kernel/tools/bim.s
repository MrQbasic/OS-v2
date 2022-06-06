;helper lib for bitmaps
;-------------------------------------------------------------------------------------------
;bim_get    rdi = pointer to bit map / rax = index of bit                 =>   rdx = val
;bim_set    rdi = pointer to bit map / rax = index of bit / rdx = val
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