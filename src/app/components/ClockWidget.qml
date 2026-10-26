import QtQuick
import QtQuick.Layouts

Item {
    id: clockRoot
    implicitWidth: 320
    implicitHeight: 90

    property string currentTime: "00:00:00"
    property string currentDate: "Đang cập nhật..."

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date()
            currentTime = date.toLocaleTimeString(Qt.locale("vi_VN"), "HH:mm:ss")
            currentDate = date.toLocaleDateString(Qt.locale("vi_VN"), "dddd, dd/MM/yyyy")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 2
        Text {
            text: clockRoot.currentTime
            font.pixelSize: 48
            font.bold: true
            color: "#38bdf8"
            Layout.alignment: Qt.AlignRight
        }
        Text {
            text: clockRoot.currentDate
            font.pixelSize: 20
            font.weight: Font.Medium
            color: "#fbbf24"
            Layout.alignment: Qt.AlignRight
        }
    }
}
