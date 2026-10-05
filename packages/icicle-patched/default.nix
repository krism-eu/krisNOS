{ upstreamIcicle }:

# Keep the upstream installer pinned by flake.lock and patch only the generated
# NixOS snippets that are incompatible with our framework/NixOS 26.05.
# --replace-fail is intentional: if upstream changes, the dedicated flake check
# fails while building this package instead of discovering the drift in the ISO.
upstreamIcicle.overrideAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    substituteInPlace src/utils/install.rs \
      --replace-fail 'services.xserver.displayManager.autoLogin.enable' 'krisos.autoLogin' \
      --replace-fail 'services.xserver.displayManager.autoLogin.user =' '# Icicle selected autologin user =' \
      --replace-fail 'services.xserver.layout' 'services.xserver.xkb.layout' \
      --replace-fail '    layout = "{}";' '    xkb.layout = "{}";' \
      --replace-fail 'xkbVariant =' 'xkb.variant ='
  '';
})
