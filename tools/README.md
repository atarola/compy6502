# Tools

## `wozmon-hex.py`

Assembles a ca65 source file and prints Wozmon-ready hex records.

```bash
tools/wozmon-hex.py --run 4000 test/wozmon/hello.s
```

Example output:

```text
3000: 0D 0A 48 65 6C
3005: 6C 6F 20 57 6F
300A: 72 6C 64 21 0D
300F: 0A 00
4000: A2 00 BD 00 30
4005: F0 0C 8D 00 C0
400A: A9 FF 3A D0 FD
400F: E8 4C 02 40 4C
4014: 00 F5
4000R
```

The default output width is 5 bytes per line for easier hand checking.

Refresh the checked-in Wozmon paste file:

```bash
tools/wozmon-hex.py --run 4000 test/wozmon/hello.s > test/wozmon/hello.w
```

Useful options:

```bash
tools/wozmon-hex.py --run 4000 --columns 8 test/wozmon/hello.s
tools/wozmon-hex.py --cpu 65c02 test/wozmon/hello.s
```

The source can use `.org` to place separate data/code ranges. Contiguous ranges are coalesced and printed as separate Wozmon records.
