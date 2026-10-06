#include "KrisDesktopBackend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSet>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QTimer>
#include <QUuid>

#ifdef Q_OS_UNIX
#include <signal.h>
#include <unistd.h>
#endif

namespace {
constexpr qsizetype kMaxActions = 12;
constexpr qsizetype kMaxActionName = 80;
constexpr qsizetype kMaxActionScript = 32 * 1024;
constexpr qsizetype kMaxOutput = 200 * 1024;

QString boundedText(const QByteArray &data)
{
    QString text = QString::fromUtf8(data);
    if (text.size() > kMaxOutput)
        text = text.left(kMaxOutput) + QStringLiteral("\n[… output troncato …]");
    return text.trimmed();
}
}

KrisDesktopBackend::KrisDesktopBackend(QObject *parent)
    : QObject(parent)
{
    refreshResources();
    refreshPowerProfile();
    reloadCustomActions();
}

void KrisDesktopBackend::setBusy(bool busy, bool cancellable)
{
    const bool changed = m_busy != busy || m_operationCancellable != cancellable;
    m_busy = busy;
    m_operationCancellable = busy && cancellable;
    if (changed)
        emit busyChanged();
}

void KrisDesktopBackend::setMessage(const QString &message)
{
    if (m_lastMessage == message)
        return;
    m_lastMessage = message;
    emit lastMessageChanged();
}

void KrisDesktopBackend::refreshResources()
{
    QFile stat(QStringLiteral("/proc/stat"));
    int cpuPercent = m_cpuUsagePercent;
    if (stat.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QList<QByteArray> fields = stat.readLine().simplified().split(' ');
        if (fields.size() >= 6 && fields.first() == "cpu") {
            quint64 total = 0;
            for (qsizetype i = 1; i < fields.size(); ++i)
                total += fields.at(i).toULongLong();
            const quint64 idle = fields.value(4).toULongLong() + fields.value(5).toULongLong();
            if (m_previousCpuTotal > 0 && total > m_previousCpuTotal) {
                const quint64 totalDelta = total - m_previousCpuTotal;
                const quint64 idleDelta = idle >= m_previousCpuIdle ? idle - m_previousCpuIdle : 0;
                cpuPercent = qBound(0, qRound(100.0 * double(totalDelta - qMin(totalDelta, idleDelta))
                                             / double(totalDelta)), 100);
            }
            m_previousCpuTotal = total;
            m_previousCpuIdle = idle;
        }
    }

    const QStorageInfo root = QStorageInfo::root();
    const qint64 totalGiB = root.isValid() && root.bytesTotal() > 0
        ? root.bytesTotal() / (1024LL * 1024LL * 1024LL) : -1;
    const qint64 availableGiB = root.isValid() && root.bytesAvailable() >= 0
        ? root.bytesAvailable() / (1024LL * 1024LL * 1024LL) : -1;

    if (cpuPercent == m_cpuUsagePercent
        && totalGiB == m_diskTotalGiB
        && availableGiB == m_diskAvailableGiB)
        return;

    m_cpuUsagePercent = cpuPercent;
    m_diskTotalGiB = totalGiB;
    m_diskAvailableGiB = availableGiB;
    emit resourcesChanged();
}

void KrisDesktopBackend::refreshPowerProfile()
{
    const QString program = QStandardPaths::findExecutable(QStringLiteral("powerprofilesctl"));
    if (program.isEmpty()) {
        if (m_powerProfile != QStringLiteral("unavailable")) {
            m_powerProfile = QStringLiteral("unavailable");
            emit powerProfileChanged();
        }
        return;
    }

    auto *process = new QProcess(this);
    process->setProcessChannelMode(QProcess::MergedChannels);
    connect(process, &QProcess::finished, this, [this, process](int code, QProcess::ExitStatus status) {
        const QString value = status == QProcess::NormalExit && code == 0
            ? QString::fromUtf8(process->readAll()).trimmed()
            : QStringLiteral("unavailable");
        if (m_powerProfile != value) {
            m_powerProfile = value;
            emit powerProfileChanged();
        }
        process->deleteLater();
    });
    process->start(program, {QStringLiteral("get")});
    QPointer<QProcess> guard = process;
    QTimer::singleShot(5000, process, [guard] {
        if (guard && guard->state() != QProcess::NotRunning)
            guard->kill();
    });
}

QProcess *KrisDesktopBackend::startOperation(const QString &program, const QStringList &arguments,
                                             const QString &operation, bool cancellable,
                                             int timeoutMs, const QString &workingDirectory)
{
    if (m_busy) {
        setMessage(tr("Un'altra operazione è già in corso."));
        return nullptr;
    }

    QString executable;
    const QFileInfo info(program);
    if (info.isAbsolute()) {
        if (info.exists() && info.isExecutable())
            executable = info.absoluteFilePath();
    } else {
        executable = QStandardPaths::findExecutable(program);
    }
    if (executable.isEmpty()) {
        setMessage(tr("Comando non disponibile: %1").arg(program));
        return nullptr;
    }

    auto *process = new QProcess(this);
    process->setProperty("krisOperation", operation);
    process->setProperty("krisTimedOut", false);
    process->setProcessChannelMode(QProcess::MergedChannels);
    if (!workingDirectory.isEmpty())
        process->setWorkingDirectory(workingDirectory);
#ifdef Q_OS_UNIX
    process->setChildProcessModifier([] { ::setpgid(0, 0); });
#endif

    m_activeProcess = process;
    setBusy(true, cancellable);

    connect(process, &QProcess::finished, this,
            [this, process, operation](int code, QProcess::ExitStatus status) {
        const QByteArray output = process->readAll();
        if (m_activeProcess == process)
            m_activeProcess = nullptr;
        setBusy(false);
        finishOperation(process, operation,
                        status == QProcess::NormalExit ? code : 127, output);
        process->deleteLater();
    });

    connect(process, &QProcess::errorOccurred, this, [this, process, operation](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart)
            return;
        if (m_activeProcess == process)
            m_activeProcess = nullptr;
        setBusy(false);
        setMessage(tr("%1: impossibile avviare il processo: %2")
                       .arg(operation, process->errorString()));
        process->deleteLater();
    });

    process->start(executable, arguments);

    if (timeoutMs > 0) {
        QPointer<QProcess> guard = process;
        QTimer::singleShot(timeoutMs, process, [this, guard] {
            if (!guard || guard->state() == QProcess::NotRunning)
                return;
            guard->setProperty("krisTimedOut", true);
            terminateProcessGroup(guard.data(), true);
        });
    }

    return process;
}

void KrisDesktopBackend::terminateProcessGroup(QProcess *process, bool force)
{
    if (!process || process->state() == QProcess::NotRunning)
        return;
#ifdef Q_OS_UNIX
    const qint64 pid = process->processId();
    if (pid > 0) {
        ::kill(-static_cast<pid_t>(pid), force ? SIGKILL : SIGTERM);
        return;
    }
#endif
    force ? process->kill() : process->terminate();
}

void KrisDesktopBackend::cancelCurrentOperation()
{
    if (!canCancel() || !m_activeProcess) {
        setMessage(tr("Questa operazione non può essere annullata in sicurezza."));
        return;
    }

    QPointer<QProcess> guard = m_activeProcess;
    terminateProcessGroup(guard.data(), false);
    setMessage(tr("Annullamento richiesto…"));
    QTimer::singleShot(1500, this, [this, guard] {
        if (guard && guard->state() != QProcess::NotRunning)
            terminateProcessGroup(guard.data(), true);
    });
}

void KrisDesktopBackend::finishOperation(QProcess *process, const QString &operation,
                                         int exitCode, const QByteArray &output)
{
    const QString text = boundedText(output);
    const bool timedOut = process->property("krisTimedOut").toBool();

    if (operation == QStringLiteral("diagnostic")) {
        m_diagnosticOutput = timedOut
            ? tr("Diagnostica terminata per timeout.")
            : (text.isEmpty() ? tr("Nessun output.") : text);
        emit diagnosticChanged();
        if (exitCode != 0 && !timedOut)
            setMessage(tr("Diagnostica terminata con codice %1.").arg(exitCode));
        return;
    }

    if (operation == QStringLiteral("custom-action")) {
        m_actionOutput = timedOut
            ? tr("Comando terminato per timeout.")
            : (text.isEmpty() ? tr("Comando completato senza output.") : text);
        m_actionError = exitCode == 0 && !timedOut
            ? QString()
            : (timedOut ? tr("Timeout.") : tr("Codice di uscita %1.").arg(exitCode));
        emit actionStateChanged();
        return;
    }

    if (operation == QStringLiteral("power-profile")) {
        refreshPowerProfile();
        setMessage(exitCode == 0 ? tr("Profilo energetico aggiornato.")
                                 : (text.isEmpty() ? tr("Cambio profilo energetico non riuscito.") : text));
        return;
    }

    if (operation == QStringLiteral("audio-restart")) {
        setMessage(exitCode == 0 ? tr("Stack audio riavviato.")
                                 : (text.isEmpty() ? tr("Riavvio audio non riuscito.") : text));
        return;
    }

    if (operation == QStringLiteral("system-rollback")) {
        emit recoveryRefreshRequested();
        setMessage(exitCode == 0
            ? tr("Rollback NixOS applicato. Riavvio consigliato per riallineare anche kernel e initrd.")
            : (text.isEmpty() ? tr("Rollback NixOS non riuscito.") : text));
        return;
    }

    if (operation == QStringLiteral("profile-rollback")) {
        emit recoveryRefreshRequested();
        setMessage(exitCode == 0 ? tr("Profilo software ripristinato alla generazione precedente.")
                                 : (text.isEmpty() ? tr("Rollback del profilo non riuscito.") : text));
        return;
    }

    setMessage(exitCode == 0
        ? (text.isEmpty() ? tr("Operazione completata.") : text)
        : (text.isEmpty() ? tr("Operazione non riuscita (%1).").arg(exitCode) : text));
}

void KrisDesktopBackend::setPowerProfile(const QString &profile)
{
    static const QStringList allowed = {
        QStringLiteral("power-saver"),
        QStringLiteral("balanced"),
        QStringLiteral("performance")
    };
    if (!allowed.contains(profile)) {
        setMessage(tr("Profilo energetico non valido."));
        return;
    }
    startOperation(QStringLiteral("powerprofilesctl"),
                   {QStringLiteral("set"), profile},
                   QStringLiteral("power-profile"), false, 15000);
}

void KrisDesktopBackend::restartAudio()
{
    startOperation(QStringLiteral("systemctl"),
                   {QStringLiteral("--user"), QStringLiteral("restart"),
                    QStringLiteral("pipewire.service"),
                    QStringLiteral("pipewire-pulse.service"),
                    QStringLiteral("wireplumber.service")},
                   QStringLiteral("audio-restart"), false, 30000);
}

void KrisDesktopBackend::runDiagnostic(const QString &diagnosticId)
{
    QString program;
    QStringList arguments;
    QString title;

    if (diagnosticId == QStringLiteral("failed-units")) {
        program = QStringLiteral("systemctl");
        arguments = {QStringLiteral("--failed"), QStringLiteral("--no-pager"), QStringLiteral("--plain")};
        title = tr("Unità di sistema fallite");
    } else if (diagnosticId == QStringLiteral("journal-errors")) {
        program = QStringLiteral("journalctl");
        arguments = {QStringLiteral("-b"), QStringLiteral("-p"), QStringLiteral("warning"),
                     QStringLiteral("--no-pager"), QStringLiteral("-n"), QStringLiteral("200")};
        title = tr("Warning ed errori dell'ultimo avvio");
    } else if (diagnosticId == QStringLiteral("kernel-errors")) {
        program = QStringLiteral("journalctl");
        arguments = {QStringLiteral("-k"), QStringLiteral("-b"), QStringLiteral("-p"),
                     QStringLiteral("warning"), QStringLiteral("--no-pager"),
                     QStringLiteral("-n"), QStringLiteral("200")};
        title = tr("Warning kernel");
    } else if (diagnosticId == QStringLiteral("boot-time")) {
        program = QStringLiteral("systemd-analyze");
        arguments = {QStringLiteral("time")};
        title = tr("Tempo di avvio");
    } else if (diagnosticId == QStringLiteral("disk-space")) {
        program = QStringLiteral("df");
        arguments = {QStringLiteral("-hT"), QStringLiteral("-x"), QStringLiteral("tmpfs"),
                     QStringLiteral("-x"), QStringLiteral("devtmpfs")};
        title = tr("Spazio filesystem");
    } else if (diagnosticId == QStringLiteral("disks")) {
        program = QStringLiteral("lsblk");
        arguments = {QStringLiteral("-e"), QStringLiteral("7"), QStringLiteral("-o"),
                     QStringLiteral("NAME,PARTN,SIZE,FSTYPE,FSVER,LABEL,UUID,MOUNTPOINTS")};
        title = tr("Dischi e partizioni");
    } else {
        setMessage(tr("Diagnostica non riconosciuta."));
        return;
    }

    m_diagnosticTitle = title;
    m_diagnosticOutput.clear();
    emit diagnosticChanged();
    startOperation(program, arguments, QStringLiteral("diagnostic"), true, 60000);
}

void KrisDesktopBackend::clearDiagnostic()
{
    if (m_busy)
        return;
    m_diagnosticTitle.clear();
    m_diagnosticOutput.clear();
    emit diagnosticChanged();
}

QString KrisDesktopBackend::previousSystemToplevel()
{
    const QString profilePath = QStringLiteral("/nix/var/nix/profiles/system");
    const QFileInfo profile(profilePath);
    const QString currentLink = profile.symLinkTarget();
    if (currentLink.isEmpty())
        return {};

    static const QRegularExpression generationPattern(
        QStringLiteral("^system-([0-9]+)-link$"));
    const QRegularExpressionMatch currentMatch =
        generationPattern.match(QFileInfo(currentLink).fileName());
    if (!currentMatch.hasMatch())
        return {};

    bool ok = false;
    const qlonglong currentGeneration = currentMatch.captured(1).toLongLong(&ok);
    if (!ok)
        return {};

    QDir profiles(QStringLiteral("/nix/var/nix/profiles"));
    qlonglong previousGeneration = -1;
    QString previousLink;
    const QStringList entries = profiles.entryList(
        {QStringLiteral("system-*-link")},
        QDir::AllEntries | QDir::System | QDir::NoDotAndDotDot);

    for (const QString &entry : entries) {
        const QRegularExpressionMatch match = generationPattern.match(entry);
        if (!match.hasMatch())
            continue;
        const qlonglong generation = match.captured(1).toLongLong(&ok);
        if (!ok || generation >= currentGeneration || generation <= previousGeneration)
            continue;
        previousGeneration = generation;
        previousLink = profiles.filePath(entry);
    }

    if (previousLink.isEmpty())
        return {};

    const QString target = QFileInfo(previousLink).canonicalFilePath();
    const QFileInfo targetInfo(target);
    if (!target.startsWith(QStringLiteral("/nix/store/"))
        || !targetInfo.fileName().contains(QStringLiteral("-nixos-system-"))
        || !QFileInfo(QDir(target).filePath(QStringLiteral("bin/switch-to-configuration"))).isExecutable())
        return {};

    return target;
}

void KrisDesktopBackend::rollbackSystem()
{
    const QString target = previousSystemToplevel();
    if (target.isEmpty()) {
        setMessage(tr("Nessuna generazione NixOS precedente valida disponibile."));
        return;
    }

    const QString helper = QStandardPaths::findExecutable(QStringLiteral("kris-system-activate"));
    if (helper.isEmpty()) {
        setMessage(tr("Helper di attivazione non disponibile."));
        return;
    }

    startOperation(QStringLiteral("/run/wrappers/bin/sudo"),
                   {QStringLiteral("-n"), QStringLiteral("--"), helper, target},
                   QStringLiteral("system-rollback"), false);
}

void KrisDesktopBackend::rollbackProfile()
{
    startOperation(QStringLiteral("kris-app"), {QStringLiteral("rollback")},
                   QStringLiteral("profile-rollback"), false, 5 * 60 * 1000);
}

QString KrisDesktopBackend::customActionsPath() const
{
    const QString configRoot = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    return QDir(configRoot).filePath(QStringLiteral("krisNCC/custom-actions.json"));
}

int KrisDesktopBackend::customActionIndex(const QString &id) const
{
    for (qsizetype i = 0; i < m_customActions.size(); ++i) {
        if (m_customActions.at(i).toMap().value(QStringLiteral("id")).toString() == id)
            return int(i);
    }
    return -1;
}

bool KrisDesktopBackend::validateCustomAction(const QString &name, const QString &script,
                                              QString *error) const
{
    if (name.trimmed().isEmpty() || name.trimmed().size() > kMaxActionName) {
        if (error)
            *error = tr("Il nome deve contenere da 1 a %1 caratteri.").arg(kMaxActionName);
        return false;
    }
    if (script.trimmed().isEmpty() || script.size() > kMaxActionScript || script.contains(QChar::Null)) {
        if (error)
            *error = tr("Il comando è vuoto o troppo grande.");
        return false;
    }
    return true;
}

void KrisDesktopBackend::reloadCustomActions()
{
    if (m_busy)
        return;

    m_actionError.clear();
    m_customStorageValid = true;
    const QString path = customActionsPath();
    const QFileInfo info(path);
    if (info.isSymLink()) {
        m_customActions.clear();
        m_customStorageValid = false;
        m_actionError = tr("Il file dei comandi personali è un collegamento simbolico e non verrà usato.");
        emit customActionsChanged();
        emit actionStateChanged();
        return;
    }

    QFile file(path);
    if (!file.exists()) {
        m_customActions.clear();
        emit customActionsChanged();
        emit actionStateChanged();
        return;
    }
    if (!file.open(QIODevice::ReadOnly)) {
        m_customActions.clear();
        m_customStorageValid = false;
        m_actionError = tr("Impossibile leggere i comandi personali.");
        emit customActionsChanged();
        emit actionStateChanged();
        return;
    }

    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject()) {
        m_customActions.clear();
        m_customStorageValid = false;
        m_actionError = tr("File dei comandi personali non valido.");
        emit customActionsChanged();
        emit actionStateChanged();
        return;
    }

    const QJsonObject root = document.object();
    const QJsonArray actions = root.value(QStringLiteral("actions")).toArray();
    if (root.value(QStringLiteral("schema")).toInt(-1) != 1
        || !root.value(QStringLiteral("actions")).isArray()
        || actions.size() > kMaxActions) {
        m_customActions.clear();
        m_customStorageValid = false;
        m_actionError = tr("Schema dei comandi personali non supportato.");
        emit customActionsChanged();
        emit actionStateChanged();
        return;
    }

    QVariantList loaded;
    QSet<QString> ids;
    static const QRegularExpression idPattern(QStringLiteral("^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$"));
    for (const QJsonValue &value : actions) {
        if (!value.isObject()) {
            m_customStorageValid = false;
            m_actionError = tr("File dei comandi personali corrotto.");
            loaded.clear();
            break;
        }
        const QJsonObject object = value.toObject();
        const QString id = object.value(QStringLiteral("id")).toString();
        const QString name = object.value(QStringLiteral("name")).toString();
        const QString script = object.value(QStringLiteral("script")).toString();
        QString error;
        if (!idPattern.match(id).hasMatch() || ids.contains(id)
            || !object.value(QStringLiteral("confirm")).isBool()
            || !validateCustomAction(name, script, &error)) {
            m_customStorageValid = false;
            m_actionError = tr("File dei comandi personali contiene dati non validi.");
            loaded.clear();
            break;
        }
        ids.insert(id);
        QVariantMap row;
        row.insert(QStringLiteral("id"), id);
        row.insert(QStringLiteral("name"), name.trimmed());
        row.insert(QStringLiteral("script"), script);
        row.insert(QStringLiteral("confirm"), object.value(QStringLiteral("confirm")).toBool());
        loaded.append(row);
    }

    m_customActions = loaded;
    if (m_customStorageValid)
        QFile::setPermissions(path, QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    emit customActionsChanged();
    emit actionStateChanged();
}

bool KrisDesktopBackend::persistCustomActions()
{
    if (!m_customStorageValid) {
        m_actionError = tr("Il file esistente non è valido: correggilo prima di salvare.");
        emit actionStateChanged();
        return false;
    }

    const QString path = customActionsPath();
    const QFileInfo existing(path);
    if (existing.exists() && existing.isSymLink()) {
        m_actionError = tr("Scrittura rifiutata: il file dei comandi personali è un symlink.");
        emit actionStateChanged();
        return false;
    }

    if (!QDir().mkpath(existing.absolutePath())) {
        m_actionError = tr("Impossibile creare la cartella di configurazione.");
        emit actionStateChanged();
        return false;
    }

    QJsonArray array;
    for (const QVariant &value : m_customActions) {
        const QVariantMap row = value.toMap();
        QJsonObject object;
        object.insert(QStringLiteral("id"), row.value(QStringLiteral("id")).toString());
        object.insert(QStringLiteral("name"), row.value(QStringLiteral("name")).toString());
        object.insert(QStringLiteral("script"), row.value(QStringLiteral("script")).toString());
        object.insert(QStringLiteral("confirm"), row.value(QStringLiteral("confirm")).toBool());
        array.append(object);
    }

    QJsonObject root;
    root.insert(QStringLiteral("schema"), 1);
    root.insert(QStringLiteral("actions"), array);

    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly)
        || !file.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner)
        || file.write(QJsonDocument(root).toJson(QJsonDocument::Indented)) < 0
        || !file.commit()) {
        m_actionError = tr("Impossibile salvare i comandi personali.");
        emit actionStateChanged();
        return false;
    }
    m_actionError.clear();
    emit actionStateChanged();
    return true;
}

bool KrisDesktopBackend::saveCustomAction(const QString &id, const QString &name,
                                          const QString &script, bool confirmBeforeRun)
{
    if (m_busy || !m_customStorageValid)
        return false;

    QString error;
    if (!validateCustomAction(name, script, &error)) {
        m_actionError = error;
        emit actionStateChanged();
        return false;
    }

    const QString requestedId = id.trimmed();
    const int index = requestedId.isEmpty() ? -1 : customActionIndex(requestedId);
    if (!requestedId.isEmpty() && index < 0) {
        m_actionError = tr("Comando da modificare non trovato.");
        emit actionStateChanged();
        return false;
    }
    if (index < 0 && m_customActions.size() >= kMaxActions) {
        m_actionError = tr("Limite di %1 comandi personali raggiunto.").arg(kMaxActions);
        emit actionStateChanged();
        return false;
    }

    QVariantMap row;
    row.insert(QStringLiteral("id"),
               index >= 0 ? requestedId : QUuid::createUuid().toString(QUuid::WithoutBraces));
    row.insert(QStringLiteral("name"), name.trimmed());
    row.insert(QStringLiteral("script"), script);
    row.insert(QStringLiteral("confirm"), confirmBeforeRun);

    const QVariantList previous = m_customActions;
    if (index >= 0)
        m_customActions[index] = row;
    else
        m_customActions.append(row);

    if (!persistCustomActions()) {
        m_customActions = previous;
        return false;
    }
    emit customActionsChanged();
    return true;
}

bool KrisDesktopBackend::removeCustomAction(const QString &id)
{
    if (m_busy || !m_customStorageValid)
        return false;
    const int index = customActionIndex(id);
    if (index < 0)
        return false;

    const QVariantList previous = m_customActions;
    m_customActions.removeAt(index);
    if (!persistCustomActions()) {
        m_customActions = previous;
        return false;
    }
    emit customActionsChanged();
    return true;
}

bool KrisDesktopBackend::runCustomAction(const QString &id)
{
#ifdef Q_OS_UNIX
    if (::geteuid() == 0) {
        m_actionError = tr("I comandi personali sono disabilitati quando krisNCC gira come root.");
        emit actionStateChanged();
        return false;
    }
#endif
    const int index = customActionIndex(id);
    if (index < 0)
        return false;

    const QString bash = QStandardPaths::findExecutable(QStringLiteral("bash"));
    if (bash.isEmpty()) {
        m_actionError = tr("Bash non è disponibile.");
        emit actionStateChanged();
        return false;
    }

    const QVariantMap row = m_customActions.at(index).toMap();
    m_actionOutput.clear();
    m_actionError.clear();
    emit actionStateChanged();
    return startOperation(bash,
                          {QStringLiteral("-c"), row.value(QStringLiteral("script")).toString()},
                          QStringLiteral("custom-action"), true,
                          30 * 60 * 1000, QDir::homePath()) != nullptr;
}

bool KrisDesktopBackend::launchTool(const QString &toolId)
{
    static const QHash<QString, QString> tools = {
        {QStringLiteral("backintime"), QStringLiteral("backintime-qt")},
        {QStringLiteral("systemmonitor"), QStringLiteral("plasma-systemmonitor")}
    };

    if (!tools.contains(toolId)) {
        setMessage(tr("Strumento non riconosciuto: %1").arg(toolId));
        return false;
    }
    const QString program = QStandardPaths::findExecutable(tools.value(toolId));
    if (program.isEmpty()) {
        setMessage(tr("Strumento non disponibile: %1").arg(toolId));
        return false;
    }
    if (!QProcess::startDetached(program, {})) {
        setMessage(tr("Avvio dello strumento non riuscito: %1").arg(toolId));
        return false;
    }
    return true;
}
