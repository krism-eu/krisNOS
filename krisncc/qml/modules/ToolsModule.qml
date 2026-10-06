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

    Component.onCompleted: DesktopBackend.reloadCustomActions()

    ColumnLayout {
        width: parent.width
        spacing: 12

        Controls.Label {
            text: qsTr("Strumenti")
            font.bold: true
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
        }

        Controls.TabBar {
            id: tabs
            Layout.fillWidth: true
            Controls.TabButton { text: qsTr("Diagnostica") }
            Controls.TabButton { text: qsTr("Miei comandi") }
            Controls.TabButton { text: qsTr("Applicazioni") }
        }

        StackLayout {
            Layout.fillWidth: true
            currentIndex: tabs.currentIndex

            ColumnLayout {
                spacing: 12

                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.75
                    text: qsTr("Controlli read-only frequenti. Nessun sudo e nessuna modifica al sistema.")
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: width > 760 ? 3 : 2
                    uniformCellWidths: true
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: [
                            { id: "failed-units", title: qsTr("Unità fallite") },
                            { id: "journal-errors", title: qsTr("Errori avvio") },
                            { id: "kernel-errors", title: qsTr("Warning kernel") },
                            { id: "boot-time", title: qsTr("Tempo avvio") },
                            { id: "disk-space", title: qsTr("Spazio disco") },
                            { id: "disks", title: qsTr("Dischi e partizioni") }
                        ]
                        delegate: Controls.Button {
                            required property var modelData
                            Layout.fillWidth: true
                            text: modelData.title
                            enabled: !root.globalBusy()
                            onClicked: DesktopBackend.runDiagnostic(modelData.id)
                        }
                    }
                }

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    visible: DesktopBackend.diagnosticTitle.length > 0
                          || DesktopBackend.diagnosticOutput.length > 0
                    contentItem: ColumnLayout {
                        RowLayout {
                            Layout.fillWidth: true
                            Controls.Label {
                                Layout.fillWidth: true
                                text: DesktopBackend.diagnosticTitle || qsTr("Output")
                                font.bold: true
                            }
                            Controls.Button {
                                text: qsTr("Annulla")
                                visible: DesktopBackend.busy && DesktopBackend.canCancel
                                onClicked: DesktopBackend.cancelCurrentOperation()
                            }
                            Controls.Button {
                                text: qsTr("Pulisci")
                                enabled: !DesktopBackend.busy
                                onClicked: DesktopBackend.clearDiagnostic()
                            }
                        }
                        Controls.ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 300
                            Controls.TextArea {
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                                font.family: "monospace"
                                text: DesktopBackend.diagnosticOutput
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        Controls.Label { text: qsTr("Miei comandi"); font.bold: true }
                        Controls.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: 0.75
                            text: qsTr("Fino a 12 comandi personali, salvati nella home ed eseguiti solo con i privilegi del tuo utente. Nessuna elevazione automatica.")
                        }
                    }
                    Controls.Label {
                        text: qsTr("%1 / %2").arg(DesktopBackend.customActions.length)
                                              .arg(DesktopBackend.customActionLimit)
                        opacity: 0.7
                    }
                    Controls.Button {
                        text: qsTr("Nuovo")
                        icon.name: "list-add"
                        enabled: !root.globalBusy()
                              && DesktopBackend.customActions.length < DesktopBackend.customActionLimit
                        onClicked: editActionDialog.openNew()
                    }
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: DesktopBackend.actionError.length > 0
                    type: Kirigami.MessageType.Error
                    text: DesktopBackend.actionError
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: DesktopBackend.customActions.length === 0
                    type: Kirigami.MessageType.Information
                    text: qsTr("Nessun comando personale salvato.")
                }

                Repeater {
                    model: DesktopBackend.customActions
                    delegate: Kirigami.AbstractCard {
                        required property var modelData
                        Layout.fillWidth: true
                        contentItem: ColumnLayout {
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Controls.Label {
                                        Layout.fillWidth: true
                                        font.bold: true
                                        text: modelData.name
                                        elide: Text.ElideRight
                                    }
                                    Controls.Label {
                                        Layout.fillWidth: true
                                        font.family: "monospace"
                                        text: modelData.script
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                        opacity: 0.72
                                    }
                                }
                                Controls.Button {
                                    text: qsTr("Esegui")
                                    enabled: !root.globalBusy()
                                    onClicked: {
                                        if (modelData.confirm) {
                                            runActionDialog.actionId = modelData.id
                                            runActionDialog.actionName = modelData.name
                                            runActionDialog.open()
                                        } else {
                                            DesktopBackend.runCustomAction(modelData.id)
                                        }
                                    }
                                }
                                Controls.Button {
                                    text: qsTr("Modifica")
                                    enabled: !root.globalBusy()
                                    onClicked: editActionDialog.openFor(modelData)
                                }
                                Controls.Button {
                                    text: qsTr("Elimina")
                                    enabled: !root.globalBusy()
                                    onClicked: {
                                        deleteActionDialog.actionId = modelData.id
                                        deleteActionDialog.actionName = modelData.name
                                        deleteActionDialog.open()
                                    }
                                }
                            }
                        }
                    }
                }

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    visible: DesktopBackend.actionOutput.length > 0 || DesktopBackend.busy
                    contentItem: ColumnLayout {
                        RowLayout {
                            Layout.fillWidth: true
                            Controls.Label { Layout.fillWidth: true; text: qsTr("Output comando"); font.bold: true }
                            Controls.Button {
                                visible: DesktopBackend.busy && DesktopBackend.canCancel
                                text: qsTr("Annulla")
                                onClicked: DesktopBackend.cancelCurrentOperation()
                            }
                        }
                        Controls.ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 220
                            Controls.TextArea {
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                                font.family: "monospace"
                                text: DesktopBackend.actionOutput
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: 12
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.75
                    text: qsTr("Qui krisNCC apre strumenti dedicati invece di duplicarne le funzioni.")
                }
                Kirigami.CardsLayout {
                    Layout.fillWidth: true
                    Kirigami.AbstractCard {
                        contentItem: Controls.Button {
                            text: qsTr("Impostazioni Plasma")
                            icon.name: "settings-configure"
                            onClicked: KrisBackend.launchTool("systemsettings")
                        }
                    }
                    Kirigami.AbstractCard {
                        contentItem: Controls.Button {
                            text: qsTr("Info Center")
                            icon.name: "hwinfo"
                            onClicked: KrisBackend.launchTool("kinfocenter")
                        }
                    }
                    Kirigami.AbstractCard {
                        contentItem: Controls.Button {
                            text: qsTr("Monitor di sistema")
                            icon.name: "utilities-system-monitor"
                            onClicked: DesktopBackend.launchTool("systemmonitor")
                        }
                    }
                    Kirigami.AbstractCard {
                        contentItem: Controls.Button {
                            text: qsTr("Terminale")
                            icon.name: "utilities-terminal"
                            onClicked: KrisBackend.launchTool("konsole")
                        }
                    }
                    Kirigami.AbstractCard {
                        contentItem: Controls.Button {
                            text: qsTr("Discover")
                            icon.name: "plasmadiscover"
                            onClicked: KrisBackend.launchTool("discover")
                        }
                    }
                }
            }
        }
    }

    Controls.Dialog {
        id: editActionDialog
        property string actionId: ""
        modal: true
        anchors.centerIn: parent
        width: Math.min(680, parent ? parent.width - 40 : 680)
        title: actionId.length > 0 ? qsTr("Modifica comando") : qsTr("Nuovo comando")
        standardButtons: Controls.Dialog.Save | Controls.Dialog.Cancel

        function openNew() {
            actionId = ""
            actionName.text = ""
            actionScript.text = ""
            actionConfirm.checked = false
            open()
        }

        function openFor(action) {
            actionId = action.id
            actionName.text = action.name
            actionScript.text = action.script
            actionConfirm.checked = action.confirm
            open()
        }

        contentItem: ColumnLayout {
            Controls.TextField {
                id: actionName
                Layout.fillWidth: true
                placeholderText: qsTr("Nome")
                maximumLength: 80
            }
            Controls.ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 260
                Controls.TextArea {
                    id: actionScript
                    placeholderText: qsTr("Comando o script Bash")
                    wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                }
            }
            Controls.CheckBox {
                id: actionConfirm
                text: qsTr("Chiedi conferma prima di eseguire")
            }
        }

        onAccepted: DesktopBackend.saveCustomAction(
            actionId, actionName.text, actionScript.text, actionConfirm.checked)
    }

    Controls.Dialog {
        id: runActionDialog
        property string actionId: ""
        property string actionName: ""
        modal: true
        anchors.centerIn: parent
        title: qsTr("Eseguire %1?").arg(actionName)
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            text: qsTr("Il comando verrà eseguito con i privilegi del tuo utente.")
            wrapMode: Text.WordWrap
        }
        onAccepted: DesktopBackend.runCustomAction(actionId)
    }

    Controls.Dialog {
        id: deleteActionDialog
        property string actionId: ""
        property string actionName: ""
        modal: true
        anchors.centerIn: parent
        title: qsTr("Eliminare %1?").arg(actionName)
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            text: qsTr("L'azione verrà rimossa dal file personale di krisNCC.")
            wrapMode: Text.WordWrap
        }
        onAccepted: DesktopBackend.removeCustomAction(actionId)
    }
}
