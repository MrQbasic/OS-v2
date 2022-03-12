while(True):
    dw1 = int(input("DW1: "),16) & 0xFFFFFFFF
    dw2 = int(input("DW2: "),16) & 0xFFFFFFFF
    dw3 = int(input("DW3: "),16) & 0xFFFFFFFF
    
    segsel = (dw1 >> 16) & 0xFFFF
    offset = (dw1 & 0xFFFF) | (dw2 & 0xFFFF0000) | (dw3 << 32)
    ist = (dw2 & 0b11)
    gatetype = (dw2 & 0b111100000000) >> 8
    dpl = (dw2 & 0b100000000000000) >> 14
    pr = (dw2 & 0b1000000000000000) >> 15

    print("Offset:  ",hex(offset))
    print("DPL:     ", dpl)
    print("Present: ", pr)
    print("IST:     ", ist)
    print("Segment Selector:")
    print("    Index: ",hex(segsel >> 3))
    print("    RPL:   ",hex(segsel & 0b11))
    if(segsel & 0b100):
        print("    LDT")
    else:
        print("    GDT")
    print("Gate Type: ")
    if(gatetype == 0b1110):
        print("    Interrupt Gate")
    if(gatetype == 0b1111):
        print("    Trap Gate")