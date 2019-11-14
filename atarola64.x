MEMORY {
    ZEROPAGE:
        start $0000
        size $100;

    HSTACK:
        start $0100
        size $100;

    RAM1:
        start $0200
        size $BD00;

    RAM2:
        start $D000
        size $1000;

    EXT:
        start $E000
        size $1000;

    ROM:
        start $F000
        size $8000
        fill yes
        file %O;
}

SEGMENTS {
    ZEROPAGE:
        load ZEROPAGE
        type zp;

    BSS:
        load RAM2
        type bss;

    CODE:
        load ROM
        type ro;

    RODATA:
        load ROM
        type ro;

    VECTORS:
        load ROM
        type ro
        start $FFFA;
}
