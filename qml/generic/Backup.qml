import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.1
import Qt.labs.settings 1.0
import BackupTools 1.0
import "UI" 1.0


Item {
    id: main
    visible: i.knownBattery > -1
    anchors { fill: parent; leftMargin: 20; topMargin: 20 }

    Timer {
        id: attemptLookup
        running: false
        interval: 12000
    }

    ColumnLayout {
        ColumnLayout {
            Text {
                text: "Options"
                font.pointSize: 14
                font.bold: true
            }
            id: options
            property int value: 0
            RowLayout {
                visible: !i.backMethods && attemptLookup.running
                Text {
                    text: "Loading Backup Options"
                    font.pointSize: 12
                }
                BusyIndicator {
                    width: parent.height
                    height: parent.height
                }
            }
            ColumnLayout {
                Repeater {
                    model: i.backMethods
                    delegate: CheckBox {
                        text: i.backNames[index] + " (" + i.backSizes[index].toFixed(1) + " MB)" // index
                        onCheckedChanged: {
                            if (checked) {
                                options.value += 1 << index;
                                totalText.totalVal += i.backSizes[index];
                            } else {
                                options.value -= 1 << index;
                                totalText.totalVal -= i.backSizes[index]
                            }
                        }
                    }
                }
            }
            Text {
                visible: i.backMethods
                id: totalText
                property double totalVal: 0.0
                text: "Total: " + totalVal.toFixed(1) + " MB"
                font.pointSize: 12
            }
        }

        Button {
            visible: !i.backMethods && !attemptLookup.running
            text: "Load Backup Options"
            onClicked: { totalText.totalVal = 0; i.backupQuery(); attemptLookup.start(); }
        }

        RowLayout {
            visible: i.backMethods
            FileDialog {
                id: backup_files
                title: "Choose backup filename"
                folder: settings.backupFolder
                onAccepted: {
                    i.backup(fileUrl, options.value)
                    settings.backupFolder = folder;
                }
                selectExisting: false

                nameFilters: [ "Blackberry Backup (*.bbb)" ]
            }
            FileDialog {
                id: restore_files
                title: "Select restore file"
                folder: settings.backupFolder
                onAccepted: {
                    i.restore(fileUrl, options.value)
                    settings.backupFolder = folder;
                }

                nameFilters: [ "Blackberry Backup (*.bbb)" ]
            }

            Button {
                text: "Create backup"
                enabled: !i.installing && !i.backing && !i.restoring && options.value != 0
                onClicked: backup_files.open();
            }
            Button {
                text: "Restore backup"
                enabled: !i.installing && !i.backing && !i.restoring && options.value != 0
                onClicked: restore_files.open();
            }
        }
    }
    Rectangle {
        id: progressBar
        visible: i.backing || i.restoring
        anchors {bottom: parent.bottom; bottomMargin: 20; horizontalCenter: parent.horizontalCenter }
        height: 66; width: parent.width - parent.width / 4; radius: 8
        z: 5;
        color: "gray"
        opacity: 0.95
        Column {
            anchors {verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: parent.width / 2 - 150 }
            Text {
                font.pointSize: 12
                text: (i.backing ? "Creating" : "Restoring") + " Backup (" + i.backProgress + "%)";
            }
            Row {
                spacing: 10
                Text {
                    font.pointSize: 12
                    text: i.backStatus + " (" + i.backCurProgress + "%)";
                }
                BusyIndicator {
                    width: parent.height
                    height: parent.height
                }
            }
        }
    }
}
