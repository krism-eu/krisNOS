#include "KrisNccBackend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QTimer>

#include <algorithm>

#ifdef Q_OS_UNIX
#include <signal.h>
#include <unistd.h>
#endif

KrisNccBackend::KrisNccBackend(QObject *parent)
    : QObject(parent)
{
    refreshResources();
    refreshConfigStatus();
    refreshRuntimeStatus();

}

bool KrisNccBackend::canCancel() const
{
    return m_activeUserProcess && m_activeUserProcess->state() != QProcess::NotRunning;
}

void KrisNccBackend::setBusy(bool value)
{
    if (m_busy == value)
        return;
    m_busy = value;
    emit busyChanged();
}

void KrisNccBackend::setMessage(const QString &message)
{
    if (m_lastMessage == message)
        return;
    m_lastMessage = message;
    emit lastMessageChanged();
}

void KrisNccBackend::refreshResources()
{
    QFile file(QStringLiteral("/proc/meminfo"));
    qint64 total = -1, free = 0, buffers = 0, cached = 0, reclaimable = 0;
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        while (!file.atEnd()) {
            const QByteArray line = file.readLine().simplified();
            const QList<QByteArray> parts = line.split(' ');
            if (parts.size() < 2)
                continue;
            const qint64 value = parts.at(1).toLongLong();
            if (line.startsWith("MemTotal:")) total = value;
            else if (line.startsWith("MemFree:")) free = value;
            else if (line.startsWith("Buffers:")) buffers = value;
            else if (line.startsWith("Cached:")) cached = value;
            else if (line.startsWith("SReclaimable:")) reclaimable = value;
        }
    }

    const qint64 used = total > 0
        ? std::max<qint64>(0, total - free - buffers - cached - reclaimable)
        : -1;
    const qint64 totalMiB = total > 0 ? total / 1024 : -1;
    const qint64 usedMiB = used >= 0 ? used / 1024 : -1;
    const double temp = readCpuTemperature();

    if (m_memoryUsedMiB == usedMiB && m_memoryTotalMiB == totalMiB
        && qAbs(m_cpuTemperatureC - temp) < 0.1)
        return;
    m_memoryUsedMiB = usedMiB;
    m_memoryTotalMiB = totalMiB;
    m_cpuTemperatureC = temp;
    emit resourcesChanged();
}

double KrisNccBackend::readCpuTemperature()
{
    const QDir hwmon(QStringLiteral("/sys/class/hwmon"));
    const QStringList devices = hwmon.entryList({QStringLiteral("hwmon*")}, QDir::Dirs | QDir::NoDotAndDotDot);
    const auto maxTempFor = [](const QDir &dir) {
        double best = -1.0;
        const QStringList inputs = dir.entryList({QStringLiteral("temp*_input")}, QDir::Files);
        for (const QString &input : inputs) {
            QFile f(dir.filePath(input));
            if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
                continue;
            bool ok = false;
            const double c = QString::fromUtf8(f.readAll()).trimmed().toDouble(&ok) / 1000.0;
            if (ok && c > 0.0 && c < 130.0)
                best = std::max(best, c);
        }
        return best;
    };

    double fallback = -1.0;
    for (const QString &device : devices) {
        QDir dir(hwmon.filePath(device));
        QFile nameFile(dir.filePath(QStringLiteral("name")));
        QString name;
        if (nameFile.open(QIODevice::ReadOnly | QIODevice::Text))
            name = QString::fromUtf8(nameFile.readAll()).trimmed().toLower();
        const double value = maxTempFor(dir);
        if (value <= 0.0)
            continue;
        if (name == QStringLiteral("k10temp") || name == QStringLiteral("zenpower")
            || name == QStringLiteral("coretemp"))
            return value;
        fallback = std::max(fallback, value);
    }
    return fallback;
}

void KrisNccBackend::terminateProcessGroup(QProcess *process, bool force)
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
    if (force)
        process->kill();
    else
        process->terminate();
}

QProcess *KrisNccBackend::startCommand(const QString &program, const QStringList &arguments,
                                       const QString &operation, bool userOperation)
{
    const QString executable = QStandardPaths::findExecutable(program);
    if (executable.isEmpty()) {
        setMessage(tr("Comando non disponibile: %1").arg(program));
        return nullptr;
    }
    if (userOperation && m_busy) {
        setMessage(tr("Un'altra operazione è già in corso."));
        return nullptr;
    }

    auto *process = new QProcess(this);
#ifdef Q_OS_UNIX
    process->setChildProcessModifier([] { ::setpgid(0, 0); });
#endif
    process->setProcessChannelMode(QProcess::SeparateChannels);

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    if (operation == QStringLiteral("config-fetch") || operation == QStringLiteral("config-sync"))
        environment.insert(QStringLiteral("KRISOS_NONINTERACTIVE"), QStringLiteral("1"));
    if (operation == QStringLiteral("bluez-status"))
        environment.insert(QStringLiteral("LC_ALL"), QStringLiteral("C"));
    process->setProcessEnvironment(environment);

    if (userOperation) {
        m_activeUserProcess = process;
        setBusy(true);
    }

    connect(process, &QProcess::finished, this,
            [this, process, operation, userOperation](int exitCode, QProcess::ExitStatus status) {
        const QByteArray out = process->readAllStandardOutput();
        const QByteArray err = process->readAllStandardError();
        const bool cancelled = m_cancelledProcess == process;

        if (m_searchProcess == process)
            m_searchProcess = nullptr;
        if (m_activeUserProcess == process)
            m_activeUserProcess = nullptr;
        if (m_cancelledProcess == process)
            m_cancelledProcess = nullptr;
        if (userOperation)
            setBusy(false);

        if (cancelled)
            setMessage(tr("Operazione annullata."));
        else
            handleCommandResult(operation, status == QProcess::NormalExit ? exitCode : 127, out, err);
        process->deleteLater();
    });

    connect(process, &QProcess::errorOccurred, this,
            [this, process, operation, userOperation](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart)
            return;
        if (m_searchProcess == process)
            m_searchProcess = nullptr;
        if (m_activeUserProcess == process)
            m_activeUserProcess = nullptr;
        setMessage(tr("%1: impossibile avviare il processo: %2")
                       .arg(operation, process->errorString()));
        if (userOperation)
            setBusy(false);
        process->deleteLater();
    });

    process->start(executable, arguments);
    return process;
}

void KrisNccBackend::cancelCurrentOperation()
{
    if (!canCancel()) {
        setMessage(tr("Questa operazione non può essere annullata in sicurezza."));
        return;
    }

    QPointer<QProcess> process = m_activeUserProcess;
    m_cancelledProcess = process;
    terminateProcessGroup(process, false);
    setMessage(tr("Annullamento richiesto…"));

    QTimer::singleShot(1500, this, [this, process] {
        if (process && process->state() != QProcess::NotRunning)
            terminateProcessGroup(process, true);
    });
}

void KrisNccBackend::startRuntimeMutation(const QString &feature, bool enabled)
{
    if (feature != QStringLiteral("bluetooth") && feature != QStringLiteral("firewall"))
        return;

    const QString helper = QStandardPaths::findExecutable(QStringLiteral("kris-runtimectl"));
    if (helper.isEmpty()) {
        setMessage(tr("Helper runtime non disponibile."));
        return;
    }

    startCommand(QStringLiteral("sudo"),
                 {QStringLiteral("-n"), QStringLiteral("--"), helper, feature,
                  enabled ? QStringLiteral("on") : QStringLiteral("off")},
                 QStringLiteral("runtime-mutation"), true);
}

QString KrisNccBackend::nixAttributeFromSearchKey(const QString &key)
{
    static const QStringList prefixes = {
        QStringLiteral("legacyPackages."),
        QStringLiteral("packages.")
    };

    for (const QString &prefix : prefixes) {
        if (!key.startsWith(prefix))
            continue;
        const int systemEnd = key.indexOf(QLatin1Char('.'), prefix.size());
        if (systemEnd >= 0 && systemEnd + 1 < key.size())
            return key.mid(systemEnd + 1);
    }
    return key;
}

void KrisNccBackend::updateBluetoothState()
{
    QString state = QStringLiteral("unknown");
    if (m_rfkillBluetoothState == QStringLiteral("unavailable"))
        state = QStringLiteral("unavailable");
    else if (m_rfkillBluetoothState == QStringLiteral("hard-blocked"))
        state = QStringLiteral("hard-blocked");
    else if (m_rfkillBluetoothState == QStringLiteral("soft-blocked"))
        state = QStringLiteral("off");
    else if (m_rfkillBluetoothState == QStringLiteral("unblocked")) {
        if (m_bluezBluetoothState == QStringLiteral("on"))
            state = QStringLiteral("on");
        else if (m_bluezBluetoothState == QStringLiteral("off"))
            state = QStringLiteral("off");
        else if (m_bluezBluetoothState == QStringLiteral("unavailable"))
            state = QStringLiteral("unavailable");
    }

    if (m_runtimeStatus.value(QStringLiteral("bluetooth")).toString() == state)
        return;
    m_runtimeStatus.insert(QStringLiteral("bluetooth"), state);
    emit runtimeStatusChanged();
}

void KrisNccBackend::handleCommandResult(const QString &operation, int exitCode,
                                         const QByteArray &out, const QByteArray &err)
{
    if (operation.startsWith(QStringLiteral("software-search:"))) {
        bool serialOk = false;
        const quint64 serial = operation.section(QLatin1Char(':'), 1, 1).toULongLong(&serialOk);
        if (!serialOk || serial != m_searchSerial)
            return;
    }

    const QString errorText = QString::fromUtf8(err).trimmed();
    const QString outputText = QString::fromUtf8(out).trimmed();
    if (exitCode != 0) {
        if (operation == QStringLiteral("bluetooth-status")) {
            m_rfkillBluetoothState = QStringLiteral("unknown");
            updateBluetoothState();
            return;
        }
        if (operation == QStringLiteral("bluez-status")) {
            m_bluezBluetoothState = QStringLiteral("unavailable");
            updateBluetoothState();
            return;
        }

        setMessage(errorText.isEmpty()
                       ? tr("Operazione non riuscita (%1).").arg(exitCode)
                       : errorText.left(1200));
        if (operation == QStringLiteral("runtime-mutation"))
            refreshRuntimeStatus();
        if (operation == QStringLiteral("config-apply"))
            refreshConfigStatus();
        return;
    }

    if (operation == QStringLiteral("config-status") || operation == QStringLiteral("runtime-status")) {
        const QJsonDocument doc = QJsonDocument::fromJson(out);
        if (!doc.isObject()) {
            setMessage(tr("Risposta JSON non valida da %1.").arg(operation));
            return;
        }
        if (operation == QStringLiteral("config-status")) {
            m_configStatus = doc.object().toVariantMap();
            emit configStatusChanged();
        } else {
            const QVariant bluetooth = m_runtimeStatus.value(QStringLiteral("bluetooth"));
            m_runtimeStatus = doc.object().toVariantMap();
            if (bluetooth.isValid())
                m_runtimeStatus.insert(QStringLiteral("bluetooth"), bluetooth);
            emit runtimeStatusChanged();
        }
        return;
    }

    if (operation == QStringLiteral("bluetooth-status")) {
        const QJsonDocument doc = QJsonDocument::fromJson(out);
        QString rfkillState = QStringLiteral("unknown");
        if (doc.isObject()) {
            const QJsonArray devices = doc.object().value(QStringLiteral("rfkilldevices")).toArray();
            bool found = false;
            bool softBlocked = false;
            bool hardBlocked = false;
            const auto isBlocked = [](const QJsonValue &value) {
                if (value.isBool())
                    return value.toBool();
                if (value.isDouble())
                    return value.toInt() != 0;
                const QString text = value.toVariant().toString().trimmed().toLower();
                return text == QStringLiteral("blocked") || text == QStringLiteral("yes")
                    || text == QStringLiteral("true") || text == QStringLiteral("1");
            };
            for (const QJsonValue &value : devices) {
                if (!value.isObject())
                    continue;
                const QJsonObject device = value.toObject();
                const QString type = device.value(QStringLiteral("type")).toVariant().toString().trimmed();
                if (type.compare(QStringLiteral("bluetooth"), Qt::CaseInsensitive) != 0)
                    continue;
                found = true;
                softBlocked = softBlocked || isBlocked(device.value(QStringLiteral("soft")));
                hardBlocked = hardBlocked || isBlocked(device.value(QStringLiteral("hard")));
            }
            if (!found)
                rfkillState = QStringLiteral("unavailable");
            else if (hardBlocked)
                rfkillState = QStringLiteral("hard-blocked");
            else if (softBlocked)
                rfkillState = QStringLiteral("soft-blocked");
            else
                rfkillState = QStringLiteral("unblocked");
        }
        m_rfkillBluetoothState = rfkillState;
        updateBluetoothState();
        return;
    }

    if (operation == QStringLiteral("bluez-status")) {
        QString bluezState = QStringLiteral("unavailable");
        const QStringList lines = outputText.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            const QString trimmed = line.trimmed();
            if (!trimmed.startsWith(QStringLiteral("Powered:"), Qt::CaseInsensitive))
                continue;
            const QString value = trimmed.section(QLatin1Char(':'), 1).trimmed().toLower();
            bluezState = (value == QStringLiteral("yes") || value == QStringLiteral("true"))
                ? QStringLiteral("on") : QStringLiteral("off");
            break;
        }
        m_bluezBluetoothState = bluezState;
        updateBluetoothState();
        return;
    }

    if (operation == QStringLiteral("config-diff")) {
        m_configDiff = outputText.isEmpty() ? tr("Nessuna differenza da mostrare.") : outputText.left(200000);
        emit configDiffChanged();
        return;
    }

    if (operation == QStringLiteral("software-list")) {
        const QJsonDocument doc = QJsonDocument::fromJson(out);
        QVariantList list;
        if (doc.isObject()) {
            const QJsonObject root = doc.object();
            const QJsonObject elements = root.value(QStringLiteral("elements")).toObject();
            for (auto it = elements.begin(); it != elements.end(); ++it) {
                QVariantMap row = it.value().toObject().toVariantMap();
                row.insert(QStringLiteral("name"), it.key());
                list.append(row);
            }
        }
        m_softwareItems = list;
        emit softwareItemsChanged();
        return;
    }

    if (operation.startsWith(QStringLiteral("software-search:"))) {
        const QJsonDocument doc = QJsonDocument::fromJson(out);
        QVariantList list;
        if (doc.isObject()) {
            const QJsonObject root = doc.object();
            for (auto it = root.begin(); it != root.end(); ++it) {
                const QJsonObject meta = it.value().toObject();
                QVariantMap row;
                row.insert(QStringLiteral("attribute"), nixAttributeFromSearchKey(it.key()));
                row.insert(QStringLiteral("name"), meta.value(QStringLiteral("pname")).toString());
                row.insert(QStringLiteral("version"), meta.value(QStringLiteral("version")).toString());
                row.insert(QStringLiteral("description"), meta.value(QStringLiteral("description")).toString());
                list.append(row);
            }
        }

        const QString query = m_searchQuery.trimmed().toLower();
        const auto score = [&query](const QVariant &value) {
            const QVariantMap row = value.toMap();
            const QString name = row.value(QStringLiteral("name")).toString().toLower();
            const QString attr = row.value(QStringLiteral("attribute")).toString().toLower();
            if (name == query)
                return 0;
            if (name.startsWith(query))
                return 1;
            if (name.contains(query))
                return 2;
            if (attr.startsWith(query) || attr.contains(QStringLiteral(".") + query))
                return 3;
            return 4;
        };
        std::stable_sort(list.begin(), list.end(), [&score](const QVariant &a, const QVariant &b) {
            const int sa = score(a);
            const int sb = score(b);
            if (sa != sb)
                return sa < sb;
            return a.toMap().value(QStringLiteral("name")).toString()
                .localeAwareCompare(b.toMap().value(QStringLiteral("name")).toString()) < 0;
        });
        if (list.size() > 60)
            list = list.mid(0, 60);
        m_searchResults = list;
        emit searchResultsChanged();
        return;
    }

    if (operation == QStringLiteral("distrobox-list")) {
        QStringList lines = outputText.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        if (!lines.isEmpty() && lines.first().contains(QStringLiteral("NAME"), Qt::CaseInsensitive))
            lines.removeFirst();
        m_distroboxes = lines;
        emit distroboxesChanged();
        return;
    }

    if (operation == QStringLiteral("system-generations")) {
        m_systemGenerations = outputText.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        emit recoveryChanged();
        return;
    }
    if (operation == QStringLiteral("profile-history")) {
        m_profileHistory = outputText.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        emit recoveryChanged();
        return;
    }

    if (operation == QStringLiteral("config-fetch") || operation == QStringLiteral("config-sync")
        || operation == QStringLiteral("config-build") || operation == QStringLiteral("config-apply"))
        refreshConfigStatus();
    if (operation == QStringLiteral("runtime-mutation"))
        refreshRuntimeStatus();
    if (operation == QStringLiteral("software-add") || operation == QStringLiteral("software-remove"))
        refreshSoftware();

    const QString message = !outputText.isEmpty() ? outputText : errorText;
    setMessage(message.isEmpty() ? tr("Operazione completata.") : message.left(1200));
}

void KrisNccBackend::refreshConfigStatus()
{
    startCommand(QStringLiteral("kris-configctl"),
                 {QStringLiteral("status"), QStringLiteral("--json")},
                 QStringLiteral("config-status"));
}
void KrisNccBackend::fetchConfig()
{
    startCommand(QStringLiteral("kris-configctl"), {QStringLiteral("fetch")}, QStringLiteral("config-fetch"), true);
}
void KrisNccBackend::showConfigDiff()
{
    startCommand(QStringLiteral("kris-configctl"), {QStringLiteral("diff")}, QStringLiteral("config-diff"), true);
}
void KrisNccBackend::syncConfig()
{
    startCommand(QStringLiteral("kris-configctl"), {QStringLiteral("sync")}, QStringLiteral("config-sync"), true);
}
void KrisNccBackend::validateConfig()
{
    startCommand(QStringLiteral("kris-configctl"), {QStringLiteral("validate")}, QStringLiteral("config-validate"), true);
}
void KrisNccBackend::buildConfig()
{
    startCommand(QStringLiteral("kris-configctl"), {QStringLiteral("build")}, QStringLiteral("config-build"), true);
}
void KrisNccBackend::applyConfig()
{
    startCommand(QStringLiteral("kris-configctl"),
                 {QStringLiteral("apply")},
                 QStringLiteral("config-apply"), true);
}

void KrisNccBackend::refreshRuntimeStatus()
{
    m_rfkillBluetoothState = QStringLiteral("unknown");
    m_bluezBluetoothState = QStringLiteral("unknown");

    startCommand(QStringLiteral("kris-runtimectl"),
                 {QStringLiteral("status"), QStringLiteral("--json")},
                 QStringLiteral("runtime-status"));
    startCommand(QStringLiteral("rfkill"),
                 {QStringLiteral("--json"), QStringLiteral("--output"),
                  QStringLiteral("TYPE,SOFT,HARD"), QStringLiteral("list"),
                  QStringLiteral("bluetooth")},
                 QStringLiteral("bluetooth-status"));
    startCommand(QStringLiteral("bluetoothctl"),
                 {QStringLiteral("show")},
                 QStringLiteral("bluez-status"));
}

void KrisNccBackend::setBluetoothEnabled(bool enabled)
{
    startRuntimeMutation(QStringLiteral("bluetooth"), enabled);
}
void KrisNccBackend::setFirewallEnabled(bool enabled)
{
    startRuntimeMutation(QStringLiteral("firewall"), enabled);
}
void KrisNccBackend::refreshSoftware()
{
    startCommand(QStringLiteral("kris-app"),
                 {QStringLiteral("list"), QStringLiteral("--json")},
                 QStringLiteral("software-list"));
}

void KrisNccBackend::searchSoftware(const QString &query)
{
    const QString trimmed = query.trimmed();
    if (trimmed.isEmpty())
        return;

    if (m_searchProcess && m_searchProcess->state() != QProcess::NotRunning)
        terminateProcessGroup(m_searchProcess, true);

    ++m_searchSerial;
    m_searchQuery = trimmed;
    m_searchProcess = startCommand(QStringLiteral("kris-app"),
                                   {QStringLiteral("search"), QStringLiteral("--json"), trimmed},
                                   QStringLiteral("software-search:%1").arg(m_searchSerial));
}

void KrisNccBackend::addSoftware(const QString &attribute, bool allowUnfree)
{
    QStringList arguments{QStringLiteral("add")};
    if (allowUnfree)
        arguments << QStringLiteral("--unfree");
    arguments << attribute;
    startCommand(QStringLiteral("kris-app"), arguments, QStringLiteral("software-add"), true);
}

void KrisNccBackend::runSoftware(const QString &attribute, bool allowUnfree)
{
    QStringList arguments{QStringLiteral("run")};
    if (allowUnfree)
        arguments << QStringLiteral("--unfree");
    arguments << attribute.trimmed();
    startCommand(QStringLiteral("kris-app"), arguments, QStringLiteral("software-run"));
}

void KrisNccBackend::removeSoftware(const QString &name)
{
    startCommand(QStringLiteral("kris-app"),
                 {QStringLiteral("remove"), name},
                 QStringLiteral("software-remove"), true);
}

void KrisNccBackend::previewSoftwareUpdates(bool allowUnfree)
{
    QStringList arguments{QStringLiteral("upgrade"), QStringLiteral("--dry-run")};
    if (allowUnfree)
        arguments << QStringLiteral("--unfree");
    startCommand(QStringLiteral("kris-app"), arguments, QStringLiteral("software-updates"), true);
}

void KrisNccBackend::refreshDistroboxes()
{
    startCommand(QStringLiteral("distrobox"),
                 {QStringLiteral("list"), QStringLiteral("--no-color")},
                 QStringLiteral("distrobox-list"));
}

void KrisNccBackend::refreshRecovery()
{
    startCommand(QStringLiteral("nix-env"),
                 {QStringLiteral("--list-generations"), QStringLiteral("-p"),
                  QStringLiteral("/nix/var/nix/profiles/system")},
                 QStringLiteral("system-generations"));
    startCommand(QStringLiteral("kris-app"), {QStringLiteral("history")}, QStringLiteral("profile-history"));
}

bool KrisNccBackend::launchTool(const QString &toolId)
{
    static const QHash<QString, QString> tools = {
        {QStringLiteral("systemsettings"), QStringLiteral("systemsettings")},
        {QStringLiteral("kinfocenter"), QStringLiteral("kinfocenter")},
        {QStringLiteral("konsole"), QStringLiteral("konsole")},
        {QStringLiteral("discover"), QStringLiteral("plasma-discover")}
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
