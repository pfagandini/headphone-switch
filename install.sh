#!/usr/bin/env bash
# Install (or upgrade) the Audio Output Switch plasmoid for the current user.
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
id="org.paulo.audioswitch"

if kpackagetool6 --type Plasma/Applet --show "$id" >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --upgrade "$here"
    echo
    echo "Upgraded. Plasma runs the old version until it restarts:"
    echo "  systemctl --user restart plasma-plasmashell.service"
else
    kpackagetool6 --type Plasma/Applet --install "$here"
    echo
    echo "Installed. It appears in the system tray; if not, enable it under"
    echo "System Tray Settings -> Entries -> Audio Output Switch."
fi
