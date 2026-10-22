#include "WatchdogSupervisor.hpp"

#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/watchdog.h>

WatchdogSupervisor::WatchdogSupervisor(int timeoutSec, int pingIntervalSec, QObject *parent)
    : QObject(parent)
    , m_fd(-1)
    , m_enabled(false)
{
    openDevice(timeoutSec);

    if (m_enabled) {
        connect(&m_pingTimer, &QTimer::timeout, this, &WatchdogSupervisor::ping);
        m_pingTimer.start(pingIntervalSec * 1000);
        qInfo() << "[WatchdogSupervisor] Hardware watchdog armed with" << timeoutSec
                << "s timeout, ping interval:" << pingIntervalSec << "s.";
    }
}

WatchdogSupervisor::~WatchdogSupervisor()
{
    closeDevice();
}

void WatchdogSupervisor::openDevice(int timeoutSec)
{
    m_fd = ::open("/dev/watchdog", O_WRONLY | O_CLOEXEC);
    if (m_fd < 0) {
        qInfo() << "[WatchdogSupervisor] /dev/watchdog unavailable or access denied. Continuing without hardware supervisor.";
        m_enabled = false;
        return;
    }

    int actualTimeout = timeoutSec;
    if (ioctl(m_fd, WDIOC_SETTIMEOUT, &actualTimeout) == 0) {
        qInfo() << "[WatchdogSupervisor] Hardware watchdog timeout negotiated to" << actualTimeout << "seconds.";
    }

    m_enabled = true;
    ping(); // Immediate initial keepalive
}

void WatchdogSupervisor::ping()
{
    if (!m_enabled || m_fd < 0) {
        return;
    }

    // Ping using ioctl keepalive or write
    if (ioctl(m_fd, WDIOC_KEEPALIVE, 0) < 0) {
        // Fallback to byte write
        static const char dummy = '\0';
        if (::write(m_fd, &dummy, 1) < 0) {
            qWarning() << "[WatchdogSupervisor] Failed to write keep-alive ping to /dev/watchdog.";
        }
    }
}

void WatchdogSupervisor::closeDevice()
{
    if (m_enabled && m_fd >= 0) {
        m_pingTimer.stop();
        // Standard Linux Watchdog Magic Close character 'V' to prevent reboot upon intentional exit
        static const char magicClose = 'V';
        if (::write(m_fd, &magicClose, 1) < 0) {
            qWarning() << "[WatchdogSupervisor] Magic close write failed.";
        }
        ::close(m_fd);
        m_fd = -1;
        m_enabled = false;
        qInfo() << "[WatchdogSupervisor] Watchdog disarmed cleanly.";
    }
}
