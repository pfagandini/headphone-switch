/*
    SPDX-FileCopyrightText: 2026 Paulo Fagandini

    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: page

    // KConfigXT entries from contents/config/main.xml.
    property string cfg_sinkName
    property string cfg_portA
    property string cfg_portB
    property string cfg_sinkNameDefault
    property string cfg_portADefault
    property string cfg_portBDefault

    // Same choice the widget makes, so "Automatic" lists the ports of the
    // sink the widget will actually switch.
    property OutputSelection selection: OutputSelection {
        sinkName: page.cfg_sinkName
        portA: page.cfg_portA
        portB: page.cfg_portB
        onUpdated: page.rebuild()
    }

    property var sinkOptions: []
    property var portOptions: []

    function indexOf(options, value) {
        return Math.max(0, options.findIndex(option => option.value === value));
    }

    function rebuild() {
        sinkOptions = [{ text: i18n("Automatic"), value: "" }].concat(
            selection.switchableSinks().map(sink => ({ text: sink.description, value: sink.name })));
        portOptions = [{ text: i18n("Automatic"), value: "" }].concat(
            selection.sinkPorts.map(port => ({ text: port.description, value: port.name })));

        sinkCombo.currentIndex = indexOf(sinkOptions, cfg_sinkName);
        portACombo.currentIndex = indexOf(portOptions, cfg_portA);
        portBCombo.currentIndex = indexOf(portOptions, cfg_portB);
    }

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: sinkCombo
            Kirigami.FormData.label: i18n("Audio output device:")
            model: page.sinkOptions
            textRole: "text"
            valueRole: "value"
            onActivated: {
                if (currentValue !== page.cfg_sinkName) {
                    page.cfg_portA = "";
                    page.cfg_portB = "";
                    page.cfg_sinkName = currentValue;
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: portACombo
            Kirigami.FormData.label: i18n("Switch between:")
            model: page.portOptions
            textRole: "text"
            valueRole: "value"
            onActivated: page.cfg_portA = currentValue
        }

        QQC2.ComboBox {
            id: portBCombo
            Kirigami.FormData.label: i18n("and:")
            model: page.portOptions
            textRole: "text"
            valueRole: "value"
            onActivated: page.cfg_portB = currentValue
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("“Automatic” picks the output with both a headphone and a line/speaker port, and switches between those two. Ports that are unplugged are not listed.")
        }
    }
}
