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
        Controls.Label { text: qsTr("Modifiche immediate"); font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2 }
        Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("NetworkManager, BlueZ, PipeWire/WirePlumber, CUPS e firewalld restano i proprietari del loro stato. krisNCC li controllerà tramite API native, senza riscrivere la configurazione Nix per le operazioni quotidiane."); opacity: 0.78 }
        Kirigami.CardsLayout {
            Layout.fillWidth: true
            Repeater {
                model: [
                    [qsTr("Rete e VPN"), "network-connect", qsTr("NetworkManager")],
                    [qsTr("Bluetooth"), "preferences-system-bluetooth", qsTr("BlueZ · %1").arg(KrisBackend.runtimeStatus.bluetooth || "?")],
                    [qsTr("Audio"), "audio-volume-high", qsTr("PipeWire / WirePlumber")],
                    [qsTr("Stampanti"), "printer", qsTr("CUPS")],
                    [qsTr("Firewall"), "security-high", qsTr("firewalld · %1").arg(KrisBackend.runtimeStatus.firewall || "?")],
                    [qsTr("Energia"), "battery", qsTr("Profili energetici")]
                ]
                delegate: Kirigami.AbstractCard {
                    required property var modelData
                    contentItem: RowLayout { Kirigami.Icon { source: modelData[1]; Layout.preferredWidth: 32; Layout.preferredHeight: 32 } ColumnLayout { Layout.fillWidth: true; Controls.Label { text: modelData[0]; font.bold: true } Controls.Label { text: modelData[2]; opacity: 0.72 } } }
                }
            }
        }
        Controls.Button { text: qsTr("Apri Impostazioni Plasma"); icon.name: "settings-configure"; onClicked: KrisBackend.launchTool("systemsettings") }
    }
}
