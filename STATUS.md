# Project status

Last updated: 2026-10-19

## TL;DR

Version 1.1.0 works as a **system-tray item** (and still as a panel or desktop
widget). Next step is publishing: make the repository public and upload to the
KDE Store.

## The tray bug and its fix

In 1.0.0 the widget occupied an empty slot in the tray. A diagnostic build showed
`expanded = true` and `compactRepresentationItem = null`: with no
`fullRepresentation`, Plasma treats the applet itself as the full representation,
keeps it "expanded", and never creates the icon. `preferredRepresentation` does
not change that. Adding a `fullRepresentation` (now the middle-click port list)
fixed it; `switchWidth`/`switchHeight` keep it an icon in panels.

## Verified on the real desktop (2026-10-19)

Fedora 44, KDE Plasma 6.7.5, PipeWire 1.6.9, sink
`alsa_output.pci-0000_31_00.4.analog-stereo` with ports
`analog-output-lineout` and `analog-output-headphones`. Checked with
screenshots and `pactl`, clicks driven by `ydotool`:

- Icon renders in the tray, just left of the volume icon, and matches the
  active port (`audio-headphones` / `audio-speakers`).
- Tooltip: "Audio output: Headphones / Click to switch to Line Out /
  Middle-click for all outputs".
- Left-click switches the port; icon and tooltip follow.
- Middle-click opens and closes the port list without changing the port;
  the list shows the card name and its usable ports.
- No QML warnings from the widget in the plasmashell log.
- Settings page (loaded offscreen against the live PipeWire state) lists the
  analog card and its two ports; a configured sink with fewer than two usable
  ports (the HDMI sink) falls back to automatic selection.

## Not yet verified

- Picking a port from the popup list (one attempt switched to Headphones, but
  the user also switched by hand at that moment, so it is inconclusive).
- The global shortcut (`Plasmoid.activated` → switch).
- Moving to the hidden tray area when no switchable output exists.
- The settings dialog opened from inside Plasma (only tested offscreen).
- Fresh install on a system where the tray has never seen the widget (it
  should be added automatically because of `X-Plasma-NotificationArea` and
  `EnabledByDefault`).

## Panel change on 2026-10-19 (for the record)

While working on the tray variant in an earlier session, a scripted `addWidget`
was used. Around the same time plasmashell logged `ListModel: remove: indices
[-1 - 0] out of range` and the panel lost applets 63–66 (including a GPU system
monitor). It is possible the scripted add tripped a panel bug. There is no
backup of the removed applets' configuration. No panel scripting was used since.

## How it is tested

No Plasma test harness exists. Changes are installed with `./install.sh`,
plasmashell is restarted (`systemctl --user restart plasma-plasmashell.service`),
and the result is checked with a screenshot (`spectacle -b -n -f -o file.png`)
and `pactl list sinks`. QML errors from plasmashell go to the user journal.
For offscreen checks with system PySide6, set `QT_FORCE_STDERR_LOGGING=1`
(otherwise QML messages go to the journal) and provide an `i18n` context
function, since Plasma normally injects it.
