# krisNOS

Architettura desktop personale basata su NixOS:

**piccolo nucleo dichiarativo + stato quotidiano mutabile + centro di controllo krisNCC**

Obiettivo: una singola macchina desktop personale x86_64 AMD, mantenendo il framework riutilizzabile separato dalla configurazione specifica del computer.

## Architettura

### krisNOS

`krisNOS` contiene il framework riutilizzabile del sistema:

- NixOS 26.05
- supporto AMD / amdgpu
- Plasma 6 / Wayland
- SDDM
- NetworkManager
- PipeWire / WirePlumber
- BlueZ
- CUPS
- firewalld
- Flatpak
- Distrobox con Podman rootless come motore sottostante
- Polkit
- ZRAM
- fstrim
- krisNCC
- piccoli helper usati da krisNCC

Il framework non contiene la configurazione hardware personale della macchina.

### krisNOS-config

`krisNOS-config` contiene la configurazione della macchina installata:

- `hardware-configuration.nix`
- impostazioni specifiche dell'host
- override strutturali
- impostazioni Nix gestite da krisNCC
- configurazione Nix personale libera
- preferenze krisNCC portabili e non sensibili

La dipendenza è unidirezionale:

    krisNOS-config
          |
          v
       krisNOS

## Stato mutabile quotidiano

Lo stato normale del desktop resta affidato al componente che lo gestisce nativamente:

- NetworkManager: connessioni, VPN e DNS
- BlueZ / rfkill: stato Bluetooth
- PipeWire / WirePlumber: stato audio
- CUPS: stampanti
- firewalld: zone, regole e servizi
- power-profiles-daemon: profilo energetico
- KDE: KConfig
- Flatpak: applicazioni e relativo stato
- Distrobox: ambienti Linux mutabili
- `nix profile`: applicazioni Nix personali

Non esiste alcun overlay scrivibile generico sopra `/etc` o `/nix/store`.

`/var/lib/krisos/runtime.conf` esiste soltanto per la piccola policy persistente relativa allo stato generale del firewall.

## Struttura del repository

- `flake.nix`
- `flake.lock`
- `modules/`
- `packages/`
- `profiles/live.nix`
- `krisncc/`
- `docs/`
- `scripts/`

Il framework non contiene più una copia duplicata della configurazione personale della macchina.

## Output principali

- `nix build .#krisNCC`
- `nix build .#iso`
- `nix build .#vm`

ISO e VM sono output pesanti espliciti e non fanno parte dei normali controlli del flake.

## Stato verificato

- `nix flake check --no-build`: PASS
- build krisNCC: PASS
- runtime offscreen krisNCC: PASS
- valutazione derivazione ISO: PASS
- valutazione derivazione VM: PASS
- build completa ISO: PASS
- avvio VM: non ancora verificato
- installazione fisica: non ancora verificata

## krisNCC

Aree principali:

- Home
- Sistema
- App
- Config
- Ripristino
- Strumenti

krisNCC deve offrire molte funzioni utili mantenendo poca complessità personalizzata. Si preferiscono API e strumenti nativi invece di duplicare i meccanismi interni di NetworkManager, BlueZ, CUPS, firewalld, Nix, Flatpak o Distrobox.

## Applicazioni personali

Le normali applicazioni appartengono al profilo utente Nix o a Flatpak, non alla generazione del sistema.

Esempi:

- `kris-app search vlc`
- `kris-app add vlc`
- `kris-app add --unfree spotify`
- `kris-app list`
- `kris-app remove vlc`
- `kris-app upgrade --dry-run`
- `kris-app history`
- `kris-app rollback`

`--impure` viene utilizzato soltanto nel percorso esplicito per i pacchetti non liberi.

## Helper runtime

`kris-runtimectl` è volutamente molto limitato:

- `kris-runtimectl status`
- `sudo kris-runtimectl firewall off`
- `sudo kris-runtimectl firewall on`
- `sudo kris-runtimectl bluetooth off`
- `sudo kris-runtimectl bluetooth on`

Solo lo stato generale del firewall viene persistito da Kris.
Per il Bluetooth l'helper espone esclusivamente la mutazione privilegiata della radio tramite rfkill; stato, pairing e dispositivi restano di proprietà BlueZ/rfkill.

`kris-system-activate` registra e attiva esclusivamente un toplevel NixOS già costruito; krisNCC lo invoca tramite `sudo -n` nella policy amministrativa passwordless iniziale dell'host.

## Modello GitHub

La sincronizzazione con GitHub è opzionale e sempre manuale.

Non esistono:

- timer
- pull automatici all'avvio
- sincronizzazione automatica
- applicazione automatica della configurazione
- polling in background

Le modifiche di sviluppo vengono prima verificate completamente in locale e solo successivamente inviate ai repository.
