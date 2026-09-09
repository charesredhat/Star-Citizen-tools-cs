# CS T Flight Hotas One — Star Citizen binding reference

Profile file: `layout_CS-T-Flight-Hotas-One_exported.xml`
Shows in UI as: **CS T Flight Hotas One**
Console load:  `pp_rebindkeys layout_CS-T-Flight-Hotas-One_exported`

## Axes  (measured from the device, not assumed)

| Physical control        | winmm | SC input      | Action                  |
|-------------------------|-------|---------------|-------------------------|
| Stick left / right      | X     | `js1_x`       | `v_roll`                |
| Stick forward / back    | Y     | `js1_y`       | `v_pitch`               |
| Throttle lever          | Z     | `js1_z`       | `v_strafe_longitudinal` |
| Rudder rocker           | R     | `js1_rotz`    | `v_yaw`                 |

Dead axes on this device — do not bind anything to these:
`js1_slider1` (never moves) and `js1_slider2` (latches to max and stays).

Deadzones: 0.05 on x/y, 0.08 on the rudder rocker.

## The throttle is not called "throttle"

In SC 4.10 (Master Modes) the throttle actions live in the **longitudinal
strafe** family. `v_throttle_abs` does not exist in this build and is silently
discarded if you bind it.

| UI label                        | Real action name              |
|---------------------------------|-------------------------------|
| Throttle - Increase             | `v_strafe_forward`            |
| Throttle - Decrease             | `v_strafe_back`               |
| Throttle - Forward / Back (axis)| `v_strafe_longitudinal`       |
| Throttle - Forward / Back Invert| `v_strafe_longitudinal_invert`|

How this was found: bind the UI row to an unused key, exit the game, then read
which action name the game wrote into `actionmaps.xml`. That works for any row
whose internal name you need — the game writes in its own vocabulary.

## Throttle direction

Measured polarity: lever **forward = raw 0**, lever **back = raw 65535** — i.e.
backwards. `invert="1"` inside `deviceoptions` is NOT valid; the game discards
it silently.

Instead `v_strafe_longitudinal_invert` is bound to button 15. Press it once to
flip the lever direction if forward is decreasing your speed.

## Hat switch — strafe (`js1_hat1`)

| Direction | Action           |
|-----------|------------------|
| up        | `v_strafe_up`    |
| down      | `v_strafe_down`  |
| left      | `v_strafe_left`  |
| right     | `v_strafe_right` |

These are the digital strafe actions — full deflection while held — which is what
a hat can drive. The analog equivalents (`v_strafe_vertical`, `v_strafe_lateral`)
need a real axis and are left unbound.

Target cycling now lives only on button 3 (`v_target_cycle_hostile_fwd`).

## Buttons

| # | Action                          | Internal name                          |
|---|---------------------------------|----------------------------------------|
| 1 | Fire selected weapon group      | `v_attack1`                            |
| 2 | Launch missile                  | `v_weapon_launch_missile`              |
| 3 | Cycle hostile target            | `v_target_cycle_hostile_fwd`           |
| 4 | Pin target 1                    | `v_target_toggle_pin_index_1`          |
| 5 | Launch countermeasures (decoy)  | `v_weapon_countermeasure_decoy_launch` |
| 6 | Boost                           | `v_afterburner`                        |
| 7 | Space brake                     | `v_brake`                              |
| 8 | Change vehicle camera view      | `v_view_cycle_fwd` (`spaceship_view`)  |
| 9 | Radar ping                      | `v_invoke_ping`                        |
|10 | Scan mode                       | `v_toggle_scan_mode`                   |
|11 | Quantum mode                    | `v_toggle_quantum_mode`                |
|12 | Engage quantum drive            | `v_toggle_qdrive_engagement`           |
|13 | Landing gear                    | `v_toggle_landing_system`              |
|14 | Launch noise                    | `v_weapon_countermeasure_noise_launch` |
|15 | Flip throttle direction         | `v_strafe_longitudinal_invert`         |

Flight ready is no longer on the stick — button 8 was reassigned to the camera
view and SC drops *both* actions if two share an input.

Camera view is bound twice on purpose: `kb1_f4` and `js1_button8`; boost the
same way with `kb1_lshift` and `js1_button6`. That is allowed because they are
different *devices* — the one-input rule is per device.

The UI row labelled **Boost** is `v_afterburner` internally. The label changed
in Master Modes; the action name did not.

SC allows only one input per action per device, so an action lives on exactly
one button — moving decoy launch onto 5 is why gear moved to 13. It also refuses
two *different* actions on the same input: binding `v_attack1` and `v_attack2`
both to button 1 caused the game to drop both, so "fire all weapons" cannot be
built that way.

## Verification status

Everything in this sheet has now been confirmed on the hardware or in flight —
none of it is assumed any more.

| Item                              | How it was confirmed                    |
|-----------------------------------|-----------------------------------------|
| `js1_x` `js1_y` `js1_z` `js1_rotz`| winmm capture, one control at a time    |
| `js1_slider1` / `js1_slider2` dead| zero travel across full capture         |
| `v_strafe_longitudinal` = throttle| flown in game                           |
| Throttle polarity + button 15     | flip tested in game, works              |
| Buttons and hat                   | flown in game                           |

If you ever need an action's real internal name, use the trick that solved the
throttle: bind that row in the keybindings UI to an unused key, exit the game
normally, then look at `actionmaps.xml` — the game writes the name itself.

## Note on actionmaps.xml

`actionmaps.xml` only records bindings that *differ* from the SC defaults. After
loading this profile, entries like `v_pitch` and `v_attack1` will be absent —
that means they match the default and are working, not that they failed.
