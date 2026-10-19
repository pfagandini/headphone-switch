/*
    SPDX-FileCopyrightText: 2026 Paulo Fagandini

    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property QtObject targetSink: selection.sink
    readonly property var switchPorts: selection.ports

    // Index into switchPorts (not the sink's own port list); -1 when the sink
    // is on some third port.
    readonly property int activeIndex: {
        const sinkActive = targetSink ? targetSink.activePortIndex : -1;
        return switchPorts.findIndex(port => port.index === sinkActive);
    }
    readonly property bool canSwitch: targetSink !== null && switchPorts.length >= 2

    readonly property var nextPort: canSwitch ? switchPorts[(activeIndex + 1) % switchPorts.length] : null

    // The port the sink is actually on, even if it is not one of the two.
    readonly property QtObject currentPort: (targetSink && targetSink.ports)
        ? targetSink.ports[targetSink.activePortIndex] ?? null
        : null

    function portIcon(port) {
        if (!port) {
            return "audio-card";
        }
        if (selection.isHeadphones(port)) {
            return "audio-headphones";
        }
        if (selection.isLine(port)) {
            return "audio-speakers";
        }
        return "audio-card";
    }

    function toggle() {
        if (nextPort) {
            targetSink.activePortIndex = nextPort.index;
        }
    }

    // Large enough that the widget is always an icon in a panel or the tray;
    // the full representation only shows in the popup or on the desktop.
    switchWidth: Kirigami.Units.gridUnit * 10
    switchHeight: Kirigami.Units.gridUnit * 8

    // A global shortcut (or Enter on the focused tray icon) switches output
    // instead of opening the popup.
    activationTogglesExpanded: false

    Plasmoid.icon: portIcon(currentPort)
    Plasmoid.status: canSwitch ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

    toolTipMainText: currentPort
        ? i18n("Audio output: %1", currentPort.description)
        : i18n("No switchable audio output")
    toolTipSubText: canSwitch
        ? i18n("Click to switch to %1\nMiddle-click for all outputs", nextPort.description)
        : ""

    OutputSelection {
        id: selection
        sinkName: Plasmoid.configuration.sinkName
        portA: Plasmoid.configuration.portA
        portB: Plasmoid.configuration.portB
    }

    Connections {
        target: Plasmoid
        function onActivated() { root.toggle(); }
    }

    compactRepresentation: MouseArea {
        id: compact

        property bool wasExpanded: false

        // Same minimum sizes as Plasma's default compact representation.
        Layout.minimumWidth: height
        Layout.minimumHeight: width

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        // The system tray forwards presses by calling this handler directly,
        // so it must exist.
        onPressed: mouse => {
            wasExpanded = root.expanded;
        }
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                root.expanded = !wasExpanded;
            } else {
                root.toggle();
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: compact.containsMouse
        }
    }

    // Plasma needs a full representation: without one it treats the applet
    // itself as expanded and never creates the icon. Here it lists every
    // usable port of the sink so any of them can be picked directly.
    fullRepresentation: PlasmaExtras.Representation {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
        Layout.preferredHeight: implicitHeight

        ColumnLayout {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Kirigami.Units.smallSpacing
            }
            spacing: Kirigami.Units.smallSpacing

            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 4
                elide: Text.ElideRight
                text: root.targetSink ? root.targetSink.description : i18n("No switchable audio output")
            }

            Repeater {
                model: selection.sinkPorts

                delegate: PC3.RadioButton {
                    required property var modelData

                    Layout.fillWidth: true
                    icon.name: root.portIcon(modelData)
                    text: modelData.description
                    checked: root.targetSink !== null && root.targetSink.activePortIndex === modelData.index
                    onToggled: root.targetSink.activePortIndex = modelData.index
                }
            }
        }
    }
}
