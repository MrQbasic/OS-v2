;pci_read_cfg_d         al = bus / bl = slot / cl = func / offset = dl                  => edx 
;pci_write_cfg_d        al = bus / bl = slot / cl = func / offset = dl / esi = data
;pci_print_cfg          al = bus / bl = slot / cl = func
;-------------------------------------------------------------------------------------------
[bits 64]

pci_read_cfg_d:
    push rbx
    push rcx
    push rdx
    push rax
    ;extract relevant parts
    and rax, 0xFF   ;bit 0-8
    and rbx, 0xFF   ;bit 0-8
    and rcx, 0xFF   ;bit 0-8
    and rdx, 0xFC   ;bit 3-8
    ;shift parts to match location in address
    shl rax, 16
    shl rbx, 11
    shl rcx, 08
    ;put addr together
    or rax, rbx
    or rax, rcx
    or rax, rdx
    or eax, 0x80000000
    ;Write addr to port
    mov rbx, rdx
    mov dx, PCI_P_CFG_ADDR
    out dx, eax
    ;calc shift for data
    and rbx, 2
    mov rax, 0x2      
    xor rax, rax
    mul ebx
    mov rcx, rax
    and rcx, 0xFFFF
    ;get data
    mov dx, PCI_P_CFG_DATA
    in eax, dx
    ;shift data
    shr eax, cl
    ;set output
    pop rdx
    mov edx, eax
    mov rax, rdx
    ;return
    pop rdx
    pop rcx
    pop rbx
    ret

pci_write_cfg_d:
    push rax
    push rbx
    push rcx
    push rdx
    ;extract relevant parts
    and rax, 0xFF   ;bit 0-8
    and rbx, 0xFF   ;bit 0-8
    and rcx, 0xFF   ;bit 0-8
    and rdx, 0xFC   ;bit 3-8
    ;shift parts to match location in address
    shl rax, 16
    shl rbx, 11
    shl rcx, 08
    ;put addr together
    or rax, rbx
    or rax, rcx
    or rax, rdx
    or eax, 0x80000000
    ;Write addr to port
    mov rbx, rdx
    mov dx, PCI_P_CFG_ADDR
    out dx, eax
    ;shift data
    mov dx, PCI_P_CFG_DATA
    mov eax, esi
    out dx, eax
    ;return
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

pci_print_cfg:
    push rax
    push rbx
    push rcx
    push rdx
    xor dl, dl          ;set offset to 0
    .l1:
        push rax
        push rdx
        call pci_read_cfg_d     ;get register
        mov rdx, rax
        call screen_nl
        call screen_print_hex_d ;print register
        pop rdx
        pop rax
        add dl, 4       ;set offset to next reg
        cmp dl, 0x40    ;check is loop is done
        jne .l1
    ;return
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

;-------------------------------------------------------------------------------------------
;ports
PCI_P_CFG_ADDR    equ 0x0CF8
PCI_P_CFG_DATA    equ 0x0CFC
;var
PCI_V_BUFFER:     dq 0x0
;const
;---------CLASS + SCLASS---------
PCI_C_CLASS_NO                  equ 0x00
PCI_C_SCLASS_NO_NO                  equ 0x00
PCI_C_SCLASS_NO_VGA                 equ 0x01
PCI_C_CLASS_STORAGE             equ 0x01
PCI_C_SCLASS_STORAGE_SCSI           equ 0x00
PCI_C_SCLASS_STORAGE_IDE            equ 0x01
PCI_C_SCLASS_STORAGE_FLOPPY         equ 0x02
PCI_C_SCLASS_STORAGE_IPI            equ 0x03
PCI_C_SCLASS_STORAGE_RAID           equ 0x04
PCI_C_SCLASS_STORAGE_ATA            equ 0x05
PCI_C_SCLASS_STORAGE_SATA           equ 0x06
PCI_C_SCLASS_STORAGE_SA_SCSI        equ 0x07
PCI_C_SCLASS_STORAGE_NV_MEM         equ 0x08
PCI_C_SCLASS_STORAGE_NO             equ 0x80
PCI_C_CLASS_NETWORK             equ 0x02
PCI_C_SCLASS_NETWORK_ETH            equ 0x00
PCI_C_SCLASS_NETWORK_TOKEN          equ 0x01
PCI_C_SCLASS_NETWORK_FDDI           equ 0x02
PCI_C_SCLASS_NETWORK_ATM            equ 0x03
PCI_C_SCLASS_NETWORK_ISDN           equ 0x04
PCI_C_SCLASS_NETWORK_WORLD_FLIP     equ 0x05
PCI_C_SCLASS_NETWORK_PICMG          equ 0x06
PCI_C_SCLASS_NETWORK_INFI           equ 0x07
PCI_C_SCLASS_NETWORK_FABRIC         equ 0x08
PCI_C_SCLASS_NETWORK_NO             equ 0x80
PCI_C_CLASS_DISPLAY             equ 0x03
PCI_C_SCLASS_DISPLAY_VGA            equ 0x00
PCI_C_SCLASS_DISPLAY_XGA            equ 0x01
PCI_C_SCLASS_DISPLAY_3D             equ 0x02
PCI_C_SCLASS_DISPLAY_AUDIO          equ 0x03
PCI_C_SCLASS_DISPLAY_NO             equ 0x80
PCI_C_CLASS_MULTIMEDIA          equ 0x04
PCI_C_SCLASS_MULTIMEDIA_M_VIDEO     equ 0x00
PCI_C_SCLASS_MULTIMEDIA_M_AUDIO     equ 0x01
PCI_C_SCLASS_MULTIMEDIA_TELE        equ 0x02
PCI_C_SCLASS_MULTIMEDIA_AUDIO       equ 0x03
PCI_C_SCLASS_MULTIMEDIA_NO          equ 0x04
PCI_C_CLASS_MEMORY              equ 0x05
PCI_C_SCLASS_MEMORY_RAM             equ 0x00
PCI_C_SCLASS_MEMORY_FLASH           equ 0x01
PCI_C_SCLASS_MEMORY_NO              equ 0x80
PCI_C_CLASS_BRIDGE              equ 0x06
PCI_C_SCLASS_BRIDGE_HOST            equ 0x00
PCI_C_SCLASS_BRIDGE_ISA             equ 0x01
PCI_C_SCLASS_BRIDGE_EISA            equ 0x02
PCI_C_SCLASS_BRIDGE_MCA             equ 0x03
PCI_C_SCLASS_BRIDGE_PCI2PCI         equ 0x04
PCI_C_SCLASS_BRIDGE_PCMCIA          equ 0x05
PCI_C_SCLASS_BRIDGE_NUBUS           equ 0x06
PCI_C_SCLASS_BRIDGE_CARDBUS         equ 0x07
PCI_C_SCLASS_BRIDGE_RACEWAY         equ 0x08
PCI_C_SCLASS_BRIDGE_INFI            equ 0x0A
PCI_C_SCLASS_BRIDGE_NO              equ 0x80
PCI_C_CLASS_COM                 equ 0x07
PCI_C_SCLASS_COM_SERIAL             equ 0x00
PCI_C_SCLASS_COM_PARALLEL           equ 0x01
PCI_C_SCLASS_COM_MULTIPORT          equ 0x02
PCI_C_SCLASS_COM_MODEM              equ 0x03
PCI_C_SCLASS_COM_IEEE               equ 0x05
PCI_C_SCLASS_COM_SMART_CARD         equ 0x06
PCI_C_SCLASS_COM_No                 equ 0x80
PCI_C_CLASS_SYSBASE             equ 0x08
PCI_C_SCLASS_SYSBASE_PCI            equ 0x00
PCI_C_SCLASS_SYSBASE_DMA            equ 0x01
PCI_C_SCLASS_SYSBASE_TIMER          equ 0x02
PCI_C_SCLASS_SYSBASE_RTC            equ 0x03
PCI_C_SCLASS_SYSBASE_HOTPLUG        equ 0x04
PCI_C_SCLASS_SYSBASE_SD             equ 0x05
PCI_C_SCLASS_SYSBASE_IOMMU          equ 0x06
PCI_C_SCLASS_SYSBASE_NO             equ 0x80
PCI_C_CLASS_INPUT               equ 0x09
PCI_C_SCLASS_INPUT_KEYB             equ 0x00
PCI_C_SCLASS_INPUT_DIGITIZER        equ 0x01
PCI_C_SCLASS_INPUT_MOUSE            equ 0x02
PCI_C_SCLASS_INPUT_SCANNER          equ 0x03
PCI_C_SCLASS_INPUT_GAMEPORT         equ 0x04
PCI_C_SCLASS_INPUT_NO               equ 0x80
PCI_C_CLASS_DOCK                equ 0x0A
PCI_C_SCLASS_DOCK_GENERIC           equ 0x00
PCI_C_SCLASS_DOCK_NO                equ 0x80
PCI_C_CLASS_PROCESSOR           equ 0x0B
PCI_C_SCLASS_PROCESSOR_386          equ 0x00
PCI_C_SCLASS_PROCESSOR_486          equ 0x01
PCI_C_SCLASS_PROCESSOR_P            equ 0x02
PCI_C_SCLASS_PROCESSOR_P_PRO        equ 0x03
PCI_C_SCLASS_PROCESSOR_ALPHA        equ 0x10
PCI_C_SCLASS_PROCESSOR_PPC          equ 0x20
PCI_C_SCLASS_PROCESSOR_MIPS         equ 0x30
PCI_C_SCLASS_PROCESSOR_CO           equ 0x50
PCI_C_SCLASS_PROCESSOR_NO           equ 0x80
PCI_C_CLASS_SERIAL              equ 0x0C
PCI_C_SCLASS_SERIAL_FIREWIRE        equ 0x00
PCI_C_SCLASS_SERIAL_ACCESS          equ 0x01
PCI_C_SCLASS_SERIAL_SSA             equ 0x02
PCI_C_SCLASS_SERIAL_USB             equ 0x03
PCI_C_SCLASS_SERIAL_FIBRE           equ 0x04
PCI_C_SCLASS_SERIAL_SMBUS           equ 0x05
PCI_C_SCLASS_SERIAL_INFI            equ 0x06
PCI_C_SCLASS_SERIAL_IPMI            equ 0x07
PCI_C_SCLASS_SERIAL_SERCOS          equ 0x08
PCI_C_SCLASS_SERIAL_CANBUS          equ 0x09
PCI_C_SCLASS_SERIAL_NO              equ 0x80
PCI_C_CLASS_WIRELESS            equ 0x0D
PCI_C_SCLASS_WIRELESS_IRDA          equ 0x00
PCI_C_SCLASS_WIRELESS_IR            equ 0x01
PCI_C_SCLASS_WIRELESS_RF            equ 0x10
PCI_C_SCLASS_WIRELESS_BLUETOOTH     equ 0x11
PCI_C_SCLASS_WIRELESS_BROADBAND     equ 0x12
PCI_C_SCLASS_WIRELESS_ETH_A         equ 0x20
PCI_C_SCLASS_WIRELESS_ETH_B         equ 0x21
PCI_C_SCLASS_WIRELESS_NO            equ 0x80
PCI_C_CLASS_INTELLIGENT         equ 0x0E
PCI_C_SCLASS_INTELLIGENT_I20        equ 0x00
PCI_C_CLASS_SATELLITE           equ 0x0F
PCI_C_SCLASS_SATELLITE_TV           equ 0x01
PCI_C_SCLASS_SATELLITE_AUDIO        equ 0x02
PCI_C_SCLASS_SATELLITE_VOICE        equ 0x03
PCI_C_SCLASS_SATELLITE_DATA         equ 0x04
PCI_C_CLASS_CRYPTO              equ 0x10
PCI_C_SCLASS_CRYPTO_NET             equ 0x00
PCI_C_SCLASS_CRYPTO_ENT             equ 0x10
PCI_C_SCLASS_CRYPTO_NO              equ 0x80
PCI_C_CLASS_SIGNAL              equ 0x11
PCI_C_SCLASS_SIGNAL_DPIO            equ 0x00
PCI_C_SCLASS_SIGNAL_CNT             equ 0x01
PCI_C_SCLASS_SIGNAL_COM             equ 0x10
PCI_C_SCLASS_SIGNAL_SIGNAL          equ 0x20
PCI_C_SCLASS_SIGNAL_NO              equ 0x80