#pragma once

#include <QObject>
#include <QTimer>
#include <QDebug>
#include <atomic>

class WatchdogSupervisor : public QObject
{
    Q_OBJECT

public:
    explicit WatchdogSupervisor(int timeoutSec = 15, int pingIntervalSec = 5, QObject *parent = nullptr);
    ~WatchdogSupervisor() override;

    bool isEnabled() const { return m_enabled; }
    int missedHeartbeatCycles() const { return m_missedHeartbeatCycles.load(std::memory_order_relaxed); }
    bool renderHeartbeat() const { return m_renderHeartbeat.load(std::memory_order_relaxed); }
    bool dataHeartbeat() const { return m_dataHeartbeat.load(std::memory_order_relaxed); }

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

    // Subsystem Health Heartbeat flags (Atomic to prevent cross-thread data races per DEF-03)
    std::atomic<bool> m_renderHeartbeat;
    std::atomic<bool> m_dataHeartbeat;
    std::atomic<int> m_missedHeartbeatCycles;
    static constexpr int MAX_ALLOWED_MISSED_CYCLES = 2; // 2 * 5s = 10s of missed heartbeats triggers watchdog freeze
};

