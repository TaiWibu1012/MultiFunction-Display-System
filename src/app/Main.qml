import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Window {
    id: rootWindow
    width: 1920
    height: 1080
    visible: true
    visibility: Window.FullScreen
    color: "#0b1120" // Deep Dark Slate (High contrast)

    property int tickerIndex: 0

    // Timer to rotate news ticker entries every 6 seconds
    Timer {
        id: tickerTimer
        interval: 6000
        running: true
        repeat: true
        onTriggered: {
            if (dataManager.newsTicker && dataManager.newsTicker.length > 0) {
                rootWindow.tickerIndex = (rootWindow.tickerIndex + 1) % dataManager.newsTicker.length
            }
        }
    }

    // Main layout container: elevated with bottom margin to remain in the clear area of display
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        anchors.topMargin: 24
        anchors.bottomMargin: 180 // Avoid bottom hardware scanline stripes on panel
        spacing: 20

        // ====================================================================
        // 1. HEADER SECTION (Top Bar: System Badge, Title, Location, Clock)
        // ====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            color: "#1e293b"
            radius: 12
            border.color: "#334155"
            border.width: 2

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 20

                // System Badge & Title
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    RowLayout {
                        spacing: 10
                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: "#22c55e" // Glowing green online dot
                        }
                        Text {
                            text: "MFDS KIOSK  |  HỆ THỐNG HIỂN THỊ ĐA CHỨC NĂNG"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#38bdf8"
                        }
                    }

                    Text {
                        text: dataManager.bannerTitle ? dataManager.bannerTitle : "BẢNG TIN ĐIỆN TỬ THÔNG MINH"
                        font.pixelSize: 32
                        font.bold: true
                        color: "#ffffff"
                    }

                    Text {
                        text: "📍 " + (dataManager.location ? dataManager.location : "Sảnh Văn Phòng Khoa KTMT") + 
                              "   •   Thiết bị: " + (dataManager.deviceName ? dataManager.deviceName : "Pi 4 Model B")
                        font.pixelSize: 16
                        color: "#94a3b8"
                    }
                }

                // Clock & Date Widget (Vivid Sky Blue & Gold)
                ClockWidget {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }
            }
        }

        // ====================================================================
        // 2. MAIN BODY SECTION (Left: Notices, Right: Daily Schedule)
        // ====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 24

            // ----------------------------------------------------------------
            // LEFT COLUMN: BẢNG THÔNG BÁO QUAN TRỌNG (60% width)
            // ----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 60
                color: "#1e293b"
                radius: 12
                border.color: "#334155"
                border.width: 2
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    // Panel Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "📢 THÔNG BÁO QUAN TRỌNG"
                            font.pixelSize: 22
                            font.bold: true
                            color: "#38bdf8"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: (dataManager.notices ? dataManager.notices.length : 0) + " tin mới"
                            font.pixelSize: 14
                            color: "#94a3b8"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#334155"
                    }

                    // Notices List
                    ListView {
                        id: noticeList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10
                        clip: true
                        model: dataManager.notices

                        delegate: Rectangle {
                            width: noticeList.width
                            height: 110
                            color: "#0f172a"
                            radius: 8
                            border.color: modelData.priority === "urgent" ? "#ef4444" : 
                                         (modelData.priority === "normal" ? "#f59e0b" : "#3b82f6")
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    // Priority Pill
                                    Rectangle {
                                        width: 85
                                        height: 22
                                        radius: 4
                                        color: modelData.priority === "urgent" ? "#ef4444" : 
                                               (modelData.priority === "normal" ? "#f59e0b" : "#3b82f6")
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.priority === "urgent" ? "KHẨN CẤP" : 
                                                 (modelData.priority === "normal" ? "QUAN TRỌNG" : "THÔNG BÁO")
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: "#ffffff"
                                        }
                                    }

                                    // Date
                                    Text {
                                        text: modelData.date ? modelData.date : ""
                                        font.pixelSize: 14
                                        color: "#94a3b8"
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                // Notice Title
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title ? modelData.title : ""
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#f8fafc"
                                    elide: Text.ElideRight
                                }

                                // Notice Content Excerpt
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.content ? modelData.content : ""
                                    font.pixelSize: 14
                                    color: "#cbd5e1"
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------------------
            // RIGHT COLUMN: LỊCH TRÌNH CÔNG TÁC (40% width)
            // ----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 40
                color: "#1e293b"
                radius: 12
                border.color: "#334155"
                border.width: 2
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    // Panel Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "📅 LỊCH TRÌNH HÔM NAY"
                            font.pixelSize: 22
                            font.bold: true
                            color: "#fbbf24"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: (dataManager.schedules ? dataManager.schedules.length : 0) + " sự kiện"
                            font.pixelSize: 14
                            color: "#94a3b8"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#334155"
                    }

                    // Schedules List
                    ListView {
                        id: scheduleList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8
                        clip: true
                        model: dataManager.schedules

                        delegate: Rectangle {
                            width: scheduleList.width
                            height: 78
                            color: "#0f172a"
                            radius: 8
                            border.color: "#334155"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    // Time Slot Badge
                                    Rectangle {
                                        width: 105
                                        height: 22
                                        radius: 4
                                        color: "#0284c7"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.time_slot ? modelData.time_slot : ""
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: "#ffffff"
                                        }
                                    }

                                    // Event Name
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.event_name ? modelData.event_name : ""
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "#f8fafc"
                                        elide: Text.ElideRight
                                    }
                                }

                                // Room & Host info
                                Text {
                                    Layout.fillWidth: true
                                    text: "🏛 " + (modelData.room ? modelData.room : "") + 
                                          "  •  👤 " + (modelData.host ? modelData.host : "")
                                    font.pixelSize: 13
                                    color: "#94a3b8"
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }

        // ====================================================================
        // 3. FOOTER SECTION: BẢNG TIN VẮN TẮT (NEWS TICKER / STATUS BAR)
        // ====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            color: "#1e293b"
            radius: 10
            border.color: "#334155"
            border.width: 2

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                // Ticker Label Badge
                Rectangle {
                    width: 90
                    height: 34
                    radius: 6
                    color: "#b91c1c" // Crimson Red
                    Text {
                        anchors.centerIn: parent
                        text: "TIN VẮN"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#ffffff"
                    }
                }

                // Rotating Ticker Text
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: (dataManager.newsTicker && dataManager.newsTicker.length > 0) ? 
                          dataManager.newsTicker[rootWindow.tickerIndex] : 
                          "Đang tải bản tin từ hệ thống..."
                    font.pixelSize: 16
                    font.bold: true
                    color: "#f1f5f9"
                    elide: Text.ElideRight
                }

                // DRM VC4 / Watchdog Badge
                Rectangle {
                    width: 170
                    height: 28
                    radius: 4
                    color: "#0f766e"
                    Text {
                        anchors.centerIn: parent
                        text: "MESA VC4 | 60 FPS"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#ccfbf1"
                    }
                }
            }
        }
    }
}
