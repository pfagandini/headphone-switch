# Project status

Last updated: 2026-10-19

## TL;DR

The widget works as a **panel applet**. The attempt to also make it a
**system-tray item** is unfinished: in the tray the icon does not render.
`main` is currently at a work-in-progress commit for that tray variant.

| Commit | State |
| --- | --- |
| `5cc96c6` | First working version — panel applet, toggling verified |
| `50b2bc1` | Guard for missing configuration (no behaviour change) |
| `09618c8` | WIP: systray metadata + compact-representation rewrite — **tray icon not visible** |

## Verified working

Tested on Fedora 44, KDE Plasma 6.7.5, PipeWire 1.6.9, sink
`alsa_output.pci-0000_31_00.4.analog-stereo` with ports
`analog-output-lineout` and `analog-output-headphones`.

- Reads the sink's `ports` and writable `activePortIndex` through
  `org.kde.plasma.private.volume` (the same module `plasma-pa` uses).
- Clicking toggles the port. Six consecutive toggles were run through the QML
  API and every result confirmed against `pactl`; the switch holds.
- Icon reflects the active port (`audio-speakers` / `audio-headphones`).
- Auto-detection picks the default sink with at least two usable ports,
  preferring a headphones + line/speaker pair.
- Configuration page lists sinks and their ports and can override both.
- `install.sh` / `uninstall.sh` round-trip cleanly through `kpackagetool6`.

## Not working yet

- **System tray icon.** `X-Plasma-NotificationArea` metadata was added and the
  applet does get registered as a tray item (seen in
  `plasma-org.kde.plasma.desktop-appletsrc` as
  `[Containments][29][Applets][34][Applets][N]`), but no icon is drawn in the
  tray. No QML errors are logged, so it is most likely a sizing/compact
  representation problem inside the systray, not a load failure.
- The same compact representation was never confirmed visually in a normal
  panel slot either: when added as a standalone applet it was placed last,
  overlapping the "Show Desktop" applet at the right edge of a full panel, so
  invisibility there is inconclusive.

## Fallback if the tray route keeps failing

Keep it as a normal panel applet placed immediately to the left of the system
tray. Visually identical to a tray icon, always visible, and already known to
render and toggle correctly. This requires no code change beyond placing it.

## Panel change on 2026-10-19 (for the record)

While working on the tray variant, a scripted `addWidget` was used. Around the
same time plasmashell logged `ListModel: remove: indices [-1 - 0] out of range`
and the panel lost applets 63–66 (including a GPU system monitor). It is
possible the scripted add tripped a panel bug. No widget other than
`org.paulo.audioswitch` was created by the assistant. There is no backup of the
removed applets' configuration.

Current panel order, after removing the test instances:

```
AppletOrder=30;31;32;33;34;49;50
```

## Next steps

1. Diagnose the systray rendering (compact representation sizing). Take a
   screenshot before/after, not just headless tests.
2. If it cannot be fixed quickly, place the applet next to the tray and cut the
   systray metadata.
3. Only then switch the repository to public and publish to the KDE Store.

## How it was tested

No Plasma test harness is installed. Verification used a small PySide6/QQml
script that loads `contents/ui/main.qml` offscreen, calls `toggle()`, and
compares the active port with `pactl list sinks`. This exercises the real QML
and the real PipeWire daemon, but not panel or tray layout — which is exactly
where the remaining bug lives.
