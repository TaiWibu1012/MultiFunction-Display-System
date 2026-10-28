#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCursor>
#include <QFontDatabase>
#include <QFont>
#include "NewsFetcher.h"
#include "WeatherFetcher.h"

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    // Cấu hình dành cho môi trường nhúng (Raspberry Pi 4 / Yocto)
    qputenv("QT_QPA_PLATFORM", "eglfs"); 
    qputenv("QT_QPA_PLATFORMTHEME", "");
    
    // ĐẢM BẢO ĐÃ XÓA (HOẶC COMMENT) DÒNG NÀY:
    // qputenv("QT_QUICK_BACKEND", "software"); 
    
    // Tùy chọn: Ép kích thước màn hình vật lý (nếu Pi nhận sai độ phân giải HDMI)
    // qputenv("QT_QPA_EGLFS_PHYSICAL_WIDTH", "1920");
    // qputenv("QT_QPA_EGLFS_PHYSICAL_HEIGHT", "1080");

    QGuiApplication app(argc, argv);

    // Nạp phông chữ Be Vietnam Pro tối ưu tiếng Việt không bị lỗi co giãn dấu
    QFontDatabase::addApplicationFont(u":/DashboardUI/src/app/assets/fonts/BeVietnamPro-Regular.ttf"_s);
    QFontDatabase::addApplicationFont(u":/DashboardUI/src/app/assets/fonts/BeVietnamPro-SemiBold.ttf"_s);
    QFontDatabase::addApplicationFont(u":/DashboardUI/src/app/assets/fonts/BeVietnamPro-Bold.ttf"_s);

    QFont appFont(u"Be Vietnam Pro"_s);
    appFont.setStyleHint(QFont::SansSerif);
    app.setFont(appFont);

    NewsFetcher newsFetcher;
    WeatherFetcher weatherFetcher;

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("newsManager", &newsFetcher);
    engine.rootContext()->setContextProperty("weatherManager", &weatherFetcher);
    
    const QUrl url(u"qrc:/DashboardUI/src/app/Main.qml"_s);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);
        
    engine.load(url);

    return app.exec();
}