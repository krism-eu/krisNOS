import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    padding: 22

    function globalBusy() {
        return KrisBackend.busy || DesktopBackend.busy
    }

    Component.onCompleted: {
        KrisBackend.refreshRuntimeStatus()
        DesktopBackend.refreshPowerProfile()
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        Controls.Label {
            text: qsTr("Sistema")
            font.bold: true
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
        }
        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Solo controlli quotidiani realmente utili. Wi-Fi e rete restano a Plasma/NetworkManager; le app Flatpak restano a Discover.")
            opacity: 0.78
        }

        Kirigami.CardsLayout {
            Layout.fillWidth: true

            Kirigami.AbstractCard {
                contentItem: RowLayout {
                    Kirigami.Icon {
                        source: "preferences-system-bluetooth"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Controls.Label { text: qsTr("Bluetooth"); font.bold: true }
                        Controls.Label { text: qsTr("BlueZ · al riavvio torna spento"); opacity: 0.70 }
                    }
                    Controls.Switch {
                        checked: KrisBackend.runtimeStatus.bluetooth === "on"
                        enabled: !root.globalBusy()
                              && KrisBackend.runtimeStatus.bluetooth !== "hard-blocked"
                              && KrisBackend.runtimeStatus.bluetooth !== "unavailable"
                        onToggled: KrisBackend.setBluetoothEnabled(checked)
                    }
                }
            }

            Kirigami.AbstractCard {
                contentItem: RowLayout {
                    Kirigami.Icon {
                        source: "security-high"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Controls.Label { text: qsTr("Firewall"); font.bold: true }
                        Controls.Label {
                            text: KrisBackend.runtimeStatus.firewallPolicy
                                ? qsTr("firewalld · policy %1").arg(KrisBackend.runtimeStatus.firewallPolicy)
                                : qsTr("firewalld")
                            opacity: 0.70
                        }
                    }
                    Controls.Switch {
                        checked: KrisBackend.runtimeStatus.firewall === "on"
                        enabled: !root.globalBusy()
                        onToggled: KrisBackend.setFirewallEnabled(checked)
                    }
                }
            }

            Kirigami.AbstractCard {
                contentItem: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true
                        Kirigami.Icon {
                            source: "audio-volume-high"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Controls.Label { text: qsTr("Audio"); font.bold: true }
                            Controls.Label { text: qsTr("PipeWire / WirePlumber"); opacity: 0.70 }
                        }
                    }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Se l'audio resta bloccato, riavvia solo lo stack della sessione utente.")
                        opacity: 0.72
                    }
                    Controls.Button {
                        text: qsTr("Ripristina audio")
                        icon.name: "view-refresh"
                        enabled: !root.globalBusy()
                        onClicked: DesktopBackend.restartAudio()
                    }
                }
            }

            Kirigami.AbstractCard {
                contentItem: ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true
                        Kirigami.Icon {
                            source: "battery"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Controls.Label { text: qsTr("Energia"); font.bold: true }
                            Controls.Label {
                                text: DesktopBackend.powerProfile === "power-saver"
                                    ? qsTr("Risparmio")
                                    : DesktopBackend.powerProfile === "balanced"
                                      ? qsTr("Bilanciato")
                                      : DesktopBackend.powerProfile === "performance"
                                        ? qsTr("Prestazioni")
                                        : qsTr("Non disponibile")
                                opacity: 0.70
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Controls.Button {
                            Layout.fillWidth: true
                            text: qsTr("Risparmio")
                            checkable: true
                            checked: DesktopBackend.powerProfile === "power-saver"
                            enabled: !root.globalBusy() && DesktopBackend.powerProfile !== "unavailable"
                            onClicked: DesktopBackend.setPowerProfile("power-saver")
                        }
                        Controls.Button {
                            Layout.fillWidth: true
                            text: qsTr("Bilanciato")
                            checkable: true
                            checked: DesktopBackend.powerProfile === "balanced"
                            enabled: !root.globalBusy() && DesktopBackend.powerProfile !== "unavailable"
                            onClicked: DesktopBackend.setPowerProfile("balanced")
                        }
                        Controls.Button {
                            Layout.fillWidth: true
                            text: qsTr("Prestazioni")
                            checkable: true
                            checked: DesktopBackend.powerProfile === "performance"
                            enabled: !root.globalBusy() && DesktopBackend.powerProfile !== "unavailable"
                            onClicked: DesktopBackend.setPowerProfile("performance")
                        }
                    }
                }
            }
        }

        RowLayout {
            Controls.Button {
                text: qsTr("Impostazioni Plasma")
                icon.name: "settings-configure"
                onClicked: KrisBackend.launchTool("systemsettings")
            }
            Controls.Button {
                text: qsTr("Info sistema")
                icon.name: "hwinfo"
                onClicked: KrisBackend.launchTool("kinfocenter")
            }
            Controls.Button {
                text: qsTr("Monitor di sistema")
                icon.name: "utilities-system-monitor"
                onClicked: DesktopBackend.launchTool("systemmonitor")
            }
        }
    }
}
