# Prossimi interventi

Questo documento contiene soltanto attività ancora realmente aperte.

## P1 - Prima della VM e dell'installazione

- verificare in VM il modello iniziale account: `kris` senza password, autologin, `sudo -n` funzionante come wheel passwordless e password root separata impostata localmente;
- testare firewall/Bluetooth ON/OFF e Config -> Applica tramite gli helper fissi;
- testare realmente `ExecCondition` per lo stato persistente generale del firewall;
- verificare il comportamento del reverse path filter di firewalld nella revisione NixOS 26.05 utilizzata;
- avviare la VM generata e verificare Plasma, SDDM e sessione utente;
- avviare la ISO generata;
- aggiungere il vero `hardware-configuration.nix` a `krisNOS-config`;
- generare/committare il `flake.lock` definitivo di `krisNOS-config` dopo la revisione del framework;
- validare la configurazione reale dell'host `krisnos`;
- testare Config -> Applica: build utente, GC root temporaneo, switch root, registrazione commit+toplevel e stato corretto dopo rollback;
- verificare systemd-boot con `krisos.bootEntryLimit = 5`: numero di configurazioni visibili, default corrente e rollback; tenere separata la retention delle generazioni Nix sul disco;
- eseguire audit e hardening kernel/sysctl prima dell'installazione definitiva (ASLR, ptrace/Yama, dmesg/kptr, BPF, perf, moduli, lockdown e user namespaces), senza rompere AMD/Wayland/audio/Flatpak/Distrobox.

## Backend krisNCC

### Sistema

- NetworkManager / VPN
- Bluetooth: solo ON/OFF affidabile, nessuna priorità a pairing/dispositivi avanzati
- PipeWire / WirePlumber
- CUPS
- firewalld
- profili energetici
- servizi systemd e log selettivi con caricamento lazy

### App

- rifinire ricerca, installazione, aggiornamento e pacchetti unfree Nix
- backend Flatpak reale
- Distrobox: crea, entra, aggiorna e rimuovi

### Config

- opzioni Nix controllate da krisNCC
- anteprima e diff
- validazione e build
- Applica tramite helper fisso e `sudo -n` nella policy passwordless iniziale dell'host
- sincronizzazione Git manuale e separata da Applica

### Ripristino

- generazioni sistema
- generazioni profilo utente
- rollback
- pulizia e retention esplicite

### Strumenti

- fino a 12 comandi personali
- launcher
- diagnostica
- collegamento al backup esterno

## Pulizia repository ancora da verificare

- mantenere tutta la configurazione specifica della macchina esclusivamente in `krisNOS-config`;
- mantenere gli strumenti Podman usati per lo sviluppo fuori dal repository del framework.

## Gate finale

1. revisione sorgenti e diff
2. `nix flake check`
3. build krisNCC
4. test runtime krisNCC
5. valutazione krisNOS-config
6. audit/hardening kernel con test compatibilità
7. build e avvio VM
8. build e avvio ISO
9. test azioni privilegiate, boot entries e rollback
10. test hardware reale
11. commit raggruppati e push
