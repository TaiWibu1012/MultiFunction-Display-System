import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Window {
    id: rootWindow
    visible: true
    visibility: Window.FullScreen
    color: "#0b1120" // Deep Dark Slate background

    property int tickerIndex: 0

    // Timer to cycle news ticker every 6 seconds
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

    // Main layout container: responsive margins matching display resolution
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.round(rootWindow.width * 0.02)
        anchors.rightMargin: Math.round(rootWindow.width * 0.02)
        anchors.topMargin: Math.round(rootWindow.height * 0.02)
        anchors.bottomMargin: Math.round(rootWindow.height * 0.10) // Lifts above bottom screen stripes
        spacing: Math.round(rootWindow.height * 0.015)

        // ====================================================================
        // 1. HEADER SECTION (System Title, Location, Clock)
        // ====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(80, Math.round(rootWindow.height * 0.12))
            color: "#1e293b"
            radius: 10
            border.color: "#334155"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16

                // System Badge & Title
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 3

                    RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: "#22c55e" // Glowing green online indicator
                        }
                        Text {
                            text: "HỆ THỐNG HIỂN THỊ ĐA CHỨC NĂNG (MFDS)"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#38bdf8"
                        }
                    }

                    Text {
                        text: dataManager.bannerTitle ? dataManager.bannerTitle : "TRUNG TÂM ĐIỀU HÀNH HỆ THỐNG"
                        font.pixelSize: Math.max(18, Math.round(rootWindow.height * 0.032))
                        font.bold: true
                        color: "#ffffff"
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "📍 " + (dataManager.location ? dataManager.location : "Khu Vực Điều Hành") + 
                              "  •  Node: " + (dataManager.deviceName ? dataManager.deviceName : "MFDS-Node-01")
                        font.pixelSize: 13
                        color: "#94a3b8"
                        elide: Text.ElideRight
                    }
                }

                // Clock & Date Widget
                ClockWidget {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }
            }
        }

        // ====================================================================
        // 2. MAIN BODY SECTION (Left: System Notices, Right: Daily Schedule)
        // ====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // ----------------------------------------------------------------
            // LEFT COLUMN: THÔNG BÁO HỆ THỐNG (58% width)
            // ----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Math.round(rootWindow.width * 0.58)
                color: "#1e293b"
                radius: 10
                border.color: "#334155"
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // Panel Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "📢 THÔNG BÁO HỆ THỐNG"
                            font.pixelSize: 17
                            font.bold: true
                            color: "#38bdf8"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: (dataManager.notices ? dataManager.notices.length : 0) + " bản tin"
                            font.pixelSize: 13
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
                        spacing: 8
                        clip: true
                        model: dataManager.notices

                        delegate: Rectangle {
                            width: noticeList.width
                            height: 78
                            color: "#0f172a"
                            radius: 8
                            border.color: "#334155"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    // Professional Priority Badge (No alarming red)
                                    Rectangle {
                                        width: 80
                                        height: 20
                                        radius: 4
                                        color: modelData.priority === "update" ? "#059669" : 
                                               (modelData.priority === "info" ? "#3b82f6" : "#0284c7")
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.priority === "update" ? "CẬP NHẬT" : 
                                                 (modelData.priority === "info" ? "TIN TỨC" : "THÔNG BÁO")
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: "#ffffff"
                                        }
                                    }

                                    // Date
                                    Text {
                                        text: modelData.date ? modelData.date : ""
                                        font.pixelSize: 12
                                        color: "#94a3b8"
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                // Notice Title
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title ? modelData.title : ""
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: "#f8fafc"
                                    elide: Text.ElideRight
                                }

                                // Notice Content Excerpt
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.content ? modelData.content : ""
                                    font.pixelSize: 12
                                    color: "#94a3b8"
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }
                        }
                    }
                }
            }

            // ----------------------------------------------------------------
            // RIGHT COLUMN: LỊCH TRÌNH VẬN HÀNH (42% width)
            // ----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Math.round(rootWindow.width * 0.40)
                color: "#1e293b"
                radius: 10
                border.color: "#334155"
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // Panel Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "📅 LỊCH TRÌNH VẬN HÀNH"
                            font.pixelSize: 17
                            font.bold: true
                            color: "#fbbf24"
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: (dataManager.schedules ? dataManager.schedules.length : 0) + " mục"
                            font.pixelSize: 13
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
                        spacing: 6
                        clip: true
                        model: dataManager.schedules

                        delegate: Rectangle {
                            width: scheduleList.width
                            height: 56
                            color: "#0f172a"
                            radius: 8
                            border.color: "#334155"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    // Time Slot Badge
                                    Rectangle {
                                        width: 95
                                        height: 19
                                        radius: 4
                                        color: "#0284c7"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.time_slot ? modelData.time_slot : ""
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: "#ffffff"
                                        }
                                    }

                                    // Event Name
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.event_name ? modelData.event_name : ""
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "#f8fafc"
                                        elide: Text.ElideRight
                                    }
                                }

                                // Room & Host info
                                Text {
                                    Layout.fillWidth: true
                                    text: "📍 " + (modelData.room ? modelData.room : "") + 
                                          "  •  👤 " + (modelData.host ? modelData.host : "")
                                    font.pixelSize: 11
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
            Layout.preferredHeight: Math.max(42, Math.round(rootWindow.height * 0.065))
            color: "#1e293b"
            radius: 8
            border.color: "#334155"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 12

                // Ticker Label Badge
                Rectangle {
                    width: 75
                    height: 28
                    radius: 5
                    color: "#0284c7"
                    Text {
                        anchors.centerIn: parent
                        text: "BẢN TIN"
                        font.pixelSize: 12
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
                    font.pixelSize: 13
                    font.bold: true
                    color: "#f1f5f9"
                    elide: Text.ElideRight
                }

                // DRM VC4 / Watchdog Status
                Rectangle {
                    width: 140
                    height: 24
                    radius: 4
                    color: "#065f46"
                    Text {
                        anchors.centerIn: parent
                        text: "VC4 KMS  •  60 FPS"
                        font.pixelSize: 11
                        font.bold: true
                        color: "#a7f3d0"
                    }
                }
            }
        }
    }
}
