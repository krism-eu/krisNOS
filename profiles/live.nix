{
  config,
  lib,
  pkgs,
  ...
}:
{
  krisos = {
    userName = "kris";
    hostName = "krisos-live";
    autoLogin = true;
    bluetoothPowerOnBoot = false;
    mutableRuntime = true;
  };

  users.users.kris = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
      "audio"
      "lp"
    ];
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = true;

  # La live non deve chiedere credenziali per avviare/gestire Icicle.
  # La regola è volutamente limitata alla sola action Polkit dell'installer e
  # vive esclusivamente nel profilo ISO, quindi non viene installata nel sistema finale.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.snowflakeos.Icicle" &&
          subject.local &&
          subject.active &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # La ISO krisNOS non porta il manuale NixOS locale nel menu.
  documentation.nixos.enable = lib.mkForce false;

  # Solo per system.build.vm: consente i test del guest dal terminale host.
  # Non modifica né la configurazione installata né l'ISO.
  virtualisation.vmVariant = {
    services.openssh.enable = lib.mkForce true;

    services.openssh.settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };

    networking.firewall.allowedTCPPorts = [ 22 ];

    virtualisation.forwardPorts = [
      {
        from = "host";
        host.address = "127.0.0.1";
        host.port = 2222;
        guest.port = 22;
      }
    ];
  };

  system.stateVersion = "26.05";
}
