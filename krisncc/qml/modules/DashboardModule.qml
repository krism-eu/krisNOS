import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    signal openRequested(int index)
    padding: 22

    Component.onCompleted: {
        KrisBackend.refreshResources()
        DesktopBackend.refreshResources()
        KrisBackend.refreshConfigStatus()
        KrisBackend.refreshRuntimeStatus()
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.visible
        onTriggered: {
            KrisBackend.refreshResources()
            DesktopBackend.refreshResources()
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        Controls.Label {
            text: qsTr("Stato del sistema")
            font.bold: true
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width > 900 ? 3 : 2
            uniformCellWidths: true
            columnSpacing: 10
            rowSpacing: 10

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Controls.Label { text: qsTr("CPU"); font.bold: true }
                    Controls.Label {
                        text: DesktopBackend.cpuUsagePercent >= 0
                            ? qsTr("%1%").arg(DesktopBackend.cpuUsagePercent)
                            : qsTr("Campionamento…")
                    }
                    Controls.Label {
                        text: KrisBackend.cpuTemperatureC > 0
                            ? qsTr("%1 °C").arg(KrisBackend.cpuTemperatureC.toFixed(1))
                            : qsTr("Temperatura non disponibile")
                        opacity: 0.72
                    }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Controls.Label { text: qsTr("RAM realmente usata"); font.bold: true }
                    Controls.Label {
                        text: KrisBackend.memoryUsedMiB >= 0
                            ? qsTr("%1 MiB su %2 MiB")
                                .arg(KrisBackend.memoryUsedMiB)
                                .arg(KrisBackend.memoryTotalMiB)
                            : qsTr("Non disponibile")
                    }
                    Controls.Label {
                        text: qsTr("Cache/buffer e swap esclusi")
                        opacity: 0.72
                    }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Controls.Label { text: qsTr("Disco /"); font.bold: true }
                    Controls.Label {
                        text: DesktopBackend.diskAvailableGiB >= 0
                            ? qsTr("%1 GiB liberi").arg(DesktopBackend.diskAvailableGiB)
                            : qsTr("Non disponibile")
                    }
                    Controls.Label {
                        text: DesktopBackend.diskTotalGiB >= 0
                            ? qsTr("%1 GiB totali").arg(DesktopBackend.diskTotalGiB)
                            : ""
                        opacity: 0.72
                    }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Controls.Label { text: qsTr("Config"); font.bold: true }
                    Controls.Label {
                        text: KrisBackend.configStatus.head
                            ? KrisBackend.configStatus.head.substring(0, 8)
                            : qsTr("Repo non inizializzato")
                    }
                    Controls.Label {
                        text: KrisBackend.configStatus.dirty
                            ? qsTr("Modifiche locali presenti")
                            : qsTr("Working tree pulito")
                        opacity: 0.72
                    }
                    Controls.Button {
                        text: qsTr("Apri Config")
                        onClicked: root.openRequested(3)
                    }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Controls.Label { text: qsTr("Stato runtime"); font.bold: true }
                    Controls.Label {
                        text: qsTr("Firewall: %1").arg(KrisBackend.runtimeStatus.firewall || "?")
                    }
                    Controls.Label {
                        text: qsTr("Bluetooth: %1").arg(KrisBackend.runtimeStatus.bluetooth || "?")
                    }
                    Controls.Button {
                        text: qsTr("Apri Sistema")
                        onClicked: root.openRequested(1)
                    }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Controls.Label { text: qsTr("Azioni rapide"); font.bold: true }
                    Controls.Button {
                        text: qsTr("Monitor di sistema")
                        icon.name: "utilities-system-monitor"
                        onClicked: DesktopBackend.launchTool("systemmonitor")
                    }
                    Controls.Button {
                        text: qsTr("Diagnostica")
                        icon.name: "tools-report-bug"
                        onClicked: root.openRequested(5)
                    }
                }
            }
        }
    }
}
