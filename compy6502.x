MEMORY {
    ROM:     start = $8000, size = $7FFA, fill = yes, file = %O;
    VECTORS: start = $FFFA, size = $0006, fill = yes, file = %O;
}

SEGMENTS {
    TEST_C555: load ROM type ro start $C555;
    CODE: load ROM type ro start $D000;
    TEST_DAAA: load ROM type ro start $DAAA;
    VECTORS: load VECTORS type ro;
}
