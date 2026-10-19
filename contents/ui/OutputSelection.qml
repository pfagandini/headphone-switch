/*
    SPDX-FileCopyrightText: 2026 Paulo Fagandini

    SPDX-License-Identifier: MIT
*/

import QtQuick

import org.kde.kitemmodels as KItemModels
import org.kde.plasma.private.volume

// Decides which sink, and which two of its ports, the widget switches between.
// Shared by the widget and its configuration page so both always agree.
Item {
    id: selection

    // Preferences; an empty string means "pick automatically".
    property string sinkName: ""
    property string portA: ""
    property string portB: ""

    // The chosen sink, and up to two of its usable ports as
    // { index, name, description, type }, where index is the sink's own port index.
    property QtObject sink: null
    property var ports: []
    // Every usable port of the chosen sink, same shape as ports.
    property var sinkPorts: []

    // Emitted whenever the list of sinks or their ports may have changed.
    signal updated()

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
            out.push({
                index: i,
                name: port.name,
                description: port.description,
                type: port.type
            });
        }
        return out;
    }

    function isHeadphones(port) {
        return port.type === Port.Headphones;
    }

    function isLine(port) {
        return port.type === Port.Line || port.type === Port.Speaker;
    }

    function allSinks() {
        const out = [];
        const role = sinkModel.KItemModels.KRoleNames.role("PulseObject");
        for (let i = 0; i < sinkModel.count; ++i) {
            const sink = sinkModel.data(sinkModel.index(i, 0), role);
            if (sink && sink.name) {
                out.push(sink);
            }
        }
        return out;
    }

    // Sinks with at least two usable ports, i.e. the ones worth switching.
    function switchableSinks() {
        return allSinks().filter(sink => usablePorts(sink).length >= 2);
    }

    // An explicitly configured sink wins. Otherwise score the switchable
    // sinks: a headphone port and a line/speaker port count most, being the
    // default sink breaks ties.
    function pickSink() {
        const sinks = switchableSinks();
        const configured = sinks.find(sink => sink.name === sinkName);
        if (configured) {
            return configured;
        }

        let best = null;
        let bestScore = -1;
        for (const sink of sinks) {
            const ports = usablePorts(sink);
            const score = (ports.some(isHeadphones) ? 2 : 0)
                + (ports.some(isLine) ? 2 : 0)
                + (sink.default ? 1 : 0);
            if (score > bestScore) {
                best = sink;
                bestScore = score;
            }
        }
        return best;
    }

    // Configured ports win if both are usable; otherwise one headphone and
    // one line/speaker port, otherwise the first two.
    function pickPorts(sink) {
        const ports = usablePorts(sink);
        if (ports.length < 2) {
            return ports;
        }

        const a = ports.find(p => p.name === portA);
        const b = ports.find(p => p.name === portB);
        if (a && b && a.index !== b.index) {
            return [a, b];
        }

        const headphones = ports.find(isHeadphones);
        const line = ports.find(isLine);
        if (headphones && line) {
            return [headphones, line];
        }
        return ports.slice(0, 2);
    }

    function update() {
        sink = pickSink();
        sinkPorts = usablePorts(sink);
        ports = pickPorts(sink);
        updated();
    }

    function scheduleUpdate() {
        Qt.callLater(update);
    }

    onSinkNameChanged: scheduleUpdate()
    onPortAChanged: scheduleUpdate()
    onPortBChanged: scheduleUpdate()
    Component.onCompleted: update()

    SinkModel {
        id: sinkModel
    }

    Connections {
        target: sinkModel
        function onModelReset() { selection.scheduleUpdate(); }
        function onDataChanged() { selection.scheduleUpdate(); }
        function onRowsInserted() { selection.scheduleUpdate(); }
        function onRowsRemoved() { selection.scheduleUpdate(); }
    }

    // Port availability changes when a jack is plugged in or out.
    Connections {
        target: selection.sink
        function onPortsChanged() { selection.scheduleUpdate(); }
    }
}
