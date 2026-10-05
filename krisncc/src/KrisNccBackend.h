#pragma once

#include <QObject>
#include <QPointer>
#include <QVariantList>
#include <QVariantMap>

class QProcess;

class KrisNccBackend final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qint64 memoryUsedMiB READ memoryUsedMiB NOTIFY resourcesChanged)
    Q_PROPERTY(qint64 memoryTotalMiB READ memoryTotalMiB NOTIFY resourcesChanged)
    Q_PROPERTY(double cpuTemperatureC READ cpuTemperatureC NOTIFY resourcesChanged)
    Q_PROPERTY(QVariantMap configStatus READ configStatus NOTIFY configStatusChanged)
    Q_PROPERTY(QString configDiff READ configDiff NOTIFY configDiffChanged)
    Q_PROPERTY(QVariantMap runtimeStatus READ runtimeStatus NOTIFY runtimeStatusChanged)
    Q_PROPERTY(QVariantList softwareItems READ softwareItems NOTIFY softwareItemsChanged)
    Q_PROPERTY(QVariantList searchResults READ searchResults NOTIFY searchResultsChanged)
    Q_PROPERTY(QStringList distroboxes READ distroboxes NOTIFY distroboxesChanged)
    Q_PROPERTY(QStringList systemGenerations READ systemGenerations NOTIFY recoveryChanged)
    Q_PROPERTY(QStringList profileHistory READ profileHistory NOTIFY recoveryChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool canCancel READ canCancel NOTIFY busyChanged)
    Q_PROPERTY(QString lastMessage READ lastMessage NOTIFY lastMessageChanged)

public:
    explicit KrisNccBackend(QObject *parent = nullptr);

    qint64 memoryUsedMiB() const { return m_memoryUsedMiB; }
    qint64 memoryTotalMiB() const { return m_memoryTotalMiB; }
    double cpuTemperatureC() const { return m_cpuTemperatureC; }
    QVariantMap configStatus() const { return m_configStatus; }
    QString configDiff() const { return m_configDiff; }
    QVariantMap runtimeStatus() const { return m_runtimeStatus; }
    QVariantList softwareItems() const { return m_softwareItems; }
    QVariantList searchResults() const { return m_searchResults; }
    QStringList distroboxes() const { return m_distroboxes; }
    QStringList systemGenerations() const { return m_systemGenerations; }
    QStringList profileHistory() const { return m_profileHistory; }
    bool busy() const { return m_busy; }
    bool canCancel() const;
    QString lastMessage() const { return m_lastMessage; }

    Q_INVOKABLE void refreshResources();
    Q_INVOKABLE void refreshConfigStatus();
    Q_INVOKABLE void fetchConfig();
    Q_INVOKABLE void showConfigDiff();
    Q_INVOKABLE void syncConfig();
    Q_INVOKABLE void validateConfig();
    Q_INVOKABLE void buildConfig();
    Q_INVOKABLE void applyConfig();
    Q_INVOKABLE void refreshRuntimeStatus();
    Q_INVOKABLE void setBluetoothEnabled(bool enabled);
    Q_INVOKABLE void setFirewallEnabled(bool enabled);
    Q_INVOKABLE void refreshSoftware();
    Q_INVOKABLE void searchSoftware(const QString &query);
    Q_INVOKABLE void addSoftware(const QString &attribute, bool allowUnfree = false);
    Q_INVOKABLE void runSoftware(const QString &attribute, bool allowUnfree = false);
    Q_INVOKABLE void removeSoftware(const QString &name);
    Q_INVOKABLE void previewSoftwareUpdates(bool allowUnfree = false);
    Q_INVOKABLE void refreshDistroboxes();
    Q_INVOKABLE void refreshRecovery();
    Q_INVOKABLE bool launchTool(const QString &toolId);
    Q_INVOKABLE void cancelCurrentOperation();

signals:
    void resourcesChanged();
    void configStatusChanged();
    void configDiffChanged();
    void runtimeStatusChanged();
    void softwareItemsChanged();
    void searchResultsChanged();
    void distroboxesChanged();
    void recoveryChanged();
    void busyChanged();
    void lastMessageChanged();

private:
    QProcess *startCommand(const QString &program, const QStringList &arguments,
                           const QString &operation, bool userOperation = false);
    void startRuntimeMutation(const QString &feature, bool enabled);
    void handleCommandResult(const QString &operation, int exitCode,
                             const QByteArray &out, const QByteArray &err);
    void updateBluetoothState();
    void terminateProcessGroup(QProcess *process, bool force = false);
    void setBusy(bool value);
    void setMessage(const QString &message);
    static QString nixAttributeFromSearchKey(const QString &key);
    static double readCpuTemperature();

    qint64 m_memoryUsedMiB = -1;
    qint64 m_memoryTotalMiB = -1;
    double m_cpuTemperatureC = -1.0;
    QVariantMap m_configStatus;
    QString m_configDiff;
    QVariantMap m_runtimeStatus;
    QVariantList m_softwareItems;
    QVariantList m_searchResults;
    QStringList m_distroboxes;
    QStringList m_systemGenerations;
    QStringList m_profileHistory;
    quint64 m_searchSerial = 0;
    QString m_searchQuery;
    QString m_rfkillBluetoothState = QStringLiteral("unknown");
    QString m_bluezBluetoothState = QStringLiteral("unknown");
    bool m_busy = false;
    QString m_lastMessage;

    QPointer<QProcess> m_activeUserProcess;
    QPointer<QProcess> m_cancelledProcess;
    QPointer<QProcess> m_searchProcess;
};
