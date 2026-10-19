/*
    SPDX-FileCopyrightText: 2026 Paulo Fagandini

    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.components as PC3
import org.kde.plasma.plasmoid
import org.kde.plasma.private.volume

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    // The sink we are switching, its two candidate ports, and the active one.
    property QtObject targetSink: null
    property var switchPorts: []
    property int activeIndex: -1

    readonly property var activePort: (switchPorts.length > 0 && activeIndex >= 0)
        ? switchPorts[activeIndex] : null
    readonly property var otherPort: (switchPorts.length > 1 && activeIndex >= 0)
        ? switchPorts[(activeIndex + 1) % switchPorts.length] : null

    readonly property string currentIcon: portIcon(activePort)
    readonly property string currentName: activePort ? activePort.description : ""
    readonly property string otherName: otherPort ? otherPort.description : ""

    readonly property string unavailableIcon: "audio-card"

    SinkModel {
        id: sinkModel
    }

    function role(name) {
        return sinkModel.KItemModels.KRoleNames.role(name);
    }

    readonly property var config: Plasmoid.configuration || null

    function configValue(name, fallback) {
        if (!config) {
            return fallback;
        }
        const value = config[name];
        return (value === undefined || value === null) ? fallback : value;
    }

    function portIcon(port) {
        if (!port) {
            return unavailableIcon;
        }
        switch (port.type) {
        case Port.Headphones:
            return "audio-headphones";
        case Port.Line:
        case Port.Speaker:
            return "audio-speakers";
        case Port.HDMI:
            return "video-display";
        default:
            return "audio-card";
        }
    }

    function availablePorts(sink) {
        const out = [];
        if (!sink || !sink.ports) {
            return out;
        }
        for (let i = 0; i < sink.ports.length; ++i) {
            const port = sink.ports[i];
            if (port.availability === Port.Unavailable) {
                continue;
            }
            out.push({
                index: i,
                name: port.name,
                description: port.description,
                type: port.type
            });
        }
        return out;
    }

    // Pick the sink we should be switching. An explicit configuration wins;
    // otherwise prefer the default sink, but only if it has at least two
    // usable ports, then any sink with both a headphone and a line port.
    function pickSink() {
        const configured = configValue("sinkName", "");
        if (configured) {
            const found = findSink(configured);
            if (found) {
                return found;
            }
        }

        const rp = role("PulseObject");
        let best = null;
        let bestScore = -1;

        for (let i = 0; i < sinkModel.count; ++i) {
            const sink = sinkModel.data(sinkModel.index(i, 0), rp);
            if (!sink || !sink.name) {
                continue;
            }

            const ports = availablePorts(sink);
            if (ports.length < 2) {
                continue;
            }

            const hasHeadphones = ports.some(p => p.type === Port.Headphones);
            const hasLine = ports.some(p => p.type === Port.Line || p.type === Port.Speaker);

            let score = 0;
            if (hasHeadphones) {
                score += 2;
            }
            if (hasLine) {
                score += 2;
            }
            if (sink.default) {
                score += 1;
            }

            if (score > bestScore) {
                best = sink;
                bestScore = score;
            }
        }

        return best;
    }

    function findSink(name) {
        const rp = role("PulseObject");
        for (let i = 0; i < sinkModel.count; ++i) {
            const sink = sinkModel.data(sinkModel.index(i, 0), rp);
            if (sink && sink.name === name) {
                return sink;
            }
        }
        return null;
    }

    // Exactly two ports to toggle between. Configured ports win; otherwise
    // headphones first, then line/speaker.
    function pickPorts(sink) {
        const ports = availablePorts(sink);
        if (ports.length < 2) {
            return ports;
        }

        const configuredA = configValue("portA", "");
        const configuredB = configValue("portB", "");
        const a = ports.find(p => p.name === configuredA);
        const b = ports.find(p => p.name === configuredB);
        if (a && b && a.index !== b.index) {
            return [a, b];
        }

        const headphones = ports.filter(p => p.type === Port.Headphones);
        const line = ports.filter(p => p.type === Port.Line || p.type === Port.Speaker);

        if (headphones.length > 0 && line.length > 0) {
            return [headphones[0], line[0]];
        }
        return ports.slice(0, 2);
    }

    function refresh() {
        const sink = pickSink();

        if (sink !== targetSink) {
            if (targetSink) {
                targetSink.activePortIndexChanged.disconnect(root.refresh);
                targetSink.portsChanged.disconnect(root.refresh);
            }
            targetSink = sink;
            if (targetSink) {
                targetSink.activePortIndexChanged.connect(root.refresh);
                targetSink.portsChanged.connect(root.refresh);
            }
        }

        switchPorts = pickPorts(targetSink);

        // activeIndex indexes switchPorts, not the sink's own port list.
        const sinkActiveIndex = targetSink ? targetSink.activePortIndex : -1;
        activeIndex = switchPorts.findIndex(port => port.index === sinkActiveIndex);

        Plasmoid.toolTipMainText = activePort
            ? i18n("Audio output: %1", activePort.description)
            : i18n("Audio output: unknown");
        Plasmoid.toolTipSubText = otherPort
            ? i18n("Click to switch to %1", otherPort.description)
            : "";
    }

    function toggle() {
        if (!targetSink || switchPorts.length < 2) {
            return;
        }

        // If the current port is not one of the two we switch, go to the first
        // one; otherwise advance to the next.
        const next = activeIndex < 0
            ? switchPorts[0]
            : switchPorts[(activeIndex + 1) % switchPorts.length];
        targetSink.activePortIndex = next.index;

        // The write is asynchronous; refresh again once it has landed.
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer
        interval: 250
        repeat: false
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    Connections {
        target: sinkModel
        function onModelReset() { root.refresh(); }
        function onDataChanged() { root.refresh(); }
        function onRowsInserted() { root.refresh(); }
        function onRowsRemoved() { root.refresh(); }
    }

    Connections {
        target: Plasmoid.configuration
        function onValueChanged() { root.refresh(); }
    }

    compactRepresentation: Item {
        id: compact

        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: implicitWidth

        Kirigami.Icon {
            id: icon
            anchors.fill: parent
            source: root.currentIcon
            active: mouseArea.containsMouse
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggle()
        }

        PC3.ToolTip {
            text: root.activePort
                ? i18n("%1 → click for %2", root.activePort.description, root.otherName)
                : i18n("No switchable audio output found")
        }
    }
}
