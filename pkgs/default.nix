{
  pkgs,
  pkgs-unstable,
}: {
  cat-gcp-secret = pkgs.callPackage ./cat-gcp-secret {};
  gcp-secret-subst = pkgs.callPackage ./gcp-secret-subst {};
  moneydance = pkgs.callPackage ./moneydance.nix {};
  prometheus-jmx = pkgs.callPackage ./prometheus-jmx.nix {};

  unifi = let
    ver = "7.5.187";
    sha = "6b9925f2065b467852fe9d6298f97bb28334fd04851dd334fb66cd9837dcd666";
  in
    pkgs-unstable.unifi.overrideAttrs {
      name = "unifi-controller-${ver}";
      src = pkgs-unstable.fetchurl {
        url = "https://dl.ubnt.com/unifi/${ver}/unifi_sysvinit_all.deb";
        sha256 = sha;
      };
    };
}
