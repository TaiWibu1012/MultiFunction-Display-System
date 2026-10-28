#pragma once

#include <QObject>
#include <QVariantList>
#include <QStringList>
#include <QFileSystemWatcher>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QFile>
#include <QTimer>
#include <QDebug>
#include <QThreadPool>

class DataManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList notices READ notices NOTIFY dataChanged)
    Q_PROPERTY(QVariantList schedules READ schedules NOTIFY dataChanged)
    Q_PROPERTY(QStringList newsTicker READ newsTicker NOTIFY dataChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY dataChanged)
    Q_PROPERTY(QString location READ location NOTIFY dataChanged)
    Q_PROPERTY(QString bannerTitle READ bannerTitle NOTIFY dataChanged)

public:
    explicit DataManager(QObject *parent = nullptr);
    ~DataManager() override;

    QVariantList notices() const { return m_notices; }
    QVariantList schedules() const { return m_schedules; }
    QStringList newsTicker() const { return m_newsTicker; }
    QString deviceName() const { return m_deviceName; }
    QString location() const { return m_location; }
    QString bannerTitle() const { return m_bannerTitle; }
    bool hasValidData() const { return m_hasValidData; }
    QString currentDataFilePath() const { return m_dataFilePath; }

public slots:
    void reload();

signals:
    void dataChanged();
    void dataReadSuccessful();
    void healthHeartbeat(); // DEF-01: Continuous liveness signal for Watchdog

private slots:
    void handleWatchedPathChanged(const QString &path);
    void checkWatcherHealth(); // DEF-01: Periodic health verification
    void applyParsedData(const QJsonObject &root, bool success);

private:
    void loadDefaults();
    void setupWatchers();

    const QString m_canonicalPath;
    const QString m_fallbackPath;
    QString m_dataFilePath;
    QString m_parentDirPath;

    QFileSystemWatcher m_watcher;
    QTimer m_debounceTimer;
    QTimer m_healthTimer;
    bool m_hasValidData;
    bool m_reloadInProgress;

    QVariantList m_notices;
    QVariantList m_schedules;
    QStringList m_newsTicker;
    QString m_deviceName;
    QString m_location;
    QString m_bannerTitle;
};

