#include "DataManager.hpp"
#include <QCoreApplication>
#include <QFileInfo>
#include <QDir>

DataManager::DataManager(QObject *parent)
    : QObject(parent)
    , m_deviceName("MFDS-Display-Box")
    , m_location("Văn Phòng Bộ Môn KTMT")
    , m_bannerTitle("BẢNG TIN ĐIỆN TỬ THÔNG MINH")
{
    // Search order for data storage path
    const QString systemPath = QStringLiteral("/var/lib/mfds/data.json");
    const QString localPath = QCoreApplication::applicationDirPath() + QStringLiteral("/data_sample.json");

    if (QFile::exists(systemPath)) {
        m_dataFilePath = systemPath;
    } else {
        m_dataFilePath = localPath;
    }

    // Monitor file changes using inotify-backed QFileSystemWatcher
    if (QFile::exists(m_dataFilePath)) {
        m_watcher.addPath(m_dataFilePath);
    }

    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString &path) {
        qDebug() << "[DataManager] Detected IPC data change in:" << path;
        // Re-add to watcher if file was replaced atomically (rename)
        if (!m_watcher.files().contains(m_dataFilePath) && QFile::exists(m_dataFilePath)) {
            m_watcher.addPath(m_dataFilePath);
        }
        reload();
    });

    reload();
}

void DataManager::reload()
{
    QFile file(m_dataFilePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "[DataManager] Cannot open data file:" << m_dataFilePath << "- using defaults.";
        loadDefaults();
        return;
    }

    QByteArray rawData = file.readAll();
    file.close();

    parseJsonData(rawData);
}

void DataManager::parseJsonData(const QByteArray &data)
{
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);

    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning() << "[DataManager] JSON parse error:" << parseError.errorString();
        loadDefaults();
        return;
    }

    QJsonObject root = doc.object();

    // 1. System info
    if (root.contains("system") && root["system"].isObject()) {
        QJsonObject sysObj = root["system"].toObject();
        m_deviceName = sysObj.value("device_name").toString(m_deviceName);
        m_location = sysObj.value("location").toString(m_location);
        m_bannerTitle = sysObj.value("banner_title").toString(m_bannerTitle);
    }

    // 2. Notices array
    if (root.contains("notices") && root["notices"].isArray()) {
        m_notices.clear();
        QJsonArray noticeArray = root["notices"].toArray();
        for (const auto &val : noticeArray) {
            if (val.isObject()) {
                m_notices.append(val.toObject().toVariantMap());
            }
        }
    }

    // 3. Schedules array
    if (root.contains("schedules") && root["schedules"].isArray()) {
        m_schedules.clear();
        QJsonArray schedArray = root["schedules"].toArray();
        for (const auto &val : schedArray) {
            if (val.isObject()) {
                m_schedules.append(val.toObject().toVariantMap());
            }
        }
    }

    // 4. News ticker
    if (root.contains("news_ticker") && root["news_ticker"].isArray()) {
        m_newsTicker.clear();
        QJsonArray tickerArray = root["news_ticker"].toArray();
        for (const auto &val : tickerArray) {
            m_newsTicker.append(val.toString());
        }
    }

    qDebug() << "[DataManager] Data reloaded successfully: "
             << m_notices.size() << "notices,"
             << m_schedules.size() << "schedules,"
             << m_newsTicker.size() << "tickers.";

    emit dataChanged();
}

void DataManager::loadDefaults()
{
    m_notices.clear();
    QVariantMap defNotice;
    defNotice["title"] = "Hệ thống Đang Khởi tạo";
    defNotice["content"] = "Đang chờ nạp dữ liệu từ máy chủ quản lý nội bộ...";
    defNotice["priority"] = "info";
    defNotice["date"] = "2026-10-20";
    defNotice["active"] = true;
    m_notices.append(defNotice);

    m_schedules.clear();
    QVariantMap defSched;
    defSched["time_slot"] = "08:00 - 17:00";
    defSched["event_name"] = "Vận hành Hệ thống Kiosk Thông minh";
    defSched["room"] = "Toàn hệ thống";
    defSched["host"] = "Admin";
    m_schedules.append(defSched);

    m_newsTicker.clear();
    m_newsTicker.append("HỆ THỐNG HIỂN THỊ ĐA CHỨC NĂNG (MFDS) - VẬN HÀNH TRÊN CUSTOM YOCTO LINUX");

    emit dataChanged();
}
