{ upstreamIcicle, installerConfig }:

# Keep the upstream installer pinned by flake.lock, patch only the generated
# NixOS snippets needed by krisNOS/NixOS 26.05, and replace Icicle's packaged
# SnowflakeOS configuration with the exact krisNOS installer configuration.
# Icicle resolves its configuration from its own $out/etc/icicle path, not from
# /etc/icicle, so merely exposing environment.etc."icicle" is not sufficient.
upstreamIcicle.overrideAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    substituteInPlace src/utils/install.rs \
      --replace-fail 'services.xserver.displayManager.autoLogin.enable' 'krisos.autoLogin' \
      --replace-fail 'services.xserver.displayManager.autoLogin.user =' '# Icicle selected autologin user =' \
      --replace-fail 'services.xserver.layout' 'services.xserver.xkb.layout' \
      --replace-fail '    layout = "{}";' '    xkb.layout = "{}";' \
      --replace-fail 'xkbVariant =' 'xkb.variant ='
  '';

  postInstall = (old.postInstall or "") + ''
    rm -rf "$out/etc/icicle"
    mkdir -p "$out/etc/icicle"
    cp -R ${installerConfig}/. "$out/etc/icicle/"
  '';
})
