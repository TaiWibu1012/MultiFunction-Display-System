import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Window {
    id: rootWindow
    width: 1920
    height: 1080
    visible: true
    // Ép chạy toàn màn hình (Kiosk Mode)
    visibility: Window.FullScreen 
    color: "#0f172a" // Nền tối (Dark mode) sang trọng cho màn hình sảnh

    // Bố cục chính
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        // Khu vực Header: Đồng hồ, Logo cơ quan, Thời tiết
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            
            // Text { text: "LOGO" ... }
            // components.ClockWidget { ... }
            // components.WeatherCard { ... }
        }

        // Khu vực Thân: Bảng tin chính và Lịch trình
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 30

            // Cột bên trái: Hiển thị Video/Hình ảnh hoặc Bảng tin lớn
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 2 // Chiếm 2/3 màn hình
                color: "#1e293b"
                radius: 15
                Text { anchors.centerIn: parent; text: "Khu vực Thông báo / Media"; color: "white" }
            }

            // Cột bên phải: Lịch trình công tác
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1 // Chiếm 1/3 màn hình
                color: "#1e293b"
                radius: 15
                Text { anchors.centerIn: parent; text: "Lịch trình hôm nay"; color: "white" }
            }
        }

        // Khu vực Footer: Dòng chữ chạy (Marquee text) tin tức vắn tắt
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#b91c1c" // Đỏ cảnh báo hoặc xanh tùy ngữ cảnh
            radius: 10
            
            // components.NewsBanner { ... }
        }
    }
}
