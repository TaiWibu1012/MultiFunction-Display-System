#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTimer>
#include <QString>

class WeatherFetcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString temperature READ temperature NOTIFY weatherChanged)
    Q_PROPERTY(QString humidity READ humidity NOTIFY weatherChanged)
    Q_PROPERTY(QString weatherIcon READ weatherIcon NOTIFY weatherChanged)
    Q_PROPERTY(QString weatherDescription READ weatherDescription NOTIFY weatherChanged)
    Q_PROPERTY(QString weatherText READ weatherText NOTIFY weatherChanged)

public:
    explicit WeatherFetcher(QObject *parent = nullptr);

    QString temperature() const;
    QString humidity() const;
    QString weatherIcon() const;
    QString weatherDescription() const;
    QString weatherText() const;

    Q_INVOKABLE void fetchWeather();

signals:
    void weatherChanged();

private slots:
    void onNetworkReply(QNetworkReply *reply);

private:
    QNetworkAccessManager m_networkManager;
    QTimer m_refreshTimer;

    QString m_temperature;
    QString m_humidity;
    QString m_weatherIcon;
    QString m_weatherDescription;
    QString m_weatherText;

    void updateWeather(double temp, int humidity, int weatherCode);
};

