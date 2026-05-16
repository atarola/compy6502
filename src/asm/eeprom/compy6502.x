MEMORY {
    ROM: start = $8000, size = $8000, type = ro, fill = yes, file = %O;
}

SEGMENTS {
    JUMPTABLE: load = ROM, type = ro, start = $C100;
    KERNEL:    load = ROM, type = ro, start = $C200;
    WOZMON:    load = ROM, type = ro, start = $F500;
    VECTORS:   load = ROM, type = ro, start = $FFFA;
}