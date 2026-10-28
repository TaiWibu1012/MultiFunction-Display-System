import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "components"

Window {
    id: rootWindow
    visible: true
    visibility: Window.FullScreen
    color: "#F2FFEF"
    title: "MFDS - Multi-Function Display System"

    // Decimal hour for dynamic schedule state (e.g. 14:30 -> 14.5)
    property real currentHourDecimal: {
        var now = new Date()
        return now.getHours() + now.getMinutes() / 60.0
    }

    Timer {
        interval: 30000 // Refresh schedule status every 30 seconds
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

    function getScheduleStatus(timeSlot) {
        if (!timeSlot || timeSlot.indexOf("-") === -1) return "SẮP DIỄN RA"
        var parts = timeSlot.split("-")
        var startParts = parts[0].trim().split(":")
        var endParts = parts[1].trim().split(":")
        var startH = parseFloat(startParts[0]) + (parseFloat(startParts[1]) || 0) / 60.0
        var endH = parseFloat(endParts[0]) + (parseFloat(endParts[1]) || 0) / 60.0

        if (currentHourDecimal < startH) return "SẮP DIỄN RA"
        if (currentHourDecimal >= startH && currentHourDecimal <= endH) return "ĐANG DIỄN RA"
        return "ĐÃ KẾT THÚC"
    }

    function getScheduleColor(timeSlot) {
        var status = getScheduleStatus(timeSlot)
        if (status === "ĐANG DIỄN RA") return "#16a34a" // Vivid Green
        if (status === "SẮP DIỄN RA") return "#2563eb"  // Blue
        return "#64748b" // Slate grey
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.round(rootWindow.width * 0.015)
        anchors.rightMargin: Math.round(rootWindow.width * 0.015)
        anchors.topMargin: Math.round(rootWindow.height * 0.015)
        anchors.bottomMargin: Math.max(50, Math.round(rootWindow.height * 0.08)) // Lifts clear above bottom scanlines
        spacing: Math.max(8, Math.round(rootWindow.height * 0.012))

        // ====================================================================
        // 1. HEADER SECTION (Emerald Green Bar with Title, Weather & Clock)
        // ====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(68, Math.round(rootWindow.height * 0.11))
            color: "#004030"
            radius: 10

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 14

                // System Badge
                Rectangle {
                    Layout.preferredWidth: Math.max(140, Math.round(rootWindow.width * 0.12))
                    Layout.preferredHeight: Math.max(48, Math.round(rootWindow.height * 0.075))
                    radius: 8
                    color: "#00281e"
                    border.color: "#4A9782"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: "#22c55e"
                        }
                        Text {
                            text: "MFDS KIOSK"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#ffffff"
                        }
                    }
                }

                // Title & Subtitle
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: (typeof dataManager !== "undefined" && dataManager.bannerTitle !== "")
                              ? dataManager.bannerTitle : "HỆ THỐNG HIỂN THỊ ĐA CHỨC NĂNG (MFDS)"
                        font.pixelSize: Math.max(16, Math.round(rootWindow.height * 0.026))
                        font.bold: true
                        color: "#ffffff"
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "📍 " + ((typeof dataManager !== "undefined" && dataManager.location !== "")
                                      ? dataManager.location : "Trung Tâm Điều Hành Hệ Thống") + 
                              "  •  Node: " + ((typeof dataManager !== "undefined" && dataManager.deviceName !== "")
                                      ? dataManager.deviceName : "MFDS-Display-01")
                        font.pixelSize: 12
                        color: "#C7E9D3"
                        elide: Text.ElideRight
                    }
                }

                // Weather Widget (Open-Meteo REST API)
                Rectangle {
                    Layout.preferredWidth: Math.max(220, Math.round(rootWindow.width * 0.18))
                    Layout.preferredHeight: Math.max(52, Math.round(rootWindow.height * 0.08))
                    radius: 8
                    color: "#00281e"
                    border.color: "#4A9782"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Text {
                            text: (typeof weatherManager !== "undefined") ? weatherManager.weatherIcon : "🌤️"
                            font.pixelSize: 26
                        }
                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: (typeof weatherManager !== "undefined") ? weatherManager.weatherText : "28.5°C | Độ ẩm: 65%"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#ffffff"
                            }
                            Text {
                                text: "Thời tiết thực tế" + ((typeof weatherManager !== "undefined" && weatherManager.weatherDescription !== "") ? (" • " + weatherManager.weatherDescription) : "")
                                font.pixelSize: 10
                                color: "#C7E9D3"
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // Digital Clock Widget (Synced with Vietnam Time UTC+7)
                ClockWidget {
                    Layout.preferredWidth: 220
                    Layout.preferredHeight: Math.max(52, Math.round(rootWindow.height * 0.08))
                }
            }
        }

        // ====================================================================
        // 2. MAIN BODY SECTION (Left: Notices & Org, Right: Daily Schedule & Telemetry)
        // ====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // --------- CỘT TRÁI (60%): ĐƠN VỊ VẬN HÀNH & THÔNG BÁO ---------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Math.round(rootWindow.width * 0.60)
                spacing: 12

                // Khối 1: Thông tin Trực ban Điều hành (Ẩn danh, chuẩn hóa kỹ thuật)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(88, Math.round(rootWindow.height * 0.15))
                    color: "#C7E9D3"
                    radius: 10
                    border.color: "#FFFFFF"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "🏛️ ĐƠN VỊ VẬN HÀNH & GIÁM SÁT HỆ THỐNG"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#004030"
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "Node ID: BCM2711-KMS"
                                font.pixelSize: 11
                                font.bold: true
                                color: "#4A9782"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 8

                            // Thẻ 1: Trực ban
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 6
                                color: "#ffffff"
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 2
                                    Text { text: "TRỰC BAN VẬN HÀNH"; font.pixelSize: 10; font.bold: true; color: "#003427" }
                                    Text { text: "Kỹ sư Trực ban"; font.pixelSize: 14; font.bold: true; color: "#004030" }
                                    Text { text: "Giám sát luồng IPC & Watchdog 24/7"; font.pixelSize: 10; color: "#64748b"; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }

                            // Thẻ 2: Ban Kỹ thuật
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 6
                                color: "#ffffff"
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 2
                                    Text { text: "BAN KỸ THUẬT HỆ THỐNG"; font.pixelSize: 10; font.bold: true; color: "#003427" }
                                    Text { text: "Trung Tâm Điều Hành"; font.pixelSize: 14; font.bold: true; color: "#004030" }
                                    Text { text: "Hệ điều hành nhúng Yocto Linux"; font.pixelSize: 10; color: "#0284c7"; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }

                            // Thẻ 3: Trạm Kiosk
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 6
                                color: "#ffffff"
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 2
                                    Text { text: "TRẠM HIỂN THỊ MFDS"; font.pixelSize: 10; font.bold: true; color: "#16a34a" }
                                    Text { text: "Phòng LAB Đo Kiểm"; font.pixelSize: 14; font.bold: true; color: "#004030" }
                                    Text { text: "Tần số: 60 FPS • EGLFS KMS"; font.pixelSize: 10; color: "#64748b"; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }
                        }
                    }
                }

                // Khối 2: Danh sách Thông báo Hệ thống (model từ dataManager.notices)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#C7E9D3"
                    radius: 10
                    border.color: "#FFFFFF"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "📢 BẢNG THÔNG BÁO VẬN HÀNH"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#004030"
                                Layout.fillWidth: true
                            }
                            Text {
                                text: (dataManager.notices ? dataManager.notices.length : 0) + " bản tin"
                                font.pixelSize: 11
                                color: "#4A9782"
                            }
                        }

                        ListView {
                            id: noticeListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6
                            model: dataManager.notices

                            delegate: Rectangle {
                                width: noticeListView.width
                                height: 58
                                radius: 6
                                color: "#ffffff"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10

                                    // Nhãn phân loại không có chữ khẩn cấp
                                    Rectangle {
                                        Layout.preferredWidth: 82
                                        Layout.preferredHeight: 24
                                        radius: 4
                                        color: modelData.priority === "update" ? "#4A9782" :
                                               (modelData.priority === "info" ? "#0284c7" : "#004030")
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.priority === "update" ? "CẬP NHẬT" :
                                                 (modelData.priority === "info" ? "TIN MỚI" : "THÔNG BÁO")
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "white"
                                        }
                                    }

                                    // Tiêu đề & trích đoạn
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.title ? modelData.title : ""
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: "#004030"
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.content ? modelData.content : ""
                                            font.pixelSize: 10
                                            color: "#64748b"
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }
                                    }

                                    // Ngày đăng
                                    Text {
                                        text: "📅 " + (modelData.date ? modelData.date : "")
                                        font.pixelSize: 10
                                        color: "#64748b"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --------- CỘT PHẢI (40%): LỊCH TRÌNH VẬN HÀNH & GIÁM SÁT ---------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Math.round(rootWindow.width * 0.40)
                spacing: 12

                // Khối 1: Lịch hoạt động trong ngày (model từ dataManager.schedules)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#C7E9D3"
                    radius: 10
                    border.color: "#FFFFFF"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: "🗓️ LỊCH HOẠT ĐỘNG VẬN HÀNH TRONG NGÀY"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#004030"
                        }

                        ListView {
                            id: schedListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6
                            model: dataManager.schedules

                            delegate: Rectangle {
                                width: schedListView.width
                                height: 56
                                radius: 6
                                color: "#ffffff"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "⏰ " + (modelData.time_slot ? modelData.time_slot : "")
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: "#004030"
                                            Layout.fillWidth: true
                                        }
                                        Rectangle {
                                            width: 88
                                            height: 18
                                            radius: 3
                                            color: rootWindow.getScheduleColor(modelData.time_slot)
                                            Text {
                                                anchors.centerIn: parent
                                                text: rootWindow.getScheduleStatus(modelData.time_slot)
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: "white"
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.event_name ? modelData.event_name : ""
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: "#004030"
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: "📍 " + (modelData.room ? modelData.room : "") + "  •  👤 " + (modelData.host ? modelData.host : "")
                                        font.pixelSize: 10
                                        color: "#64748b"
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }

                // Khối 2: Thông số Trạm Kiosk & Watchdog
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(90, Math.round(rootWindow.height * 0.16))
                    color: "#C7E9D3"
                    radius: 10
                    border.color: "#FFFFFF"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        Text {
                            text: "⚙️ THÔNG SỐ VẬN HÀNH & WATCHDOG TRẠM"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#004030"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: 6
                                color: "#ffffff"
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    Text { text: "Hệ điều hành Nhúng"; font.pixelSize: 11; font.bold: true; color: "#004030"; Layout.alignment: Qt.AlignHCenter }
                                    Text { text: "Yocto Linux 5.0 (ARM64)"; font.pixelSize: 9; color: "#64748b"; Layout.alignment: Qt.AlignHCenter }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: 6
                                color: "#ffffff"
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    Text { text: "Đồ họa Hiệu năng Cao"; font.pixelSize: 11; font.bold: true; color: "#16a34a"; Layout.alignment: Qt.AlignHCenter }
                                    Text { text: "Qt 6.8 EGLFS Direct VC4"; font.pixelSize: 9; color: "#64748b"; Layout.alignment: Qt.AlignHCenter }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6
                            color: "#ffffff"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10

                                Text {
                                    text: "🟢 Watchdog: Armed (15s)"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#16a34a"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "🔄 IPC: Inotify Active"
                                    font.pixelSize: 11
                                    color: "#0284c7"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "🖥️ HDMI-A-2 Direct"
                                    font.pixelSize: 11
                                    color: "#4A9782"
                                }
                            }
                        }
                    }
                }
            }
        }

        // ====================================================================
        // 3. FOOTER SECTION (Marquee News Banner)
        // ====================================================================
        NewsBanner {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(40, Math.round(rootWindow.height * 0.065))
        }
    }
}
