#include "DataManager.hpp"
#include <QCoreApplication>
#include <QFileInfo>
#include <QDir>
#include <QMetaObject>

DataManager::DataManager(QObject *parent)
    : QObject(parent)
    , m_canonicalPath(QStringLiteral("/var/lib/mfds/data.json"))
    , m_fallbackPath(QCoreApplication::applicationDirPath() + QStringLiteral("/data_sample.json"))
    , m_dataFilePath(m_canonicalPath)
    , m_hasValidData(false)
    , m_reloadInProgress(false)
    , m_deviceName("MFDS-Display-Box")
    , m_location("Văn Phòng Khoa KTMT")
    , m_bannerTitle("BẢNG TIN ĐIỆN TỬ THÔNG MINH")
{
    m_parentDirPath = QFileInfo(m_canonicalPath).absolutePath();

    // Verify canonical path existence; fallback to application sample if missing initially
    if (!QFile::exists(m_canonicalPath) && QFile::exists(m_fallbackPath)) {
        m_dataFilePath = m_fallbackPath;
        qInfo() << "[DataManager] Canonical path" << m_canonicalPath << "not found at startup; using fallback" << m_fallbackPath;
    } else {
        m_dataFilePath = m_canonicalPath;
    }

    // Debounce timer (150ms) to coalesce inotify bursts and wait for atomic sync
    m_debounceTimer.setSingleShot(true);
    m_debounceTimer.setInterval(150);
    connect(&m_debounceTimer, &QTimer::timeout, this, &DataManager::reload);

    // DEF-01: Periodic health heartbeat timer (2000ms) to monitor watcher & thread health
    connect(&m_healthTimer, &QTimer::timeout, this, &DataManager::checkWatcherHealth);
    m_healthTimer.start(2000);

    setupWatchers();

    // Initial asynchronous load
    reload();
}

DataManager::~DataManager()
{
    m_healthTimer.stop();
    m_debounceTimer.stop();
}

void DataManager::setupWatchers()
{
    // Ensure parent directory exists for inotify watching
    QDir parentDir(m_parentDirPath);
    if (!parentDir.exists()) {
        parentDir.mkpath(QStringLiteral("."));
    }

    // Always watch canonical parent directory to catch creation/atomic replacement of data.json (DEF-06)
    if (parentDir.exists() && !m_watcher.directories().contains(m_parentDirPath)) {
        m_watcher.addPath(m_parentDirPath);
    }

    // If canonical or current data file exists, watch it directly
    if (QFile::exists(m_dataFilePath) && !m_watcher.files().contains(m_dataFilePath)) {
        m_watcher.addPath(m_dataFilePath);
    }

    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &DataManager::handleWatchedPathChanged);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &DataManager::handleWatchedPathChanged);
}

void DataManager::handleWatchedPathChanged(const QString &path)
{
    // DEF-06: Filter directory changes specifically for data.json creation or modification
    if (path == m_parentDirPath) {
        // Directory change: check if canonical file was created or modified
        if (QFile::exists(m_canonicalPath)) {
            if (m_dataFilePath != m_canonicalPath) {
                qInfo() << "[DataManager] Canonical data.json detected in" << m_parentDirPath << "; switching target.";
                m_dataFilePath = m_canonicalPath;
            }
            if (!m_watcher.files().contains(m_canonicalPath)) {
                m_watcher.addPath(m_canonicalPath);
            }
            m_debounceTimer.start();
        }
        return;
    }

    // File change event on watched file
    if (path == m_dataFilePath || path == m_canonicalPath) {
        // If file was replaced atomically via rename, inotify watcher might drop it; re-add if exists
        if (QFile::exists(path) && !m_watcher.files().contains(path)) {
            m_watcher.addPath(path);
        }
        m_debounceTimer.start();
    }
}

void DataManager::checkWatcherHealth()
{
    // DEF-01: Health check pulse for WatchdogSupervisor
    // Verify that the event loop is responsive and inotify watcher or target storage is active
    bool watcherOk = !m_watcher.directories().isEmpty() || !m_watcher.files().isEmpty();
    bool fileOk = QFile::exists(m_dataFilePath) || QFile::exists(m_canonicalPath) || m_hasValidData;

    if (watcherOk && fileOk) {
        emit healthHeartbeat();
    } else {
        qWarning() << "[DataManager] Watcher health degraded (watcherOk:" << watcherOk << "fileOk:" << fileOk << ")";
    }
}

void DataManager::reload()
{
    if (m_reloadInProgress) {
        return;
    }
    m_reloadInProgress = true;

    // Check if canonical path has become available
    if (m_dataFilePath != m_canonicalPath && QFile::exists(m_canonicalPath)) {
        m_dataFilePath = m_canonicalPath;
        if (!m_watcher.files().contains(m_canonicalPath)) {
            m_watcher.addPath(m_canonicalPath);
        }
    }

    const QString targetFile = m_dataFilePath;

    // DEF-04: Offload disk I/O and JSON deserialization to worker thread pool
    QThreadPool::globalInstance()->start([this, targetFile]() {
        QFile file(targetFile);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QMetaObject::invokeMethod(this, [this]() {
                qWarning() << "[DataManager] Asynchronous reader cannot open file:" << m_dataFilePath;
                if (!m_hasValidData) {
                    loadDefaults();
                }
                m_reloadInProgress = false;
            }, Qt::QueuedConnection);
            return;
        }

        QByteArray rawData = file.readAll();
        file.close();

        if (rawData.trimmed().isEmpty()) {
            QMetaObject::invokeMethod(this, [this]() {
                qWarning() << "[DataManager] Read empty payload (atomic write in progress). Preserving cache.";
                m_reloadInProgress = false;
            }, Qt::QueuedConnection);
            return;
        }

        QJsonParseError parseError;
        QJsonDocument doc = QJsonDocument::fromJson(rawData, &parseError);
        if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
            QMetaObject::invokeMethod(this, [this, errStr = parseError.errorString()]() {
                qWarning() << "[DataManager] Asynchronous JSON parse error:" << errStr;
                if (!m_hasValidData) {
                    loadDefaults();
                }
                m_reloadInProgress = false;
            }, Qt::QueuedConnection);
            return;
        }

        QJsonObject rootObj = doc.object();
        QMetaObject::invokeMethod(this, [this, rootObj]() {
            applyParsedData(rootObj, true);
            m_reloadInProgress = false;
        }, Qt::QueuedConnection);
    });
}

void DataManager::applyParsedData(const QJsonObject &root, bool success)
{
    if (!success) {
        if (!m_hasValidData) {
            loadDefaults();
        }
        return;
    }

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

    qDebug() << "[DataManager] Data updated asynchronously:"
             << m_notices.size() << "notices,"
             << m_schedules.size() << "schedules,"
             << m_newsTicker.size() << "tickers.";

    m_hasValidData = true;
    emit dataChanged();
    emit dataReadSuccessful();
    emit healthHeartbeat(); // Immediate heartbeat pulse upon successful data arrival
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

