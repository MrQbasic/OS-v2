;screen_clear
;screen_lineup
;screen_linestart
;screen_nl
;screen_print_char         dl = char
;screen_print_string       rdi = pointer to string
;screen_print_hex_n        dl = val (low)
;screen_print_hex_b        dl = val
;screen_print_hex_w        dx = val
;screen_print_hex_d       edx = val
;screen_print_hex_q       rdx = val
;screen_print_bin_n        dl = val (low)
;screen_print_bin_b        dl = val
;screen_print_bin_w        dx = val
;screen_print_bin_d       edx = val
;screen_print_bin_q       rdx = val
;-------------------------------------------------------------------------------------------
screen_clear:
    push rcx
    push rdi
    mov rdi, [V_SCREEN_START]       ;set pointer to start of screen mem
    mov rcx, [V_SCREEN_SIZE]        ;load counter
    .loop1:
        mov word [rdi], 0x0020      ;write color byte
        add edi, 2                  ;set pointer to the next word
        loop .loop1                 ;loop until screen is cleared
    mov word [V_CURSOR], 0          ;set cursor position to start
    pop rdi
    pop rcx
    ret

screen_lineup:
    push rdi
    push rsi
    push rcx
    mov rdi, [V_SCREEN_START]       ;set pointer1 to the start of the screenmem
    mov rsi, [V_SCREEN_START]       ;set pointer2 to the start of the screenmem
    add si, [V_LINE_SIZE]           ;+= the size of 1 line in word * 2 -> in bytes
    add si, [V_LINE_SIZE]
    mov rcx, [V_SCREEN_SIZE]        ;set counter to size of screen mem in words
    sub cx, [V_LINE_SIZE]           ;-= the size of 1 line in word(chars)
    .loop1:
        mov ax, [rsi]               ;get word from pointer2
        mov [rdi], ax               ;write the wort pointer1
        add rdi, 2                  ;set pointer1 to next word
        add rsi, 2                  ;set pointer2 to next word
        loop .loop1                 ;loop until counter = 0
    mov ax, [V_LINE_SIZE]           ;cursor -= 1line
    add ax, [V_LINE_SIZE]
    sub [V_CURSOR], ax
    pop rcx
    pop rsi
    pop rdi
    ret

screen_nl:
    push rax
    push rbx
    push rdx
    call screen_linestart           ;set cursor to start of line
    mov bx, [V_LINE_SIZE]           ;get the size of 1 line
    add [V_CURSOR], bx              ;cursor = cursor + line_size -> setting it to the next line
    mov ax, [V_CURSOR]              ;set new cursor position
    cmp ax, [V_CURSOR_MAX]          ;is new cursor pos > cursor_max pos then lineup
    jle .skipp
    call screen_lineup              ;call lineup
    .skipp:
    pop rdx
    pop rbx
    pop rax
    ret

screen_linestart:
    push rax
    push rbx
    push rdx
    mov ax, [V_CURSOR]              ;get the cursor position
    mov bx, [V_LINE_SIZE]           ;get the size of 1 line
    xor dx, dx                      ;set dx to 0 for div
    div bx                          ;ax dx = cursor / line_size
    sub [V_CURSOR], dx              ;cursor = cursor - remainder div -> setting it so the start of the line
    pop rdx
    pop rbx
    pop rax
    ret

screen_print_char:
    push rdi
    xor rdi, rdi                    ;set pointer to 0
    mov di, [V_CURSOR]              ;setup pointer to current cursorposition
    cmp di, [V_CURSOR_MAX]          ;is pointer > schreen size then lineup
    jle .skipp1
        call screen_lineup          ;call lineup
    .skipp1:
    add rdi, [V_SCREEN_START]       ;add screenmem start add as offset tro pointer
    mov byte [rdi+1], DEFAULT_COLOR ;write the color
    mov [rdi], dl                   ;write the char
    add word [V_CURSOR], 2          ;set coursor to point to the next char
    pop rdi
    ret

screen_print_string:
    mov [V_A], rax
    mov [V_B], rbx
    mov [V_C], rcx
    mov [V_D], rdx
    push rdi
    push rdx
    .loop1:
        mov dl, [rdi]               ;get the char
        cmp dl, "\"                 ;is char a cmd prefix
        jne .nocmd                  ;if no then skipp
        inc rdi                     ;set pointer to next char
        mov dl, [rdi]               ;get the char
        cmp dl, "e"                 ;if \e then exit
        je .exit
        cmp dl, "n"                 ;if \n then new line
        je .nl
        cmp dl, "r"                 ;if \r then reg print
        je .reg
        jmp .cmdret                 ;if nothing is found then goto cmdret
    .reg:
        inc rdi                     ;set pointer to next char
        mov dl, [rdi]               ;get the char
        cmp dl, "A"                 ;-> print rax
        je .A
        cmp dl, "B"                 ;-> print rbx
        je .B
        cmp dl, "C"                 ;-> print rcx
        je .C
        cmp dl, "D"                 ;-> print rdx  
        je .D
        jmp .cmdret                 ;if nothing is found then cmdret
        .A:
            mov rdx, [V_A]
            call screen_print_hex_q
            jmp .cmdret
        .B:
            mov rdx, [V_B]
            call screen_print_hex_q
            jmp .cmdret
        .C:
            mov rdx, [V_C]
            call screen_print_hex_q
            jmp .cmdret
        .D:
            mov rdx, [V_D]
            call screen_print_hex_q
            jmp .cmdret
    .nl:
        call screen_nl
        jmp .cmdret
    .cmdret:
        inc rdi                     ;set pointer to next byte
        jmp .loop1                  ;loop to start
    .nocmd:
        call screen_print_char      ;print char
        inc rdi                     ;set pointer to next byte
        jmp .loop1                  ;loop to start
    .exit:
        pop rdx
        pop rdi
        ret

screen_print_hex_n:
    push rdx
    push rdi
    and rdx, 0xF                    ;get only 1 N
    mov rdi, HEX                    ;get a pointer to the HEX char table
    add rdi, rdx                    ;add the val as an offset to the pointer
    mov dl, [rdi]                   ;get the char
    call screen_print_char          ;print the char
    pop rdi
    pop rdx
    ret

screen_print_hex_b:
    ror rdx, 4
    call screen_print_hex_n         ;print the higher N
    rol rdx ,4
    call screen_print_hex_n         ;print the lower N
    ret

screen_print_hex_w:
    ror rdx, 8
    call screen_print_hex_b         ;print the higher byte
    rol rdx, 8
    call screen_print_hex_b         ;print the lower byte
    ret

screen_print_hex_d:
    ror rdx, 16
    call screen_print_hex_w         ;print the higher word
    rol rdx, 16
    call screen_print_hex_w         ;print the lower word
    ret

screen_print_hex_q:
    ror rdx, 32
    call screen_print_hex_d         ;print the higher dword
    rol rdx, 32
    call screen_print_hex_d         ;print the lower qword
    ret

screen_print_bin_n:
    push rcx
    push rdx 
    mov rcx, 4                      ;set counter to 4 1N = 4 bits
    ror rdx, 3                      ;offset val so bit 3 of val is at position 0
    .loop1:
        test rdx, 0x1               ;test if the first bit is a 1
        jz .skipp1
            push rdx
            mov dl, "1"             ;set char to "1"
            call screen_print_char  ;write char
            pop rdx
        jmp .skipp2                 ;goto skipp2
    .skipp1:
        push rdx
        mov dl, "0"                 ;set char to "0"
        call screen_print_char      ;write char
        pop rdx
    .skipp2:
        rol rdx, 1                  ;shift val 1 bit left
        loop .loop1
    pop rdx
    pop rcx
    ret

screen_print_bin_b:
    ror rdx, 4
    call screen_print_bin_n
    rol rdx, 4
    call screen_print_bin_n
    ret

screen_print_bin_w:
    ror rdx, 8
    call screen_print_bin_b
    rol rdx, 8
    call screen_print_bin_b
    ret

screen_print_bin_d:
    ror rdx, 16
    call screen_print_bin_w
    rol rdx, 16
    call screen_print_bin_w
    ret

screen_print_bin_q:
    ror rdx, 32
    call screen_print_bin_d
    rol rdx, 32
    call screen_print_bin_d
    ret

;-------------------------------------------------------------------------------------------
;Const
DEFAULT_COLOR       equ 0x0A

;Var
V_SCREEN_START:     dq 0xB8000
V_SCREEN_SIZE:      dq 0x007FF ;size in words

V_CURSOR:           dw 0x0000  ;is in bytes not in chars!
V_CURSOR_MAX:       dw 0x1000  ;is in bytes not in chars!

V_LINE_SIZE:        dw 160     ;num of chars in 1 line (1 char = 2bytes)

HEX:                db "0123456789ABCDEF"

V_A:                dq 0
V_B:                dq 0
V_C:                dq 0
V_D:                dq 0