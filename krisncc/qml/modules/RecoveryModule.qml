import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    padding: 22
    Component.onCompleted: KrisBackend.refreshRecovery()
    ColumnLayout {
        width: parent.width
        spacing: 12
        RowLayout { Layout.fillWidth: true; Controls.Label { Layout.fillWidth: true; text: qsTr("Generazioni e rollback"); font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2 } Controls.Button { text: qsTr("Aggiorna"); onClicked: KrisBackend.refreshRecovery() } }
        Controls.Label { text: qsTr("Sistema NixOS"); font.bold: true }
        Repeater { model: KrisBackend.systemGenerations; delegate: Kirigami.AbstractCard { required property string modelData; Layout.fillWidth: true; contentItem: Controls.Label { text: modelData } } }
        Controls.Label { text: qsTr("Profilo software utente"); font.bold: true }
        Repeater { model: KrisBackend.profileHistory; delegate: Kirigami.AbstractCard { required property string modelData; Layout.fillWidth: true; contentItem: Controls.Label { text: modelData } } }
        Kirigami.InlineMessage { Layout.fillWidth: true; text: qsTr("In questo bootstrap la pagina è volutamente read-only. Le azioni di rollback verranno aggiunte solo con conferme e contratti testati.") }
    }
}
