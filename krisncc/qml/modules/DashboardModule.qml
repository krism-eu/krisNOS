import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    signal openRequested(int index)
    padding: 22
    Component.onCompleted: { KrisBackend.refreshResources(); KrisBackend.refreshConfigStatus(); KrisBackend.refreshRuntimeStatus() }
    Timer { interval: 2000; repeat: true; running: parent.visible; onTriggered: KrisBackend.refreshResources() }

    ColumnLayout {
        width: parent.width
        spacing: 12
        Controls.Label { text: qsTr("Stato del sistema"); font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2 }
        Kirigami.CardsLayout {
            Layout.fillWidth: true
            Kirigami.AbstractCard { contentItem: ColumnLayout { Controls.Label { text: qsTr("RAM in uso"); font.bold: true } Controls.Label { text: KrisBackend.memoryUsedMiB >= 0 ? qsTr("%1 MiB su %2 MiB").arg(KrisBackend.memoryUsedMiB).arg(KrisBackend.memoryTotalMiB) : qsTr("Non disponibile") } Controls.Label { text: qsTr("Cache e buffer esclusi · swap esclusa"); opacity: 0.72 } } }
            Kirigami.AbstractCard { contentItem: ColumnLayout { Controls.Label { text: qsTr("Temperatura CPU"); font.bold: true } Controls.Label { text: KrisBackend.cpuTemperatureC > 0 ? qsTr("%1 °C").arg(KrisBackend.cpuTemperatureC.toFixed(1)) : qsTr("Non disponibile") } } }
            Kirigami.AbstractCard { contentItem: ColumnLayout { Controls.Label { text: qsTr("Config"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.head ? KrisBackend.configStatus.head.substring(0, 8) : qsTr("Repo non inizializzato") } Controls.Label { text: KrisBackend.configStatus.dirty ? qsTr("Modifiche locali presenti") : qsTr("Working tree pulito"); opacity: 0.72 } Controls.Button { text: qsTr("Apri Config"); onClicked: openRequested(3) } } }
            Kirigami.AbstractCard { contentItem: ColumnLayout { Controls.Label { text: qsTr("Sistema"); font.bold: true } Controls.Label { text: qsTr("Firewall: %1").arg(KrisBackend.runtimeStatus.firewall || "?") } Controls.Label { text: qsTr("Bluetooth: %1").arg(KrisBackend.runtimeStatus.bluetooth || "?") } Controls.Button { text: qsTr("Apri Sistema"); onClicked: openRequested(1) } } }
        }
    }
}
