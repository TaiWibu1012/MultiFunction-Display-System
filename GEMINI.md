# Project Context: Hệ thống hiển thị đa chức năng (Multi-Function Display System)

## 1. Tổng quan dự án (Project Overview)
- **Môn học:** Đồ án 1 - Chuyên ngành Hệ thống nhúng và IoT, Khoa Kỹ thuật Máy tính (FCE), Trường Đại học Công nghệ Thông tin (UIT - ĐHQG TP.HCM).
- **Tên đề tài:** Hệ thống hiển thị đa chức năng (Mã viết tắt: `HTHTDCN` hoặc `MFDS`).
- **Thành viên thực hiện:**
  - Võ Thanh Dũng (MSSV: 24520355)
  - Lê Phúc Tài (MSSV: 24521548)
- **Giảng viên hướng dẫn:** ThS. Phan Đình Duy (Phó Trưởng khoa KTMT).
- **Trưởng khoa KTMT hiện tại:** TS. Nguyễn Minh Sơn.
- **Quy tắc đặt tên file tài liệu/báo cáo (nếu tạo):** `24520355-24521548-VoThanhDung-LePhucTai-HTHTDCN.xxx`
- **Mục tiêu hệ thống:** Xây dựng thiết bị Kiosk Digital Signage chạy ứng dụng Qt6/QML toàn màn hình (1920x1080) hiển thị thông tin Khoa KTMT, lịch hoạt động trong ngày, đồng hồ thời gian thực, trạng thái hệ thống và bảng tin + dòng chữ chạy (Marquee) lấy dữ liệu RSS trực tiếp từ `https://fce.uit.edu.vn/feed/`. Định hướng đóng gói xuống Linux nhúng tùy biến (Yocto Project, chạy trực tiếp qua DRM/KMS `eglfs`).

## 2. Môi trường phát triển & Đặc thù hệ thống (Environment & Quirks)
- **Hệ điều hành phát triển:** Ubuntu 22.04 LTS chạy trên máy ảo Oracle VirtualBox (8 CPUs, 12-16GB RAM, 200GB Disk, EFI enabled).
- **Đường dẫn dự án:** `/home/dung/DisplayBox_Project`
- **Qt Version & Path:** Qt `6.12.0` cài đặt tại `/home/dung/Qt/6.12.0/gcc_64`.
- **Build System:** CMake (cài qua Snap tại `/snap/bin/cmake` để đáp ứng yêu cầu CMake >= 3.25 của Qt 6.12) + Ninja (`-G Ninja`).
- **Thư viện hệ thống đã cài để fix lỗi môi trường:** `libgl1-mesa-dev`, `libxcb-cursor0`.
- **LƯU Ý QUAN TRỌNG VỀ RUNTIME TRÊN VIRTUALBOX (`src/app/main.cpp`):**
  Khi chạy thử nghiệm trên máy ảo Ubuntu 22.04, **BẮT BUỘC** phải giữ 3 dòng cấu hình biến môi trường sau ở đầu hàm `main()` trước khi khởi tạo `QGuiApplication` để tránh lỗi `core dumped` do xung đột GNOME schema, Wayland và driver OpenGL 3D của VirtualBox:
  ```cpp
  qputenv("QT_QPA_PLATFORM", "xcb");
  qputenv("QT_QPA_PLATFORMTHEME", "");
  qputenv("QT_QUICK_BACKEND", "software");

```

*(Khi biên dịch chéo sang phần cứng nhúng thực tế chạy Yocto sau này mới chuyển sang `eglfs` và bật lại Hardware Rendering).*

## 3. Kiến trúc thư mục & Trạng thái hiện tại (Current Architecture)

```text
DisplayBox_Project/
├── CMakeLists.txt
├── .vscode/
│   └── settings.json                  # Chứa -DCMAKE_PREFIX_PATH=/home/dung/Qt/6.12.0/gcc_64
├── build/                             # Thư mục build của CMake + Ninja
└── src/
    └── app/
        ├── main.cpp                   # Entry point, đăng ký context property "newsManager"
        ├── NewsFetcher.h              # Header C++ Backend tải và phân tích RSS
        ├── NewsFetcher.cpp            # Dùng QNetworkAccessManager & QXmlStreamReader đọc [https://fce.uit.edu.vn/feed/](https://fce.uit.edu.vn/feed/)
        ├── Main.qml                   # Giao diện Kiosk chính (Header, Cột trái 62%, Cột phải 38%, Footer)
        ├── assets/                    # Chứa hình ảnh tĩnh (VD: logo_fce.png)
        └── components/
            ├── ClockWidget.qml        # Đồng hồ thời gian thực + Thứ/Ngày/Tháng
            └── NewsBanner.qml         # Thanh chữ chạy (Marquee) ở đáy màn hình, tự tính lại animation khi đổi width/text

```

## 4. Quy tắc lập trình bắt buộc cho Agent (Coding Standards & Rules)

1. **Quản lý `CMakeLists.txt`:**
* Dự án sử dụng chuẩn Qt6 hiện đại với `qt_add_executable(DashboardApp ...)` và `qt_add_qml_module(DashboardApp URI DashboardUI VERSION 1.0 ...)`.
* **Mọi file `.cpp` / `.h` mới** tạo ra phải được khai báo vào `qt_add_executable`.
* **Mọi file `.qml` mới** phải được thêm vào nhánh `QML_FILES` của `qt_add_qml_module`.
* **Mọi file ảnh/icon/font mới** trong `src/app/assets/` phải được thêm vào nhánh `RESOURCES` của `qt_add_qml_module`.
* Luôn đảm bảo `target_link_libraries` có đủ: `Qt6::Core`, `Qt6::Gui`, `Qt6::Qml`, `Qt6::Quick`, `Qt6::Network`.


2. **Chuẩn C++ & Qt 6.12:**
* Sử dụng chuẩn `C++17`.
* Dùng `using namespace Qt::StringLiterals;` và hậu tố `_s` (ví dụ: `u"qrc:/DashboardUI/src/app/Main.qml"_s`), **không dùng** `_qs` vì đã bị deprecated trên Qt 6.12.
* Mọi tác vụ gọi mạng (HTTP/RSS/REST API), đọc file, hoặc xử lý dữ liệu nặng phải viết ở tầng C++ Backend bất đồng bộ (`QNetworkAccessManager`), tuyệt đối không dùng đồng bộ làm đơ luồng giao diện QML.
* Khi gọi HTTPS tới `fce.uit.edu.vn`, luôn giữ header `User-Agent` và xử lý `ignoreSslErrors()` để tránh lỗi chứng chỉ SSL trung gian trên Linux.


3. **Chuẩn thiết kế QML:**
* Trong `Main.qml`, đã khai báo `import "components"`, do đó gọi trực tiếp tên component (ví dụ `ClockWidget {}`, `NewsBanner {}`), **không** gọi qua tiền tố `components.`.
* Khi viết `NumberAnimation` cho hiệu ứng chạy chữ hoặc chuyển động phụ thuộc vào `width`/`height`, luôn xử lý khởi động lại animation trong `onWidthChanged`, `onTextChanged`, và `Component.onCompleted` để tránh lỗi nhận giá trị `width = 0` lúc mới khởi tạo cửa sổ.



## 5. Lệnh kiểm tra và Build (Verification Commands)

Sau khi chỉnh sửa code C++ hoặc QML, Agent có thể tự kiểm tra lỗi biên dịch bằng lệnh:
/snap/bin/cmake --build /home/dung/DisplayBox_Project/build --config Debug --target all

