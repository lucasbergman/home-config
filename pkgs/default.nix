{
  pkgs,
  ...
}:
{
  gcp-secret-subst = pkgs.callPackage ./gcp-secret-subst { };
  ip-abuse-report = pkgs.callPackage ./ip-abuse-report { };
  moneydance = pkgs.callPackage ./moneydance.nix { };
  openarc = pkgs.callPackage ./openarc.nix { };
  prometheus-jmx = pkgs.callPackage ./prometheus-jmx.nix { };
}
