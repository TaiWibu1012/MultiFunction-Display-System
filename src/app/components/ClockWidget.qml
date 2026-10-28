import QtQuick
import QtQuick.Layouts

Item {
    id: clockRoot
    implicitWidth: 260
    implicitHeight: 70

    property string timeString: "00:00:00"
    property string dateString: "Đang đồng bộ..."

    function updateClock() {
        var now = new Date()
        timeString = Qt.formatTime(now, "HH:mm:ss")
        var days = ["Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"]
        dateString = days[now.getDay()] + ", " + Qt.formatDate(now, "dd/MM/yyyy")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockRoot.updateClock()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        Text {
            text: clockRoot.timeString
            font.pixelSize: 32
            font.bold: true
            color: "#FFE100"
            Layout.alignment: Qt.AlignRight
        }

        Text {
            text: clockRoot.dateString
            font.pixelSize: 14
            color: "#C7E9D3"
            Layout.alignment: Qt.AlignRight
        }
    }
}
