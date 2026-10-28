#include "WeatherFetcher.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSslError>
#include <QDebug>

WeatherFetcher::WeatherFetcher(QObject *parent)
    : QObject(parent),
      m_temperature("31°C"),
      m_humidity("68%"),
      m_weatherIcon("🌤️"),
      m_weatherDescription("Nắng dịu"),
      m_weatherText("31°C | Độ ẩm: 68%")
{
    connect(&m_networkManager, &QNetworkAccessManager::finished,
            this, &WeatherFetcher::onNetworkReply);

    // Cập nhật lại thời tiết mỗi 60 giây (60.000 ms)
    connect(&m_refreshTimer, &QTimer::timeout, this, &WeatherFetcher::fetchWeather);
    m_refreshTimer.start(60000);

    // Tải dữ liệu thời tiết ngay khi khởi động
    fetchWeather();
}

QString WeatherFetcher::temperature() const
{
    return m_temperature;
}

QString WeatherFetcher::humidity() const
{
    return m_humidity;
}

QString WeatherFetcher::weatherIcon() const
{
    return m_weatherIcon;
}

QString WeatherFetcher::weatherDescription() const
{
    return m_weatherDescription;
}

QString WeatherFetcher::weatherText() const
{
    return m_weatherText;
}

void WeatherFetcher::fetchWeather()
{
    // Tọa độ chuẩn Khu đô thị ĐHQG-HCM / Trường ĐH Công nghệ Thông tin (UIT)
    // Latitude: 10.8700, Longitude: 106.8031
    QUrl url("https://api.open-meteo.com/v1/forecast?latitude=10.8700&longitude=106.8031&current=temperature_2m,relative_humidity_2m,weather_code&timezone=Asia%2FHo_Chi_Minh");
    
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      "Mozilla/5.0 (X11; Linux x86_64) Qt6Dashboard/1.0");

    QNetworkReply *reply = m_networkManager.get(request);

    connect(reply, &QNetworkReply::sslErrors, this, [reply](const QList<QSslError> &errors) {
        Q_UNUSED(errors);
        reply->ignoreSslErrors();
    });

    qDebug() << "[WeatherFetcher] Đang cập nhật dữ liệu thời tiết thực tế từ Open-Meteo...";
}

void WeatherFetcher::onNetworkReply(QNetworkReply *reply)
{
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray response = reply->readAll();
        QJsonDocument jsonDoc = QJsonDocument::fromJson(response);
        if (jsonDoc.isObject()) {
            QJsonObject rootObj = jsonDoc.object();
            if (rootObj.contains("current") && rootObj["current"].isObject()) {
                QJsonObject current = rootObj["current"].toObject();

                double temp = current["temperature_2m"].toDouble(31.0);
                int humidity = current["relative_humidity_2m"].toInt(68);
                int weatherCode = current["weather_code"].toInt(1);

                updateWeather(temp, humidity, weatherCode);
                qDebug() << "[WeatherFetcher] Thời tiết cập nhật thành công:" << m_weatherText << m_weatherDescription;
            }
        }
    } else {
        qWarning() << "[WeatherFetcher] Lỗi kết nối Open-Meteo:" << reply->errorString();
    }

    reply->deleteLater();
}

void WeatherFetcher::updateWeather(double temp, int humidity, int weatherCode)
{
    m_temperature = QString::asprintf("%.1f°C", temp);
    m_humidity = QString::asprintf("%d%%", humidity);

    // Bảng mã thời tiết chuẩn WMO (World Meteorological Organization)
    switch (weatherCode) {
    case 0:
        m_weatherIcon = "☀️";
        m_weatherDescription = "Trời quang";
        break;
    case 1:
    case 2:
        m_weatherIcon = "🌤️";
        m_weatherDescription = "Nắng dịu";
        break;
    case 3:
        m_weatherIcon = "☁️";
        m_weatherDescription = "Nhiều mây";
        break;
    case 45:
    case 48:
        m_weatherIcon = "🌫️";
        m_weatherDescription = "Sương mù";
        break;
    case 51:
    case 53:
    case 55:
        m_weatherIcon = "🌦️";
        m_weatherDescription = "Mưa phùn";
        break;
    case 61:
    case 63:
    case 65:
        m_weatherIcon = "🌧️";
        m_weatherDescription = "Mưa rào";
        break;
    case 80:
    case 81:
    case 82:
        m_weatherIcon = "🌧️";
        m_weatherDescription = "Mưa to";
        break;
    case 95:
    case 96:
    case 99:
        m_weatherIcon = "⛈️";
        m_weatherDescription = "Có dông sét";
        break;
    default:
        m_weatherIcon = "🌤️";
        m_weatherDescription = "Thời tiết tốt";
        break;
    }

    m_weatherText = QString("%1 | Độ ẩm: %2").arg(m_temperature, m_humidity);

    emit weatherChanged();
}

