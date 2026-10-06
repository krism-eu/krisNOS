import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    padding: 22

    function mibText(value) {
        const mib = Number(value || 0)
        if (mib >= 1024)
            return (mib / 1024).toFixed(1) + " GiB"
        return mib + " MiB"
    }

    Component.onCompleted: PackageBackend.refreshCleanup()

    ColumnLayout {
        width: parent.width
        spacing: 12

        Controls.Label {
            text: qsTr("Pulizia")
            font.bold: true
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
        }
        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Nessuna pulizia è automatica. Le tre operazioni sono separate per non sacrificare rollback utili senza una scelta esplicita.")
            opacity: 0.78
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: GridLayout {
                columns: 2
                columnSpacing: 18
                rowSpacing: 8
                Controls.Label { text: qsTr("Generazioni sistema"); font.bold: true }
                Controls.Label { text: PackageBackend.cleanupStatus.systemGenerations ?? "?" }
                Controls.Label { text: qsTr("Generazioni profilo app"); font.bold: true }
                Controls.Label { text: PackageBackend.cleanupStatus.profileGenerations ?? "?" }
                Controls.Label { text: qsTr("Store usato"); font.bold: true }
                Controls.Label { text: root.mibText(PackageBackend.cleanupStatus.storeUsedMiB) }
                Controls.Label { text: qsTr("Spazio libero"); font.bold: true }
                Controls.Label { text: root.mibText(PackageBackend.cleanupStatus.storeFreeMiB) }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: RowLayout {
                ColumnLayout {
                    Layout.fillWidth: true
                    Controls.Label { text: qsTr("Cronologia app personali"); font.bold: true }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Rimuove soltanto le versioni non correnti del profilo Nix più vecchie di 30 giorni. Le app attualmente installate restano intatte.")
                        opacity: 0.75
                    }
                }
                Controls.Button {
                    text: qsTr("Pulisci > 30 giorni")
                    enabled: !PackageBackend.busy
                    onClicked: profileDialog.open()
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: RowLayout {
                ColumnLayout {
                    Layout.fillWidth: true
                    Controls.Label { text: qsTr("Vecchie generazioni di sistema"); font.bold: true }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Mantiene le ultime 5 generazioni rispetto a quella corrente. Le generazioni eliminate non potranno più essere usate per il rollback.")
                        opacity: 0.75
                    }
                }
                Controls.Button {
                    text: qsTr("Mantieni ultime 5")
                    enabled: !PackageBackend.busy
                    onClicked: systemDialog.open()
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: RowLayout {
                ColumnLayout {
                    Layout.fillWidth: true
                    Controls.Label { text: qsTr("Pacchetti non più usati") ; font.bold: true }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Esegue la garbage collection dello store. Vengono rimossi soltanto i path non più raggiungibili da profili, generazioni o altre radici Nix conservate.")
                        opacity: 0.75
                    }
                }
                Controls.Button {
                    text: qsTr("Libera store")
                    enabled: !PackageBackend.busy
                    onClicked: storeDialog.open()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Controls.Button {
                text: qsTr("Rileggi")
                enabled: !PackageBackend.busy
                onClicked: PackageBackend.refreshCleanup()
            }
            Item { Layout.fillWidth: true }
            Controls.BusyIndicator {
                running: PackageBackend.busy
                visible: running
            }
        }
    }

    Controls.Dialog {
        id: profileDialog
        modal: true
        width: Math.min(560, root.width - 60)
        title: qsTr("Pulire cronologia app?")
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
        onAccepted: PackageBackend.cleanupProfileHistory()
        contentItem: Controls.Label {
            width: 500
            wrapMode: Text.WordWrap
            text: qsTr("Saranno eliminate solo le versioni non correnti del profilo app più vecchie di 30 giorni. Questa operazione riduce la cronologia di rollback delle app personali.")
        }
    }

    Controls.Dialog {
        id: systemDialog
        modal: true
        width: Math.min(560, root.width - 60)
        title: qsTr("Ridurre le generazioni di sistema?")
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
        onAccepted: PackageBackend.cleanupSystemGenerations()
        contentItem: Controls.Label {
            width: 500
            wrapMode: Text.WordWrap
            text: qsTr("Verranno mantenute le ultime 5 generazioni rispetto a quella corrente. Le generazioni più vecchie eliminate non saranno più selezionabili per il rollback.")
        }
    }

    Controls.Dialog {
        id: storeDialog
        modal: true
        width: Math.min(560, root.width - 60)
        title: qsTr("Liberare lo store Nix?")
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
        onAccepted: PackageBackend.cleanupStore()
        contentItem: Controls.Label {
            width: 500
            wrapMode: Text.WordWrap
            text: qsTr("Saranno cancellati solo i path dello store non più referenziati. Le generazioni che hai scelto di conservare continueranno a proteggere i pacchetti necessari al loro rollback.")
        }
    }
}
