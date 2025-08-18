{
  pkgs,
  ...
}:
{
  gcp-secret-subst = pkgs.callPackage ./gcp-secret-subst { };
  prometheus-jmx = pkgs.callPackage ./prometheus-jmx.nix { };
}
