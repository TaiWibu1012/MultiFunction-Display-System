#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCursor>
#include "DataManager.hpp"
#include "WatchdogSupervisor.hpp"

int main(int argc, char *argv[])
{
    // Mặc định xuất thẳng KMS/DRM (HDMI) nếu không truyền platform khác (như VNC)
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) {
        qputenv("QT_QPA_PLATFORM", "eglfs");
    }

    QGuiApplication app(argc, argv);

    // Ẩn con trỏ chuột cho Kiosk Mode
    app.setOverrideCursor(QCursor(Qt::BlankCursor));

    // Khởi tạo Hardware Watchdog Supervisor (15s timeout, ping mỗi 5s)
    WatchdogSupervisor watchdog(15, 5);

    QQmlApplicationEngine engine;

    // Khởi tạo DataManager và expose sang QML dưới tên "dataManager"
    DataManager dataManager;
    engine.rootContext()->setContextProperty("dataManager", &dataManager);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    // Nạp module QML chính
    engine.loadFromModule("MultiFunctionDisplay", "Main");

    return app.exec();
}
