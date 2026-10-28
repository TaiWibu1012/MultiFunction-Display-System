import QtQuick
import QtQuick.Layouts

Rectangle {
    id: bannerRoot
    height: 60
    color: "#004030"
    radius: 10
    border.color: "#4A9782"
    border.width: 1
    clip: true // Cắt phần chữ tràn ra ngoài hai đầu khung

    Text {
        id: scrollingText
        // Lấy dữ liệu từ C++ newsManager; nếu rỗng thì hiện chuỗi mặc định để kiểm tra
        text: (typeof newsManager !== "undefined" && newsManager.currentNews !== "")
              ? newsManager.currentNews
              : "Khoa Kỹ thuật Máy tính (FCE - UIT)   🔹   Hệ thống hiển thị đa chức năng"
        font.pixelSize: 26
        font.bold: true
        color: "#FFE100"
        anchors.verticalCenter: parent.verticalCenter
    }

    // Tách riêng NumberAnimation để chủ động điều khiển lúc dừng/chạy
    NumberAnimation {
        id: scrollAnim
        target: scrollingText
        property: "x"
        from: bannerRoot.width
        to: -scrollingText.width
        // Tốc độ chạy tỉ lệ thuận với tổng quãng đường (tránh chạy quá nhanh hoặc quá chậm)
        duration: Math.max(1000, (bannerRoot.width + scrollingText.width) * 8)
        loops: Animation.Infinite
    }

    // Hàm khởi động lại hiệu ứng mỗi khi khung hình hoặc độ dài chữ thay đổi
    function restartMarquee() {
        if (bannerRoot.width > 0 && scrollingText.width > 0) {
            scrollAnim.stop()
            scrollingText.x = bannerRoot.width
            scrollAnim.start()
            console.log("Marquee started! Banner width:", bannerRoot.width,
                        "Text width:", scrollingText.width,
                        "Content:", scrollingText.text)
        }
    }

    // Tự động kích hoạt lại khi cửa sổ phóng to hoặc khi C++ cập nhật tin tức mới
    onWidthChanged: restartMarquee()
    Component.onCompleted: restartMarquee()

    Connections {
        target: scrollingText
        function onWidthChanged() { bannerRoot.restartMarquee() }
        function onTextChanged() { bannerRoot.restartMarquee() }
    }
}