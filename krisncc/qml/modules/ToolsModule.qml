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

    readonly property string txtMergePresetName: qsTr("Unisci TXT di una cartella")
    readonly property string promptPresetName: qsTr("Prompt Bash colorato")

    readonly property string txtMergePresetScript: [
        "folder=\"$(kdialog --getexistingdirectory \"$HOME\" --title \"Seleziona cartella con file TXT\")\" || exit 0",
        "[ -n \"$folder\" ] || exit 0",
        "parent=\"$(dirname \"$folder\")\"",
        "name=\"$(basename \"$folder\")\"",
        "output=\"$parent/${name}-uniti.txt\"",
        "shopt -s nullglob nocaseglob",
        "files=(\"$folder\"/*.txt)",
        "if [ \"${#files[@]}\" -eq 0 ]; then",
        "  kdialog --sorry \"Nessun file TXT trovato nella cartella selezionata.\"",
        "  exit 1",
        "fi",
        ": > \"$output\"",
        "for file in \"${files[@]}\"; do",
        "  printf '===== %s =====\\n\\n' \"$(basename \"$file\")\" >> \"$output\"",
        "  cat -- \"$file\" >> \"$output\"",
        "  printf '\\n\\n' >> \"$output\"",
        "done",
        "kdialog --msgbox \"Creato: $output\""
    ].join("\n")

    readonly property string promptPresetScript: [
        "rc=\"$HOME/.bashrc\"",
        "begin='# >>> krisNCC prompt >>>'",
        "end='# <<< krisNCC prompt <<<'",
        "tmp=\"$(mktemp)\"",
        "skip=0",
        "if [ -f \"$rc\" ]; then",
        "  while IFS= read -r line || [ -n \"$line\" ]; do",
        "    if [ \"$line\" = \"$begin\" ]; then skip=1; continue; fi",
        "    if [ \"$line\" = \"$end\" ]; then skip=0; continue; fi",
        "    [ \"$skip\" -eq 1 ] || printf '%s\\n' \"$line\" >> \"$tmp\"",
        "  done < \"$rc\"",
        "  chmod --reference=\"$rc\" \"$tmp\"",
        "else",
        "  chmod 600 \"$tmp\"",
        "fi",
        "printf '%s\\n' \"$begin\" >> \"$tmp\"",
        "printf '%s\\n' \"PS1='\\n\\[\\e[1;36m\\]\\u\\[\\e[0m\\]@\\[\\e[1;35m\\]\\h\\[\\e[0m\\] \\[\\e[1;33m\\]\\w\\[\\e[0m\\]\\n\\[\\e[1;32m\\]\\$\\[\\e[0m\\] '\" >> \"$tmp\"",
        "printf '%s\\n' \"$end\" >> \"$tmp\"",
        "mv -- \"$tmp\" \"$rc\"",
        "kdialog --msgbox \"Prompt salvato in ~/.bashrc. Apri un nuovo terminale.\""
    ].join("\n")

    function hasCustomAction(name) {
        for (let i = 0; i < DesktopBackend.customActions.length; ++i) {
            if (DesktopBackend.customActions[i].name === name)
                return true
        }
        return false
    }

    function addPreset(name, script, confirm) {
        if (!hasCustomAction(name)
                && DesktopBackend.customActions.length < DesktopBackend.customActionLimit)
            DesktopBackend.saveCustomAction("", name, script, confirm)
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

                Controls.Label {
                    text: qsTr("Preset pronti")
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: width > 760 ? 2 : 1
                    uniformCellWidths: true
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: [
                            {
                                name: root.txtMergePresetName,
                                description: qsTr("Sceglie graficamente una cartella, unisce i file TXT e salva il risultato nella cartella madre."),
                                script: root.txtMergePresetScript,
                                confirm: false
                            },
                            {
                                name: root.promptPresetName,
                                description: qsTr("Imposta in ~/.bashrc il prompt colorato utente/host/percorso con separazione visiva tra i comandi."),
                                script: root.promptPresetScript,
                                confirm: true
                            }
                        ]
                        delegate: Kirigami.AbstractCard {
                            required property var modelData
                            Layout.fillWidth: true
                            contentItem: ColumnLayout {
                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.bold: true
                                }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    text: modelData.description
                                    opacity: 0.72
                                }
                                Controls.Button {
                                    text: root.hasCustomAction(modelData.name)
                                        ? qsTr("Presente") : qsTr("Aggiungi")
                                    enabled: !root.globalBusy()
                                          && !root.hasCustomAction(modelData.name)
                                          && DesktopBackend.customActions.length < DesktopBackend.customActionLimit
                                    onClicked: root.addPreset(
                                        modelData.name, modelData.script, modelData.confirm)
                                }
                            }
                        }
                    }
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: DesktopBackend.customActions.length === 0
                    type: Kirigami.MessageType.Information
                    text: qsTr("Nessun comando personale salvato. Puoi aggiungere uno dei preset qui sopra o crearne uno nuovo.")
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
