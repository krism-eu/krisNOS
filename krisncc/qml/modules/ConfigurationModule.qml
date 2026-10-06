import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    padding: 22

    function globalBusy() {
        return KrisBackend.busy || DesktopBackend.busy || PackageBackend.busy
    }

    Component.onCompleted: KrisBackend.refreshConfigStatus()

    ColumnLayout {
        width: parent.width
        spacing: 12

        Controls.Label { text: qsTr("Config del sistema"); font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2 }
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            text: qsTr("La configurazione locale è la sorgente principale del sistema. GitHub è facoltativo e viene usato solo quando scegli esplicitamente di sincronizzare.")
            type: Kirigami.MessageType.Information
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: GridLayout {
                columns: 2
                columnSpacing: 18
                rowSpacing: 8
                Controls.Label { text: qsTr("Repo locale"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.repo || "~/krisNOS-config" }
                Controls.Label { text: qsTr("Branch"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.branch || "?" }
                Controls.Label { text: qsTr("Commit"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.head ? KrisBackend.configStatus.head.substring(0, 12) : "?" }
                Controls.Label { text: qsTr("GitHub"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.upstream ? KrisBackend.configStatus.upstream : qsTr("Non collegato") }
                Controls.Label { text: qsTr("Locale avanti"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.upstream ? KrisBackend.configStatus.ahead : "—" }
                Controls.Label { text: qsTr("GitHub avanti"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.upstream ? KrisBackend.configStatus.behind : "—" }
                Controls.Label { text: qsTr("Modifiche locali"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.dirty ? qsTr("Sì") : qsTr("No") }
                Controls.Label { text: qsTr("Ultima applicata"); font.bold: true } Controls.Label { text: KrisBackend.configStatus.appliedCommit ? KrisBackend.configStatus.appliedCommit.substring(0, 12) : qsTr("Non registrata") }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Controls.Button { text: qsTr("Rileggi"); enabled: !root.globalBusy(); onClicked: KrisBackend.refreshConfigStatus() }
            Controls.Button { text: qsTr("Mostra differenze"); enabled: !root.globalBusy(); onClicked: KrisBackend.showConfigDiff() }
            Item { Layout.fillWidth: true }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Controls.Label { text: qsTr("GitHub — opzionale"); font.bold: true }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: KrisBackend.configStatus.upstream
                        ? qsTr("Remote collegato. La sincronizzazione resta manuale e non applica mai automaticamente una configurazione.")
                        : qsTr("GitHub non è collegato. Verifica, costruzione e applicazione del sistema continuano a funzionare interamente in locale.")
                    opacity: 0.78
                }
                RowLayout {
                    Controls.Button {
                        text: qsTr("Controlla GitHub")
                        enabled: !root.globalBusy() && !!KrisBackend.configStatus.upstream
                        onClicked: KrisBackend.fetchConfig()
                    }
                    Controls.Button {
                        text: qsTr("Sincronizza")
                        enabled: !root.globalBusy() && !!KrisBackend.configStatus.upstream
                        onClicked: KrisBackend.syncConfig()
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }

        Controls.ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 320 : 0
            visible: KrisBackend.configDiff.length > 0
            clip: true

            Controls.TextArea {
                readOnly: true
                wrapMode: TextEdit.NoWrap
                text: KrisBackend.configDiff
                font.family: "monospace"
                selectByMouse: true
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Controls.Label { text: qsTr("Modifiche strutturali"); font.bold: true }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Avvio, ZRAM, desktop, Nix e servizi base saranno modificabili con controlli semplici. krisNCC scrive solo krisncc-managed.nix; free.nix e i tuoi altri moduli non vengono mai riscritti.")
                    opacity: 0.78
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [qsTr("Avvio"), qsTr("Memoria / ZRAM"), qsTr("Desktop"), qsTr("Nix"), qsTr("Servizi base")]
                        delegate: Controls.Button { required property string modelData; text: modelData; enabled: false }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Controls.Button { text: qsTr("Verifica"); enabled: !root.globalBusy(); onClicked: KrisBackend.validateConfig() }
            Controls.Button { text: qsTr("Costruisci"); enabled: !root.globalBusy(); onClicked: KrisBackend.buildConfig() }
            Controls.Button {
                text: qsTr("Applica")
                enabled: !root.globalBusy()
                onClicked: KrisBackend.applyConfig()
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: qsTr("Valida e costruisce da utente; solo l'attivazione finale usa l'helper amministrativo fisso tramite sudo non interattivo.")
            }
            Item { Layout.fillWidth: true }
            Controls.Label { text: qsTr("Sync ≠ Applica"); font.bold: true; opacity: 0.75 }
        }
    }
}
