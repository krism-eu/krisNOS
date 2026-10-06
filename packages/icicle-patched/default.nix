{ upstreamIcicle, installerConfig }:

# Keep the upstream installer pinned by flake.lock, patch only the generated
# NixOS snippets needed by krisNOS/NixOS 26.05, and replace Icicle's packaged
# SnowflakeOS configuration with the exact krisNOS installer configuration.
#
# Icicle 0.0.2 uses /tmp/icicle both as the mounted target root and as the flake
# path. Nix 2.35 rejects flakes below world-writable /tmp, while allowing
# nixos-install to write flake.lock inside that same tree can change its NAR hash
# during evaluation. Use the conventional /mnt target and keep the temporary
# installer flake read-only while nixos-install evaluates it.
upstreamIcicle.overrideAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    substituteInPlace src/utils/install.rs \
      --replace-fail 'services.xserver.displayManager.autoLogin.enable' 'krisos.autoLogin' \
      --replace-fail 'services.xserver.displayManager.autoLogin.user =' '# Icicle selected autologin user =' \
      --replace-fail 'services.xserver.layout' 'services.xserver.xkb.layout' \
      --replace-fail '    layout = "{}";' '    xkb.layout = "{}";' \
      --replace-fail 'xkbVariant =' 'xkb.variant =' \
      --replace-fail '/tmp/icicle' '/mnt' \
      --replace-fail '"--no-channel-copy",' '"--no-channel-copy", "--no-write-lock-file",'

    substituteInPlace icicle-helper/src/main.rs \
      --replace-fail '/tmp/icicle' '/mnt'
  '';

  postInstall = (old.postInstall or "") + ''
    rm -rf "$out/etc/icicle"
    mkdir -p "$out/etc/icicle"
    cp -R ${installerConfig}/. "$out/etc/icicle/"
  '';
})
