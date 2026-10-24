#!/usr/bin/env python3
"""lut.py — gamma LUT + colour-matrix (CTM) engine for the X11 session.

Why this exists
---------------
`xrandr --brightness` applies a flat multiply to the video LUT. On this panel
that multiply saturates almost immediately (setting 1.25 reads back as 1.3),
and it clips every highlight into white. `xcalib` is not an option either: it
writes through XF86VidMode, which the modesetting driver does not expose, so it
silently no-ops (verified: `xcalib -clear` does not even remove an
`xrandr --brightness` boost).

So we talk to the same RandR LUT that `xrandr` and picom use, via ctypes — no
compiled helper, no extra package, and an exact curve instead of a multiply:

    out = in ** e        (0 < e < 1 lifts midtones, keeps white at white)

That cannot add nits (the panel is already at 100% duty); it redistributes the
tonal range so dark content stops looking black. Shadows lift, white stays put.

The CTM path sets the 3x3 colour matrix the modesetting driver exposes per
output (saturation / digital vibrance). It is a separate stage from the gamma
LUT, so picom resetting the LUT does not disturb it, and vice versa.

Commands
--------
    lut.py lum <pct>       LUT curve for 100..130 (100 = identity)
    lut.py lum-reset       identity LUT
    lut.py vib <pct>       extra saturation 0..40 (0 = identity)
    lut.py show            what the server currently holds
    lut.py lum <pct> --test [secs]
                           apply, wait, restore — surfaces a bad curve without
                           leaving the screen in that state

Environment
-----------
    LIGHT_CEILING   upper end of the lum scale (default 130)
    LIGHT_STRENGTH  how hard the curve pushes (default 0.30; 0 = off)
"""

import ctypes
import ctypes.util
import os
import sys
import time

# --- ctypes plumbing -------------------------------------------------------

_x11 = ctypes.CDLL(ctypes.util.find_library("X11") or "libX11.so.6")
_xrr = ctypes.CDLL(ctypes.util.find_library("Xrandr") or "libXrandr.so.2")

XID = ctypes.c_ulong


class _ScreenResources(ctypes.Structure):
    """XRRScreenResources — stable ABI: two Time, then count/pointer pairs."""

    _fields_ = [
        ("timestamp", ctypes.c_ulong),
        ("config_timestamp", ctypes.c_ulong),
        ("n_crtc", ctypes.c_int),
        ("crtcs", ctypes.POINTER(XID)),
        ("n_output", ctypes.c_int),
        ("outputs", ctypes.POINTER(XID)),
        ("n_mode", ctypes.c_int),
        ("modes", ctypes.c_void_p),
    ]


class _CrtcGamma(ctypes.Structure):
    _fields_ = [
        ("size", ctypes.c_int),
        ("red", ctypes.POINTER(ctypes.c_ushort)),
        ("green", ctypes.POINTER(ctypes.c_ushort)),
        ("blue", ctypes.POINTER(ctypes.c_ushort)),
    ]


_x11.XOpenDisplay.restype = ctypes.c_void_p
_x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
_x11.XDefaultRootWindow.restype = XID
_x11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
_x11.XInternAtom.restype = ctypes.c_ulong
_x11.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
_x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
_x11.XSync.argtypes = [ctypes.c_void_p, ctypes.c_int]

_xrr.XRRGetScreenResourcesCurrent.restype = ctypes.POINTER(_ScreenResources)
_xrr.XRRGetScreenResourcesCurrent.argtypes = [ctypes.c_void_p, XID]
_xrr.XRRFreeScreenResources.argtypes = [ctypes.POINTER(_ScreenResources)]
_xrr.XRRGetCrtcGammaSize.restype = ctypes.c_int
_xrr.XRRGetCrtcGammaSize.argtypes = [ctypes.c_void_p, XID]
_xrr.XRRGetCrtcGamma.restype = ctypes.POINTER(_CrtcGamma)
_xrr.XRRGetCrtcGamma.argtypes = [ctypes.c_void_p, XID]
_xrr.XRRSetCrtcGamma.restype = None
_xrr.XRRSetCrtcGamma.argtypes = [ctypes.c_void_p, XID, ctypes.POINTER(_CrtcGamma)]
_xrr.XRRFreeGamma.argtypes = [ctypes.POINTER(_CrtcGamma)]
_xrr.XRRGetOutputProperty.restype = ctypes.c_int
_xrr.XRRGetOutputProperty.argtypes = [
    ctypes.c_void_p, XID, ctypes.c_ulong, ctypes.c_long, ctypes.c_long,
    ctypes.c_int, ctypes.c_int, ctypes.c_ulong,
    ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_int),
    ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_ulong),
    ctypes.POINTER(ctypes.c_void_p),
]
_xrr.XRRChangeOutputProperty.restype = ctypes.c_int
_xrr.XRRChangeOutputProperty.argtypes = [
    ctypes.c_void_p, XID, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_int,
    ctypes.c_int, ctypes.c_void_p, ctypes.c_int,
]

# Any X error (a driver rejecting CTM, a vanished output) must surface as a
# Python exception, not kill the process half-way with a bad LUT installed.
_LAST_X_ERROR = []
_ERR_HANDLER = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p)


def _on_x_error(dpy, event):
    _LAST_X_ERROR.append(int(ctypes.cast(event, ctypes.POINTER(ctypes.c_int))[0]))
    return 0


_ERROR_CB = _ERR_HANDLER(_on_x_error)
_x11.XSetErrorHandler.argtypes = [ctypes.c_void_p]
_x11.XSetErrorHandler.restype = ctypes.c_void_p


class Display:
    def __init__(self):
        self.dpy = _x11.XOpenDisplay(None)
        if not self.dpy:
            raise RuntimeError("cannot open DISPLAY")
        _x11.XSetErrorHandler(ctypes.cast(_ERROR_CB, ctypes.c_void_p))
        self.root = _x11.XDefaultRootWindow(self.dpy)
        self.res = _xrr.XRRGetScreenResourcesCurrent(self.dpy, self.root)

    def check(self):
        _x11.XSync(self.dpy, 0)
        if _LAST_X_ERROR:
            codes = ",".join(str(c) for c in _LAST_X_ERROR)
            del _LAST_X_ERROR[:]
            raise RuntimeError(f"X error(s): {codes}")

    def atoms(self, *names):
        return [_x11.XInternAtom(self.dpy, n.encode(), 0) for n in names]

    def close(self):
        if self.res:
            _xrr.XRRFreeScreenResources(self.res)
        _x11.XCloseDisplay(self.dpy)

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()


# --- LUT -------------------------------------------------------------------

def curve(size, pct, ceiling=130, strength=0.30):
    """out = in ** e, e <= 1. White is preserved, midtones lift with pct."""
    if pct <= 100 or size < 2:
        return [round(i * 65535 / (size - 1)) for i in range(size)]
    span = max(1, ceiling - 100)
    t = min(1.0, (pct - 100) / span)
    e = 1.0 - strength * t
    return [round(65535 * (i / (size - 1)) ** e) for i in range(size)]


def _gamma_block(size, red, green=None, blue=None):
    """Pack three ramps into the single contiguous block libXrandr expects.

    XRRSetCrtcGamma() serialises size*3 shorts starting at gamma->red and never
    reads the green/blue pointers, so separate allocations send garbage (or
    zeros) for two channels — the server then reports an all-black ramp.
    """
    green = red if green is None else green
    blue = red if blue is None else blue
    buf = (ctypes.c_ushort * (size * 3))()
    buf[0:size] = red
    buf[size:2 * size] = green
    buf[2 * size:3 * size] = blue
    red_ptr = ctypes.cast(buf, ctypes.POINTER(ctypes.c_ushort))
    green_ptr = ctypes.cast(ctypes.byref(buf, size * 2), ctypes.POINTER(ctypes.c_ushort))
    blue_ptr = ctypes.cast(ctypes.byref(buf, size * 4), ctypes.POINTER(ctypes.c_ushort))
    return buf, _CrtcGamma(size, red_ptr, green_ptr, blue_ptr)


def frames(d, pct):
    """Current ramps of every CRTC that has one, for reporting."""
    out = []
    for i in range(d.res.contents.n_crtc):
        crtc = d.res.contents.crtcs[i]
        size = _xrr.XRRGetCrtcGammaSize(d.dpy, crtc)
        if size <= 0:
            continue
        g = _xrr.XRRGetCrtcGamma(d.dpy, crtc)
        if not g:
            continue
        out.append((crtc, size, g.contents.red[(size - 1) // 2]))
        _xrr.XRRFreeGamma(g)
    return out


def apply_lum(pct, dry_run=False):
    ceiling = int(os.environ.get("LIGHT_CEILING", "130"))
    strength = float(os.environ.get("LIGHT_STRENGTH", "0.30"))
    limit = 1 << 16
    changed = []
    with Display() as d:
        for i in range(d.res.contents.n_crtc):
            crtc = d.res.contents.crtcs[i]
            size = _xrr.XRRGetCrtcGammaSize(d.dpy, crtc)
            if size <= 0:  # CRTC is off
                continue
            ramp = curve(size, pct, ceiling, strength)
            if min(ramp) < 0 or max(ramp) > limit - 1:
                raise ValueError("curve out of LUT range")
            buf, gamma = _gamma_block(size, ramp)
            if not dry_run:
                _xrr.XRRSetCrtcGamma(d.dpy, crtc, ctypes.byref(gamma))
            changed.append((size, ramp[(size - 1) // 2]))
        d.check()
    for size, mid in changed:
        gain = 1.0
        if pct > 100:
            gain = 2 ** (0.30 * min(1.0, (pct - 100) / max(1, ceiling - 100)))
        print(f"crtc lut={size} mid={mid} (x{gain:.2f} at midtones)")
    if not changed:
        raise RuntimeError("no active CRTC exposed a gamma LUT")


# --- CTM (saturation / vibrance) -------------------------------------------

def _s31_32(value):
    """Encode a float as the (lo, hi) int32 pair xserver wants for CTM.

    The property is an array of nine s31.32 int64 in host (little-endian)
    order, so each coefficient contributes its low word before its high word.
    """
    fixed = int(round(value * (1 << 32)))
    fixed &= (1 << 64) - 1  # two's complement into 64 bits
    return fixed & 0xFFFFFFFF, (fixed >> 32) & 0xFFFFFFFF


def saturation_matrix(pct):
    """Identity at pct=0; chroma amplified around luma above it."""
    s = 1.0 + max(0.0, pct) / 100.0
    luma = (0.2126, 0.7152, 0.0722)
    return [[s + (1 - s) * luma[j] if i == j else (1 - s) * luma[j]
             for j in range(3)] for i in range(3)]


def _ctm_words(matrix):
    words = []
    for row in matrix:
        for value in row:
            lo, hi = _s31_32(value)
            words.extend((lo, hi))
    return words


def read_ctm(d, output, atom):
    st, fmt, n = ctypes.c_ulong(), ctypes.c_int(), ctypes.c_ulong()
    after, data = ctypes.c_ulong(), ctypes.c_void_p()
    rc = _xrr.XRRGetOutputProperty(
        d.dpy, output, atom, 0, 64, 0, 0, 0,
        ctypes.byref(st), ctypes.byref(fmt), ctypes.byref(n),
        ctypes.byref(after), ctypes.byref(data))
    if rc != 0 or not data.value or n.value != 18:
        return None
    # format=32 properties come back as an array of `long`, 4 bytes used per
    # slot on LP64 — indexing as int32 silently misreads them.
    words = [ctypes.cast(data, ctypes.POINTER(ctypes.c_long))[i] & 0xFFFFFFFF
             for i in range(18)]
    matrix, i = [], 0
    while i < 18:
        c = (words[i + 1] << 32) | words[i]
        if c >= 1 << 63:
            c -= 1 << 64
        matrix.append(c / (1 << 32))
        i += 2
    return matrix


def _words_data(words):
    """Wrap 32-bit property words as C long[], which is what Xlib expects.

    For format=32 properties Xlib takes the low 32 bits of each `long`, so an
    int32 array is read 8 bytes at a time and the property comes out garbage.
    """
    signed = [w if w < 1 << 31 else w - (1 << 32) for w in words]
    return (ctypes.c_long * len(signed))(*signed)


def _connected(d, output, edid_atom):
    """A monitor is attached iff the EDID property carries bytes."""
    st, fmt, n = ctypes.c_ulong(), ctypes.c_int(), ctypes.c_ulong()
    after, data = ctypes.c_ulong(), ctypes.c_void_p()
    rc = _xrr.XRRGetOutputProperty(
        d.dpy, output, edid_atom, 0, 64, 0, 0, 0,
        ctypes.byref(st), ctypes.byref(fmt), ctypes.byref(n),
        ctypes.byref(after), ctypes.byref(data))
    return rc == 0 and n.value > 0


def apply_vib(pct, test_seconds=0):
    strength = max(0.0, min(40.0, pct))
    matrix = saturation_matrix(strength)
    words = _ctm_words(matrix)
    data = _words_data(words)
    applied = []
    with Display() as d:
        ctm_atom, type_atom, edid_atom = d.atoms("CTM", "INTEGER", "EDID")
        for i in range(d.res.contents.n_output):
            output = d.res.contents.outputs[i]
            if read_ctm(d, output, ctm_atom) is None:
                continue
            if not _connected(d, output, edid_atom):
                continue
            _xrr.XRRChangeOutputProperty(
                d.dpy, output, ctm_atom, type_atom, 32, 0, data, 18)
            d.check()
            applied.append(output)
        if not applied:
            raise RuntimeError("no connected output exposed a writable CTM")
        print(f"ctm set on {len(applied)} output(s): saturation x{1 + strength / 100:.2f}")
        for output in applied:
            print(f"  output {hex(output)} -> {[round(v, 3) for v in read_ctm(d, output, ctm_atom)]}")
        if test_seconds:
            d.check()
            time.sleep(test_seconds)
            ident = _words_data(_ctm_words(saturation_matrix(0)))
            for output in applied:
                _xrr.XRRChangeOutputProperty(
                    d.dpy, output, ctm_atom, type_atom, 32, 0, ident, 18)
            d.check()
            print("ctm restored to identity")


# --- CLI -------------------------------------------------------------------

def usage():
    print(__doc__.strip().split("Commands\n--------\n")[-1].split("\n\n")[0],
          file=sys.stderr)
    print("  show                 report current LUT midpoint and CTM", file=sys.stderr)


def main(argv):
    if len(argv) < 2:
        usage()
        return 2
    cmd = argv[1]
    test = "--test" in argv
    args = [a for a in argv[2:] if not a.startswith("--")]
    test_secs = 8
    if test and args and args[-1].isdigit():
        test_secs = int(args.pop())

    if cmd == "lum":
        pct = int(args[0]) if args else 100
        apply_lum(pct)
        if test:
            print(f"holding {test_secs}s, then identity", flush=True)
            time.sleep(test_secs)
            apply_lum(100)
        return 0
    if cmd in ("lum-reset", "reset"):
        apply_lum(100)
        return 0
    if cmd == "vib":
        apply_vib(int(args[0]) if args else 0, test_secs if test else 0)
        return 0
    if cmd == "show":
        with Display() as d:
            (ctm_atom,) = d.atoms("CTM")
            (edid_atom,) = d.atoms("EDID")
            for size, mid in [(s, m) for _, s, m in frames(d, 0)]:
                print(f"lut size={size} mid={mid} ({mid / 65535:.3f} of white)")
            for i in range(d.res.contents.n_output):
                output = d.res.contents.outputs[i]
                if not _connected(d, output, edid_atom):
                    continue
                m = read_ctm(d, output, ctm_atom)
                if m is not None:
                    print(f"ctm output {hex(output)}: {[round(v, 3) for v in m]}")
        return 0
    usage()
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except BrokenPipeError:
        # `lut.py show | head` closes the pipe early; not an error worth a
        # traceback in the caller's OSD/log.
        devnull = os.open(os.devnull, os.O_WRONLY)
        os.dup2(devnull, sys.stdout.fileno())
        sys.exit(0)
    except Exception as exc:  # never leave a half-applied state unexplained
        print(f"lut.py: {exc}", file=sys.stderr)
        sys.exit(1)
