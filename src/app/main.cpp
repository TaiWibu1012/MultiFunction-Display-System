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
#include <fcntl.h>
#include "DataManager.hpp"
#include "WatchdogSupervisor.hpp"

// Socketpair descriptor for asynchronous POSIX signal delivery into Qt Event Loop
// DEF-08: Initialized to -1 and closed cleanly upon termination
static int sigFd[2] = {-1, -1};

static void posixSignalHandler(int sig)
{
    char a = static_cast<char>(sig);
    if (sigFd[0] >= 0) {
        ssize_t ret = ::write(sigFd[0], &a, sizeof(a));
        (void)ret; // Non-blocking write; ignore return in async signal handler
    }
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

    // 1. Setup POSIX signal handler with non-blocking socketpair (DEF-08)
    if (::socketpair(AF_UNIX, SOCK_STREAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0, sigFd) == 0) {
        struct sigaction sa;
        sa.sa_handler = posixSignalHandler;
        sigemptyset(&sa.sa_mask);
        sa.sa_flags = SA_RESTART;

        sigaction(SIGTERM, &sa, nullptr);
        sigaction(SIGINT, &sa, nullptr);

        auto *sn = new QSocketNotifier(sigFd[1], QSocketNotifier::Read, &app);
        QObject::connect(sn, &QSocketNotifier::activated, [&app]() {
            char sig = 0;
            if (::read(sigFd[1], &sig, sizeof(sig)) > 0) {
                qInfo() << "[Main] Received shutdown signal (" << int(sig) << "). Gracefully closing application...";
                app.quit();
            }
        });
    } else {
        qWarning() << "[Main] Failed to create signal socketpair. Falling back to default signal disposition.";
    }

    // 2. Initialize Hardware Watchdog Supervisor (15s hardware timeout, 5s check interval)
    WatchdogSupervisor watchdog(15, 5);

    // 3. Initialize DataManager
    DataManager dataManager;

    // DEF-01: Connect Data Heartbeat
    // - Continuous health heartbeat verifies IPC watcher liveness even when data.json is static
    // - dataReadSuccessful also pulses heartbeat whenever new payload is processed
    QObject::connect(&dataManager, &DataManager::healthHeartbeat,
                     &watchdog, &WatchdogSupervisor::feedDataHeartbeat);
    QObject::connect(&dataManager, &DataManager::dataReadSuccessful,
                     &watchdog, &WatchdogSupervisor::feedDataHeartbeat);

    // DEF-02: Connect Render / GUI Event Loop Heartbeat
    // A periodic 2-second GUI timer ensures static QML scenes and DPMS standby display modes
    // do not starve the watchdog, while still guaranteeing the GUI event loop is actively dispatching
    auto *guiHeartbeatTimer = new QTimer(&app);
    QObject::connect(guiHeartbeatTimer, &QTimer::timeout,
                     &watchdog, &WatchdogSupervisor::feedRenderHeartbeat);
    guiHeartbeatTimer->start(2000);

    // 4. Initialize QML Engine
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("dataManager", &dataManager);
    engine.rootContext()->setContextProperty("watchdog", &watchdog);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    // Hook frameSwapped to also feed render heartbeat when active animations are rendering
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [&watchdog](QObject *object, const QUrl &) {
        auto *window = qobject_cast<QQuickWindow*>(object);
        if (window) {
            QObject::connect(window, &QQuickWindow::frameSwapped,
                             &watchdog, &WatchdogSupervisor::feedRenderHeartbeat);
            qInfo() << "[Main] Render loop hooked to Watchdog heartbeat via QQuickWindow::frameSwapped.";
        }
    });

    // Load Main QML Module
    engine.loadFromModule("MultiFunctionDisplay", "Main");

    // Execute application event loop
    int exitCode = app.exec();

    // DEF-08: Orderly cleanup of signal socket descriptors
    if (sigFd[0] >= 0) {
        ::close(sigFd[0]);
        sigFd[0] = -1;
    }
    if (sigFd[1] >= 0) {
        ::close(sigFd[1]);
        sigFd[1] = -1;
    }

    return exitCode;
}

