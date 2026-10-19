# Audio Output Switch

A small KDE Plasma 6 panel widget with one job: toggle between two audio output
ports of the same sound card — typically **Line Out** (your speakers) and
**Headphones** — with a single click.

The icon always shows the output that is currently active, and the tooltip tells
you what the next click will switch to.

```
🎧 Headphones   →   click   →   🔊 Line Out
```

## Why

On a desktop with both the rear line-out and the front headphone jack plugged in,
Plasma's volume applet makes you go through *system tray → audio device → ⋮ →
port*. That's four interactions for something you do several times a day. This
widget is one click, and it never opens a popup.

## How it works

It uses Plasma's own audio models (`org.kde.plasma.private.volume`, the same
module `plasma-pa` uses) and writes the sink's `activePortIndex`. Switching the
port on the sink — rather than changing the default sink — means running
applications keep playing; no stream is moved, nothing is restarted.

No shell commands, no helper daemon, no compiled code: it is pure QML.

## Requirements

- KDE Plasma 6 (developed against 6.7)
- PipeWire with `pipewire-pulse` (or PulseAudio)
- `plasma-pa`, which provides the audio QML module

## Install

```sh
./install.sh
```

or manually:

```sh
kpackagetool6 --type Plasma/Applet --install .
```

Then right-click your panel → **Add or Manage Widgets…** → search for
**Audio Output Switch** → drag it onto the panel.

## Uninstall

1. Right-click the widget on the panel → **Remove**.
2. Run `./uninstall.sh` (or `kpackagetool6 --type Plasma/Applet --remove org.paulo.audioswitch`).
3. Optionally delete this checkout.

Removing the files before removing the widget from the panel leaves a
"missing widget" placeholder until you remove it, so do it in that order.

## Configuration

Right-click the widget → **Configure Audio Output Switch…**.

| Option | Meaning |
| --- | --- |
| **Audio output device** | Which sink to switch. `Automatic` picks the default sink if it has at least two usable ports, otherwise the first sink that has both a headphone and a line/speaker port. |
| **Switch between / and** | The two ports to toggle. `Automatic` prefers one headphone port and one line/speaker port. |

If the two configured ports are not available (device unplugged), the widget
falls back to auto-detection so the button never becomes a no-op.

## Notes and limitations

- Port definitions come from the ALSA card profile. Cards that expose their
  outputs as separate *sinks* (e.g. some USB DACs) are `default sink` switches,
  not port switches, and are out of scope.
- `activePortIndex` is part of Plasma's private audio QML API. It is what the
  stock volume applet itself uses, but a future Plasma release could rename it.
  If that ever happens the widget fails visibly (icon disappears / no switch)
  and can simply be removed.
- If your card re-selects a port when you plug or unplug the headset, that is
  WirePlumber's jack detection, not this widget. It will update its icon
  accordingly.

## License

MIT — see [LICENSE](LICENSE).
