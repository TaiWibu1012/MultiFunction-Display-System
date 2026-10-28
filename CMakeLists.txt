cmake_minimum_required(VERSION 3.16)
project(MultiFunctionDashboard VERSION 1.0 LANGUAGES CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Tự động xử lý các macro của Qt
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Tìm thư viện Qt6 đã cài đặt
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

# Khai báo file thực thi
qt_add_executable(DashboardApp 
    src/app/main.cpp
    src/app/NewsFetcher.cpp
    src/app/NewsFetcher.h
    src/app/WeatherFetcher.cpp
    src/app/WeatherFetcher.h
)

# Đóng gói các file QML vào bộ nhớ (chuẩn mới của Qt6)
qt_add_qml_module(DashboardApp
    URI DashboardUI
    VERSION 1.0
    QML_FILES
        src/app/Main.qml
        src/app/components/ClockWidget.qml
        src/app/components/NewsBanner.qml
    RESOURCES 
        src/app/assets/full_size_logo_fce.png
        src/app/assets/fonts/BeVietnamPro-Regular.ttf
        src/app/assets/fonts/BeVietnamPro-SemiBold.ttf
        src/app/assets/fonts/BeVietnamPro-Bold.ttf
)

# Liên kết thư viện
target_link_libraries(DashboardApp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
)