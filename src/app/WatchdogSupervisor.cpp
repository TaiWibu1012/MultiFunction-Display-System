#include "WatchdogSupervisor.hpp"

#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/watchdog.h>

WatchdogSupervisor::WatchdogSupervisor(int timeoutSec, int pingIntervalSec, QObject *parent)
    : QObject(parent)
    , m_fd(-1)
    , m_enabled(false)
    , m_renderHeartbeat(true)
    , m_dataHeartbeat(true)
    , m_missedHeartbeatCycles(0)
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
    m_renderHeartbeat = true;
    m_dataHeartbeat = true;
    m_missedHeartbeatCycles = 0;
    ping(); // Immediate initial keepalive
}

void WatchdogSupervisor::feedDataHeartbeat()
{
    m_dataHeartbeat = true;
}

void WatchdogSupervisor::feedRenderHeartbeat()
{
    m_renderHeartbeat = true;
}

void WatchdogSupervisor::ping()
{
    if (!m_enabled || m_fd < 0) {
        return;
    }

    // Health Check Gate: Both render loop and data reader must report healthy
    if (!m_renderHeartbeat || !m_dataHeartbeat) {
        m_missedHeartbeatCycles++;
        qWarning() << "[WatchdogSupervisor] Subsystem health check missing cycle!"
                   << "Misses:" << m_missedHeartbeatCycles << "/" << MAX_ALLOWED_MISSED_CYCLES
                   << "(Render:" << m_renderHeartbeat << "Data:" << m_dataHeartbeat << ")";

        if (m_missedHeartbeatCycles >= MAX_ALLOWED_MISSED_CYCLES) {
            qCritical() << "[WatchdogSupervisor] SUBSYSTEM STALLED! Halting watchdog keepalive to trigger hardware reboot.";
            return; // Cease keepalive -> hardware watchdog will reset BCM2711
        }
    } else {
        m_missedHeartbeatCycles = 0;
    }

    // Reset heartbeats for next monitoring cycle
    m_renderHeartbeat = false;
    m_dataHeartbeat = false;

    // Ping using ioctl keepalive or byte write fallback
    if (ioctl(m_fd, WDIOC_KEEPALIVE, 0) < 0) {
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
