# Backlight & Legibility — Implementation (2026-10)

## Why this exists

The complaint was "screen brightness is very low". Measurement said something
else, and the two facts below shaped the whole design:

1. **The panel was already at 100% duty** — `brightnessctl` reports
   `1515/1515` on `intel_backlight` (BOE NV140FHM-N41, the stock T480 ~250-nit
   FHD panel). No userspace knob can add light above that.
2. **The session boots at 36%** — `systemd-backlight` restores
   `/var/lib/systemd/backlight/pci-0000:00:02.0:backlight:intel_backlight`,
   which held `549` (36%). That, not the panel, is what "very low" really was:
   the old `10%+` keybinding needed seven presses to climb out of it.

Two more things were measured along the way:

- `picom` installs an **identity gamma LUT** when it starts, silently
  discarding any curve applied earlier (observed: a `1.3` boost read back as
  `1.0` right after picom came up). Brightness must be re-applied *after* it.
- `xrandr --brightness` is a flat multiply that saturates almost immediately
  (`1.25` reads back as `1.3`) and clips highlights. It also means `xcalib` is
  not a usable alternative: xcalib writes through XF86VidMode, which the
  modesetting driver does not expose, so it silently no-ops (`xcalib -clear`
  does not even remove an xrandr boost — verified).

## What was built

| File | Role |
|---|---|
| `profiles/desktop/scripts/lut.py` | RandR gamma-LUT + CTM engine (ctypes, no deps). Lifts midtones with `out = in**e`; white stays white. Also saturation via the 3x3 colour matrix. |
| `profiles/desktop/scripts/light.sh` | The single owner of brightness. One 0–130% scale: ≤100% hardware via `brightnessctl`, >100% hardware 100% + curve. Persists state, draws the dunst OSD. |
| `profiles/desktop/scripts/backlight-probe.sh` | Read-only firmware/kernel report (DPST/CABC, ACIP backlight selection, systemd-backlight saved value) plus opt-in `--fix-saved` / `--grub-test` / `--grub-revert`. |
| `profiles/desktop/configs/Xresources` | `Xft.dpi: 110` + subpixel/hinting for Xft clients (dwm, dmenu, rofi). |
| `configs/fontconfig/fonts.conf` | Same rendering choices where GTK3 actually looks (it ignores `Xft.rgba`). |
| `profiles/desktop/configs/dwm-session.sh` | Merges `Xresources` before dwm starts; re-applies saved brightness 1s after picom. |
| `suckless/dwm/config.h` | Brightness keys now call `light.sh up/down` (5% steps) instead of `brightnessctl 10%±`. |
| `configs/theme/scripts/gtk_theme.sh` | Writes `Xft/DPI 112640` (110dpi × 1024) into `~/.xsettingsd` — the only writer of that file, so the key survives every theme toggle. |
| `~/.config/mozilla/firefox/vrwhvdpg.default-esr/user.js` | `layout.css.devPixelsPerPx = 1.15` (machine-local, not in this repo). |

## Fresh install (what `install.sh --profile desktop` now does)

Everything below happens without a manual step, and re-running the installer is
a no-op:

| Stage | Where | Effect |
|---|---|---|
| packages | `profiles/desktop/packages.apt` | `brightnessctl`, `x11-xserver-utils` (xrdb/xrandr), `fontconfig`, `python3` (base), `dunst`, `xsettingsd` — declared explicitly, not relied on transitively |
| link | `scripts/lib/link.sh` | `configs/fontconfig` → `~/.config/fontconfig` (universal loop, no manifest change needed) |
| build | `profiles/desktop/scripts/build_suckless.sh` | dwm compiled with the `light.sh` key bindings |
| configure | `profiles/desktop/scripts/setup_legibility.sh` (new, called from `scripts/debian/configure_system.sh`) | validates deps + `lut.py` imports, writes the Firefox block, `fc-cache -f`, and applies Xft.dpi + brightness if run inside a session |
| session start | `profiles/desktop/configs/dwm-session.sh` | `xrdb -merge Xresources` before dwm; `light.sh restore` 1s after picom; refreshes the Firefox block for profiles created later |
| login | `configs/theme/scripts/gtk_theme.sh` | writes `Xft/DPI 112640` into `~/.xsettingsd` on every theme toggle |
| drift | `scripts/check_parity.sh` | desktop section now checks `Xresources`, `light.sh`, and that every existing Firefox profile carries the block |

A fresh desktop install starts at **120%** (`LIGHT_DEFAULT` in `light.sh`):
percentages above 100 are hardware 100% + curve, which is what makes a new
machine look like a tuned one. It is a default, not a lock — the first key
press writes user state and `LIGHT_DEFAULT` stops mattering.

One boot-cycle caveat: `systemd-backlight` has no saved value on a brand-new
machine, so the *greeter* can boot at the kernel default until the first clean
shutdown records the 100% the session leaves behind. To close that window
immediately, run `sudo backlight-probe.sh --fix-saved` (see below).

### Changing the defaults

| Knob | Default | Where |
|---|---|---|
| fresh-session level | 120 | `LIGHT_DEFAULT` env, or the `DEFAULT_LEVEL` line in `light.sh` |
| upper end of the scale | 130 | `LIGHT_CEILING` env |
| key step | 5 | `LIGHT_STEP` env |
| curve strength | 0.30 | `LIGHT_STRENGTH` env / `curve()` in `lut.py` |
| text/UI size | 110dpi | `Xft.dpi` in `configs/Xresources` **and** `Xft/DPI 112640` in `gtk_theme.sh` (both, or X clients and GTK disagree) |
| Firefox page size | 1.15 | `FIREFOX_LEGIBILITY_SCALE`, or `SCALE` in `firefox_legibility.sh` |

## Decisions

- **Step 5%, ceiling 130%.** 5% because above 100% the curve is steep enough
  that 10% jumps are visible; 130% because that is where the LUT curve still
  behaves (midtones ×1.23, white untouched).
- **Curve, not multiply.** `out = in**0.7` at 130%: midtone 0.5 → 0.615
  (+23%), black stays black, white stays white. Nothing clips. Honest caveat:
  this is *perceived* luminance — shadow separation is traded away, which is
  exactly right for dark-theme UI on a dim panel.
- **No `xcalib`, no `colord`, no extra package.** `xcalib` cannot work under
  modesetting (above), and `colord` would add a daemon for one curve.
- **No `text-scaling-factor`.** `org.gnome.desktop.interface
  text-scaling-factor` is only mapped by gnome-settings-daemon, which this
  session does not run; setting it would be cargo cult and risks double
  scaling if one is ever added. `Xft/DPI` over XSETTINGS is the mechanism
  GTK3/Firefox actually honour — verified live with `dump_xsettings`.
- **DPI 110, not 120.** The panel is 157dpi; clients assumed 96. +15% closes
  most of the gap without breaking dwm's 14pt bar or rofi geometry. 120 is the
  next step if 110 still feels small (`Xft.dpi` + the `Xft/DPI` line).

## Technical gotchas encoded in lut.py (both cost an hour to find)

1. `XRRSetCrtcGamma()` serialises `size*3` shorts **starting at `gamma->red`**
   and never reads the green/blue pointers. Three separate allocations send
   garbage for two channels; the driver then reports an all-black ramp
   (`xrandr` prints `Brightness: 0.0`). All three ramps must be one
   contiguous block.
2. For `format=32` properties, Xlib transfers arrays of **`long`**, not
   `int32` — on LP64 that is 8 bytes per element. Reading/writing CTM as
   int32 mis-aligns every coefficient (the "garbage matrix" symptom).

## Usage

```sh
light.sh get            # saved level
light.sh set 120        # 0..130
light.sh up / down      # 5% steps (also XF86MonBrightnessUp/Down)
light.sh restore        # re-apply after picom restarts / output changes
light.sh vib 15         # +15% saturation via CTM (0..40, 0 = off)
light.sh viboff
light.sh diag           # saved, hardware duty, LUT midpoint, CTM
```

## Verification performed

- LUT: `lum 130` → `xrandr` reads `Gamma: 0.70:0.70:0.70`, `Brightness: 1.0`
  (white preserved), LUT midpoint `0.615`; `lum-reset` returns to `1.0`.
- Scale: state 60% → hardware `909/1515`, identity LUT; 130% → hardware
  `1515/1515`, curve; 125% → curve mid `0.594`.
- CTM: `vib 30` read back exactly
  `[1.236, -0.215, -0.022, -0.064, 1.085, -0.022, -0.064, -0.215, 1.278]`,
  `vib 0` back to identity; disconnected outputs normalised.
- XSETTINGS: `dump_xsettings` shows `Xft/DPI 112640` live; `xrdb -query`
  shows `Xft.dpi: 110`.
- dwm rebuilt from the repo (`make`), so the session's preferred binary has
  the new key bindings.

## Still manual (needs root or a reboot)

The defaults above need nothing; these are the optional hardware checks.

```sh
# 1. Is content-adaptive dimming (DPST/CABC) active? Read-only otherwise.
sudo profiles/desktop/scripts/backlight-probe.sh

# 2. Make the *greeter* bright too (it runs before light.sh).
sudo profiles/desktop/scripts/backlight-probe.sh --fix-saved

# 3. Optional A/B: does the ACPI interface expose a higher ceiling?
sudo profiles/desktop/scripts/backlight-probe.sh --grub-test acpi_backlight=native
#    reboot, compare `brightnessctl -m`, then either keep or:
sudo profiles/desktop/scripts/backlight-probe.sh --grub-revert
```

Expected: (1) reports no DPST knobs (Linux leaves it off), (3) changes
nothing. If both are negative, the panel's ~250 nits is the ceiling and the
only remaining real fix is a swap to the 400-nit Innolux N140HCE-EN1 Rev.C2
(same 30-pin eDP, drop-in on the T480).

## Rollback

```sh
profile=$HOME/dotfiles/profiles/desktop/scripts
$profile/light.sh reset              # backlight 100%, identity LUT/CTM
xrdb -remove                         # drop Xft.dpi for new clients
$profile/firefox_legibility.sh       # no-op; to opt out, delete the marked block
# and `git checkout` the tracked files listed above; delete the new ones
```

Note: `dwm-session.sh` re-adds the Firefox block at every login, so opting out
means removing that call (or the block after each login).

## Known limitations

- A `picom` restart outside the session script re-installs an identity LUT;
  brightness then looks like "saved level without curve" until
  `light.sh restore` (or a key press) runs. Picom is not supervised, so this
  only happens if it is started by hand.
- `light.sh vib` changes saturation only for the *attached* outputs; external
  monitors keep their own colour settings.
- The curve is global, not per-content: in a dark theme it lifts the
  background as well as the text, so very dark UI gains less than documents
  do. Lower `LIGHT_STRENGTH` (default 0.30) in `lut.py` for a gentler curve.
