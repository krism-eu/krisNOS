# Decisioni architetturali attuali

1. Base: NixOS upstream 26.05.
2. Nessun fork profondo di altre distribuzioni.
3. Uso dei builder immagini nativi di NixOS.
4. `krisNOS` contiene il framework riutilizzabile; `krisNOS-config` contiene la configurazione personale della macchina.
5. Home Manager non è un requisito.
6. Nessun overlay scrivibile generico su `/etc` o `/nix/store`.
7. Le normali applicazioni appartengono a `nix profile` o Flatpak.
8. I demoni necessari al desktop sono dichiarati da NixOS, mentre lo stato quotidiano resta gestito tramite API e stato nativi.
9. Nessun server SSH predefinito.
10. Plasma 6 Wayland è la sessione principale; XWayland può rimanere per compatibilità.
11. Il numero di pacchetti di sistema deve rimanere ridotto.
12. I test locali sono il percorso principale di sviluppo; GitHub CI non è obbligatorio.
13. firewalld usa il backend NixOS supportato con nftables abilitato.
14. Hardware e configurazione specifica della macchina vivono soltanto in `krisNOS-config`.
15. Il profilo live usa password temporanea e sudo senza password; l’host personale iniziale usa autologin, utente `kris` senza password e `wheel` passwordless. La password root viene impostata localmente e non versionata. Questa policy è intenzionalmente temporanea e modificabile.
16. Lo stato persistente personalizzato da Kris deve restare minimo: attualmente solo lo stato generale del firewall.
17. `kris-runtimectl` persiste esclusivamente la piccola policy firewall e fornisce anche una mutazione privilegiata allowlisted della radio Bluetooth.
18. Per Bluetooth la priorità funzionale è soltanto un ON/OFF affidabile: BlueZ rappresenta `Powered`, rfkill gestisce soft/hard block; niente gestione dispositivi avanzata finché non serve.
19. `kris-app` rifiuta l'esecuzione come root e il supporto unfree è esplicito.
20. `--impure` è limitato al percorso unfree esplicito.
21. `system.stateVersion` appartiene all'host/profilo e non al modulo riutilizzabile.
22. Il garbage collection automatico resta disabilitato finché la retention non sarà resa chiara in krisNCC.
23. Distrobox è l'interfaccia utente per gli ambienti mutabili; Podman resta infrastruttura sottostante.
24. Lo scambio della configurazione GitHub è esclusivamente manuale: niente timer, polling, pull o apply automatici.
25. `krisNOS` e `krisNOS-config` sono repository separati.
26. `krisNOS-config` non contiene segreti in chiaro né database runtime nativi.
27. La revisione Nix è fissata dal `flake.lock`; krisNOS non sovrascrive `nix.registry.nixpkgs`.
28. ISO e VM sono output pesanti espliciti, non normali check del flake.
29. krisNCC deve preferire API e strumenti nativi rispetto a state machine personalizzate.
30. Build e valutazione della configurazione utente avvengono senza privilegi; le mutazioni root passano solo attraverso helper fissi.
31. Nella configurazione personale iniziale `kris` è deliberatamente amministratore passwordless (`wheelNeedsPassword = false`). krisNCC usa `sudo -n` soltanto verso helper fissi e validati, ma questa non è una barriera di sicurezza contro altri processi dell'utente: l'account `kris` è amministrativamente root-equivalente per scelta.
32. systemd-boot mantiene come baseline 5 configurazioni tramite `krisos.bootEntryLimit = 5`; la retention delle generazioni Nix sul disco resta una policy separata ed esplicita.
33. Prima dell'installazione definitiva va eseguito un audit/hardening del kernel e dei sysctl, privilegiando protezioni con beneficio reale e compatibilità con AMD/Wayland/Flatpak/Distrobox.
