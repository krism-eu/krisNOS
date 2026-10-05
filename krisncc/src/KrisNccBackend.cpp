#include "KrisNccBackend.h"

#include <QDir>
#include <QFile>
#include <QHash>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>
#include <QSysInfo>

#include <algorithm>

KrisNccBackend::KrisNccBackend(QObject *parent)
    : QObject(parent)
{
    refreshResources();
    refreshConfigStatus();
    refreshRuntimeStatus();
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

void KrisNccBackend::startCommand(const QString &program, const QStringList &arguments,
                                  const QString &operation, bool userOperation)
{
    const QString executable = QStandardPaths::findExecutable(program);
    if (executable.isEmpty()) {
        setMessage(tr("Comando non disponibile: %1").arg(program));
        return;
    }
    if (userOperation && m_busy) {
        setMessage(tr("Un'altra operazione è già in corso."));
        return;
    }
    if (userOperation)
        setBusy(true);

    auto *process = new QProcess(this);
    process->setProcessChannelMode(QProcess::SeparateChannels);
    connect(process, &QProcess::finished, this,
            [this, process, operation, userOperation](int exitCode, QProcess::ExitStatus status) {
        const QByteArray out = process->readAllStandardOutput();
        const QByteArray err = process->readAllStandardError();
        handleCommandResult(operation, status == QProcess::NormalExit ? exitCode : 127, out, err);
        if (userOperation)
            setBusy(false);
        process->deleteLater();
    });
    process->start(executable, arguments);
}

void KrisNccBackend::startRuntimeMutation(const QString &feature, bool enabled)
{
    if (feature != QStringLiteral("bluetooth") && feature != QStringLiteral("firewall"))
        return;
    const QString pkexec = QStandardPaths::findExecutable(QStringLiteral("pkexec"));
    const QString helper = QStandardPaths::findExecutable(QStringLiteral("kris-runtimectl"));
    if (pkexec.isEmpty() || helper.isEmpty()) {
        setMessage(tr("Percorso amministrativo non disponibile."));
        return;
    }
    startCommand(pkexec, {helper, feature, enabled ? QStringLiteral("on") : QStringLiteral("off")},
                 QStringLiteral("runtime-mutation"), true);
}

QString KrisNccBackend::nixAttributeFromSearchKey(const QString &key)
{
    const QString archMarker = QStringLiteral(".%1.").arg(QSysInfo::currentCpuArchitecture());
    const int pos = key.indexOf(archMarker);
    return pos >= 0 ? key.mid(pos + archMarker.size()) : key.section(QLatin1Char('.'), -1);
}

void KrisNccBackend::handleCommandResult(const QString &operation, int exitCode,
                                         const QByteArray &out, const QByteArray &err)
{
    const QString errorText = QString::fromUtf8(err).trimmed();
    const QString outputText = QString::fromUtf8(out).trimmed();
    if (exitCode != 0) {
        setMessage(errorText.isEmpty() ? tr("Operazione non riuscita (%1).").arg(exitCode) : errorText.left(1200));
        if (operation == QStringLiteral("runtime-mutation"))
            refreshRuntimeStatus();
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
            m_runtimeStatus = doc.object().toVariantMap();
            emit runtimeStatusChanged();
        }
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
        bool serialOk = false;
        const quint64 serial = operation.section(QLatin1Char(':'), 1, 1).toULongLong(&serialOk);
        if (!serialOk || serial != m_searchSerial)
            return;
        const QJsonDocument doc = QJsonDocument::fromJson(out);
        QVariantList list;
        if (doc.isObject()) {
            const QJsonObject root = doc.object();
            int count = 0;
            for (auto it = root.begin(); it != root.end() && count < 60; ++it, ++count) {
                const QJsonObject meta = it.value().toObject();
                QVariantMap row;
                row.insert(QStringLiteral("attribute"), nixAttributeFromSearchKey(it.key()));
                row.insert(QStringLiteral("name"), meta.value(QStringLiteral("pname")).toString());
                row.insert(QStringLiteral("version"), meta.value(QStringLiteral("version")).toString());
                row.insert(QStringLiteral("description"), meta.value(QStringLiteral("description")).toString());
                list.append(row);
            }
        }
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
        || operation == QStringLiteral("config-build"))
        refreshConfigStatus();
    if (operation == QStringLiteral("runtime-mutation"))
        refreshRuntimeStatus();
    if (operation == QStringLiteral("software-add") || operation == QStringLiteral("software-remove"))
        refreshSoftware();

    const QString message = !outputText.isEmpty() ? outputText : errorText;
    setMessage(message.isEmpty() ? tr("Operazione completata.") : message.left(1200));
}

void KrisNccBackend::refreshConfigStatus() { startCommand(QStringLiteral("kris-configctl"), {QStringLiteral("status"), QStringLiteral("--json")}, QStringLiteral("config-status")); }
void KrisNccBackend::fetchConfig() { startCommand(QStringLiteral("kris-configctl"), {QStringLiteral("fetch")}, QStringLiteral("config-fetch"), true); }
void KrisNccBackend::showConfigDiff() { startCommand(QStringLiteral("kris-configctl"), {QStringLiteral("diff")}, QStringLiteral("config-diff"), true); }
void KrisNccBackend::syncConfig() { startCommand(QStringLiteral("kris-configctl"), {QStringLiteral("sync")}, QStringLiteral("config-sync"), true); }
void KrisNccBackend::validateConfig() { startCommand(QStringLiteral("kris-configctl"), {QStringLiteral("validate")}, QStringLiteral("config-validate"), true); }
void KrisNccBackend::buildConfig() { startCommand(QStringLiteral("kris-configctl"), {QStringLiteral("build")}, QStringLiteral("config-build"), true); }
void KrisNccBackend::refreshRuntimeStatus() { startCommand(QStringLiteral("kris-runtimectl"), {QStringLiteral("status"), QStringLiteral("--json")}, QStringLiteral("runtime-status")); }
void KrisNccBackend::setBluetoothEnabled(bool enabled) { startRuntimeMutation(QStringLiteral("bluetooth"), enabled); }
void KrisNccBackend::setFirewallEnabled(bool enabled) { startRuntimeMutation(QStringLiteral("firewall"), enabled); }
void KrisNccBackend::refreshSoftware() { startCommand(QStringLiteral("kris-app"), {QStringLiteral("list"), QStringLiteral("--json")}, QStringLiteral("software-list")); }
void KrisNccBackend::searchSoftware(const QString &query)
{
    if (query.trimmed().isEmpty())
        return;
    ++m_searchSerial;
    startCommand(QStringLiteral("kris-app"), {QStringLiteral("search"), QStringLiteral("--json"), query.trimmed()}, QStringLiteral("software-search:%1").arg(m_searchSerial));
}
void KrisNccBackend::addSoftware(const QString &attribute, bool allowUnfree) { QStringList a{QStringLiteral("add")}; if (allowUnfree) a << QStringLiteral("--unfree"); a << attribute; startCommand(QStringLiteral("kris-app"), a, QStringLiteral("software-add"), true); }
void KrisNccBackend::runSoftware(const QString &attribute)
{
    const QString helper = QStandardPaths::findExecutable(QStringLiteral("kris-app"));
    if (helper.isEmpty() || attribute.trimmed().isEmpty()) {
        setMessage(tr("Impossibile avviare il programma di prova."));
        return;
    }
    if (!QProcess::startDetached(helper, {QStringLiteral("run"), attribute.trimmed()}))
        setMessage(tr("Avvio del programma di prova non riuscito."));
}
void KrisNccBackend::removeSoftware(const QString &name) { startCommand(QStringLiteral("kris-app"), {QStringLiteral("remove"), name}, QStringLiteral("software-remove"), true); }
void KrisNccBackend::previewSoftwareUpdates() { startCommand(QStringLiteral("kris-app"), {QStringLiteral("upgrade"), QStringLiteral("--dry-run")}, QStringLiteral("software-updates"), true); }
void KrisNccBackend::refreshDistroboxes() { startCommand(QStringLiteral("distrobox"), {QStringLiteral("list"), QStringLiteral("--no-color")}, QStringLiteral("distrobox-list")); }
void KrisNccBackend::refreshRecovery() { startCommand(QStringLiteral("nix-env"), {QStringLiteral("--list-generations"), QStringLiteral("-p"), QStringLiteral("/nix/var/nix/profiles/system")}, QStringLiteral("system-generations")); startCommand(QStringLiteral("kris-app"), {QStringLiteral("history")}, QStringLiteral("profile-history")); }

bool KrisNccBackend::launchTool(const QString &toolId) const
{
    static const QHash<QString, QString> tools = {
        {QStringLiteral("systemsettings"), QStringLiteral("systemsettings")},
        {QStringLiteral("kinfocenter"), QStringLiteral("kinfocenter")},
        {QStringLiteral("konsole"), QStringLiteral("konsole")},
        {QStringLiteral("discover"), QStringLiteral("plasma-discover")}
    };
    const QString program = QStandardPaths::findExecutable(tools.value(toolId));
    return !program.isEmpty() && QProcess::startDetached(program, {});
}
