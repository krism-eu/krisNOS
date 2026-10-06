#include "KrisPackageBackend.h"

#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>

KrisPackageBackend::KrisPackageBackend(QObject *parent)
    : QObject(parent)
{
}

void KrisPackageBackend::setBusy(bool value)
{
    if (m_busy == value)
        return;
    m_busy = value;
    emit busyChanged();
}

void KrisPackageBackend::setMessage(const QString &message)
{
    if (m_lastMessage == message)
        return;
    m_lastMessage = message;
    emit lastMessageChanged();
}

QProcess *KrisPackageBackend::startCommand(const QStringList &arguments,
                                           const QString &operation,
                                           bool userOperation)
{
    const QString executable = QStandardPaths::findExecutable(QStringLiteral("kris-configctl"));
    if (executable.isEmpty()) {
        setMessage(tr("kris-configctl non disponibile."));
        return nullptr;
    }
    if (userOperation && m_busy) {
        setMessage(tr("Un'altra operazione è già in corso."));
        return nullptr;
    }

    auto *process = new QProcess(this);
    process->setProperty("krisOperation", operation);
    process->setProcessChannelMode(QProcess::SeparateChannels);

    if (userOperation) {
        m_activeProcess = process;
        setBusy(true);
    }

    connect(process, &QProcess::finished, this,
            [this, process, operation, userOperation](int exitCode, QProcess::ExitStatus status) {
        const QByteArray out = process->readAllStandardOutput();
        const QByteArray err = process->readAllStandardError();
        if (m_activeProcess == process)
            m_activeProcess = nullptr;
        if (userOperation)
            setBusy(false);

        handleCommandResult(operation,
                            status == QProcess::NormalExit ? exitCode : 127,
                            out, err);
        process->deleteLater();
    });

    connect(process, &QProcess::errorOccurred, this,
            [this, process, operation, userOperation](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart)
            return;
        if (m_activeProcess == process)
            m_activeProcess = nullptr;
        if (userOperation)
            setBusy(false);
        setMessage(tr("%1: impossibile avviare il processo: %2")
                       .arg(operation, process->errorString()));
        process->deleteLater();
    });

    process->start(executable, arguments);
    return process;
}

void KrisPackageBackend::handleCommandResult(const QString &operation, int exitCode,
                                             const QByteArray &out, const QByteArray &err)
{
    const QString outputText = QString::fromUtf8(out).trimmed();
    const QString errorText = QString::fromUtf8(err).trimmed();

    if (exitCode != 0) {
        if (operation == QStringLiteral("system-package-add")
            || operation == QStringLiteral("system-package-remove")) {
            refreshSystemPackages();
            refreshCleanup();
            emit systemConfigurationChanged();
        }
        setMessage(errorText.isEmpty()
                       ? tr("Operazione non riuscita (%1).").arg(exitCode)
                       : errorText.left(1600));
        return;
    }

    if (operation == QStringLiteral("system-packages")) {
        const QJsonDocument document = QJsonDocument::fromJson(out);
        if (!document.isArray()) {
            setMessage(tr("Elenco pacchetti di sistema non valido."));
            return;
        }
        QStringList packages;
        for (const QJsonValue &value : document.array()) {
            if (value.isString() && !value.toString().isEmpty())
                packages.append(value.toString());
        }
        packages.sort(Qt::CaseInsensitive);
        m_systemPackages = packages;
        emit systemPackagesChanged();
        return;
    }

    if (operation == QStringLiteral("cleanup-status")) {
        const QJsonDocument document = QJsonDocument::fromJson(out);
        if (!document.isObject()) {
            setMessage(tr("Stato pulizia non valido."));
            return;
        }
        m_cleanupStatus = document.object().toVariantMap();
        emit cleanupStatusChanged();
        return;
    }

    if (operation == QStringLiteral("system-package-add")
        || operation == QStringLiteral("system-package-remove")) {
        refreshSystemPackages();
        refreshCleanup();
        emit systemConfigurationChanged();
    } else if (operation.startsWith(QStringLiteral("cleanup-"))) {
        refreshCleanup();
    }

    const QString message = !outputText.isEmpty() ? outputText : errorText;
    setMessage(message.isEmpty() ? tr("Operazione completata.") : message.left(1600));
}

void KrisPackageBackend::refreshSystemPackages()
{
    startCommand({QStringLiteral("system-packages"), QStringLiteral("--json")},
                 QStringLiteral("system-packages"));
}

void KrisPackageBackend::installSystemPackage(const QString &attribute, bool allowUnfree)
{
    const QString trimmed = attribute.trimmed();
    if (trimmed.isEmpty())
        return;
    QStringList arguments{QStringLiteral("system-package-add")};
    if (allowUnfree)
        arguments << QStringLiteral("--unfree");
    arguments << trimmed;
    startCommand(arguments, QStringLiteral("system-package-add"), true);
}

void KrisPackageBackend::removeSystemPackage(const QString &attribute)
{
    const QString trimmed = attribute.trimmed();
    if (trimmed.isEmpty())
        return;
    startCommand({QStringLiteral("system-package-remove"), trimmed},
                 QStringLiteral("system-package-remove"), true);
}

void KrisPackageBackend::refreshCleanup()
{
    startCommand({QStringLiteral("cleanup-status"), QStringLiteral("--json")},
                 QStringLiteral("cleanup-status"));
}

void KrisPackageBackend::cleanupProfileHistory()
{
    startCommand({QStringLiteral("cleanup-profile")}, QStringLiteral("cleanup-profile"), true);
}

void KrisPackageBackend::cleanupSystemGenerations()
{
    startCommand({QStringLiteral("cleanup-system")}, QStringLiteral("cleanup-system"), true);
}

void KrisPackageBackend::cleanupStore()
{
    startCommand({QStringLiteral("cleanup-store")}, QStringLiteral("cleanup-store"), true);
}
