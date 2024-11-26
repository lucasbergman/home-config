{
  pkgs,
  pkgs-unstable,
  ...
}:
{
  gcp-secret-subst = pkgs.callPackage ./gcp-secret-subst { };
  moneydance = pkgs.callPackage ./moneydance.nix {
    openjdk23 = pkgs-unstable.openjdk23;
    jvmFlags = [ "-Dawt.useSystemAAFontSettings=on" ];
  };
  prometheus-jmx = pkgs.callPackage ./prometheus-jmx.nix { };
}
