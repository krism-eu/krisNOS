# THIS FILE IS OWNED BY krisNCC.
#
# krisNCC may change only this file, only after an explicit user action.
# Hand-written Nix belongs in free.nix or local-system.nix.
{ ... }:
{
  # Icicle-selected values live in the host configuration. The entries below
  # are the small structural surface intentionally owned by krisNCC.
  krisos.allowUnfreeSystemPackages = false;
  krisos.extraSystemPackages = [
    # krisNCC system packages: begin
    # krisNCC system packages: end
  ];
}
