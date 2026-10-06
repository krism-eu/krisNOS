import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.krisncc

Kirigami.ApplicationWindow {
    id: root
    width: 1280
    height: 820
    minimumWidth: 920
    minimumHeight: 640
    visible: true
    title: qsTr("krisNCC")
    palette.highlight: Qt.darker(Kirigami.Theme.highlightColor, 1.12)
    property int currentSection: 0
    readonly property bool globalBusy: KrisBackend.busy || DesktopBackend.busy
    readonly property bool globalCanCancel:
        (KrisBackend.busy && KrisBackend.canCancel)
        || (DesktopBackend.busy && DesktopBackend.canCancel)

    readonly property var navigationModel: [
        { section: 0, label: qsTr("Home"), icon: "go-home" },
        { section: 1, label: qsTr("Sistema"), icon: "computer" },
        { section: 2, label: qsTr("App"), icon: "package-x-generic" },
        { section: 3, label: qsTr("Config"), icon: "settings-configure" },
        { section: 4, label: qsTr("Ripristino"), icon: "edit-undo" },
        { section: 5, label: qsTr("Strumenti"), icon: "tools-wizard" }
    ]

    function showIndex(index) {
        if (!globalBusy && index >= 0 && index < navigationModel.length)
            currentSection = index
    }

    function sectionTitle(index) {
        for (let i = 0; i < navigationModel.length; ++i)
            if (navigationModel[i].section === index)
                return navigationModel[i].label
        return qsTr("krisNCC")
    }

    onClosing: function(close) {
        if (root.globalBusy) {
            close.accepted = false
            busyDialog.open()
        }
    }

    pageStack.globalToolBar.style: Kirigami.ApplicationHeaderStyle.None
    pageStack.initialPage: Kirigami.Page {
        padding: 0

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.preferredWidth: root.width < 1080 ? 205 : 228
                Layout.fillHeight: true
                color: Kirigami.Theme.alternateBackgroundColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: Kirigami.Units.largeSpacing
                        Controls.Label {
                            text: qsTr("krisNCC")
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 4
                        }
                        Controls.Label {
                            text: qsTr("Control Center · krisNOS")
                            opacity: UiMetrics.secondaryOpacity
                        }
                    }

                    Repeater {
                        model: root.navigationModel
                        delegate: Controls.ItemDelegate {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            enabled: !root.globalBusy || checked
                            checkable: true
                            checked: root.currentSection === modelData.section
                            onClicked: root.showIndex(modelData.section)

                            contentItem: RowLayout {
                                spacing: Kirigami.Units.largeSpacing
                                Kirigami.Icon {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    source: modelData.icon
                                    color: parent.parent.checked
                                        ? Kirigami.Theme.highlightColor
                                        : Kirigami.Theme.textColor
                                }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    font.bold: true
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                                    color: parent.parent.checked
                                        ? Kirigami.Theme.highlightColor
                                        : Kirigami.Theme.textColor
                                }
                            }

                            background: Rectangle {
                                radius: 9
                                color: parent.checked
                                    ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                              Kirigami.Theme.highlightColor.g,
                                              Kirigami.Theme.highlightColor.b, 0.12)
                                    : parent.hovered
                                      ? Qt.rgba(Kirigami.Theme.textColor.r,
                                                Kirigami.Theme.textColor.g,
                                                Kirigami.Theme.textColor.b, 0.05)
                                      : "transparent"
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 3
                                    height: parent.height - 12
                                    radius: 2
                                    visible: parent.parent.checked
                                    color: Kirigami.Theme.highlightColor
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Sync e applicazione sempre manuali")
                        opacity: UiMetrics.secondaryOpacity
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Qt.rgba(Kirigami.Theme.textColor.r,
                               Kirigami.Theme.textColor.g,
                               Kirigami.Theme.textColor.b, 0.10)
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    color: Kirigami.Theme.backgroundColor
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UiMetrics.pageMargin
                        anchors.rightMargin: UiMetrics.pageMargin
                        Controls.Label {
                            Layout.fillWidth: true
                            text: root.sectionTitle(root.currentSection)
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3
                        }
                        Controls.BusyIndicator {
                            running: root.globalBusy
                            visible: running
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                        }
                        Controls.Label {
                            text: qsTr("v%1").arg(Qt.application.version)
                            opacity: UiMetrics.secondaryOpacity
                        }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.currentSection
                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        active: root.currentSection === 0
                        sourceComponent: Component {
                            DashboardModule {
                                onOpenRequested: function(i) { root.showIndex(i) }
                            }
                        }
                    }
                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        active: root.currentSection === 1
                        sourceComponent: Component { SystemModule {} }
                    }
                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        active: root.currentSection === 2
                        sourceComponent: Component { SoftwareModule {} }
                    }
                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        active: root.currentSection === 3
                        sourceComponent: Component { ConfigurationModule {} }
                    }
                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        active: root.currentSection === 4
                        sourceComponent: Component { RecoveryModule {} }
                    }
                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        active: root.currentSection === 5
                        sourceComponent: Component { ToolsModule {} }
                    }
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    visible: KrisBackend.lastMessage.length > 0
                          || DesktopBackend.lastMessage.length > 0
                    text: DesktopBackend.lastMessage.length > 0
                        ? DesktopBackend.lastMessage
                        : KrisBackend.lastMessage
                    type: Kirigami.MessageType.Information
                }
            }
        }
    }

    Controls.Dialog {
        id: busyDialog
        modal: true
        anchors.centerIn: parent
        implicitWidth: 500
        title: qsTr("Operazione in corso")
        standardButtons: root.globalCanCancel ? Controls.Dialog.Cancel : Controls.Dialog.Close
        onRejected: {
            if (KrisBackend.busy && KrisBackend.canCancel)
                KrisBackend.cancelCurrentOperation()
            else if (DesktopBackend.busy && DesktopBackend.canCancel)
                DesktopBackend.cancelCurrentOperation()
        }
        contentItem: Controls.Label {
            width: 440
            text: root.globalCanCancel
                ? qsTr("L'operazione può essere annullata. krisNCC resterà aperto finché il processo non termina.")
                : qsTr("Questa modifica non può essere interrotta in sicurezza. krisNCC resterà aperto fino al completamento.")
            wrapMode: Text.WordWrap
        }
    }
}
