{
  pkgs,
  ...
}:
{
  gcp-secret-subst = pkgs.callPackage ./gcp-secret-subst { };
  moneydance = pkgs.callPackage ./moneydance.nix { };
  openarc = pkgs.callPackage ./openarc.nix { };
  prometheus-jmx = pkgs.callPackage ./prometheus-jmx.nix { };
}
