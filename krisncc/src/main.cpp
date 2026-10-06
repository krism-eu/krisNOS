#include <QCoreApplication>
#include <QGuiApplication>
#include <QPalette>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "KrisDesktopBackend.h"
#include "KrisNccBackend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QPalette palette = app.palette();
    palette.setColor(QPalette::HighlightedText, Qt::black);
    app.setPalette(palette);

    QCoreApplication::setOrganizationName(QStringLiteral("krisNOS"));
    QCoreApplication::setApplicationName(QStringLiteral("krisNCC"));
    QCoreApplication::setApplicationVersion(QStringLiteral(KRISNCC_VERSION));

    KrisNccBackend backend;
    KrisDesktopBackend desktopBackend;

    QObject::connect(&desktopBackend, &KrisDesktopBackend::recoveryRefreshRequested,
                     &backend, &KrisNccBackend::refreshRecovery);
    QObject::connect(&desktopBackend, &KrisDesktopBackend::recoveryRefreshRequested,
                     &backend, &KrisNccBackend::refreshConfigStatus);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("KrisBackend"), &backend);
    engine.rootContext()->setContextProperty(QStringLiteral("DesktopBackend"), &desktopBackend);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.loadFromModule(QStringLiteral("org.krisncc"), QStringLiteral("Main"));
    return app.exec();
}
