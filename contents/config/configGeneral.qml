/*
    SPDX-FileCopyrightText: 2026 Paulo Fagandini

    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.private.volume

Kirigami.ScrollablePage {
    id: page

    // Mirrors the KConfigXT entries in contents/config/main.xml.
    QtObject {
        id: state
        property string sinkName: ""
        property string portA: ""
        property string portB: ""
    }

    property alias cfg_sinkName: state.sinkName
    property alias cfg_portA: state.portA
    property alias cfg_portB: state.portB

    property var sinks: sinkList
    property var ports: portList

    SinkModel { id: sinkModel }
    ListModel { id: sinkList }
    ListModel { id: portList }

    function role(name) {
        return sinkModel.KItemModels.KRoleNames.role(name);
    }

    function usablePorts(sink) {
        const out = [];
        if (!sink || !sink.ports) {
            return out;
        }
        for (let i = 0; i < sink.ports.length; ++i) {
            const port = sink.ports[i];
            if (port.availability === Port.Unavailable) {
                continue;
            }
            out.push({ name: port.name, description: port.description, type: port.type });
        }
        return out;
    }

    function allSinks() {
        const out = [];
        const rp = role("PulseObject");
        for (let i = 0; i < sinkModel.count; ++i) {
            const sink = sinkModel.data(sinkModel.index(i, 0), rp);
            if (sink && sink.name) {
                out.push(sink);
            }
        }
        return out;
    }

    function findSink(name) {
        if (!name) {
            return null;
        }
        return allSinks().find(sink => sink.name === name) || null;
    }

    function defaultSink() {
        const sinks = allSinks();
        const withPorts = sinks.filter(sink => usablePorts(sink).length >= 2);
        return withPorts.find(sink => sink.default) || withPorts[0] || sinks[0] || null;
    }

    function rebuildSinks() {
        sinkList.clear();
        sinkList.append({ text: i18n("Automatic (default output)"), value: "" });
        for (const sink of allSinks()) {
            if (usablePorts(sink).length < 2) {
                continue;
            }
            sinkList.append({
                text: sink.description + " — " + sink.name,
                value: sink.name
            });
        }
    }

    function rebuildPorts() {
        portList.clear();
        portList.append({ text: i18n("Automatic"), value: "" });

        const sink = findSink(state.sinkName) || defaultSink();
        if (!sink) {
            return;
        }
        for (const port of usablePorts(sink)) {
            portList.append({ text: port.description, value: port.name });
        }
    }

    function indexOfValue(listModel, value) {
        for (let i = 0; i < listModel.count; ++i) {
            if (listModel.get(i).value === value) {
                return i;
            }
        }
        return 0;
    }

    Component.onCompleted: {
        rebuildSinks();
        rebuildPorts();
    }

    Connections {
        target: sinkModel
        function onRowsInserted() { page.rebuildSinks(); page.rebuildPorts(); }
        function onRowsRemoved() { page.rebuildSinks(); page.rebuildPorts(); }
        function onModelReset() { page.rebuildSinks(); page.rebuildPorts(); }
        function onDataChanged() { page.rebuildSinks(); page.rebuildPorts(); }
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {
            QQC2.ComboBox {
                id: sinkCombo
                Kirigami.FormData.label: i18n("Audio output device:")
                model: sinkList
                textRole: "text"
                valueRole: "value"
                currentIndex: page.indexOfValue(sinkList, state.sinkName)
                onActivated: {
                    state.sinkName = sinkList.get(currentIndex).value;
                    state.portA = "";
                    state.portB = "";
                    page.rebuildPorts();
                }
            }

            QQC2.ComboBox {
                id: portACombo
                Kirigami.FormData.label: i18n("Switch between:")
                enabled: state.sinkName !== ""
                model: portList
                textRole: "text"
                valueRole: "value"
                currentIndex: page.indexOfValue(portList, state.portA)
                onActivated: state.portA = portList.get(currentIndex).value
            }

            QQC2.ComboBox {
                id: portBCombo
                Kirigami.FormData.label: i18n("and:")
                enabled: state.sinkName !== ""
                model: portList
                textRole: "text"
                valueRole: "value"
                currentIndex: page.indexOfValue(portList, state.portB)
                onActivated: state.portB = portList.get(currentIndex).value
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("Left on “Automatic”, the widget uses the default output and switches between its headphone and line/speaker ports.")
        }
    }
}
