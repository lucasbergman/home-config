{
  pkgs,
  ...
}:
{
  gcp-secret-subst = pkgs.callPackage ./gcp-secret-subst { };
  moneydance = pkgs.callPackage ./moneydance.nix { };
  prometheus-jmx = pkgs.callPackage ./prometheus-jmx.nix { };
}
