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

## Branch e installazione con Icicle

- `main` contiene il framework, i moduli NixOS, gli helper e krisNCC.
- [`iso`](https://github.com/krism-eu/krisNOS/tree/iso) contiene Icicle, i template di installazione, i profili live e gli script ISO/VM.
- [`krisNOS-config`](https://github.com/krism-eu/krisNOS-config) contiene la configurazione personale.

La branch `iso` importa una revisione esatta di `main`, fissata nel proprio `flake.lock`. Un aggiornamento di `main` non aggiorna automaticamente le ISO: l'adozione del nuovo framework richiede un aggiornamento esplicito del lock nella branch `iso`.

Icicle prepara e monta le partizioni scelte, esegue `nixos-generate-config` sul sistema di destinazione e installa tramite `nixos-install --flake`. La configurazione generata usa i moduli del framework e nixpkgs tramite input locali `path:` corrispondenti alle sorgenti incorporate nella ISO.

Al termine dell'installazione la configurazione generata resta in `/etc/nixos`, compreso il vero `hardware-configuration.nix` prodotto sulla macchina reale. L'installer non crea né inizializza `~/krisNOS-config` e non crea una storia Git parallela. Dopo il primo avvio si clona il repository personale canonico in `~/krisNOS-config`, si copia e si controlla il file hardware generato in `hosts/krisnos/hardware-configuration.nix`, quindi si valida, costruisce e applica la configurazione tramite krisNCC/`kris-configctl`.

Per i comandi di build e la verifica di installazione e primo avvio, vedere il [README della branch ISO](https://github.com/krism-eu/krisNOS/blob/iso/README.md).

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

## Struttura della branch main

- `flake.nix` e `flake.lock`
- `modules/`
- `packages/`
- `krisncc/`
- `docs/`
- `.github/workflows/nix.yml`

## Output e controlli del framework

```bash
nix build --no-update-lock-file .#krisNCC
nix build --no-update-lock-file --no-link .#checks.x86_64-linux.krisos-system
```

Sono disponibili anche i pacchetti `kris-app`, `kris-configctl`, `kris-runtimectl` e `kris-system-activate`.

La CI di `main` verifica il formato e costruisce il sistema completo con un filesystem sintetico. Questa build non sostituisce il test dell'installer e del primo avvio sul computer reale.

Gli output `iso`, `vm`, `icicle-patched` e `installer-config`, insieme agli script `scripts/check.sh`, `scripts/build-iso.sh` e `scripts/build-vm.sh`, appartengono esclusivamente alla branch `iso`.

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
