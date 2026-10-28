#include "NewsFetcher.h"
#include <QNetworkRequest>
#include <QXmlStreamReader>
#include <QSslError>
#include <QVariantMap>
#include <QDebug>

NewsFetcher::NewsFetcher(QObject *parent) : QObject(parent)
{
    connect(&m_networkManager, &QNetworkAccessManager::finished,
            this, &NewsFetcher::onNetworkReply);

    m_newsList << "Khoa Kỹ thuật Máy tính (FCE - UIT) - Trưởng khoa: TS. Nguyễn Minh Sơn | Phó Trưởng khoa: TS. Đoàn Duy | Phó Trưởng khoa: Ths. Phan Đình Duy"
               << "Chúc mừng ThS. Phan Đình Duy đạt danh hiệu Giảng viên của năm 2025";

    // Dữ liệu thẻ mặc định khi khởi động
    m_newsItems.append(QVariantMap{
        {"title", "Đang đồng bộ dữ liệu thông báo mới nhất từ cổng thông tin fce.uit.edu.vn..."},
        {"date", "Hôm nay"},
        {"category", "HỆ THỐNG"}
    });

    updateNewsString();

    connect(&m_refreshTimer, &QTimer::timeout, this, &NewsFetcher::fetchNews);
    m_refreshTimer.start(600000);

    fetchNews();
}

QString NewsFetcher::currentNews() const
{
    return m_currentNewsString;
}

QVariantList NewsFetcher::newsItems() const
{
    return m_newsItems;
}

void NewsFetcher::fetchNews()
{
    qDebug() << "[NewsFetcher] Đang tải RSS từ https://fce.uit.edu.vn/feed/ ...";
    QUrl url("https://fce.uit.edu.vn/feed/");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      "Mozilla/5.0 (X11; Linux x86_64) Qt6Dashboard/1.0");

    QNetworkReply *reply = m_networkManager.get(request);

    connect(reply, &QNetworkReply::sslErrors, this, [reply](const QList<QSslError> &errors) {
        Q_UNUSED(errors);
        reply->ignoreSslErrors();
    });
}

void NewsFetcher::onNetworkReply(QNetworkReply *reply)
{
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray response = reply->readAll();
        QXmlStreamReader xml(response);

        QStringList fetchedStrings;
        QVariantList fetchedCards;
        bool insideItem = false;
        QString currentTitle;
        QString currentPubDate;

        while (!xml.atEnd() && !xml.hasError()) {
            QXmlStreamReader::TokenType token = xml.readNext();

            if (token == QXmlStreamReader::StartElement) {
                if (xml.name() == QLatin1String("item")) {
                    insideItem = true;
                    currentTitle.clear();
                    currentPubDate.clear();
                } else if (insideItem && xml.name() == QLatin1String("title")) {
                    currentTitle = xml.readElementText().trimmed();
                } else if (insideItem && xml.name() == QLatin1String("pubDate")) {
                    // Cắt lấy phần ngày tháng gọn gàng (VD: "15 Oct 2026")
                    QString rawDate = xml.readElementText().trimmed();
                    currentPubDate = (rawDate.length() >= 16) ? rawDate.mid(5, 11) : rawDate;
                }
            } else if (token == QXmlStreamReader::EndElement) {
                if (xml.name() == QLatin1String("item")) {
                    insideItem = false;
                    if (!currentTitle.isEmpty()) {
                        fetchedStrings.append("Thông báo mới: " + currentTitle);

                        // Tự động gắn nhãn phân loại dựa theo từ khóa tiêu đề
                        QString category = "THÔNG BÁO";
                        if (currentTitle.contains("Seminar", Qt::CaseInsensitive)) {
                            category = "SEMINAR";
                        } else if (currentTitle.contains("học vụ", Qt::CaseInsensitive) ||
                                   currentTitle.contains("chứng chỉ", Qt::CaseInsensitive)) {
                            category = "HỌC VỤ";
                        }

                        QVariantMap card;
                        card["title"] = currentTitle;
                        card["date"] = currentPubDate.isEmpty() ? "Mới cập nhật" : currentPubDate;
                        card["category"] = category;
                        fetchedCards.append(card);
                    }
                    if (fetchedStrings.size() >= 5) {
                        break;
                    }
                }
            }
        }

        if (!fetchedStrings.isEmpty()) {
            m_newsList.clear();
            m_newsList << "Khoa Kỹ thuật Máy tính (FCE - UIT) - Trưởng khoa: TS. Nguyễn Minh Sơn | Phó Trưởng khoa: TS. Đoàn Duy | Phó Trưởng khoa: Ths. Phan Đình Duy"
                       << "Chúc mừng ThS. Phan Đình Duy đạt danh hiệu Giảng viên của năm 2025";
            m_newsList.append(fetchedStrings);

            m_newsItems = fetchedCards;
            updateNewsString();
        }
    } else {
        qWarning() << "[NewsFetcher] Lỗi kết nối mạng:" << reply->errorString();
    }

    reply->deleteLater();
}

void NewsFetcher::updateNewsString()
{
    m_currentNewsString = m_newsList.join("   🔹   ");
    emit currentNewsChanged();
}