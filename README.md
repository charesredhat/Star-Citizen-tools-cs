# Star Citizen HOTAS tools

Diagnostic scripts and binding profiles for setting up a joystick in Star
Citizen, built while getting a **T.Flight Hotas One** working in Alpha 4.10
(build 1.0.191.51145).

The scripts are device-agnostic — they read whatever joystick is on winmm id 0.

## Why these exist

Star Citizen fails silently. An invalid action name, an invalid input token, or
an axis that does not physically exist all produce the same result: the binding
is discarded without a log line, an error, or any visible difference from a
binding that simply matches the default. Guessing is therefore expensive, and
every one of these scripts exists to replace a guess with a measurement.

## Scripts

Run from PowerShell. **Close Star Citizen first** — it acquires the joystick
exclusively, and the legacy API then reports every axis as dead-centre, which
looks exactly like broken hardware.

| Script | Purpose |
|---|---|
| `scripts/joycaps.ps1` | Enumerate joysticks: axis count, button count, capability flags, ranges |
| `scripts/find-axes.ps1` | 30-second free capture; reports which axes actually travel and which are phantom |
| `scripts/map-axes.ps1` | Guided, one control at a time. Identifies each axis *and* throttle polarity |
| `scripts/passive.ps1` | Quick resting-position read; also the fastest way to confirm the game is holding the device |

`map-axes.ps1` is the one to reach for. Example:

```
powershell -ExecutionPolicy Bypass -File scripts\map-axes.ps1
```

Sample output from a real run is in `samples/`.

## Finding an action's real internal name

The single most useful technique here, and the one that solved a problem six
rounds of educated guessing did not.

Star Citizen's keybinding UI shows **labels**; profile XML needs **internal
action names**, and the two often have nothing to do with each other. To get the
real name for any row:

1. In game: Options → Keybindings, find the row you want
2. Double-click it and bind it to an unused key (Numpad 7, say)
3. Exit the game **normally** so it flushes settings
4. Read `actionmaps.xml` — the game has written the binding in its own vocabulary

```
%PROGRAMFILES%\Roberts Space Industries\StarCitizen\LIVE\user\client\0\Profiles\default\actionmaps.xml
```

Two names found this way, neither guessable:

| UI label | Internal name | Actionmap |
|---|---|---|
| Throttle - Increase | `v_strafe_forward` | `spaceship_movement` |
| Change Vehicle Camera View | `v_view_cycle_fwd` | `spaceship_view` |

## Findings worth keeping

**The throttle is not called "throttle."** In 4.10's Master Modes the throttle
rows belong to the *longitudinal strafe* family. `v_throttle_abs` does not exist
in this build and is discarded in silence. The lever axis is
`v_strafe_longitudinal`.

**`actionmaps.xml` only records deviations from the defaults.** A binding absent
from that file may be working perfectly (it matches the default) or may have
been rejected outright. The file cannot distinguish the two, so never read
absence as proof of either.

**One input per action, per device.** An action lives on exactly one button. Two
*different* actions sharing one input makes the game drop **both** —
`v_attack1` + `v_attack2` on one button yields no fire at all, so "fire all
weapons" cannot be built by stacking. The rule is per device, though, so one
action can hold a keyboard key and a joystick button simultaneously.

**`invert="1"` is not valid inside `deviceoptions`.** Only `deadzone` survives
there. Invert a throttle by binding the `_invert` companion action to a button
instead.

**Devices lie about their axes.** The T.Flight Hotas One advertises six; only
four are real. `slider1` never moves and `slider2` latches to maximum. A binding
on either is inert and indistinguishable from a typo.

## Profiles

`profiles/` holds a copy of the working setup. The live files are at:

```
...\StarCitizen\LIVE\user\client\0\controls\mappings\
```

Copies here are snapshots, not symlinks — re-copy after editing the live files.

Load a profile in game via Options → Keybindings → Control Profiles, or from the
console (`~`):

```
pp_rebindkeys layout_CS-T-Flight-Hotas-One_exported
```

That is a **game console** command, not a shell command. The argument is the
filename without `.xml`, and the file must sit in the Mappings folder above.

For the profile to appear in the Control Profiles list at all, the filename has
to follow the game's own export convention: `layout_<name>_exported.xml`.

## Reference card

`reference-card/hotas-card.html` is the source for a printable one-page binding
card — axes, buttons and hat, split by stick and throttle.
