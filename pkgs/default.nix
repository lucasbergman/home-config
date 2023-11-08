{
  pkgs,
  pkgs-unstable,
}: {
  cat-gcp-secret = pkgs.callPackage ./cat-gcp-secret {};
  gcp-secret-subst = pkgs.callPackage ./gcp-secret-subst {};

  unifi = let
    ver = "7.4.162";
    sha = "069652f793498124468c985537a569f3fe1d8dd404be3fb69df6b2d18b153c4c";
  in
    pkgs-unstable.unifi.overrideAttrs {
      name = "unifi-controller-${ver}";
      src = pkgs-unstable.fetchurl {
        url = "https://dl.ubnt.com/unifi/${ver}/unifi_sysvinit_all.deb";
        sha256 = sha;
      };
    };
}
