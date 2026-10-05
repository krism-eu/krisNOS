import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    padding: 22
    Component.onCompleted: KrisBackend.refreshRuntimeStatus()

    ColumnLayout {
        width: parent.width
        spacing: 12
        Controls.Label { text: qsTr("Sistema"); font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2 }
        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Le modifiche quotidiane restano immediate: krisNCC usa NetworkManager, BlueZ, PipeWire/WirePlumber, CUPS e firewalld invece di ricostruire NixOS per ogni operazione.")
            opacity: 0.78
        }

        Kirigami.CardsLayout {
            Layout.fillWidth: true

            Kirigami.AbstractCard {
                contentItem: RowLayout {
                    Kirigami.Icon { source: "network-connect"; Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
                    ColumnLayout { Layout.fillWidth: true; Controls.Label { text: qsTr("Rete e VPN"); font.bold: true } Controls.Label { text: qsTr("NetworkManager"); opacity: 0.72 } }
                }
            }

            Kirigami.AbstractCard {
                contentItem: RowLayout {
                    Kirigami.Icon { source: "preferences-system-bluetooth"; Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
                    ColumnLayout { Layout.fillWidth: true; Controls.Label { text: qsTr("Bluetooth"); font.bold: true } Controls.Label { text: qsTr("BlueZ"); opacity: 0.72 } }
                    Controls.Switch { checked: KrisBackend.runtimeStatus.bluetooth === "on"; enabled: !KrisBackend.busy; onToggled: KrisBackend.setBluetoothEnabled(checked) }
                }
            }

            Kirigami.AbstractCard {
                contentItem: RowLayout {
                    Kirigami.Icon { source: "audio-volume-high"; Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
                    ColumnLayout { Layout.fillWidth: true; Controls.Label { text: qsTr("Audio"); font.bold: true } Controls.Label { text: qsTr("PipeWire / WirePlumber"); opacity: 0.72 } }
                }
            }

            Kirigami.AbstractCard {
                contentItem: RowLayout {
                    Kirigami.Icon { source: "printer"; Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
                    ColumnLayout { Layout.fillWidth: true; Controls.Label { text: qsTr("Stampanti"); font.bold: true } Controls.Label { text: qsTr("CUPS"); opacity: 0.72 } }
                }
            }

            Kirigami.AbstractCard {
                contentItem: RowLayout {
                    Kirigami.Icon { source: "security-high"; Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
                    ColumnLayout { Layout.fillWidth: true; Controls.Label { text: qsTr("Firewall"); font.bold: true } Controls.Label { text: qsTr("firewalld"); opacity: 0.72 } }
                    Controls.Switch { checked: KrisBackend.runtimeStatus.firewall === "on"; enabled: !KrisBackend.busy; onToggled: KrisBackend.setFirewallEnabled(checked) }
                }
            }

            Kirigami.AbstractCard {
                contentItem: RowLayout {
                    Kirigami.Icon { source: "battery"; Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
                    ColumnLayout { Layout.fillWidth: true; Controls.Label { text: qsTr("Energia"); font.bold: true } Controls.Label { text: qsTr("Profili energetici"); opacity: 0.72 } }
                }
            }
        }

        RowLayout {
            Controls.Button { text: qsTr("Impostazioni Plasma"); icon.name: "settings-configure"; onClicked: KrisBackend.launchTool("systemsettings") }
            Controls.Button { text: qsTr("Info sistema"); icon.name: "hwinfo"; onClicked: KrisBackend.launchTool("kinfocenter") }
        }
    }
}
