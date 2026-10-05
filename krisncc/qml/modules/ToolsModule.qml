import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    padding: 22
    ColumnLayout {
        width: parent.width
        spacing: 12
        Controls.Label { text: qsTr("Strumenti"); font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2 }
        Kirigami.CardsLayout {
            Layout.fillWidth: true
            Kirigami.AbstractCard { contentItem: Controls.Button { text: qsTr("Impostazioni Plasma"); icon.name: "settings-configure"; onClicked: KrisBackend.launchTool("systemsettings") } }
            Kirigami.AbstractCard { contentItem: Controls.Button { text: qsTr("Info Center"); icon.name: "hwinfo"; onClicked: KrisBackend.launchTool("kinfocenter") } }
            Kirigami.AbstractCard { contentItem: Controls.Button { text: qsTr("Terminale"); icon.name: "utilities-terminal"; onClicked: KrisBackend.launchTool("konsole") } }
            Kirigami.AbstractCard { contentItem: Controls.Button { text: qsTr("Discover / Flatpak"); icon.name: "plasmadiscover"; onClicked: KrisBackend.launchTool("discover") } }
        }
        Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("La sezione ‘I miei comandi’ dell’attuale krisCC verrà portata dopo il bootstrap, mantenendo il limite a 12 comandi e i dati nel profilo utente."); opacity: 0.78 }
    }
}
