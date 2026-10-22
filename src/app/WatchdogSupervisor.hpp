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

private:
    void openDevice(int timeoutSec);
    void closeDevice();

    int m_fd;
    bool m_enabled;
    QTimer m_pingTimer;
};
