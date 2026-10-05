import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    padding: 22
    Component.onCompleted: {
        KrisBackend.refreshSoftware()
        KrisBackend.refreshDistroboxes()
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        Controls.Label { text: qsTr("App e ambienti"); font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2 }
        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Le app normali vivono nel profilo Nix o in Flatpak. Distrobox serve per ambienti Linux separati; Podman resta un dettaglio interno.")
            opacity: 0.78
        }

        Controls.TabBar {
            id: tabs
            Layout.fillWidth: true
            Controls.TabButton { text: qsTr("Nix") }
            Controls.TabButton { text: qsTr("Flatpak") }
            Controls.TabButton { text: qsTr("Distrobox") }
        }

        StackLayout {
            Layout.fillWidth: true
            currentIndex: tabs.currentIndex

            ColumnLayout {
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Controls.TextField { id: search; Layout.fillWidth: true; placeholderText: qsTr("Cerca in nixpkgs…"); onAccepted: KrisBackend.searchSoftware(text) }
                    Controls.Button { text: qsTr("Cerca"); enabled: search.text.trim().length > 0 && !KrisBackend.busy; onClicked: KrisBackend.searchSoftware(search.text) }
                    Controls.CheckBox {
                        id: allowUnfree
                        text: qsTr("Non libere")
                        enabled: !KrisBackend.busy
                    }
                    Controls.Button {
                        text: qsTr("Aggiornamenti")
                        enabled: !KrisBackend.busy
                        onClicked: KrisBackend.previewSoftwareUpdates(allowUnfree.checked)
                    }
                }
                Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Installa aggiunge l'app al tuo profilo senza rebuild. Prova usa nix run e non installa nulla."); opacity: 0.72 }
                Repeater {
                    model: KrisBackend.searchResults
                    delegate: Kirigami.AbstractCard {
                        required property var modelData
                        Layout.fillWidth: true
                        contentItem: RowLayout {
                            ColumnLayout {
                                Layout.fillWidth: true
                                Controls.Label { text: modelData.name || modelData.attribute; font.bold: true }
                                Controls.Label { Layout.fillWidth: true; text: (modelData.version ? modelData.version + " · " : "") + (modelData.description || modelData.attribute); elide: Text.ElideRight; opacity: 0.75 }
                            }
                            Controls.Button { text: qsTr("Prova"); onClicked: KrisBackend.runSoftware(modelData.attribute, allowUnfree.checked) }
                            Controls.Button { text: qsTr("Installa"); enabled: !KrisBackend.busy; onClicked: KrisBackend.addSoftware(modelData.attribute, allowUnfree.checked) }
                        }
                    }
                }
                Controls.Label { text: qsTr("Installate con Nix (%1)").arg(KrisBackend.softwareItems.length); font.bold: true }
                Repeater {
                    model: KrisBackend.softwareItems
                    delegate: Kirigami.AbstractCard {
                        required property var modelData
                        Layout.fillWidth: true
                        contentItem: RowLayout {
                            Controls.Label { Layout.fillWidth: true; text: modelData.name; font.bold: true }
                            Controls.Button { text: qsTr("Rimuovi"); enabled: !KrisBackend.busy; onClicked: KrisBackend.removeSoftware(modelData.name) }
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: 12
                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        Controls.Label { text: qsTr("Flatpak"); font.bold: true }
                        Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Flatpak resta completamente mutabile. La gestione nativa verrà portata nel CC senza cambiare la base Nix; nel bootstrap puoi usare Discover."); opacity: 0.75 }
                        Controls.Button { text: qsTr("Apri Discover"); icon.name: "plasmadiscover"; onClicked: KrisBackend.launchTool("discover") }
                    }
                }
            }

            ColumnLayout {
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Controls.Label { Layout.fillWidth: true; text: qsTr("Ambienti Distrobox"); font.bold: true }
                    Controls.Button { text: qsTr("Aggiorna"); onClicked: KrisBackend.refreshDistroboxes() }
                }
                Repeater {
                    model: KrisBackend.distroboxes
                    delegate: Kirigami.AbstractCard {
                        required property string modelData
                        Layout.fillWidth: true
                        contentItem: Controls.Label { text: modelData }
                    }
                }
                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: KrisBackend.distroboxes.length === 0
                    text: qsTr("Nessun ambiente Distrobox rilevato.")
                }
            }
        }
    }
}
