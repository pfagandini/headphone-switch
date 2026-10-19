#!/usr/bin/env bash
# Remove the Audio Output Switch plasmoid for the current user.
set -euo pipefail

id="org.paulo.audioswitch"

if kpackagetool6 --type Plasma/Applet --show "$id" >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --remove "$id"
    echo "Removed $id."
else
    echo "$id is not installed." >&2
fi
