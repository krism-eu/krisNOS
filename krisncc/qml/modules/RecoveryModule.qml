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

    Component.onCompleted: KrisBackend.refreshRecovery()

    ColumnLayout {
        width: parent.width
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Controls.Label {
                Layout.fillWidth: true
                text: qsTr("Backup e ripristino")
                font.bold: true
                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
            }
            Controls.Button {
                text: qsTr("Aggiorna")
                enabled: !root.globalBusy()
                onClicked: KrisBackend.refreshRecovery()
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: RowLayout {
                Kirigami.Icon {
                    source: "document-save-all"
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Controls.Label { text: qsTr("Backup personali"); font.bold: true }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("I file personali restano affidati a Back In Time: krisNCC non implementa un secondo motore di backup.")
                        opacity: 0.72
                    }
                }
                Controls.Button {
                    text: qsTr("Apri Back In Time")
                    icon.name: "document-save-all"
                    onClicked: DesktopBackend.launchTool("backintime")
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Controls.Label { text: qsTr("Rollback NixOS"); font.bold: true }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Torna alla generazione di sistema precedente. L'attivazione è immediata; il riavvio è consigliato per riallineare anche kernel e initrd.")
                    opacity: 0.72
                }
                Controls.Button {
                    text: qsTr("Ripristina generazione precedente")
                    icon.name: "edit-undo"
                    enabled: !root.globalBusy() && KrisBackend.systemGenerations.length > 1
                    onClicked: systemRollbackDialog.open()
                }
            }
        }

        Controls.Label { text: qsTr("Generazioni sistema NixOS"); font.bold: true }
        Repeater {
            model: KrisBackend.systemGenerations
            delegate: Kirigami.AbstractCard {
                required property string modelData
                Layout.fillWidth: true
                contentItem: Controls.Label {
                    text: modelData
                    font.family: "monospace"
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Controls.Label { text: qsTr("Profilo software utente"); font.bold: true }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Ripristina la generazione precedente del profilo Nix dell'utente, senza toccare il sistema base.")
                    opacity: 0.72
                }
                Controls.Button {
                    text: qsTr("Rollback app Nix")
                    icon.name: "edit-undo"
                    enabled: !root.globalBusy()
                    onClicked: profileRollbackDialog.open()
                }
            }
        }

        Repeater {
            model: KrisBackend.profileHistory
            delegate: Kirigami.AbstractCard {
                required property string modelData
                Layout.fillWidth: true
                contentItem: Controls.Label {
                    text: modelData
                    font.family: "monospace"
                }
            }
        }
    }

    Controls.Dialog {
        id: systemRollbackDialog
        modal: true
        anchors.centerIn: parent
        width: Math.min(560, parent ? parent.width - 40 : 560)
        title: qsTr("Ripristinare la generazione NixOS precedente?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("krisNCC attiverà il toplevel precedente tramite lo stesso helper amministrativo ristretto usato da Config. Nessun file personale viene modificato.")
        }
        onAccepted: DesktopBackend.rollbackSystem()
    }

    Controls.Dialog {
        id: profileRollbackDialog
        modal: true
        anchors.centerIn: parent
        width: Math.min(520, parent ? parent.width - 40 : 520)
        title: qsTr("Ripristinare il profilo Nix precedente?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("Le app del profilo utente torneranno alla generazione precedente.")
        }
        onAccepted: DesktopBackend.rollbackProfile()
    }
}
