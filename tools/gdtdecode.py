while(True):
    dw1 = int(input("DW1: "),16) & 0xFFFFFFFF
    dw2 = int(input("DW2: "),16) & 0xFFFFFFFF

    base = (dw1 & 0xFFFF0000) >> 16
    base += (dw2 & 0xFF) << 16
    base += (dw2 & 0xFF000000)

    limit = (dw1 & 0xFFFF)
    limit += (dw2 & 0xFF0000)

    acb = (dw2 & 0xFF00) >> 8

    flags = (dw2 & 0xF00000) >> 20

    print("Base:  ", hex(base))

    print("Limit: ", hex(limit))

    print("ACB:   ", hex(acb))
    if(acb & 0b10000000):
        print("  Present")
    else:
        print("  Not Present")
    print("  DPL: ", hex((acb & 0b01100000) >> 5))
    if(acb & 0b00010000):
        print("  code/data seg")
    else:
        print("  system seg")
    if(acb & 0b00001000):
        print("  code seg")
    else:
        print("  data seg")
    if(acb & 0b00000001):
        print("  Accessed")
    else:
        print("  Not Accessed")

    print("Flags: ", hex(flags))
    if(flags & 0b1000):
        print("  Block size 4-KiB")
    else:
        print("  Block size 1-B")
    if(flags & 0b0100):
        print("  16-Bit PM seg")
    else:
        print("  32-Bit PM seg")
    if(flags & 0b0010):
        print("  64-Bit code seg")