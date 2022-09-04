[bits 64]
[org 0x80000000]
kernelstart:
    ;clear screen + start msg
    call screen_clear
    mov rdi, T_MSG_KERNEL
    call screen_print_string

    ;print kernel start addr
    mov rax, kernelstart
    mov rdi, T_MSG_SADDR
    call screen_print_string

    ;print kernal end addr
    mov rax, kernelend
    mov rdi, T_MSG_EADDR
    call screen_print_string

    ;print stack start addr
    mov rax, rbp
    mov rdi, T_MSG_STACK
    call screen_print_string

    ;remap IRQs
    mov bl, 0x20
    mov bh, 0x28
    call pic_remap
    mov rdi, T_MSG_PIC
    call screen_print_string

    ;init idt
    call idt_init
    mov rdi, T_MSG_IDT
    call screen_print_string

    ;setup exception handler
    call exc_init
    mov rdi, T_MSG_EXC
    call screen_print_string

    ;setup systemcounter
    call syscounter_init
    mov rdi, T_MSG_SYSCNT
    call screen_print_string

    ;get the amount of physical address bits
    mov eax, 0x80000008
    cpuid
    mov rsi, V_P_ADDR_BITS
    mov [rsi], al
    mov rsi, V_L_ADDR_BITS
    mov [rsi], ah
    mov rdi, T_MSG_PAB
    call screen_print_string
    mov dl, al
    call screen_print_hex_b
    mov rdi, T_MSG_LAB
    call screen_print_string
    mov dl, ah
    call screen_print_hex_b

    ;get memory map
    mov rsi, 0x7F00         ;get pointer to number of map entries
    xor rax, rax            ;set rax to 0
    mov ax, [rsi]           ;get number of pages from pointer
    mov rsi, V_BOOT_MEMMAP_CNT
    mov [rsi], ax           ;save count
    mov rsi, rax            ;copy it to counter max
    xor rcx, rcx            ;reset counter
    .l1:
        mov rdi, BOOT_MEMMAP     ;get pointer to start of map
        mov rax, 20              ;get factor 1(24) for mul
        mov rbx, rcx             ;get factor 2(counter)
        mul rbx                  ;calc map offset to get to entry of index counter
        add rdi, rax             ;add ofset to base addr
        mov rdx, [rdi + 8]       ;get size
        push rdi                 ;save pointer
        mov rdi, V_MEM_ALL       ;get pointer to memsize_all
        add [rdi], rdx           ;add size to var
        pop rdi                  ;get pointer back
        mov dl, [rdi + 16]       ;get type of entry
        cmp dl, 0x01             ;check if it is free useable memory
        jne .skipp1              ;if not skipp to end of loop code
        mov rdx, [rdi + 8]       ;get size of entry
        mov rdi, V_MEM_USEABLE   ;get pointer to memsize var
        add [rdi], rdx           ;add size to var
        .skipp1:
            inc rcx              ;dec counter
            cmp rcx, rsi         ;check if done
            jne .l1              ;if not loop
    mov rdi, T_MSG_MEM           ;get pointer to msg
    call screen_print_string     ;print msg
    mov rsi, V_MEM_USEABLE       ;get pointer to memsizevar 
    mov rdx, [rsi]               ;get val from var
    call screen_print_hex_q      ;print it
    
    ;copy memory map
    mov dx, 0x01
    mov cl, 0b00000011
    mov rbx, memorymap
    mov rax, 0x0
    call page_map
    mov rcx, 0x1000
    mov rbx, BOOT_MEMMAP
    .l2:
        mov dl, [rbx]
        mov [rax], dl
        inc rbx
        inc rax
        dec rcx
        jg .l2

    ;init memory management system for kernelspace
    call mem_init

    mov rdi, 8
    call mem_alloc
    mov QWORD [rdi], 0xFFFFFFFFFFFFFFFF
    mov rdx, rdi
    call screen_nl
    call screen_print_hex_q

    mov rdi, 8
    call mem_alloc
    mov QWORD [rdi], 0xFFFFFFFFFFFFFFFF
    mov rdx, rdi
    call screen_nl
    call screen_print_hex_q

    mov rdi, 8
    call mem_alloc
    mov QWORD [rdi], 0xFFFFFFFFFFFFFFFF
    mov rdx, rdi
    call screen_nl
    call screen_print_hex_q

    ;Print done msg
    mov rdi, T_MSG_END
    call screen_print_string
    jmp $


T_MSG_KERNEL:       db "---KERNEL-IN-64BIT-MODE---\e"
T_MSG_SADDR:        db "\nKernel start addr: \rA\e"
T_MSG_EADDR:        db "\nKernel end   addr: \rA\e"
T_MSG_STACK:        db "\nStack  start addr: \rA\e"
T_MSG_PIC:          db "\nRemaped IRQs\e"
T_MSG_IDT:          db "\nEnable IDT\e"
T_MSG_EXC:          db "\nSetup exception handler\e"
T_MSG_PAB:          db "\nPhysical address bits: 0x\e"
T_MSG_LAB:          db "\nLinear address bits:   0x\e"
T_MSG_AHCI:         db "\nSetup AHCI\e"
T_MSG_END:          db "\nDone with boot process \e"
T_MSG_PAGE:         db "\nMAP_PAGES start addr: \rA\e"
T_MSG_MEM:          db "\nMemory available: \e"
T_MSG_MEM_P_TBL:    db "\nP-mem allocator addr: \rA\e"
T_MSG_MEM_V_TBL:    db "\nV-mem allocator addr: \rA\e"
T_MSG_SYSCNT:       db "\nSetup system counter\e"

V_P_ADDR_BITS:      db 0
V_L_ADDR_BITS:      db 0

V_MEM_USEABLE:      dq 0
V_MEM_ALL:          dq 0

V_BOOT_MEMMAP_CNT:  dw 0

BOOT_MEMMAP         equ 0x0000000000008000
BOOT_MEMMAP_CNT     equ 0x0000000000007F00

;include tools
%include "./tools/bim.s"
%include "./math.s"

;include drivers
%include "./screen.s"

%include "./driver/syscounter.s"

%include "./cpu/idt.s"
%include "./cpu/pic.s"
%include "./cpu/exception.s"

%include "./mem/page_map.s"

%include "./memory/memory.s"

align 0x1000    ;get end of kernel page aligned
memorymap:      db 0

align 0x1000
kernelend:      db 0
