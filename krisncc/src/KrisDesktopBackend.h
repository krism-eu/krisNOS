#pragma once

#include <QObject>
#include <QPointer>
#include <QStringList>
#include <QVariantList>

class QProcess;

class KrisDesktopBackend final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int cpuUsagePercent READ cpuUsagePercent NOTIFY resourcesChanged)
    Q_PROPERTY(qint64 diskAvailableGiB READ diskAvailableGiB NOTIFY resourcesChanged)
    Q_PROPERTY(qint64 diskTotalGiB READ diskTotalGiB NOTIFY resourcesChanged)
    Q_PROPERTY(QString powerProfile READ powerProfile NOTIFY powerProfileChanged)
    Q_PROPERTY(QString diagnosticTitle READ diagnosticTitle NOTIFY diagnosticChanged)
    Q_PROPERTY(QString diagnosticOutput READ diagnosticOutput NOTIFY diagnosticChanged)
    Q_PROPERTY(QVariantList customActions READ customActions NOTIFY customActionsChanged)
    Q_PROPERTY(int customActionLimit READ customActionLimit CONSTANT)
    Q_PROPERTY(QString actionOutput READ actionOutput NOTIFY actionStateChanged)
    Q_PROPERTY(QString actionError READ actionError NOTIFY actionStateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool canCancel READ canCancel NOTIFY busyChanged)
    Q_PROPERTY(QString lastMessage READ lastMessage NOTIFY lastMessageChanged)

public:
    explicit KrisDesktopBackend(QObject *parent = nullptr);

    int cpuUsagePercent() const { return m_cpuUsagePercent; }
    qint64 diskAvailableGiB() const { return m_diskAvailableGiB; }
    qint64 diskTotalGiB() const { return m_diskTotalGiB; }
    QString powerProfile() const { return m_powerProfile; }
    QString diagnosticTitle() const { return m_diagnosticTitle; }
    QString diagnosticOutput() const { return m_diagnosticOutput; }
    QVariantList customActions() const { return m_customActions; }
    int customActionLimit() const { return 12; }
    QString actionOutput() const { return m_actionOutput; }
    QString actionError() const { return m_actionError; }
    bool busy() const { return m_busy; }
    bool canCancel() const { return m_busy && m_operationCancellable; }
    QString lastMessage() const { return m_lastMessage; }

    Q_INVOKABLE void refreshResources();
    Q_INVOKABLE void refreshPowerProfile();
    Q_INVOKABLE void setPowerProfile(const QString &profile);
    Q_INVOKABLE void restartAudio();
    Q_INVOKABLE void runDiagnostic(const QString &diagnosticId);
    Q_INVOKABLE void clearDiagnostic();
    Q_INVOKABLE void rollbackSystem();
    Q_INVOKABLE void rollbackProfile();
    Q_INVOKABLE void reloadCustomActions();
    Q_INVOKABLE bool saveCustomAction(const QString &id, const QString &name,
                                      const QString &script, bool confirmBeforeRun);
    Q_INVOKABLE bool removeCustomAction(const QString &id);
    Q_INVOKABLE bool runCustomAction(const QString &id);
    Q_INVOKABLE void cancelCurrentOperation();
    Q_INVOKABLE bool launchTool(const QString &toolId);

signals:
    void resourcesChanged();
    void powerProfileChanged();
    void diagnosticChanged();
    void customActionsChanged();
    void actionStateChanged();
    void busyChanged();
    void lastMessageChanged();
    void recoveryRefreshRequested();

private:
    QProcess *startOperation(const QString &program, const QStringList &arguments,
                             const QString &operation, bool cancellable,
                             int timeoutMs = 0, const QString &workingDirectory = {});
    void finishOperation(QProcess *process, const QString &operation,
                         int exitCode, const QByteArray &output);
    void terminateProcessGroup(QProcess *process, bool force);
    void setBusy(bool busy, bool cancellable = false);
    void setMessage(const QString &message);
    QString customActionsPath() const;
    int customActionIndex(const QString &id) const;
    bool persistCustomActions();
    bool validateCustomAction(const QString &name, const QString &script,
                              QString *error) const;
    static QString previousSystemToplevel();

    int m_cpuUsagePercent = -1;
    quint64 m_previousCpuTotal = 0;
    quint64 m_previousCpuIdle = 0;
    qint64 m_diskAvailableGiB = -1;
    qint64 m_diskTotalGiB = -1;
    QString m_powerProfile = QStringLiteral("unknown");
    QString m_diagnosticTitle;
    QString m_diagnosticOutput;
    QVariantList m_customActions;
    QString m_actionOutput;
    QString m_actionError;
    QString m_lastMessage;
    bool m_customStorageValid = true;
    bool m_busy = false;
    bool m_operationCancellable = false;
    QPointer<QProcess> m_activeProcess;
};
