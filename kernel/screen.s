;screen_space
;screen_clear
;screen_lineup
;screen_linestart
;screen_nl
;screen_stackdump
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
screen_space:
    push rdx
    mov dl, " "
    call screen_print_char
    pop rdx
    ret

screen_clear:
    push rcx
    push rdi
    push rsi
    mov rsi, V_SCREEN_START
    mov rdi, [rsi]                  ;set pointer to start of screen mem
    mov rsi, V_SCREEN_SIZE
    mov rcx, [rsi]                  ;load counter
    .loop1:
        mov word [rdi], 0x0020      ;write color byte
        add edi, 2                  ;set pointer to the next word
        loop .loop1                 ;loop until screen is cleared
    mov rsi, V_CURSOR
    mov word [rsi], 0               ;set cursor position to start
    pop rsi
    pop rdi
    pop rcx
    ret

screen_lineup:
    push rdi
    push rsi
    push rcx
    push rax
    push rbx
    mov rcx, V_SCREEN_START
    mov rdi, [rcx]                  ;set pointer1 to the start of the screenmem
    mov rsi, [rcx]                  ;set pointer2 to the start of the screenmem
    mov rbx, V_LINE_SIZE
    add si, [rbx]                   ;+= the size of 1 line in word * 2 -> in bytes
    add si, [rbx]
    mov rbx, V_SCREEN_SIZE
    mov rcx, [rbx]                  ;set counter to size of screen mem in words
    mov rbx, V_LINE_SIZE
    sub cx, [rbx]                   ;-= the size of 1 line in word(chars)
    .loop1:
        mov ax, [rsi]               ;get word from pointer2
        mov [rdi], ax               ;write the wort pointer1
        add rdi, 2                  ;set pointer1 to next word
        add rsi, 2                  ;set pointer2 to next word
        loop .loop1                 ;loop until counter = 0
    mov rbx, V_LINE_SIZE
    mov ax, [rbx]                   ;cursor -= 1line
    add ax, [rbx]
    mov rbx, V_CURSOR
    sub [rbx], ax
    pop rbx
    pop rax
    pop rcx
    pop rsi
    pop rdi
    ret

screen_nl:
    push rax
    push rbx
    push rdx
    call screen_linestart           ;set cursor to start of line
    mov rdx, V_LINE_SIZE
    mov bx, [rdx]                   ;get the size of 1 line
    mov rdx, V_CURSOR
    add [rdx], bx                   ;cursor = cursor + line_size -> setting it to the next line
    mov ax, [rdx]                   ;set new cursor position
    mov rdx, V_CURSOR_MAX
    cmp ax, [rdx]                   ;is new cursor pos > cursor_max pos then lineup
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
    push rcx
    push rdx
    mov rcx, V_CURSOR
    mov ax, [rcx]                   ;get the cursor position
    mov rcx, V_LINE_SIZE
    mov bx, [rcx]                   ;get the size of 1 line
    xor dx, dx                      ;set dx to 0 for div
    div bx                          ;ax dx = cursor / line_size
    mov rcx, V_CURSOR
    sub [rcx], dx                   ;cursor = cursor - remainder div -> setting it so the start of the line
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

screen_print_char:
    push rdi
    push rsi
    xor rdi, rdi                    ;set pointer to 0
    mov rsi, V_CURSOR
    mov di, [rsi]                   ;setup pointer to current cursorposition
    mov rsi, V_CURSOR_MAX
    cmp di, [rsi]                   ;is pointer > schreen size then lineup
    jle .skipp1
        call screen_lineup          ;call lineup
    .skipp1:
    mov rsi, V_SCREEN_START
    add rdi, [rsi]                  ;add screenmem start add as offset tro pointer
    mov byte [rdi+1], DEFAULT_COLOR ;write the color
    mov [rdi], dl                   ;write the char
    mov rsi, V_CURSOR
    add word [rsi], 2          ;set coursor to point to the next char
    pop rsi
    pop rdi
    ret

screen_print_string:
    push rdi
    push rsi
    push rdx
    mov rsi, V_A
    mov [rsi], rax
    mov rsi, V_B
    mov [rsi], rbx
    mov rsi, V_C
    mov [rsi], rcx
    mov rsi, V_D
    mov [rsi], rdx
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
            mov rsi, V_A
            mov rdx, [rsi]
            call screen_print_hex_q
            jmp .cmdret
        .B:
            mov rsi, V_B
            mov rdx, [rsi]
            call screen_print_hex_q
            jmp .cmdret
        .C:
            mov rsi, V_C
            mov rdx, [rsi]
            call screen_print_hex_q
            jmp .cmdret
        .D:
            mov rsi, V_D
            mov rdx, [rsi]
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
        pop rsi
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
    rol rdx, 4
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

screen_stackdump:
    push rdi 
    push rdx
    push rcx
    ;get the stack size
    mov edx, ebp                ;get stack base addr 
    sub edx, esp                ;stakc base addr - stack pointer addr = stack size
    mov rdi, T_SIZE             ;set pointer to string
    call screen_print_string    ;print string
    call screen_print_hex_d     ;print number -> stack size
    xor rcx, rcx
    mov ecx, edx
    ;print the stack
    .loop1:
        pop rdx
        call screen_nl
        call screen_print_hex_q
        loop .loop1
    ;return
    pop rcx 
    pop rdx
    pop rdi
    ret 
;-------------------------------------------------------------------------------------------
;Const
DEFAULT_COLOR       equ 0x0A

;Var
V_SCREEN_START:     dq 0xB8000
V_SCREEN_SIZE:      dq 0x0075F ;size in words

V_CURSOR:           dw 0x0000  ;is in bytes not in chars!
V_CURSOR_MAX:       dw 0x0EBE  ;is in bytes not in chars!

V_LINE_SIZE:        dw 160     ;num of chars in 1 line (1 char = 2bytes)

HEX:                db "0123456789ABCDEF_"

V_A:                dq 0
V_B:                dq 0
V_C:                dq 0
V_D:                dq 0

T_SIZE:             db "\nSize: \e"