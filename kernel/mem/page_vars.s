[bits 64]

;vars
page_pml4e:         dq 0
page_pdpte:         dq 0
page_pde:           dq 0

page_pml4_base:     dq 0
page_pdpt_base:     dq 0
page_pd_base:       dq 0
page_pt_base:       dq 0

page_buffer_p_addr: dq 0
page_buffer_v_addr: dq 0
page_buffer_flags:  db 0

page_filter:        dq 0

page_start:         dq 0    ; start addr of pages

;text
page_E_space:       db "\nERROR->no space left for mem-map pages! \e"
page_E_res_1:       db "\nERROR->can not resolve addr. No plm4e!  \e"
page_E_res_2:       db "\nERROR->can not resolve addr. No pdpte!  \e"
page_E_res_3:       db "\nERROR->can not resolve addr. No pde!    \e"
page_E_res_4:       db "\nERROR->can not resolve addr. NO pte!    \e"
page_T_plm4:        db "\nGet sapce for plm4e  ENTRY:\rA  ADDR:\rB\e"
page_T_pdpt:        db "\nGet sapce for pdpte  ENTRY:\rA  ADDR:\rB\e"
page_T_pd:          db "\nGet sapce for pde    ENTRY:\rA  ADDR:\rB\e"

page_T_ree:         db "\nreentry\e"

;consts
page_plm4_default_flags     equ 0b00000011
page_pdpt_default_flags     equ 0b00000011
page_pd_default_flags       equ 0b00000011  
page_numpages               equ 1023

;page index
page_pages:
times 1024          db 0x00