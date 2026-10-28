import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "components"

Window {
    id: rootWindow
    width: 1920
    height: 1080
    visible: true
    visibility: Window.FullScreen
    color: "#F2FFEF"
    title: "FCE - UIT Multi-Function Display System"

    // Biến lưu giờ hiện tại (ví dụ 13:30 sẽ là 13.5), tự cập nhật mỗi phút
    property real currentHourDecimal: {
        var now = new Date()
        return now.getHours() + now.getMinutes() / 60.0
    }

    Timer {
        interval: 60000 // Cập nhật mỗi 60 giây
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            rootWindow.currentHourDecimal = now.getHours() + now.getMinutes() / 60.0
            if (typeof weatherManager !== "undefined") {
                weatherManager.fetchWeather()
            }
        }
    }

    // Hàm tự động trả về nhãn trạng thái dựa theo khung giờ
    function getScheduleStatus(startH, endH) {
        if (currentHourDecimal < startH) return "SẮP DIỄN RA"
        if (currentHourDecimal >= startH && currentHourDecimal <= endH) return "ĐANG DIỄN RA"
        return "ĐÃ KẾT THÚC"
    }

    // Hàm tự động trả về màu sắc tương ứng
    function getScheduleColor(startH, endH) {
        if (currentHourDecimal < startH) return "#2563eb" // Xanh dương
        if (currentHourDecimal >= startH && currentHourDecimal <= endH) return "#16a34a" // Xanh lá
        return "#475569" // Xám trầm
    }

    // Dữ liệu Lịch hoạt động / Trực sảnh trong ngày
    ListModel {
        id: scheduleModel
        ListElement {
            time: "08:00 - 11:30"
            startHour: 8.0
            endHour: 11.5
            title: "Trực Văn phòng Khoa & Tiếp nhận hồ sơ sinh viên"
            location: "Phòng E6.2 - Tòa nhà E"
        }
        ListElement {
            time: "09:30 - 11:30"
            startHour: 9.5
            endHour: 11.5
            title: "Seminar Khoa học: Quang phổ cận hồng ngoại & Đánh giá nông sản"
            location: "Phòng E6.1 / Trực tuyến"
        }
        ListElement {
            time: "13:30 - 16:30"
            startHour: 13.5
            endHour: 16.5
            title: "Thực hành Đồ án & Nghiên cứu tại Phòng Lab Hệ thống Nhúng"
            location: "Phòng Lab KTMT - Tầng 6, Tòa E"
        }
        ListElement {
            time: "14:00 - 16:30"
            startHour: 14.0
            endHour: 16.5
            title: "Tiếp nhận đơn cứu xét Học vụ & Phát chứng chỉ GDQPAN"
            location: "Văn phòng Khoa E6.2"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ==================== 1. KHU VỰC HEADER ====================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 96
            color: "#004030"
            radius: 12

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 20

                // Logo Badge KTMT
                Rectangle {
                    Layout.preferredWidth: 223.04
                    Layout.preferredHeight: 80
                    radius: 12
                    color: "#004030"

                    Image {
                        anchors.fill: parent
                        anchors.margins: 6 // Tạo khoảng đệm nhỏ để logo không chạm sát viền khung
                        source: "assets/full_size_logo_fce.png"
                        
                        // Giữ nguyên tỉ lệ khung hình gốc của logo, không làm méo ảnh
                        fillMode: Image.PreserveAspectFit 
                        
                        // Làm mịn điểm ảnh khi thu nhỏ từ ảnh độ phân giải cao
                        smooth: true
                        mipmap: true
                    }
                }

                // Tên Trường & Khoa
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "ĐẠI HỌC QUỐC GIA TP.HCM - TRƯỜNG ĐẠI HỌC CÔNG NGHỆ THÔNG TIN"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#8d8d8d"
                    }
                    Text {
                        text: "KHOA KỸ THUẬT MÁY TÍNH"
                        font.pixelSize: 24
                        font.bold: true
                        color: "#ffffff"
                    }
                }

                // Khối Thời tiết / Môi trường Khu đô thị ĐHQG
                Rectangle {
                    Layout.preferredWidth: 280
                    Layout.preferredHeight: 68
                    radius: 10
                    color: "#00281e"
                    border.color: "#4A9782"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Text {
                            text: (typeof weatherManager !== "undefined") ? weatherManager.weatherIcon : "🌤️"
                            font.pixelSize: 32
                        }
                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: (typeof weatherManager !== "undefined") ? weatherManager.weatherText : "31°C | Độ ẩm: 68%"
                                font.pixelSize: 17
                                font.bold: true
                                color: "#ffffff"
                            }
                            Text {
                                text: "Khu đô thị ĐHQG-HCM" + ((typeof weatherManager !== "undefined" && weatherManager.weatherDescription !== "") ? (" • " + weatherManager.weatherDescription) : "")
                                font.pixelSize: 12
                                color: "#C7E9D3"
                            }
                        }
                    }
                }

                // Đồng hồ thời gian thực
                ClockWidget {
                    Layout.preferredWidth: 240
                    Layout.preferredHeight: 70
                }
            }
        }

        // ==================== 2. KHU VỰC NỘI DUNG CHÍNH ====================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // --------- CỘT TRÁI (62%): TỔ CHỨC KHOA & THÔNG BÁO MỚI NHẤT ---------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 62
                spacing: 16

                // Khối 1: Thông tin Ban Chủ nhiệm & Văn phòng Khoa
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 165
                    color: "#C7E9D3"
                    radius: 12
                    border.color: "#FFFFFF"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "🏛️ THÔNG TIN ĐƠN VỊ & BAN CHỦ NHIỆM KHOA"
                                font.pixelSize: 17
                                font.bold: true
                                color: "#004030"
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "🌐 Website: fce.uit.edu.vn"
                                font.pixelSize: 14
                                font.bold: true
                                color: "#8d8d8d"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 14

                            // Thẻ Trưởng khoa
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: "#ffffff"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4
                                    Text {
                                        text: "TRƯỞNG KHOA"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: "#003427"
                                    }
                                    Text {
                                        text: "TS. Nguyễn Minh Sơn"
                                        font.pixelSize: 20
                                        font.bold: true
                                        color: "#004030"
                                    }
                                    Text {
                                        text: "Phụ trách chung & Đào tạo, Khoa học Công nghệ"
                                        font.pixelSize: 13
                                        color: "#8d8d8d"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            // Thẻ Phó Trưởng khoa
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: "#ffffff"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4
                                    Text {
                                        text: "PHÓ TRƯỞNG KHOA"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: "#003427"
                                    }
                                    Text {
                                        text: "ThS. Phan Đình Duy"
                                        font.pixelSize: 20
                                        font.bold: true
                                        color: "#004030"
                                    }
                                    Text {
                                        text: "Danh hiệu Giảng viên của năm ĐHQG-HCM 2025"
                                        font.pixelSize: 13
                                        color: "#ff7b00"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            // Thẻ Văn phòng Khoa
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: "#ffffff"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4
                                    Text {
                                        text: "VĂN PHÒNG KHOA"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: "#22c55e"
                                    }
                                    Text {
                                        text: "Phòng E6.2 - Tòa nhà E"
                                        font.pixelSize: 19
                                        font.bold: true
                                        color: "#004030"
                                    }
                                    Text {
                                        text: "Giờ tiếp SV: 08:00 - 11:30 & 13:30 - 16:30"
                                        font.pixelSize: 13
                                        color: "#8d8d8d"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }

                // Khối 2: Danh sách Thông báo mới nhất từ RSS fce.uit.edu.vn
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#C7E9D3"
                    radius: 12
                    border.color: "#FFFFFF"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "📢 THÔNG BÁO & SỰ KIỆN MỚI NHẤT"
                                font.pixelSize: 17
                                font.bold: true
                                color: "#004030"
                                Layout.fillWidth: true
                            }
                        }

                        ListView {
                            id: rssListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 10
                            model: (typeof newsManager !== "undefined") ? newsManager.newsItems : []

                            delegate: Rectangle {
                                width: rssListView.width
                                height: 74
                                radius: 8
                                color: "#ffffff"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 14

                                    // Nhãn phân loại (SEMINAR / HỌC VỤ / THÔNG BÁO)
                                    Rectangle {
                                        Layout.preferredWidth: 105
                                        Layout.preferredHeight: 34
                                        radius: 6
                                        color: modelData.category === "SEMINAR" ? "#4A9782" :
                                               (modelData.category === "HỌC VỤ" ? "#FF7B00" : "#004030")

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.category
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: "white"
                                        }
                                    }

                                    // Tiêu đề thông báo
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "#004030"
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }

                                    // Ngày đăng
                                    Text {
                                        text: "📅 " + modelData.date
                                        font.pixelSize: 13
                                        color: "#8d8d8d"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --------- CỘT PHẢI (38%): LỊCH TRONG NGÀY & TRẠM IOT ---------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 38
                spacing: 16

                // Khối 1: Lịch công tác & Sự kiện trong ngày
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#c7e9d3"
                    radius: 12
                    border.color: "#ffffff"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        Text {
                            text: "🗓️ LỊCH HOẠT ĐỘNG & SỰ KIỆN TRONG NGÀY"
                            font.pixelSize: 17
                            font.bold: true
                            color: "#004030"
                        }

                        ListView {
                            id: scheduleListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 10
                            model: scheduleModel

                            delegate: Rectangle {
                                width: scheduleListView.width
                                height: 86
                                radius: 8
                                color: "#ffffff"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "⏰ " + model.time
                                            font.pixelSize: 14
                                            font.bold: true
                                            color: "#004030"
                                            Layout.fillWidth: true
                                        }
                                        Rectangle {
                                            width: 115
                                            height: 24
                                            radius: 4
                                            color: rootWindow.getScheduleColor(model.startHour, model.endHour)
                                            Text {
                                                anchors.centerIn: parent
                                                text: rootWindow.getScheduleStatus(model.startHour, model.endHour)
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: "white"
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.title
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: "#004030"
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "📍 " + model.location
                                        font.pixelSize: 13
                                        color: "#8d8d8d"
                                    }
                                }
                            }
                        }
                    }
                }

                // Khối 2: Giám sát Node Nhúng & Bộ môn Chuyên ngành
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190
                    color: "#c7e9d3"
                    radius: 12
                    border.color: "#ffffff"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10

                        Text {
                            text: "⚙️ CÁC BỘ MÔN CHUYÊN NGÀNH & TRẠNG THÁI TRẠM HIỂN THỊ"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#004030"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.fillWidth: true
                                height: 54
                                radius: 8
                                color: "#ffffff"
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        text: "Hệ thống Nhúng & IoT"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#e7b019"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Text {
                                        text: "Embedded Systems & IoT"
                                        font.pixelSize: 12
                                        color: "#8d8d8d"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 54
                                radius: 8
                                color: "#ffffff"
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        text: "Thiết kế Vi mạch"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "#047519"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Text {
                                        text: "IC Design & Hardware"
                                        font.pixelSize: 12
                                        color: "#8d8d8d"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }

                        // Dòng thông số kỹ thuật của Box nhúng
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: "#ffffff"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14

                                Text {
                                    text: "🟢 Trạng thái Kiosk: Online"
                                    font.pixelSize: 13
                                    color: "#22c55e"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "🌡️ Nhiệt độ sảnh E6: 26.5°C"
                                    font.pixelSize: 13
                                    color: "#8d8d8d"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "🔄 Tự động cập nhật: 60 giây"
                                    font.pixelSize: 13
                                    color: "#4A9782"
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==================== 3. KHU VỰC FOOTER (CHỮ CHẠY) ====================
        NewsBanner {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
        }
    }
}