#!/usr/bin/env bash
# Install (or upgrade) the Audio Output Switch plasmoid for the current user.
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
id="org.paulo.audioswitch"

if kpackagetool6 --type Plasma/Applet --show "$id" >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --upgrade "$here"
else
    kpackagetool6 --type Plasma/Applet --install "$here"
fi

echo
echo "Installed. Add it via: right-click panel -> Add or Manage Widgets -> Audio Output Switch"
