;pic_remap        bl = PIC_1 Offset / bh = PIC_2 Offset
;pic_eoi
;-------------------------------------------------------------------------------------------
[bits 64]
pic_remap:
    push rax
    push rcx
    push rdx
    ;save marks
    mov dx, PIC_1_DATA          ;PIC_1_DATA port
    in al, dx                   ;get PIC_1_DATA
    mov cl, al                  ;save it in cl
    mov dx, PIC_2_DATA          ;PIC_2_DATA port
    in al, dx                   ;get PIC_2_DATA
    mov ch, al                  ;save it in ch
    ;ICW1 - send init to both PICs
    mov al, (PIC_ICW1_INIT | PIC_ICW1_ICW4) ;INIT cmd
    mov dx, PIC_1_CMD           ;PIC_1_CMD port
    out dx, al                  ;send init cmd to PIC_1
    mov dx, PIC_2_CMD           ;PIC_2_CMD port
    out dx, al                  ;send init cmd to PIC_2
    ;ICW2 - set vector offsets
    mov al, bl                  ;get bl (offset for PIC_1)
    mov dx, PIC_1_DATA          ;PIC_1_DATA port
    out dx, al                  ;send bl to PIC_1_DATA
    mov al, bh                  ;get bh (offset for PIC_2)
    mov dx, PIC_2_DATA          ;PIC_2_DATA port
    out dx, al                  ;send bh to PIC_2_DATA
    ;ICW3 - master / slave cfg
    mov al, 0b00000100          ;master cgf (slave at IRQ-2 0x04)
    mov dx, PIC_1_DATA          ;PIC_1_DATA port
    out dx, al                  ;send master cfg to PIC_1_DATA
    mov al, 0b00000010          ;slave cfg  (cascade identity 0x02) 
    mov dx, PIC_2_DATA          ;PIC_2_DATA port
    out dx, al                  ;send slave cgf to PIC_2_DATA
    ;ICW4 - operation mode
    mov al, PIC_ICW4_8086       ;80x86 mode
    mov dx, PIC_1_DATA          ;PIC_1_DATA port
    out dx, al                  ;send cfg to PIC_1_DATA port
    mov dx, PIC_2_DATA          ;PIC_2_DATA port
    out dx, al                  ;send cgf ti PIC_2_DATA port
    ;restore marks
    mov al, cl                  ;get cl (saved marks of PIC_1)
    mov dx, PIC_1_DATA          ;PIC_1_DATA port
    out dx, al                  ;send cl to PIC_1_DATA
    mov al, ch                  ;get ch (saved marks of PIC_2)
    mov dx, PIC_2_DATA          ;PIC_2_DATA port
    out dx, al                  ;send ch to PIC_2_DATA
    ;return
    pop rdx
    pop rcx
    pop rax
    ret

pic_eoi:
    push rax
    push rdx
    mov al, PIC_EOI             ;EOI cmd
    mov dx, PIC_1_CMD           ;PIC_1_CMD port
    mov dx, al                  ;send EOI cmd to PIC_1_CMD
    mov dx, PIC_2_CMD           ;PIC_2_CMD port
    mov dx, al                  ;send EOI cmd to PIC_2_CMD
    ;return
    pop rdx
    pop rax
    ret
;-------------------------------------------------------------------------------------------
;Const
;IO Ports
PIC_1_CMD           equ 0x20
PIC_1_DATA          equ 0x21
PIC_2_CMD           equ 0xA0
PIC_2_DATA          equ 0xA1
;COMMANDS
PIC_ICW1_ICW4       equ 0x01
PIC_ICW1_SINGLE     equ 0x02
PIC_ICW1_INTERVAL4  equ 0x04
PIC_ICW1_LEVEL      equ 0x08
PIC_ICW1_INIT       equ 0x10
PIC_ICW4_8086       equ 0x01
PIC_ICW4_AUTO       equ 0x02
PIC_ICW4_BUF_SLAVE  equ 0x08
PIC_ICW4_BUF_MASTER equ 0x0C
PIC_ICW4_SFNM       equ 0x10
PIC_EOI             equ 0x20