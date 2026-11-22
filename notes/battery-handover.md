# Battery handover on the T480

This note records why the laptop runs `scripts/battery_guard.sh` instead of
just letting the EC decide when to change packs, and what the guard can and
cannot do.

## The hardware reality

The T480 has two packs:

| pack | role | model in this machine |
|---|---|---|
| BAT0 | internal | LGC 01AV420 |
| BAT1 | removable / Power Bridge | SMP 01AV452 |

The embedded controller (EC), not Linux, chooses which pack supplies the
machine. There is no sysfs/ACPI "select active battery" attribute. TLP's FAQ
lists ThinkPad battery balancing as intentionally unsupported because the
Lenovo firmware offers no way to do it, manually or automatically
(<https://linrunner.de/tlp/faq/misc.html>; see also
<https://github.com/linrunner/TLP/issues/576> and
<https://github.com/linrunner/TLP/issues/338>).

On this generation the Power Bridge normally drains the external pack first
and only reaches the internal one when the external pack is nearly flat. A
worn pack's fuel gauge can still report 10–20% while its cells are already at
the design minimum voltage; the machine then loses power before the EC's
handover. That is the failure this guard exists to prevent.

Observed on this machine (2026-11-22, BAT1 SMP 01AV452, 1156 cycles): the EC
kept BAT1 discharging past 10%, 9%, 8%, 7% and 6%, then handed over to BAT0 at
5% (BAT1 voltage had fallen to ~9.5 V under a ~11 W load; it rebounded to
~10.8 V once the load was removed). The guard's 10% point is deliberately
earlier than the firmware's cutoff, so it either moves the load while the peer
is healthy or hibernates before that last 5% becomes a hard power loss.

## The only userspace knob: charge_behaviour

Since Linux 5.17, `thinkpad_acpi` exposes per-battery
`/sys/class/power_supply/BAT*/charge_behaviour`:

```
auto            charge normally, respect thresholds
inhibit-charge  do not charge while AC is attached
force-discharge force discharge while AC is attached
```

`force-discharge` is the ACPI `BDSS` method. It is documented as a
calibration/AC-attached mode, and its effect on battery power is
firmware-dependent:

- Some ThinkPads switch the load to the forced pack.
- Some report success but keep draining the original pack; on other models the
  write itself fails with `EIO` while AC is unplugged.
- On some models it drains the forced pack in parallel rather than selecting
  it.

So the guard treats it as a request, not a command: write, wait 6 seconds,
then check that the old source really stopped discharging. If it did not, the
peer is put back to `auto` and the guard falls through to the safe action.

References:

- kernel ABI: `Documentation/ABI/testing/sysfs-class-power`
- `thinkpad_acpi` battery extension: `drivers/platform/x86/thinkpad_acpi.c`
- tpacpi-bat history and the per-machine differences:
  <https://github.com/teleshoes/tpacpi-bat/issues/64>,
  <https://github.com/teleshoes/tpacpi-bat/issues/95>
- force-discharge behaviour reported across models:
  <https://github.com/maniacx/Battery-Health-Charging/issues/74>

## What the guard does

`profiles/desktop/systemd/system/battery-guard.service` runs
`/usr/local/lib/battery-guard/battery_guard.sh` every 30 seconds as root
(hibernation and sysfs writes need root). The unit lives in the `desktop`
profile, so base-only servers never install it.

At each run:

1. **On AC**: restore any pack this guard forced back to `auto`, clear state,
   exit. The barrel adapter (`AC/online`) and USB-C PD
   (`ucsi-source-psy-*/online`) both count as AC. (`FORCED_FILE` is written
   *before* the force-discharge write, so a crash between the two still leaves
   enough information for the next AC run to clean up.)
2. **Find the real source**: the lowest-capacity pack that reports
   `Discharging`. If no pack reports it (flaky EC), fall back to the lowest
   present pack when AC is offline. Never use an aggregate: `BAT0:99%` +
   `BAT1:10%` averages to 54% and hides the pack about to die.
3. **At 10%** (`BATTERY_GUARD_SWITCH_AT`): if the other pack is at 15% or more
   (`BATTERY_GUARD_PEER_MIN`), request a handover with `force-discharge`.
   Success means the old source is no longer `Discharging`, or it is drawing
   ≤0.5 W while the peer is drawing more. On success the peer stays forced
   until AC (resetting it immediately could make the EC pick the low pack
   again).
4. **If no handover happened**: hibernate at 10% (`BATTERY_GUARD_FLOOR`).
   That is safer than letting the EC's cutoff kill the session. The next
   power-on makes the EC re-evaluate both packs, which is the only handover
   trigger the firmware exposes.
5. `STATE_FILE` (`/var/lib/battery-guard/last`) remembers the level the guard
   hibernated at. After resuming on the same pack it waits until the pack
   drops `BATTERY_GUARD_REARM` more points (default 1) before hibernating
   again, so resume does not loop forever. It is cleared on AC and after a
   successful live handover.

## Configuration

Edit the unit, not the script:

```ini
Environment=BATTERY_GUARD_SWITCH_AT=10
Environment=BATTERY_GUARD_PEER_MIN=15
Environment=BATTERY_GUARD_FLOOR=10
Environment=BATTERY_GUARD_REARM=1
Environment=BATTERY_GUARD_HANDOVER=force   # or off for hibernate-only
```

Useful overrides for a one-off run:

```sh
# decision table only
sh scripts/battery_guard.sh --selftest

# read the real packs and describe what would happen; no writes, no hibernate
BATTERY_GUARD_DRY_RUN=1 sh scripts/battery_guard.sh

# force a capacity for the live-read path
BATTERY_GUARD_DRY_RUN=1 BATTERY_GUARD_TEST_CAPACITY=10 sh scripts/battery_guard.sh
```

The dry run is safe as a normal user when `BATTERY_GUARD_STATE_DIR` points at
a writable temp dir (it does not write sysfs or call hibernate).

## Deployment / repair

The full installer installs it on the desktop profile:

```sh
cd ~/dotfiles && ./install.sh
```

To repair only the root-owned script/units on an existing machine:

```sh
cd ~/dotfiles && scripts/install_battery_guard.sh
```

This is a copy on `/`, not a symlink into `/home`: `/home` is a separate
mount, so systemd cannot resolve a unit symlinked into it when it builds the
unit table at boot. A systemd unit that points into `/home` is silently
skipped, which is how the old guard missed the cutoff.

Check parity with:

```sh
./install.sh --check
```

or look at the journal after a low-battery event:

```sh
journalctl -t battery-guard -b --no-pager
```
