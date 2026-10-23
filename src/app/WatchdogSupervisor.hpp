#pragma once

#include <QObject>
#include <QTimer>
#include <QDebug>

class WatchdogSupervisor : public QObject
{
    Q_OBJECT

public:
    explicit WatchdogSupervisor(int timeoutSec = 15, int pingIntervalSec = 5, QObject *parent = nullptr);
    ~WatchdogSupervisor() override;

    bool isEnabled() const { return m_enabled; }

public slots:
    void ping();
    void feedDataHeartbeat();
    Q_INVOKABLE void feedRenderHeartbeat();

private:
    void openDevice(int timeoutSec);
    void closeDevice();

    int m_fd;
    bool m_enabled;
    QTimer m_pingTimer;

    // Subsystem Health Heartbeat flags
    bool m_renderHeartbeat;
    bool m_dataHeartbeat;
    int m_missedHeartbeatCycles;
    static constexpr int MAX_ALLOWED_MISSED_CYCLES = 2; // 2 * 5s = 10s of missed heartbeats triggers watchdog freeze
};
