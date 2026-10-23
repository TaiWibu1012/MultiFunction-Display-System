#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCursor>
#include <QSocketNotifier>
#include <QQuickWindow>
#include <QTimer>
#include <csignal>
#include <sys/socket.h>
#include <unistd.h>
#include "DataManager.hpp"
#include "WatchdogSupervisor.hpp"

// Socketpair descriptor for asynchronous POSIX signal delivery into Qt Event Loop
static int sigFd[2];

static void posixSignalHandler(int sig)
{
    char a = static_cast<char>(sig);
    ::write(sigFd[0], &a, sizeof(a));
}

int main(int argc, char *argv[])
{
    // Default to native KMS/DRM (Direct HDMI via EGLFS)
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) {
        qputenv("QT_QPA_PLATFORM", "eglfs");
    }

    QGuiApplication app(argc, argv);

    // Hide mouse cursor for dedicated kiosk appliance
    app.setOverrideCursor(QCursor(Qt::BlankCursor));

    // 1. Setup POSIX signal handler to ensure orderly destruction on SIGTERM/SIGINT
    if (::socketpair(AF_UNIX, SOCK_STREAM, 0, sigFd) == 0) {
        struct sigaction sa;
        sa.sa_handler = posixSignalHandler;
        sigemptyset(&sa.sa_mask);
        sa.sa_flags = SA_RESTART;

        sigaction(SIGTERM, &sa, nullptr);
        sigaction(SIGINT, &sa, nullptr);

        auto *sn = new QSocketNotifier(sigFd[1], QSocketNotifier::Read, &app);
        QObject::connect(sn, &QSocketNotifier::activated, [&app]() {
            char sig;
            ::read(sigFd[1], &sig, sizeof(sig));
            qInfo() << "[Main] Received shutdown signal (" << int(sig) << "). Gracefully closing application...";
            app.quit();
        });
    }

    // 2. Initialize Hardware Watchdog Supervisor (15s hardware timeout, 5s check interval)
    WatchdogSupervisor watchdog(15, 5);

    // 3. Initialize DataManager
    DataManager dataManager;

    // Connect Data Heartbeat: whenever data is read/parsed successfully, feed the watchdog
    QObject::connect(&dataManager, &DataManager::dataReadSuccessful,
                     &watchdog, &WatchdogSupervisor::feedDataHeartbeat);

    // 4. Initialize QML Engine
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("dataManager", &dataManager);
    engine.rootContext()->setContextProperty("watchdog", &watchdog);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    // Connect Render Heartbeat: once root QML window is created, hook frameSwapped or continuous render pulse
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [&watchdog](QObject *object, const QUrl &) {
        auto *window = qobject_cast<QQuickWindow*>(object);
        if (window) {
            QObject::connect(window, &QQuickWindow::frameSwapped,
                             &watchdog, &WatchdogSupervisor::feedRenderHeartbeat);
            qInfo() << "[Main] Render loop hooked to Watchdog heartbeat via QQuickWindow::frameSwapped.";
        } else {
            // Fallback render pulse if running headlessly or off-screen
            auto *renderPulseTimer = new QTimer(&watchdog);
            QObject::connect(renderPulseTimer, &QTimer::timeout,
                             &watchdog, &WatchdogSupervisor::feedRenderHeartbeat);
            renderPulseTimer->start(1000);
            qInfo() << "[Main] Fallback render heartbeat pulse active.";
        }
    });

    // Load Main QML Module
    engine.loadFromModule("MultiFunctionDisplay", "Main");

    // app.exec() will return cleanly on app.quit(), causing ~WatchdogSupervisor() to run and write 'V'
    return app.exec();
}
