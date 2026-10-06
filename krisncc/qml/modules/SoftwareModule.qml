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

    Component.onCompleted: KrisBackend.refreshSoftware()

    ColumnLayout {
        width: parent.width
        spacing: 12

        Controls.Label {
            text: qsTr("App e ambienti")
            font.bold: true
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
        }
        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Le app installate da krisNCC vivono nel profilo Nix. Flatpak resta a Discover; Distrobox resta l'ambiente Linux separato.")
            opacity: 0.78
        }

        Controls.TabBar {
            id: tabs
            Layout.fillWidth: true
            onCurrentIndexChanged: {
                if (currentIndex === 1)
                    KrisBackend.refreshDistroboxes()
            }
            Controls.TabButton { text: qsTr("Nix") }
            Controls.TabButton { text: qsTr("Distrobox") }
        }

        StackLayout {
            Layout.fillWidth: true
            currentIndex: tabs.currentIndex

            ColumnLayout {
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Controls.TextField {
                        id: search
                        Layout.fillWidth: true
                        placeholderText: qsTr("Cerca in nixpkgs…")
                        onAccepted: if (!root.globalBusy()) KrisBackend.searchSoftware(text)
                    }
                    Controls.Button {
                        text: qsTr("Cerca")
                        enabled: search.text.trim().length > 0 && !root.globalBusy()
                        onClicked: KrisBackend.searchSoftware(search.text)
                    }
                    Controls.CheckBox {
                        id: allowUnfree
                        text: qsTr("Non libere")
                        enabled: !root.globalBusy()
                    }
                    Controls.Button {
                        text: qsTr("Aggiornamenti")
                        enabled: !root.globalBusy()
                        onClicked: KrisBackend.previewSoftwareUpdates(allowUnfree.checked)
                    }
                }

                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Installa aggiunge l'app al tuo profilo senza rebuild. Prova usa nix run e non installa nulla.")
                    opacity: 0.72
                }

                Repeater {
                    model: KrisBackend.searchResults
                    delegate: Kirigami.AbstractCard {
                        required property var modelData
                        Layout.fillWidth: true
                        contentItem: RowLayout {
                            ColumnLayout {
                                Layout.fillWidth: true
                                Controls.Label {
                                    text: modelData.name || modelData.attribute
                                    font.bold: true
                                }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: (modelData.version ? modelData.version + " · " : "")
                                        + (modelData.description || modelData.attribute)
                                    elide: Text.ElideRight
                                    opacity: 0.75
                                }
                            }
                            Controls.Button {
                                text: qsTr("Prova")
                                enabled: !root.globalBusy()
                                onClicked: KrisBackend.runSoftware(modelData.attribute, allowUnfree.checked)
                            }
                            Controls.Button {
                                text: qsTr("Installa")
                                enabled: !root.globalBusy()
                                onClicked: KrisBackend.addSoftware(modelData.attribute, allowUnfree.checked)
                            }
                        }
                    }
                }

                Controls.Label {
                    text: qsTr("Installate con Nix (%1)").arg(KrisBackend.softwareItems.length)
                    font.bold: true
                }

                Repeater {
                    model: KrisBackend.softwareItems
                    delegate: Kirigami.AbstractCard {
                        required property var modelData
                        Layout.fillWidth: true
                        contentItem: RowLayout {
                            Controls.Label {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.bold: true
                            }
                            Controls.Button {
                                text: qsTr("Rimuovi")
                                enabled: !root.globalBusy()
                                onClicked: KrisBackend.removeSoftware(modelData.name)
                            }
                        }
                    }
                }

                Controls.Button {
                    text: qsTr("Apri Discover")
                    icon.name: "plasmadiscover"
                    enabled: !root.globalBusy()
                    onClicked: KrisBackend.launchTool("discover")
                }
            }

            ColumnLayout {
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Controls.Label {
                        Layout.fillWidth: true
                        text: qsTr("Container Distrobox presenti (%1)").arg(KrisBackend.distroboxes.length)
                        font.bold: true
                    }
                    Controls.Button {
                        text: qsTr("Aggiorna")
                        enabled: !root.globalBusy()
                        onClicked: KrisBackend.refreshDistroboxes()
                    }
                }

                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Qui krisNCC mostra solo l'inventario. Creazione, accesso e rimozione restano a un gestore esterno dedicato.")
                    opacity: 0.72
                }

                Repeater {
                    model: KrisBackend.distroboxes
                    delegate: Kirigami.AbstractCard {
                        required property string modelData
                        Layout.fillWidth: true
                        contentItem: Controls.Label {
                            text: {
                                const parts = modelData.split("|")
                                return parts.length > 1 ? parts[1].trim() : modelData.trim()
                            }
                            font.bold: true
                        }
                    }
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: KrisBackend.distroboxes.length === 0
                    text: qsTr("Nessun container Distrobox rilevato.")
                }
            }
        }
    }
}
