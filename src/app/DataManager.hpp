#pragma once

#include <QObject>
#include <QVariantList>
#include <QStringList>
#include <QFileSystemWatcher>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QFile>
#include <QDebug>

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

    QVariantList notices() const { return m_notices; }
    QVariantList schedules() const { return m_schedules; }
    QStringList newsTicker() const { return m_newsTicker; }
    QString deviceName() const { return m_deviceName; }
    QString location() const { return m_location; }
    QString bannerTitle() const { return m_bannerTitle; }

public slots:
    void reload();

signals:
    void dataChanged();

private:
    void loadDefaults();
    void parseJsonData(const QByteArray &data);

    QString m_dataFilePath;
    QFileSystemWatcher m_watcher;

    QVariantList m_notices;
    QVariantList m_schedules;
    QStringList m_newsTicker;
    QString m_deviceName;
    QString m_location;
    QString m_bannerTitle;
};
