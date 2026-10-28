#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QStringList>
#include <QVariantList>
#include <QTimer>

class NewsFetcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentNews READ currentNews NOTIFY currentNewsChanged)
    Q_PROPERTY(QVariantList newsItems READ newsItems NOTIFY currentNewsChanged)

public:
    explicit NewsFetcher(QObject *parent = nullptr);

    QString currentNews() const;
    QVariantList newsItems() const;
    Q_INVOKABLE void fetchNews();

signals:
    void currentNewsChanged();

private slots:
    void onNetworkReply(QNetworkReply *reply);

private:
    QNetworkAccessManager m_networkManager;
    QStringList m_newsList;
    QVariantList m_newsItems;
    QString m_currentNewsString;
    QTimer m_refreshTimer;

    void updateNewsString();
};