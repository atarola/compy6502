MEMORY {
    DSTACK:
        start $0000
        size $100;
    HSTACK:
        start $0100
        size $100;
    RAM:
        start $0200
        size $CD00;
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
    CODE:
        load ROM
        align $100
        type ro;
    RODATA:
        load ROM
        align $100
        type ro;
    VECTORS:
        load ROM
        type ro
        start $FFFA;
}
