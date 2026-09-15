#!/usr/bin/env python3
"""Assert that dwm's bar is painted with the palette the state file asks for.

This is the end-to-end check for dwm's runtime theming: dwm re-reads
~/.local/state/theme and rebuilds its colour schemes on SIGWINCH, which
propagate_state.sh sends after each toggle (see reloadtheme() in
profiles/desktop/configs/suckless/dwm/dwm.c).

Needs a running X session with dwm — run it on the desktop machine.

    dwm_bar_probe.py                        # list the bar colours (debugging)
    dwm_bar_probe.py --expect light|dark    # assert, exit 1 on mismatch

Signatures (config.h: col_secondary = bar surface, col_primary = focused tab):
    dark   surface #1c1f26   tab #505151
    light  surface #FAFAFA   tab #1A1A2E
"""

import collections
import struct
import subprocess
import sys

SURFACE = {"dark": "1C1F26", "light": "FAFAFA"}
ROWS = (2, 5, 10, 15, 20)  # inside dwm's bar (bh = font height + 2, ~25px)


def bar_colours(rows=ROWS, top_n=3):
    """Colours of the root window's top rows, most common first."""
    raw = subprocess.run(["xwd", "-root", "-silent"], capture_output=True, check=True).stdout
    for endian in "<>":  # xwd writes in the server's byte order
        hdr = struct.unpack_from(endian + "25I", raw, 0)
        if hdr[1] == 7:  # XWD_FILE_VERSION
            break
    hsize, width, height = hdr[0], hdr[4], hdr[5]
    byteorder, bits_pp, bytes_pl, ncolors = hdr[7], hdr[11], hdr[12], hdr[19]
    off = hsize + ncolors * 12
    nbytes = bits_pp // 8
    px_endian = "little" if byteorder == 0 else "big"

    seen = collections.Counter()
    for y in rows:
        if y >= height:
            continue
        line = raw[off + y * bytes_pl: off + y * bytes_pl + width * nbytes]
        for colour, n in collections.Counter(
            int.from_bytes(line[x:x + nbytes], px_endian) & 0xFFFFFF
            for x in range(0, len(line) - nbytes + 1, nbytes)
        ).most_common(top_n):
            seen[f"{colour:06X}"] += n
    return seen


def main():
    expect = None
    if "--expect" in sys.argv:
        expect = sys.argv[sys.argv.index("--expect") + 1]

    colours = bar_colours()
    print("bar colours:", ", ".join(f"#{c} ({n}px)" for c, n in colours.most_common(6)))

    if not expect:
        return 0
    if expect not in SURFACE:
        print(f"usage: {sys.argv[0]} [--expect light|dark]", file=sys.stderr)
        return 2

    mine, theirs = SURFACE[expect], SURFACE["light" if expect == "dark" else "dark"]
    if mine in colours and theirs not in colours:
        print(f"OK: bar shows the {expect} palette (#{mine})")
        return 0
    print(f"FAIL: expected the {expect} palette (#{mine} present, #{theirs} absent)", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
