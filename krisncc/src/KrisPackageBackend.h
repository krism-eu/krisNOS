#pragma once

#include <QObject>
#include <QPointer>
#include <QStringList>
#include <QVariantMap>

class QProcess;

class KrisPackageBackend final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList systemPackages READ systemPackages NOTIFY systemPackagesChanged)
    Q_PROPERTY(QVariantMap cleanupStatus READ cleanupStatus NOTIFY cleanupStatusChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString lastMessage READ lastMessage NOTIFY lastMessageChanged)

public:
    explicit KrisPackageBackend(QObject *parent = nullptr);

    QStringList systemPackages() const { return m_systemPackages; }
    QVariantMap cleanupStatus() const { return m_cleanupStatus; }
    bool busy() const { return m_busy; }
    QString lastMessage() const { return m_lastMessage; }

    Q_INVOKABLE void refreshSystemPackages();
    Q_INVOKABLE void installSystemPackage(const QString &attribute, bool allowUnfree = false);
    Q_INVOKABLE void removeSystemPackage(const QString &attribute);

    Q_INVOKABLE void refreshCleanup();
    Q_INVOKABLE void cleanupProfileHistory();
    Q_INVOKABLE void cleanupSystemGenerations();
    Q_INVOKABLE void cleanupStore();

signals:
    void systemPackagesChanged();
    void cleanupStatusChanged();
    void busyChanged();
    void lastMessageChanged();
    void systemConfigurationChanged();

private:
    QProcess *startCommand(const QStringList &arguments, const QString &operation, bool userOperation = false);
    void handleCommandResult(const QString &operation, int exitCode,
                             const QByteArray &out, const QByteArray &err);
    void setBusy(bool value);
    void setMessage(const QString &message);

    QStringList m_systemPackages;
    QVariantMap m_cleanupStatus;
    bool m_busy = false;
    QString m_lastMessage;
    QPointer<QProcess> m_activeProcess;
};
