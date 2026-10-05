import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    padding: 22
    Component.onCompleted: KrisBackend.refreshSoftware()
    ColumnLayout {
        width: parent.width
        spacing: 12
        Controls.Label { text: qsTr("Software personale Nix"); font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2 }
        Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Installazioni nel profilo utente: nessun rebuild del sistema. ‘Prova’ usa nix run e non installa il programma."); opacity: 0.78 }
        RowLayout {
            Layout.fillWidth: true
            Controls.TextField { id: search; Layout.fillWidth: true; placeholderText: qsTr("Cerca in nixpkgs…"); onAccepted: KrisBackend.searchSoftware(text) }
            Controls.Button { text: qsTr("Cerca"); enabled: search.text.trim().length > 0 && !KrisBackend.busy; onClicked: KrisBackend.searchSoftware(search.text) }
            Controls.Button { text: qsTr("Aggiornamenti"); enabled: !KrisBackend.busy; onClicked: KrisBackend.previewSoftwareUpdates() }
        }
        Repeater {
            model: KrisBackend.searchResults
            delegate: Kirigami.AbstractCard {
                required property var modelData
                Layout.fillWidth: true
                contentItem: RowLayout {
                    ColumnLayout { Layout.fillWidth: true; Controls.Label { text: modelData.name || modelData.attribute; font.bold: true } Controls.Label { Layout.fillWidth: true; text: (modelData.version ? modelData.version + " · " : "") + (modelData.description || modelData.attribute); elide: Text.ElideRight; opacity: 0.75 } }
                    Controls.Button { text: qsTr("Prova"); enabled: !KrisBackend.busy; onClicked: KrisBackend.runSoftware(modelData.attribute) }
                    Controls.Button { text: qsTr("Installa"); enabled: !KrisBackend.busy; onClicked: KrisBackend.addSoftware(modelData.attribute, false) }
                }
            }
        }
        Controls.Label { text: qsTr("Installati (%1)").arg(KrisBackend.softwareItems.length); font.bold: true }
        Repeater {
            model: KrisBackend.softwareItems
            delegate: Kirigami.AbstractCard {
                required property var modelData
                Layout.fillWidth: true
                contentItem: RowLayout { Controls.Label { Layout.fillWidth: true; text: modelData.name; font.bold: true } Controls.Button { text: qsTr("Rimuovi"); enabled: !KrisBackend.busy; onClicked: KrisBackend.removeSoftware(modelData.name) } }
            }
        }
    }
}
