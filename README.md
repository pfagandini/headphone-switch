# Audio Output Switch

A small KDE Plasma 6 widget with one job: toggle between two audio output
ports of the same sound card — typically **Line Out** (your speakers) and
**Headphones** — with a single click.

It lives in the **system tray**, next to the volume icon. The icon always shows
the output that is currently active, and the tooltip tells you what the next
click will switch to.

```
🎧 Headphones   →   click   →   🔊 Line Out
```

| Action | Result |
| --- | --- |
| Left-click | Switch to the other output |
| Middle-click | Popup listing every output port of the card; pick any |
| Global shortcut (optional) | Switch to the other output |

## Why

On a desktop with both the rear line-out and the front headphone jack plugged in,
Plasma's volume applet makes you go through *system tray → audio device → ⋮ →
port*. That's four interactions for something you do several times a day. This
widget is one click.

## How it works

It uses Plasma's own audio models (`org.kde.plasma.private.volume`, the same
module `plasma-pa` uses) and writes the sink's `activePortIndex`. Switching the
port on the sink — rather than changing the default sink — means running
applications keep playing; no stream is moved, nothing is restarted.

No shell commands, no helper daemon, no compiled code: it is pure QML.

| File | Role |
| --- | --- |
| `contents/ui/main.qml` | The widget: tray icon, tooltip, click handling, port popup |
| `contents/ui/OutputSelection.qml` | Picks the sink and the two ports; shared with the settings page |
| `contents/ui/configGeneral.qml` | Settings page |
| `contents/config/main.xml` | Stored settings |

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

The widget then shows up in the system tray on its own. If it doesn't, right-click
the tray's arrow → **Configure System Tray…** → **Entries**, and set
**Audio Output Switch** to *Always shown*.

You can also put it on a panel or the desktop as a normal widget: right-click the
panel → **Add or Manage Widgets…** → **Audio Output Switch**.

After upgrading, Plasma keeps running the old code until it restarts:

```sh
systemctl --user restart plasma-plasmashell.service
```

## Uninstall

1. If you added it to a panel, right-click it → **Remove** first.
2. Run `./uninstall.sh` (or `kpackagetool6 --type Plasma/Applet --remove org.paulo.audioswitch`).

## Configuration

Right-click the icon → **Configure Audio Output Switch…**.

| Option | Meaning |
| --- | --- |
| **Audio output device** | Which sink to switch. `Automatic` picks the sink that has both a headphone and a line/speaker port, preferring the default sink on a tie. Only sinks with at least two usable ports are listed. |
| **Switch between / and** | The two ports to toggle. `Automatic` uses one headphone port and one line/speaker port. |

A global shortcut can be set on the **Keyboard Shortcuts** page of the same dialog.

If the configured device or ports are not available (device unplugged), the widget
falls back to automatic selection so the button never becomes a no-op. When there
is nothing to switch at all, it moves into the tray's hidden area.

## Notes and limitations

- Port definitions come from the ALSA card profile. Cards that expose their
  outputs as separate *sinks* (e.g. some USB DACs) are `default sink` switches,
  not port switches, and are out of scope.
- `activePortIndex` is part of Plasma's private audio QML API. It is what the
  stock volume applet itself uses, but a future Plasma release could rename it.
- If your card re-selects a port when you plug or unplug the headset, that is
  WirePlumber's jack detection, not this widget. It will update its icon
  accordingly.
- Plasma only creates the small icon if a widget also has a full
  representation; without one the widget is treated as permanently expanded and
  shows nothing in the tray. That is why the port popup exists.

## License

MIT — see [LICENSE](LICENSE).
