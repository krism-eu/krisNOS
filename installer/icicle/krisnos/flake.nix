{
  description = "Installed krisNOS configuration";

  # Both paths are substituted while the ISO is built and already exist in the
  # installer store. krisNOSSource is deliberately non-flake: the installed
  # system needs only its reusable modules, not its Icicle build dependencies.
  inputs = {
    nixpkgs.url = "path:@NIXPKGS_SOURCE@";
    krisNOSSource = {
      url = "path:@FRAMEWORK_SOURCE@";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      krisNOSSource,
      ...
    }:
    let
      system = "x86_64-linux";
      frameworkModule = builtins.toPath "${krisNOSSource}/modules";
      hostConfig = builtins.toPath (toString ./. + "/hosts/@HOSTNAME@/configuration.nix");
    in
    {
      nixosConfigurations."@HOSTNAME@" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit krisNOSSource;
          nixpkgsSource = builtins.toPath "${nixpkgs.outPath}";
        };
        modules = [
          frameworkModule
          hostConfig
        ];
      };
    };
}
