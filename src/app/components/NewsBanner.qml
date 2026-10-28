import QtQuick
import QtQuick.Layouts

Rectangle {
    id: bannerRoot
    implicitHeight: 52
    color: "#004030"
    radius: 10
    border.color: "#4A9782"
    border.width: 1
    clip: true // Cắt phần chữ tràn ra ngoài viền khung

    Text {
        id: scrollingText
        text: (typeof dataManager !== "undefined" && dataManager.newsTicker && dataManager.newsTicker.length > 0)
              ? dataManager.newsTicker.join("   🔹   ")
              : "HỆ THỐNG HIỂN THỊ ĐA CHỨC NĂNG (MFDS)   🔹   TRẠNG THÁI VẬN HÀNH: BÌNH THƯỜNG"
        font.pixelSize: 22
        font.bold: true
        color: "#FFE100"
        anchors.verticalCenter: parent.verticalCenter
    }

    NumberAnimation {
        id: scrollAnim
        target: scrollingText
        property: "x"
        from: bannerRoot.width
        to: -scrollingText.width
        duration: Math.max(1000, (bannerRoot.width + scrollingText.width) * 12)
        loops: Animation.Infinite
    }

    function restartMarquee() {
        if (bannerRoot.width > 0 && scrollingText.width > 0) {
            scrollAnim.stop()
            scrollingText.x = bannerRoot.width
            scrollAnim.start()
        }
    }

    onWidthChanged: restartMarquee()
    Component.onCompleted: restartMarquee()

    Connections {
        target: scrollingText
        function onWidthChanged() { bannerRoot.restartMarquee() }
        function onTextChanged() { bannerRoot.restartMarquee() }
    }
}
