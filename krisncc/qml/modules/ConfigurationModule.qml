import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    padding: 22
    Component.onCompleted: KrisBackend.refreshConfigStatus()
    ColumnLayout {
        width: parent.width
        spacing: 12
        Controls.Label { text: qsTr("Configurazione krisNOS"); font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2 }
        Kirigami.InlineMessage { Layout.fillWidth: true; text: qsTr("La sincronizzazione è sempre manuale. Sincronizzare non applica e non ricostruisce il sistema."); type: Kirigami.MessageType.Information }
        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: GridLayout {
                columns: 2
                columnSpacing: 18
                rowSpacing: 8
                Controls.Label { text: qsTr("Repo locale"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.repo || "~/krisNOS-config" }
                Controls.Label { text: qsTr("Branch"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.branch || "?" }
                Controls.Label { text: qsTr("Commit"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.head ? KrisBackend.configStatus.head.substring(0, 12) : "?" }
                Controls.Label { text: qsTr("Locale avanti"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.ahead !== undefined ? KrisBackend.configStatus.ahead : "?" }
                Controls.Label { text: qsTr("Remoto avanti"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.behind !== undefined ? KrisBackend.configStatus.behind : "?" }
                Controls.Label { text: qsTr("Modifiche locali"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.dirty ? qsTr("Sì") : qsTr("No") }
            }
        }
        RowLayout {
            Controls.Button { text: qsTr("Rileggi locale"); onClicked: KrisBackend.refreshConfigStatus() }
            Controls.Button { text: qsTr("Controlla GitHub"); enabled: !KrisBackend.busy; onClicked: KrisBackend.fetchConfig() }
            Controls.Button { text: qsTr("Sincronizza"); enabled: !KrisBackend.busy; onClicked: KrisBackend.syncConfig() }
            Controls.Button { text: qsTr("Valida"); enabled: !KrisBackend.busy; onClicked: KrisBackend.validateConfig() }
        }
        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Controls.Label { text: qsTr("Fondamenta Nix"); font.bold: true }
                Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("krisNCC gestirà solo un modulo dedicato della configurazione personale. I moduli Nix liberi rimarranno fuori dal suo controllo. Prima di scrivere opzioni strutturali mostrerà sempre il diff e richiederà una validazione."); opacity: 0.78 }
                Controls.Button { text: qsTr("Editor opzioni avanzate · prossimo step"); enabled: false }
            }
        }
    }
}
