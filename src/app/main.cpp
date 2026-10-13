#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QCursor> // Dùng để ẩn chuột

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Ẩn con trỏ chuột hoàn toàn cho Kiosk Mode
    app.setOverrideCursor(QCursor(Qt::BlankCursor));

    QQmlApplicationEngine engine;
    
    // Nạp giao diện gốc
    const QUrl url(u"qrc:/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);
        
    engine.load(url);

    return app.exec();
}
