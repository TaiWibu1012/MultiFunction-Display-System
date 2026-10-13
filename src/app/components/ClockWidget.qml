import QtQuick
import QtQuick.Layouts

Item {
    width: 300
    height: 100

    property string currentTime: "00:00:00"
    property string currentDate: "Thứ Hai, 01/01/2026"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var date = new Date()
            currentTime = date.toLocaleTimeString(Qt.locale("vi_VN"), "HH:mm:ss")
            currentDate = date.toLocaleDateString(Qt.locale("vi_VN"), "dddd, dd/MM/yyyy")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        Text {
            text: currentTime
            font.pixelSize: 48
            font.bold: true
            color: "white"
            Layout.alignment: Qt.AlignRight
        }
        Text {
            text: currentDate
            font.pixelSize: 24
            color: "#94a3b8"
            Layout.alignment: Qt.AlignRight
        }
    }
}
