import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    padding: 22
    Component.onCompleted: KrisBackend.refreshDistroboxes()
    ColumnLayout {
        width: parent.width
        spacing: 12
        Controls.Label { text: qsTr("Distrobox"); font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2 }
        Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Distrobox è l’interfaccia utente; Podman resta soltanto il motore rootless interno di krisNOS."); opacity: 0.78 }
        Controls.Button { text: qsTr("Aggiorna elenco"); onClicked: KrisBackend.refreshDistroboxes() }
        Repeater { model: KrisBackend.distroboxes; delegate: Kirigami.AbstractCard { required property string modelData; Layout.fillWidth: true; contentItem: Controls.Label { text: modelData } } }
        Kirigami.InlineMessage { Layout.fillWidth: true; visible: KrisBackend.distroboxes.length === 0; text: qsTr("Nessun container Distrobox rilevato. Creazione, ingresso ed export app verranno aggiunti dopo il primo build test del bootstrap.") }
    }
}
