cmake_minimum_required(VERSION 3.16)

project(MultiFunctionDisplay VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Quick Qml Network)

qt_standard_project_setup()
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 OLD)

qt_add_executable(appMultiFunctionDisplay
    main.cpp
    DataManager.hpp
    DataManager.cpp
    WatchdogSupervisor.hpp
    WatchdogSupervisor.cpp
    WeatherFetcher.h
    WeatherFetcher.cpp
)

qt_add_qml_module(appMultiFunctionDisplay
    URI MultiFunctionDisplay
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES
        Main.qml
        components/ClockWidget.qml
        components/NewsBanner.qml
    RESOURCES
        assets/fonts/BeVietnamPro-Regular.ttf
        assets/fonts/BeVietnamPro-SemiBold.ttf
        assets/fonts/BeVietnamPro-Bold.ttf
        assets/full_size_logo_fce.png
)

target_link_libraries(appMultiFunctionDisplay PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::Network
)

target_compile_options(appMultiFunctionDisplay PRIVATE
    -Wall
    -Wextra
    -Wpedantic
)

include(GNUInstallDirs)
install(TARGETS appMultiFunctionDisplay
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
